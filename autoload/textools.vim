"-----------------------------------------------------------------------------"
" Surrounding delim modifications
" Since vim-surround does not support the 'dsX' and 'csX' maps for custom
" delimiters, we define custom functions that can be mapped to 'dsX' and 'csX'
" for deleting and changing arbitrary delimiters
"-----------------------------------------------------------------------------"
" Driver function that accepts left and right delims, and normal mode commands
" run from the leftmost character of left and right delims. This function sets
" the mark 'z to the end of each delim, so expression can be d`zx
" Note: Mark motion commands only work up until and excluding the mark, so
" make sure your command accounts for that!
function! s:pair_action(left, right, lexpr, rexpr) abort
  if !exists('*searchpairpos') " older versions
    return
  endif

  " Get pairs
  let pos1 = searchpairpos(a:left, '', a:right, 'bnW') " set '' mark at current location
  let pos2 = searchpairpos(a:left, '', a:right, 'nW')
  let [l1, c11] = pos1
  let [l2, c21] = pos2
  if l1 == 0 || l2 == 0
    return
  endif

  " Delete or change right delim
  " Note: Right must come first!
  call cursor(l2, c21)
  let [l2, c22] = searchpos(a:right, 'cen')
  call setpos("'z", [0, l2, c22, 0])
  exe 'normal! "_' . a:rexpr

  " Delete or change left delim
  call cursor(l1, c11)
  let [l1, c12] = searchpos(a:left, 'cen')
  call setpos("'z", [0, l1, c12, 0])
  exe 'normal! "_' . a:lexpr
endfunction

" Delete delims function
function! textools#delete_delims(left, right) abort
  call s:pair_action(a:left, a:right, 'd`zx', 'd`zx')
endfunction

" Change delims function, use input replacement text
" or existing mapped surround character
function! textools#change_delims(left, right, ...) abort
  if a:0
    let [nleft, nright] = split(a:1, "\r")
  else
    let cnum = getchar()
    if exists('b:surround_' . cnum)
      let [nleft, nright] = split(b:surround_{cnum}, "\r")
    elseif exists('g:surround_' . cnum)
      let [nleft, nright] = split(g:surround_{cnum}, "\r")
    else
      echohl WarningMsg
      echom 'Warning: Replacement delim code "' . nr2char(cnum) . '" not found.'
      echohl None | return
    endif
  endif
  call s:pair_action(
    \ a:left, a:right,
    \ 'c`z' . nleft . "\<Delete>", 'c`z' . nright . "\<Delete>"
  \ )
endfunction

"-----------------------------------------------------------------------------"
" Citation vim integration
"-----------------------------------------------------------------------------"
" Run citation vim and enter insert mode
function! s:citation_vim_run(suffix, opts) abort
  if b:citation_vim_mode ==# 'bibtex' && b:citation_vim_bibtex_file ==# ''
    let b:citation_vim_bibtex_file = s:citation_vim_bibfile()
  endif
  let g:citation_vim_mode = b:citation_vim_mode
  let g:citation_vim_outer_prefix = '\cite' . a:suffix . '{'
  let g:citation_vim_bibtex_file = b:citation_vim_bibtex_file
  call unite#helper#call_unite('Unite', a:opts, line('.'), line('.'))
  silent! normal! a
  return ''
endfunction

" Ask user to select bibliography files from list
" Requires special completion function for selecting bibfiles
function! s:citation_vim_bibfile() abort
  let cwd = expand('%:h')
  let refs = split(glob(cwd . '/*.bib'), "\n")
  if len(refs) == 1
    let ref = refs[0]
  elseif len(refs)
    let items = fzf#run({'source':refs, 'options':'--no-sort', 'down':'~30%'})
    if len(items)
      let ref = items[0]
    else " user cancelled or entered invalid name
      let ref = refs[0]
    endif
  else
    echohl WarningMsg
    echom 'Warning: No .bib files found in file directory.'
    echohl None
    let ref = ''
  endif
  return ref
endfunction

" Citation toggle function
function! textools#citation_vim_toggle(...) abort
  " Get citation mode
  let mode_prev = b:citation_vim_mode
  let file_prev = b:citation_vim_bibtex_file
  if a:0
    let b:citation_vim_mode = (a:1 ? 'bibtex' : 'zotero')
  elseif b:citation_vim_mode ==# 'bibtex'
    let b:citation_vim_mode = 'zotero'
  else
    let b:citation_vim_mode = 'bibtex'
  endif

  " Toggle mode
  if b:citation_vim_mode ==# 'bibtex'
    if b:citation_vim_bibtex_file ==# ''
      let b:citation_vim_bibtex_file = s:citation_vim_bibfile()
    endif
    echom 'Using BibTex file: ' . expand(b:citation_vim_bibtex_file)
  else
    echom 'Using Zotero database: ' . expand(g:citation_vim_zotero_path)
  endif

  " Delete cache
  if mode_prev != b:citation_vim_mode || file_prev != b:citation_vim_bibtex_file
    call delete(expand(g:citation_vim_cache_path . '/citation_vim_cache'))
  endif
endfunction
