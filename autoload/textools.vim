"-----------------------------------------------------------------------------"
" Running latexmk in background
"-----------------------------------------------------------------------------"
let s:vim8 = has('patch-8.0.0039') && exists('*job_start')  " copied from autoreload/plug.vim
let s:path = expand('<sfile>:p:h')
function! textools#latex_background(...) abort
  if !s:vim8
    echohl WarningMsg
    echom 'Error: Latex compilation requires vim >= 8.0'
    echohl None
    return 1
  endif
  " Jump to logfile if it is open, else open one
  " Warning: Trailing space will be escaped as a flag! So trim it unless
  " we have any options
  let opts = trim(a:0 ? a:1 : '') " flags
  if opts !=# ''
    let opts = ' ' . opts
  endif
  let texfile = expand('%')
  let logfile = 'latexmk.log'
  let lognum = bufwinnr(logfile)
  if lognum == -1
    silent! exe string(winheight('.') / 4) . 'split ' . logfile
    silent! exe winnr('#') . 'wincmd w'
  else
    silent! exe bufwinnr(logfile) . 'wincmd w'
    silent! 1,$d
    silent! exe winnr('#') . 'wincmd w'
  endif
  " Run job in realtime
  let num = bufnr(logfile)
  echom s:path . '/../latexmk'
  let g:tex_job = job_start(s:path . '/../latexmk ' . texfile . opts,
      \ { 'out_io': 'buffer', 'out_buf': num })
endfunction

"-----------------------------------------------------------------------------"
" Displaying surround and snippet mappings
"-----------------------------------------------------------------------------"
function! s:bindings_table(table) abort
  " Return a nice displayable list of bindings
  let nspace = max(map(keys(a:table), 'len(v:val)'))
  let mspace = max(map(values(a:table), 'type(v:val) == 1 ? len(v:val) : len(v:val[0])'))  " might be just string
  let bindings = []
  for [key, value] in items(a:table)
    " Support for tables with 'value' and ['left', 'right'] values
    if type(value) == 1  " string
      let values = [value]
    elseif type(value) == 3  " list
      let values = value
    else
      echohl WarningMsg
      echom 'Error: Invalid table dictionary'
      echohl None
      return
    endif
    " Get key and value strings
    let keystring = key . ':' . repeat(' ', nspace - len(key) + 1)
    let valstring = ''
    for i in range(len(values))
      let val = substitute(values[i], "\n", '\\n', 'g')
      let quote = (val =~# "'" ? '"' : "'")
      let suffix = (i < len(values) - 1 && len(values) > 1 ? ',' : '')
      let suffix .= (i == 0 ? repeat(' ', mspace - len(val) + 3) : '')
      let valstring .= quote . val . quote . suffix
    endfor
    call add(bindings, keystring . valstring)
  endfor
  return join(bindings, "\n")
endfunction

function! textools#show_bindings(prefix, table) abort
  " Show the entire table
  let header = 'Table of ' . a:prefix . "<KEY> bindings:\n"
  echo header . s:bindings_table(a:table)
endfunction

function! textools#find_bindings(prefix, table, regex) abort
  " Find the matching entry/entries
  let table_filtered = {}
  for [key, value] in items(a:table)
    if type(value) == 1
      let val = value
    else
      let val = value[0]
    endif
    if val =~# a:regex
      let table_filtered[key] = val
    endif
  endfor
  if len(table_filtered) == 0
    echohl WarningMsg
    echom "Error: No mappings found for regex '" . a:regex . "'"
    echohl None
    return
  endif
  let header = (len(table_filtered) == 1 ? '' : "Bindings matching regex '" . a:regex . "':\n")
  echo header . s:bindings_table(table_filtered)
endfunction

"-----------------------------------------------------------------------------"
" Changing and deleting surrounding delim
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
      echohl None
      return
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

" Run citation vim and enter insert mode
function! textools#citation_vim_run(suffix, opts) abort
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
