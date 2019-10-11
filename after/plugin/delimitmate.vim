"------------------------------------------------------------------------------"
" Very simple script, just adds a handy mapping
"------------------------------------------------------------------------------"
" Dependencies
if !g:loaded_delimitMate
  echom "Warning: vim-textools requires delimitMate, disabling some features."
  finish
endif
" Map to 'ctrl-.' which is remapped to <F2> in my iTerm session
if !exists('g:textools_delimjump_regex')
  let g:textools_delimjump_regex = "[()\\[\\]{}<>]" "list of 'outside' delimiters for jk matching
endif
if !exists('g:textools_prevdelim_map')
  let g:textools_prevdelim_map = '<F1>'
endif
if !exists('g:textools_nextdelim_map')
  let g:textools_nextdelim_map = '<F2>'
endif
" Make mapping
exe 'imap '.g:textools_prevdelim_map.' <Plug>textools-prevdelim'
exe 'imap '.g:textools_nextdelim_map.' <Plug>textools-nextdelim'

" Simple functions put cursor to the right of closing braces and quotes
" ( [ [ ( "  "  asdfad) sdf    ]  sdfad   ]  asdfasdf) hello   asdfas)
" Note: matchstrpos is relatively new/less portable, e.g. fails on midway
" Used to use matchstrpos, now just use match(); much simpler
function! s:prevdelim(n)
  " Why up to two places to left of current position (col('.')-1)? there is delimiter to our left, want to ignore that
  " If delimiter is to left of cursor, we are at a 'next to
  " the cursor' position; want to test line even further to the left
  let string = getline('.')[:col('.')-3]
  let string = join(reverse(split(string, '.\zs')), '') " search the *reversed* string
  let pos = 0
  for i in range(a:n)
    let result = match(string, g:textools_delimjump_regex, pos) " get info on *first* match
    if result==-1 | break | endif
    let pos = result + 1 " go to next one
  endfor
  if pos==0 " relative position is zero, i.e. don't move
    return ""
  else
    return repeat("\<Left>", pos)
  endif
endfunction
function! s:nextdelim(n)
  " Why starting from current position? Even if cursor is
  " on delimiter, want to find it and move to the right of it
  let string = getline('.')[col('.')-1:]
  let pos = 0
  for i in range(a:n)
    let result = match(string, g:textools_delimjump_regex, pos) " get info on *first* match
    if result==-1 | break | endif
    let pos = result + 1 " go to next one
  endfor
  if mode()!~#'[rRiI]' && pos+col('.')>=col('$') " want to put cursor at end-of-line, but can't because not in insert mode
    let pos = col('$')-col('.')-1
  endif
  if pos==0 " relative position is zero, i.e. don't move
    return ""
  else
    return repeat("\<Right>", pos)
  endif
endfunction
" Helper function, harmless but does nothing for most users
" See https://github.com/lukelbd/dotfiles/blob/master/.vimrc
function! s:tab_reset()
  let b:menupos = 0 | return ''
endfunction
" Define the maps, with special consideration for whether
" popup menu is open (accept the entry if user has scrolled
" into the menu).
" See https://github.com/lukelbd/dotfiles/blob/master/.vimrc
inoremap <expr> <Plug>textools-prevdelim !pumvisible() ? <sid>prevdelim(1)
  \ : b:menupos==0 ? "\<C-e>".<sid>tab_reset().<sid>prevdelim(1)
  \ : " \<C-y>".<sid>tab_reset().<sid>prevdelim(1)
inoremap <expr> <Plug>textools-nextdelim !pumvisible() ? <sid>nextdelim(1)
  \ : b:menupos==0 ? "\<C-e>".<sid>tab_reset().<sid>nextdelim(1)
  \ : " \<C-y>".<sid>tab_reset().<sid>nextdelim(1)
