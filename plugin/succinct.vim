"-----------------------------------------------------------------------------"
" Tools for working with snippets, delimiters, and text objects {{{1
"-----------------------------------------------------------------------------"
" Initial stuff {{{2
" Author: Luke Davis (lukelbd@gmail.com)
" This plugin includes utilities for defining text objects and vim-surround delimiters
" in one go and defining snippet and delimiter mappings under a standardized prefix.
if exists('g:loaded_succinct')
  finish
endif
augroup vim_succinct
  au!
  au BufNewFile * call succinct#fzf_template()
  au FileType * call succinct#filetype_delims()
  au FileType * call succinct#filetype_snippets()
augroup END
silent! au! succinct
scriptencoding utf-8

" Disable mappings {{{2
if !exists('g:succinct_nomap')
  let g:succinct_nomap = 0
endif
if !exists('g:succinct_nomap_actions')
  let g:succinct_nomap_actions = g:succinct_nomap
endif
if !exists('g:succinct_nomap_objects')
  let g:succinct_nomap_objects = g:succinct_nomap
endif

" General settings {{{2
if !exists('g:succinct_templates_path')
  let g:succinct_templates_path = '~/templates'
endif
if !exists('g:succinct_snippet_map')  " backwards compatibility
  let g:succinct_snippet_map = get(g:, 'succinct_snippet_prefix', '<C-e>')
endif
if !exists('g:succinct_surround_map')  " backwards compatibility
  let g:succinct_surround_map = get(g:, 'succinct_surround_prefix', '<C-s>')
endif

" Delimiter settings {{{2
if !exists('g:succinct_prevdelim_map')
  let g:succinct_prevdelim_map = '<C-h>'
endif
if !exists('g:succinct_nextdelim_map')
  let g:succinct_nextdelim_map = '<C-l>'
endif

"-----------------------------------------------------------------------------"
" Default commands, mappings, delims, and text objects {{{1
"-----------------------------------------------------------------------------"
" Selecting and inserting insert-mode delimiters and snippets {{{2
" Note: <Plug> names cannot begin with same letters or vim will hang until next
" key resolve ambiguity (<Plug>Name is parsed by vim as successive keystrokes).
" Note: Ysuccinct manually processes the delimiter then sends '\1' to vim-surround
" that directs to a b:surround_1 variable that we've assigned the processed result.
noremap <expr> <Plug>PrevDelim succinct#prev_delim()
noremap <expr> <Plug>NextDelim succinct#next_delim()
noremap <expr> <Plug>Vssetup '<Esc>' . succinct#setup_motion() . 'gv' . v:count1
noremap <Plug>Vsuccinct <Cmd>call succinct#surround_motion(visualmode())<CR>
inoremap <expr> <Plug>PrevDelim succinct#prev_delim()
inoremap <expr> <Plug>NextDelim succinct#next_delim()
inoremap <expr> <Plug>Issetup succinct#setup_insert()
inoremap <silent> <Plug>Isuccinct <Cmd>call succinct#surround_insert()<CR>
inoremap <silent> <Plug>Isnippet <Cmd>call succinct#snippet_insert()<CR>
if !g:succinct_nomap_actions  " add mappings
  exe 'vmap ' . g:succinct_surround_map . ' <Plug>Vssetup<Plug>Vsuccinct'
  exe 'imap ' . g:succinct_surround_map . ' <Plug>Issetup<Plug>Isuccinct'
  exe 'imap ' . g:succinct_snippet_map . ' <Plug>Issetup<Plug>Isnippet'
  for s:mode in ['', 'i'] | if !hasmapto('<Plug>PrevDelim', s:mode)
    exe s:mode . 'map ' . g:succinct_prevdelim_map . ' <Plug>PrevDelim'
  endif | endfor
  for s:mode in ['', 'i'] | if !hasmapto('<Plug>NextDelim', s:mode)
    exe s:mode . 'map ' . g:succinct_nextdelim_map . ' <Plug>NextDelim'
  endif | endfor
endif

" Selecting, using, changing, and deleting normal and visual-mode delimiters {{{2
" Note: Add operator maps so e.g. 'd2s' count style is captured, but still need
" explicit e.g. 'ds' maps so they override vim-surround versions.
" Note: This supports fancy count/indent behavior e.g. ysiw<CR>b to surround current
" word by parentheses and put on a new indented line, and supports repeating \1...\1
" style user-input delimiters with '.'. Also 'yss<Key>' gives result identical to
" vim-text-obj-line 'ys<Key>il' See: https://github.com/tpope/vim-surround/issues/140.
noremap <expr> <Plug>Yssetup succinct#setup_motion() . v:count1
noremap <Plug>Ysuccinct <Cmd>call succinct#surround_motion(0)<CR>
noremap <Plug>YSuccinct <Cmd>call succinct#surround_motion(1)<CR>
noremap <Plug>Yssuccinct <Cmd>call succinct#surround_motion(0, '^', 'g_')<CR>
noremap <Plug>YSsuccinct <Cmd>call succinct#surround_motion(1, '^', 'g_')<CR>
noremap <Plug>Csuccinct <Cmd>call succinct#change_delims(v:prevcount, 0)<CR>
noremap <Plug>CSuccinct <Cmd>call succinct#change_delims(v:prevcount, 1)<CR>
noremap <Plug>Dsuccinct <Cmd>call succinct#delete_delims(v:prevcount, 0)<CR>
noremap <Plug>DSuccinct <Cmd>call succinct#delete_delims(v:prevcount, 1)<CR>
if !g:succinct_nomap_actions
  omap <expr> s '<Esc>' . v:count1 . '<Plug>Yssetup' . succinct#setup_operator(0)
  omap <expr> S '<Esc>' . v:count1 . '<Plug>Yssetup' . succinct#setup_operator(1)
  for s:map in ['c', 'd', 'y'] | for s:key in ['s', 'S']
    exe 'nmap ' . s:map . s:key . ' <Plug>Yssetup<Plug>' . toupper(s:map) . s:key . 'uccinct'
  endfor | endfor
  for s:map in ['ss', 'sS', 'Ss', 'SS']
    exe 'nmap y' . s:map . ' <Plug>Yssetup<Plug>Y' . (s:map =~# 'S' ? 'S' : 's') . 'succinct'
  endfor
endif

" Add global delimiters and text objects {{{2
" Note: For surrounding with spaces can hit space twice, and for surrounding
" with enter can use e.g. 'yS' intead of 'ys'.
let s:defaults = {
  \ "'": '''\r''',
  \ '"': '"\r"',
  \ ';': ';\r;',
  \ ',': ',\r,',
  \ '.': '.\r.',
  \ '_': '_\r_',
  \ '-': '-\r-',
  \ '+': '+\r+',
  \ '=': '=\r=',
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
  \ }
if !g:succinct_nomap_objects
  let delims = get(g:, 'succinct_delims', {})
  let snippets = get(g:, 'succinct_snippets', {})
  call succinct#add_delims(s:defaults)  " missing arg uses textobj plugin name 'default' 
  call succinct#add_delims(delims, 0)  " uses textobj plugin name 'global'
  call succinct#add_snippets(snippets, 0)
endif
let g:loaded_succinct = 1
