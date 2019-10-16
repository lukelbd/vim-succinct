"-----------------------------------------------------------------------------"
" Delimiter navigation improvements
"-----------------------------------------------------------------------------"
" Define mappings and delimiters
if !exists('g:textools_delimjump_regex')
  let g:textools_delimjump_regex = "[()\\[\\]{}<>]" "list of 'outside' delimiters for jk matching
endif
if !exists('g:textools_prevdelim_map')
  let g:textools_prevdelim_map = '<F1>'
endif
if !exists('g:textools_nextdelim_map')
  let g:textools_nextdelim_map = '<F2>'
endif
exe 'imap ' . g:textools_prevdelim_map . ' <Plug>textools-prevdelim'
exe 'imap ' . g:textools_nextdelim_map . ' <Plug>textools-nextdelim'

" Move to left of previous delim
" ( [ [ ( "  "  asdfad) sdf    ]  sdfad   ]  asdfasdf) hello   asdfas)
" Note: matchstrpos is relatively new/less portable, e.g. fails on midway
" Used to use matchstrpos, now just use match(); much simpler
" Note: Why up to two places to left of current position (col('.')-1)? there is delimiter to our left, want to ignore that
" If delimiter is to left of cursor, we are at a 'next to
" the cursor' position; want to test line even further to the left
function! s:prevdelim(n)
  let string = getline('.')[:col('.')-3]
  let string = join(reverse(split(string, '.\zs')), '') " search the *reversed* string
  let pos = 0
  for i in range(a:n)
    let result = match(string, g:textools_delimjump_regex, pos) " get info on *first* match
    if result==-1 | break | endif
    let pos = result + 1 " go to next one
  endfor
  if pos == 0 " relative position is zero, i.e. don't move
    return ""
  else
    return repeat("\<Left>", pos)
  endif
endfunction

" Move to left of right delim
" Why starting from current position? Even if cursor is
" on delimiter, want to find it and move to the right of it
function! s:nextdelim(n)
  let string = getline('.')[col('.')-1:]
  let pos = 0
  for i in range(a:n)
    let result = match(string, g:textools_delimjump_regex, pos) " get info on *first* match
    if result==-1 | break | endif
    let pos = result + 1 " go to next one
  endfor
  if mode()!~#'[rRiI]' && pos+col('.') >= col('$') " want to put cursor at end-of-line, but can't because not in insert mode
    let pos = col('$')-col('.')-1
  endif
  if pos == 0 " relative position is zero, i.e. don't move
    return ""
  else
    return repeat("\<Right>", pos)
  endif
endfunction

" Define the maps, with special consideration for whether popup menu is
" open. See: https://github.com/lukelbd/dotfiles/blob/master/.vimrc
function! s:popup_close()
  if !pumvisible()
    return
  elseif b:menupos = 0 " exit
    return "\<C-e>"
  else
    let b:menupos = 0 " approve and exit
    return "\<C-y>"
  endif
endfunction
inoremap <expr> <Plug>textools-prevdelim <sid>popup_close().<sid>prevdelim(1)
inoremap <expr> <Plug>textools-nextdelim <sid>popup_close().<sid>nextdelim(1)

"-----------------------------------------------------------------------------"
" Prompt user to choose from a list of templates (located in ~/latex folder)
" when creating a new LaTeX file. Consider adding to this for other filetypes!
"-----------------------------------------------------------------------------"
" Make sure menu generating tool available
" No fall back because IDGAF about distribution right now
if exists('*fzf#run')
  " Autocommand
  augroup tex_templates
    au!
    au BufNewFile *.tex call fzf#run({'source':s:tex_templates(), 'options':'--no-sort', 'sink':function('s:tex_select'), 'down':'~30%'})
  augroup END

  " Functions that list and read templates
  function! s:tex_templates()
    let templates = map(split(globpath('~/latex/', '*.tex'), "\n"), 'fnamemodify(v:val, ":t")')
    return [''] + templates " add blank entry as default choice
  endfunction
  function! s:tex_select(item)
    if len(a:item)
      execute "0r ~/latex/" . a:item
    endif
  endfunction
endif
