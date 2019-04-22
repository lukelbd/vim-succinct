"------------------------------------------------------------------------------"
" Simple script that generates command for turning 'expandtab'
" on and off.
"------------------------------------------------------------------------------"
"Autocommand
if !exists('g:textools_tab_filetypes')
  let g:textools_tab_filetypes=['text','gitconfig','make']
endif
augroup tab_toggle
  au!
  au FileType * exe 'TabToggle '.(index(g:textools_tab_filetypes, &ft)!=-1)
augroup END
"Fucntion
function! s:tabtoggle(...)
  if a:0
    let &l:expandtab=1-a:1 "toggle 'on' means literal tabs are 'on'
  else
    setlocal expandtab!
  endif
  let b:tab_mode=&l:expandtab
endfunction
"Command
command! -nargs=? TabToggle call <sid>tabtoggle(<args>)

