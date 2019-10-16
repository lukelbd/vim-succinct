"-----------------------------------------------------------------------------"
" Define global functions for use in ftplugin/tex.vim
" so users can also use them in .vimrc
"-----------------------------------------------------------------------------"
" Delete delims function
" Unfortunately vim-surround does not support the 'dsX' and 'csX' maps for
" custom delimiters, only insertion. We make our own maps.
" NOTE: This is fairly primitive as it relies on last character of each
" delimiter occurs once, and is not part of a regex e.g. \w! Prevents us from
" having to directly manipulate lines as strings.
function! DeleteDelims(left, right, ...) " pass 1 to search multiple lines
  if a:0 && a:1
    let l1 = 1
    let l2 = line('$')
  else
    let l1 = line('.') " search only current line
    let l2 = l1
  endif
  if search(a:right, 'n', l2) == 0 || search(a:left, 'nb', l1) == 0
    return
  endif
  " NOTE: For some reason cannot use -ve indexing for strings, only lists
  call search(a:right, '')
  if len(a:right) == 1
    exe 'normal! x'
  else
    exe 'normal! df' . a:right[len(a:right)-1]
  endif
  call search(a:left, 'b')
  if len(a:left) == 1
    exe 'normal! x'
  else
    exe 'normal! df' . a:left[len(a:left)-1]
  endif
endfunction

" Replace delims func
" Pass extra argument '1' to search multiple lines
" NOTE: If replace is empty, we look for left and right delims from existing
" surround variables! Useful for \left(\right) delims!
" NOTE: Make these funcs global so they can be used
" in the plugins setup
function! ChangeDelims(left, right, replace, ...)
  if a:0 && a:1
    let l1 = 1
    let l2 = line('$')
  else
    let l1 = line('.') " search only current line
    let l2 = l1
  endif
  if search(a:right, 'n', l2) == 0 || search(a:left, 'nb', l1) == 0
    return
  endif
  " Get replacement strings
  if a:replace != ''
    let group = '\\(.*\\)' " match for group
    let left = substitute(a:left, group, a:replace, '')
    let right = substitute(a:right, group, a:replace, '')
  else
    let cnum = getchar()
    if exists('b:surround_' . cnum)
      let [left, right] = split(b:surround_{cnum}, "\r")
    elseif exists('g:surround_' . cnum)
      let [left, right] = split(g:surround_{cnum}, "\r")
    else
      echohl WarningMsg
      echom 'Warning: Replacement delim code "' . nr2char(cnum) . '" not found.'
      echohl None
      return
    endif
    echo "hi! " . cnum . ' ' . left . ' ' . right
  endif
  " Replace
  call search(a:right, '')
  if len(a:right) == 1
    let cmd = 'cf' . a:right[len(a:right)-1]
  else
    let cmd = 'cl'
  endif
  exe 'normal! ' . cmd . right
  call search(a:left, 'b')
  if len(a:left) == 1
    let cmd = 'cf' . a:left[len(a:left)-1]
  else
    let cmd = 'cl'
  endif
  exe 'normal! ' . cmd . left
endfunction

