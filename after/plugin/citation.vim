"------------------------------------------------------------------------------"
" Author: Luke Davis (lukelbd@gmail.com)
" Date:   2018-09-10
" Custom maps for working with citation.vim
" For more info see: https://github.com/rafaqz/citation.vim
"------------------------------------------------------------------------------"
if !g:loaded_unite || &rtp !~ 'citation.vim\/'
  finish
endif
if !exists('g:textools_surround_prefix')
  let g:textools_citation_prefix = '<C-b>'
endif

" Activate maps
augroup tex_citation
  au!
  au FileType tex call s:citation_maps()
augroup END

" Citations function
function! s:citation_maps()
  " Toggle bibtex
  let b:citation_vim_mode = 'bibtex'
  let b:citation_vim_bibtex_file = ''
  nnoremap <silent> <buffer> <Leader>B :BibtexToggle<CR>

  " Citation mappings
  for s:pair in items({'c':'', 't':'t', 'p':'p', 'n':'num'})
    exe 'inoremap <silent> <buffer> ' . g:textools_citation_prefix
      \ . s:pair[0] . ' <Esc>:call <sid>citation_vim_run("'
      \ . s:pair[1] . '", g:citation_vim_opts)<CR>'
      \ . '")'
  endfor
endfunction

" Bibtex and Zotero INTEGRATION
" Requires pybtex and bibtexparser python modules, and unite.vim plugin
" NOTE: Set up with macports. By default the +python vim was compiled with
" is not on path; access with port select --set pip <pip36|python36>. To
" install module dependencies, use that pip. Can also install most packages
" with 'port install py36-module_name' but often get error 'no module
" named pkg_resources'; see this thread: https://stackoverflow.com/a/10538412/4970632
" Global settings
" Local settings are applied as global variables before calling cite command,
" and note they are always defined since this is an ftplugin file!
let g:unite_data_directory = '~/.unite'
let g:citation_vim_cache_path = '~/.unite'
let g:citation_vim_outer_prefix = ''
let g:citation_vim_inner_prefix = ''
let g:citation_vim_suffix = '}'
let g:citation_vim_et_al_limit = 3 " show et al if more than 2 authors
let g:citation_vim_zotero_path = '~/Zotero' " location of .sqlite file
let g:citation_vim_zotero_version = 5
let g:citation_vim_opts = '-start-insert -buffer-name=citation -ignorecase -default-action=append citation/key'

" Where to search for stuff
" This uses allow buffer-local settings
function! s:citation_vim_run(suffix, opts)
  if b:citation_vim_mode == 'bibtex' && b:citation_vim_bibtex_file == ''
    let b:citation_vim_bibtex_file = s:citation_vim_bibfile()
  endif
  let g:citation_vim_mode = b:citation_vim_mode
  let g:citation_vim_outer_prefix = '\cite' . a:suffix . '{'
  let g:citation_vim_bibtex_file = b:citation_vim_bibtex_file
  call unite#helper#call_unite('Unite', a:opts, line('.'), line('.'))
  normal! a
  return ''
endfunction

" Ask user to select bibliography files from list
" Requires special completion function for selecting bibfiles
function! s:citation_vim_bibfile()
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

" Toggle func
function s:citation_vim_toggle(...)
  let mode_prev = b:citation_vim_mode
  let file_prev = b:citation_vim_bibtex_file
  if a:0
    let b:citation_vim_mode = (a:1 ? 'bibtex' : 'zotero')
  elseif b:citation_vim_mode == 'bibtex'
    let b:citation_vim_mode = 'zotero'
  else
    let b:citation_vim_mode = 'bibtex'
  endif
  " Toggle
  if b:citation_vim_mode == 'bibtex'
    if b:citation_vim_bibtex_file == ''
      let b:citation_vim_bibtex_file = s:citation_vim_bibfile()
    endif
    echom "Using BibTex file: " . expand(b:citation_vim_bibtex_file)
  else
    echom "Using Zotero database: " . expand(g:citation_vim_zotero_path)
  endif
  " Delete cache
  if mode_prev != b:citation_vim_mode || file_prev != b:citation_vim_bibtex_file
    call delete(expand(g:citation_vim_cache_path . '/citation_vim_cache'))
  endif
endfunction
command! BibtexToggle call <sid>bibtex_toggle()
