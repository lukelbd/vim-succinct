"-----------------------------------------------------------------------------"
" Templates
"-----------------------------------------------------------------------------"
" Make sure menu generating tool available
" No fall back because IDGAF about distribution right now
if !exists('*fzf#run') || g:loaded_surround
  finish
endif

" Prompt user to choose from a list of templates (located in ~/latex folder)
" when creating a new LaTeX file. Consider adding to this for other filetypes!
" See: http://learnvimscriptthehardway.stevelosh.com/chapters/35.html
augroup tex_templates
  au!
  au BufNewFile *.tex call fzf#run({'source':s:tex_templates(), 'options':'--no-sort', 'sink':function('s:texselect'), 'down':'~30%'})
augroup END

" Function that reads in a template from the line shown be tex_templates
function! s:texselect(item)
  if len(a:item)
    execute "0r ~/latex/".a:item
  endif
endfunction

" Function that displays list of possible LaTeX templates
" NOTE: When using builtin vim API, used input('prefix', '', 'customlist,TexTemplates')
" where TexTemplates was a function TexTemplates(A,L,P) that returned a list of
" possible choices given the prefix A of what user typed so far
function! s:tex_templates()
  let templates = map(split(globpath('~/latex/', '*.tex'),"\n"), 'fnamemodify(v:val, ":t")')
  return [''] + templates " add blank entry as default choice
endfunction
