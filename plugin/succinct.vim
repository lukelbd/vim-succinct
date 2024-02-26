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
nnoremap <Plug>SelectDsurround <Cmd>call succinct#surround_select('d')<CR>
nnoremap <Plug>SelectCsurround <Cmd>call succinct#surround_select('c')<CR>
nnoremap <Plug>SelectYsurround <Cmd>call succinct#surround_select('y')<CR>
exe 'imap ' . repeat(g:succinct_snippet_map, 2) . ' <Plug>SelectIsnippet'
exe 'imap ' . repeat(g:succinct_surround_map, 2) . ' <Plug>SelectIsurround'
exe 'vmap ' . repeat(g:succinct_surround_map, 2) . ' <Plug>SelectVsurround'
exe 'nmap y' . g:succinct_surround_map . ' <Plug>SelectYsurround'
exe 'nmap c' . g:succinct_surround_map . ' <Plug>SelectCsurround'
exe 'nmap d' . g:succinct_surround_map . ' <Plug>SelectDsurround'
exe 'nmap ys' . g:succinct_surround_map . ' <Plug>SelectYsurround'
exe 'nmap cs' . g:succinct_surround_map . ' <Plug>SelectCsurround'
exe 'nmap ds' . g:succinct_surround_map . ' <Plug>SelectDsurround'

" Delimiter navigation and modification mappings
" Note: Redirect nonexistent <Plug>Vsurround to defined <Plug>VSurround for
" consistency with <Plug>Isurround and s:surround_sink() in autoload utilities.
" Note: Lowercase Isurround plug inserts delims without newlines. Can be added using
" either ISurround (note uppercase) or just pressing <CR> before delim character.
" Note: Ysuccinct manually processes the delimiter then sends '\1' to vim-surround
" that directs to a b:surround_1 variable that we've assigned the processed result.
" This permits custom count/indent behavior e.g. ysiw<CR>b and lets us repeat \1...\1
" style user-input delimiters with '.'. And Yssuccint reproduces the vim-text-obj-line
" result 'ys<Key>il' in-house. See: https://github.com/tpope/vim-surround/issues/140
inoremap <Plug>ResetUndo <C-g>u
inoremap <expr> <Plug>PrevDelim succinct#prev_delim()
inoremap <expr> <Plug>NextDelim succinct#next_delim()
inoremap <Plug>Isnippet <C-r>=succinct#insert_snippet()<CR>
vnoremap <Plug>VSuccinct :<C-u>call succinct#insert_visual()<CR>
nnoremap <Plug>ResetRepeat <Cmd>call succinct#reset_repeat()<CR>
nnoremap <Plug>Dsuccinct <Cmd>call succinct#delete_delims(v:prevcount, 0)<CR>
nnoremap <Plug>DSuccinct <Cmd>call succinct#delete_delims(v:prevcount, 1)<CR>
nnoremap <Plug>Csuccinct <Cmd>call succinct#change_delims(v:prevcount, 0)<CR>
nnoremap <Plug>CSuccinct <Cmd>call succinct#change_delims(v:prevcount, 1)<CR>
nnoremap <expr> <Plug>Ysuccinct succinct#insert_normal(0)
nnoremap <expr> <Plug>YSuccinct succinct#insert_normal(1)
nnoremap <expr> <Plug>Yssuccinct '^' . v:count1 . succinct#insert_normal(0) . 'g_'
nnoremap <expr> <Plug>YSsuccinct '^' . v:count1 . succinct#insert_normal(1) . 'g_'
nmap ds <Plug>ResetRepeat<Plug>Dsuccinct
nmap dS <Plug>ResetRepeat<Plug>DSuccinct
nmap cs <Plug>ResetRepeat<Plug>Csuccinct
nmap cS <Plug>ResetRepeat<Plug>CSuccinct
nmap ys <Plug>ResetRepeat<Plug>Ysuccinct
nmap YS <Plug>ResetRepeat<Plug>YSuccinct
nmap yss <Plug>ResetRepeat<Plug>Yssuccinct
nmap ySs <Plug>ResetRepeat<Plug>YSsuccinct
nmap ysS <Plug>ResetRepeat<Plug>YSsuccinct
nmap ySS <Plug>ResetRepeat<Plug>YSsuccinct
exe 'vmap ' . g:succinct_surround_map . ' <Plug>VSuccinct'
exe 'imap ' . g:succinct_snippet_map . ' <Plug>ResetUndo<Plug>Isnippet'
exe 'imap ' . g:succinct_surround_map . ' <Plug>ResetUndo<Plug>Isurround'
exe 'imap ' . g:succinct_prevdelim_map . ' <Plug>PrevDelim'
exe 'imap ' . g:succinct_nextdelim_map . ' <Plug>NextDelim'

" Add $global$ *delimiters* and text objects
" Note: For surrounding with spaces can hit space twice, and for surrounding
" with enter can use e.g. 'yS' intead of 'ys', so '^M' regex works here.
let s:delims = {
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
  \ 'n': '\n\r\n',
  \ 'f': '\1function: \1(\r)',
  \ 'A': '\1array: \1[\r]',
\ }
call succinct#add_delims(s:delims, 0, 1)
