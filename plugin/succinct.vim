"-----------------------------------------------------------------------------
" Author: Luke Davis (lukelbd@gmail.com)
" Date:   2018-09-09
" Tools for working with snippets, delimiters, and text objects in vim. Includes
" utilities for defining text objects and vim-surround delimiters in one go and
" defining snippet and delimiter mappings under a standardized prefix.
"-----------------------------------------------------------------------------
" Define mappings and delimiters
scriptencoding utf-8
if !exists('g:succinct_templates_path')
  let g:succinct_templates_path = '~/templates'
endif
if exists('g:succinct_snippet_prefix')  " backwards compatibility
  let g:succinct_snippet_map = g:succinct_snippet_prefix
endif
if !exists('g:succinct_snippet_map')  " backwards compatibility
  let g:succinct_snippet_map = '<C-e>'
endif
if exists('g:succinct_surround_prefix')
  let g:succinct_surround_map = g:succinct_surround_prefix
endif
if !exists('g:succinct_surround_map')
  let g:succinct_surround_map = '<C-s>'
endif
if !exists('g:succinct_prevdelim_map')
  let g:succinct_prevdelim_map = '<C-h>'
endif
if !exists('g:succinct_nextdelim_map')
  let g:succinct_nextdelim_map = '<C-l>'
endif

"-----------------------------------------------------------------------------
" Default commands, mappings, delims, and text objects
"-----------------------------------------------------------------------------
" Template selection with safety measures
" Note: If statement must be embedded in function to avoid race condition issues
augroup succinct
  au!
  au BufNewFile * call succinct#template_select()
augroup END

" Fuzzy delimiter and snippet selection
" Warning: Again the <Plug> name cannot start with <Plug>Isnippet or <Plug>Isurround
" or else vim will wait until another keystroke to figure out which <Plug> is meant.
inoremap <Plug>SelectIsnippet <Cmd>call succinct#snippet_select()<CR>
inoremap <Plug>SelectIsurround <Cmd>call succinct#surround_select('I')<CR>
vnoremap <Plug>SelectVsurround <Cmd>call succinct#surround_select('V')<CR>
exe 'imap ' . repeat(g:succinct_snippet_map, 2) . ' <Plug>SelectIsnippet'
exe 'imap ' . repeat(g:succinct_surround_map, 2) . ' <Plug>SelectIsurround'
exe 'vmap ' . repeat(g:succinct_surround_map, 2) . ' <Plug>SelectVsurround'

" Delimiter navigation and modification mappings
" Note: Redirect nonexistent <Plug>Vsurround to defined <Plug>VSurround for
" consistency with <Plug>Isurround and s:surround_sink() in autoload utilities.
" Note: Lowercase Isurround plug inserts delims without newlines. Can be added using
" either ISurround (note uppercase) or just pressing <CR> before delim character.
vmap <Plug>Vsurround <Plug>VSurround
inoremap <Plug>ResetUndo <C-g>u
nnoremap <Plug>UpdateDelims <Cmd>call succinct#update_delims()<CR>
nnoremap <Plug>ResetDelims <Cmd>call succinct#reset_delims()<CR>
nnoremap <Plug>DeleteDelims <Cmd>call succinct#delete_delims()<CR>
nnoremap <Plug>ChangeDelims <Cmd>call succinct#change_delims()<CR>
inoremap <Plug>Isnippet <C-r>=succinct#insert_snippet()<CR>
inoremap <expr> <Plug>PrevDelim succinct#prev_delim()
inoremap <expr> <Plug>NextDelim succinct#next_delim()
exe 'imap ' . g:succinct_prevdelim_map . ' <Plug>PrevDelim'
exe 'imap ' . g:succinct_nextdelim_map . ' <Plug>NextDelim'
exe 'imap ' . g:succinct_snippet_map . ' <Plug>ResetUndo<Plug>Isnippet'
exe 'imap ' . g:succinct_surround_map . ' <Plug>ResetUndo<Plug>Isurround'
exe 'vmap ' . g:succinct_surround_map . ' <Plug>VSurround'
nmap ds <Plug>ResetDelims<Plug>DeleteDelims
nmap cs <Plug>ResetDelims<Plug>ChangeDelims

" Add $global$ *delimiters* and text objects
" Note: For surrounding with spaces can hit space twice, and for surrounding
" with enter can hit enter twice. Very simple.
let s:delims = {
  \ '': '\n\r\n',
  \ "'": '''\r''',
  \ '"': '"\r"',
  \ 'q': '‘\r’',
  \ 'Q': '“\r”',
  \ 'b': '(\r)',
  \ '(': '(\r)',
  \ 'c': '{\r}',
  \ 'B': '{\r}',
  \ '{': '{\r}',
  \ '*': '*\r*',
  \ 'r': '[\r]',
  \ '[': '[\r]',
  \ 'a': '<\r>',
  \ '<': '<\r>',
  \ 'f': '\1function: \1(\r)',
  \ 'A': '\1array: \1[\r]',
  \ }
call succinct#add_delims(s:delims, 0, 1)
