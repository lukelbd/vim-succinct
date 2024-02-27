"-----------------------------------------------------------------------------
" Author:  Luke Davis (lukelbd@gmail.com)
" Tools for working with snippets, delimiters, and text objects in vim. Includes
" utilities for defining text objects and vim-surround delimiters in one go and
" defining snippet and delimiter mappings under a standardized prefix.
"-----------------------------------------------------------------------------
" Template select autocommand
augroup succinct
  au!
  au BufNewFile * call succinct#template_select()
augroup END

" Mappings and other settings
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
" Selecting and using insert/visual mode delimiters/snippets
" Note: <Plug> names cannot begin with same letters or vim will hang until next
" key resolve ambiguity (<Plug>Name is parsed by vim as successive keystrokes).
" Note: Ysuccinct manually processes the delimiter then sends '\1' to vim-surround
" that directs to a b:surround_1 variable that we've assigned the processed result.
inoremap <Plug>ResetUndo <C-g>u
vnoremap <Plug>Vsselect <Cmd>call succinct#surround_select('V')<CR>
inoremap <Plug>Isselect <Cmd>call succinct#surround_select('I')<CR>
inoremap <Plug>Ieselect <Cmd>call succinct#snippet_select()<CR>
vnoremap <silent> <Plug>Vsuccinct :<C-u>call succinct#surround_visual()<CR>
inoremap <expr> <silent> <Plug>PrevDelim succinct#prev_delim()
inoremap <expr> <silent> <Plug>NextDelim succinct#next_delim()
inoremap <expr> <silent> <Plug>Isuccinct succinct#surround_insert()
inoremap <expr> <silent> <Plug>Isnippet succinct#snippet_insert()
exe 'imap ' . g:succinct_prevdelim_map . ' <Plug>PrevDelim'
exe 'imap ' . g:succinct_nextdelim_map . ' <Plug>NextDelim'
exe 'vmap ' . g:succinct_surround_map . ' <Plug>ResetRepeat<Plug>Vsuccinct'
exe 'imap ' . g:succinct_surround_map . ' <Plug>ResetUndo<Plug>Isuccinct'
exe 'imap ' . g:succinct_snippet_map . ' <Plug>ResetUndo<Plug>Isnippet'
exe 'vmap ' . repeat(g:succinct_surround_map, 2) . ' <Plug>Vsselect'
exe 'imap ' . repeat(g:succinct_surround_map, 2) . ' <Plug>Isselect'
exe 'imap ' . repeat(g:succinct_snippet_map, 2) . ' <Plug>Ieselect'

" Selecting, using, changing, and deleting normal-mode delimiters
" Note: This supports fancy count/indent behavior e.g. ysiw<CR>b to surround current
" word by parentheses and put on a new indented line, and supports repeating \1...\1
" style user-input delimiters with '.'. Also 'yss<Key>' gives result identical to
" vim-text-obj-line 'ys<Key>il' See: https://github.com/tpope/vim-surround/issues/140.
nnoremap <Plug>Ysselect <Cmd>call succinct#surround_select('y')<CR>
nnoremap <Plug>Csselect <Cmd>call succinct#surround_select('c')<CR>
nnoremap <Plug>Dsselect <Cmd>call succinct#surround_select('d')<CR>
nnoremap <Plug>Csuccinct <Cmd>call succinct#change_delims(v:prevcount, 0)<CR>
nnoremap <Plug>CSuccinct <Cmd>call succinct#change_delims(v:prevcount, 1)<CR>
nnoremap <Plug>Dsuccinct <Cmd>call succinct#delete_delims(v:prevcount, 0)<CR>
nnoremap <Plug>DSuccinct <Cmd>call succinct#delete_delims(v:prevcount, 1)<CR>
nnoremap <expr> <Plug>Ysuccinct succinct#surround_normal(0)
nnoremap <expr> <Plug>YSuccinct succinct#surround_normal(1)
nnoremap <expr> <Plug>Yssuccinct '^' . v:count1 . succinct#surround_normal(0) . 'g_'
nnoremap <expr> <Plug>YSsuccinct '^' . v:count1 . succinct#surround_normal(1) . 'g_'
noremap <Plug>ResetRepeat <Cmd>call succinct#reset_repeat()<CR>
nmap cs <Plug>ResetRepeat<Plug>Csuccinct
nmap cS <Plug>ResetRepeat<Plug>CSuccinct
nmap ds <Plug>ResetRepeat<Plug>Dsuccinct
nmap dS <Plug>ResetRepeat<Plug>DSuccinct
nmap ys <Plug>ResetRepeat<Plug>Ysuccinct
nmap YS <Plug>ResetRepeat<Plug>YSuccinct
nmap yss <Plug>ResetRepeat<Plug>Yssuccinct
nmap ySs <Plug>ResetRepeat<Plug>YSsuccinct
nmap ysS <Plug>ResetRepeat<Plug>YSsuccinct
nmap ySS <Plug>ResetRepeat<Plug>YSsuccinct
exe 'nmap y' . g:succinct_surround_map . ' <Plug>Ysselect'
exe 'nmap c' . g:succinct_surround_map . ' <Plug>Csselect'
exe 'nmap d' . g:succinct_surround_map . ' <Plug>Dsselect'
exe 'nmap ys' . g:succinct_surround_map . ' <Plug>Ysselect'
exe 'nmap cs' . g:succinct_surround_map . ' <Plug>Csselect'
exe 'nmap ds' . g:succinct_surround_map . ' <Plug>Dsselect'

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
  \ 'm': '\n\r\n',
  \ 'f': '\1function: \1(\r)',
  \ 'A': '\1array: \1[\r]',
\ }
call succinct#add_delims(s:delims, 0, 1)
