"-----------------------------------------------------------------------------"
" Since vim-surround does not support the 'dsX' and 'csX' maps for custom
" delimiters, we define custom functions that can be mapped to 'dsX' and 'csX'
" for deleting and changing arbitrary delimiters
"-----------------------------------------------------------------------------"
" Driver function, accepts left and right delims, and normal mode commands run
" from the leftmost character of left and right delims. This function sets
" the mark 'z to the end of each delim, so e.g. 'd`zx' works
" NOTE: Mark motion commands only work up until and excluding the mark, so
" make sure your command accounts for that!
function! s:pair_action(left, right, lexpr, rexpr)
  " Check
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
  " NOTE: Right must come first!
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

" Delete delims
function! textools#delete_delims(left, right)
  call s:pair_action(a:left, a:right, "d`zx", "d`zx")
endfunction

" Change delims
function! textools#change_delims(left, right, replace)
  if a:replace != ''
    let group = '\\(.*\\)' " match for group
    let nleft = substitute(a:left, group, a:replace, '')
    let nright = substitute(a:right, group, a:replace, '')
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
  call s:pair_action(a:left, a:right, "c`z" . nleft . "\<Delete>", "c`z" . nright . "\<Delete>")
endfunction

