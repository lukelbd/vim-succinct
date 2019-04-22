"------------------------------------------------------------------------------"
" Very simple script
" Just adds a handy mapping
"------------------------------------------------------------------------------"
"Dependencies
if !g:loaded_delimitMate
  echom "Warning: vim-textools requires delimitMate, disabling some features."
  finish
endif
"Map to 'ctrl-.' which is remapped to <F2> in my iTerm session
if !exists('g:textools_outofdelim_map')
  let g:textools_outofdelim_map='<F2>'
endif
"Make mapping
exe 'imap '.g:textools_outofdelim_map.' <Plug>outofdelim'

"Simple function puts cursor to the right of closing braces and quotes
" * Just search for braces instead of using percent-mapping, because when
"   in the middle of typing often don't particularly *care* if a bracket is completed/has
"   a pair -- just see a bracket, and want to get out of it.
" * Also percent matching solution would require leaving insert mode, triggering
"   various autocmds, and is much slower/jumpier -- vim script solutions are better!
" ( [ [ ( "  "  asdfad) sdf    ]  sdfad   ]  asdfasdf) hello   asdfas) 
function! s:outofdelim(n)
  "Note: matchstrpos is relatively new/less portable, e.g. fails on midway
  "Used to use matchstrpos, now just use match(); much simpler
  " let regex = "[\"')\\]}>]"
  let regex="[)\\]}>]" "list of 'outside' delimiters for jk matching
  let pos=0 "minimum match position
  let string=getline('.')[col('.')-1:]
  for i in range(a:n)
    let result=match(string, regex, pos) "get info on *first* match
    if result==-1 | break | endif
    let pos=result + 1 "go to next one
  endfor
  if mode()!~#'[rRiI]' && pos+col('.')>=col('$')
    let pos=col('$')-col('.')-1
  endif
  if pos==0 "relative position is zero, i.e. don't move
    return ""
  else
    return repeat("\<Right>", pos)
  endif
endfunction
"Helper function, harmless but does nothing for most users
"See https://github.com/lukelbd/dotfiles/blob/master/.vimrc
function! s:tab_reset()
  let b:menupos=0 | return ''
endfunction
"The mapping
inoremap <expr> <Plug>outofdelim !pumvisible() ? <sid>outofdelim(1)
  \ : b:menupos==0 ? "\<C-e>".<sid>tab_reset().<sid>outofdelim(1)
  \ : "\<C-y>".<sid>tab_reset().<sid>outofdelim(1)
