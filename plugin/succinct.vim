"-----------------------------------------------------------------------------
" Author:  Luke Davis (lukelbd@gmail.com)
" Tools for working with snippets, delimiters, and text objects in vim. Includes
" utilities for defining text objects and vim-surround delimiters in one go and
" defining snippet and delimiter mappings under a standardized prefix.
"-----------------------------------------------------------------------------
" Template select autocommand
scriptencoding utf-8
augroup succinct
  au!
  au BufNewFile * call succinct#template_select()
augroup END

" Template location
if !exists('g:succinct_templates_path')
  let g:succinct_templates_path = '~/templates'
endif

" Disable mappings
if !exists('g:succinct_nomap')
  let g:succinct_nomap = 0
endif
if !exists('g:succinct_nomap_actions')
  let g:succinct_nomap_actions = g:succinct_nomap
endif
if !exists('g:succinct_nomap_objects')
  let g:succinct_nomap_objects = g:succinct_nomap
endif

" Surround and snippet maps
if !exists('g:succinct_snippet_map')  " backwards compatibility
  let g:succinct_snippet_map = get(g:, 'succinct_snippet_prefix', '<C-e>')
endif
if !exists('g:succinct_surround_map')  " backwards compatibility
  let g:succinct_surround_map = get(g:, 'succinct_surround_prefix', '<C-s>')
endif

" Next and previous delimiter maps
if !exists('g:succinct_prevdelim_map')
  let g:succinct_prevdelim_map = '<C-h>'
endif
if !exists('g:succinct_nextdelim_map')
  let g:succinct_nextdelim_map = '<C-l>'
endif

"-----------------------------------------------------------------------------
" Default commands, mappings, delims, and text objects
"-----------------------------------------------------------------------------
" Selecting and inserting insert-mode delimiters and snippets
" Note: <Plug> names cannot begin with same letters or vim will hang until next
" key resolve ambiguity (<Plug>Name is parsed by vim as successive keystrokes).
" Note: Ysuccinct manually processes the delimiter then sends '\1' to vim-surround
" that directs to a b:surround_1 variable that we've assigned the processed result.
noremap <expr> <Plug>PrevDelim succinct#prev_delim()
noremap <expr> <Plug>NextDelim succinct#next_delim()
noremap <expr> <Plug>Vssetup '<Esc>' . succinct#setup_motion() . 'gv' . v:count1
noremap <expr> <Plug>Vsuccinct succinct#surround_motion(visualmode())
noremap <Plug>Vsselect <Cmd>call succinct#surround_select('V')<CR>
inoremap <Plug>Isselect <Cmd>call succinct#surround_select('I')<CR>
inoremap <Plug>Ieselect <Cmd>call succinct#snippet_select()<CR>
inoremap <expr> <Plug>Issetup succinct#setup_insert()
inoremap <expr> <Plug>Isuccinct succinct#surround_insert()
inoremap <expr> <Plug>Isnippet succinct#snippet_insert()
inoremap <expr> <Plug>PrevDelim succinct#prev_delim()
inoremap <expr> <Plug>NextDelim succinct#next_delim()
if !g:succinct_nomap_actions  " add mappings
  exe 'vmap ' . g:succinct_surround_map . ' <Plug>Vssetup<Plug>Vsuccinct'
  exe 'imap ' . g:succinct_surround_map . ' <Plug>Issetup<Plug>Isuccinct'
  exe 'imap ' . g:succinct_snippet_map . ' <Plug>Issetup<Plug>Isnippet'
  exe 'vmap ' . repeat(g:succinct_surround_map, 2) . ' <Plug>Vsselect'
  exe 'imap ' . repeat(g:succinct_surround_map, 2) . ' <Plug>Isselect'
  exe 'imap ' . repeat(g:succinct_snippet_map, 2) . ' <Plug>Ieselect'
  for s:mode in ['', 'i']
    if !hasmapto('<Plug>PrevDelim', s:mode) || !hasmapto('<Plug>NextDelim', s:mode)
      exe s:mode . 'map ' . g:succinct_prevdelim_map . ' <Plug>PrevDelim'
      exe s:mode . 'map ' . g:succinct_nextdelim_map . ' <Plug>NextDelim'
    endif
  endfor
endif

" Selecting, using, changing, and deleting normal and visual-mode delimiters
" Note: Add operator maps so e.g. 'd2s' count style is captured, but still need
" explicit e.g. 'ds' maps so they override vim-surround versions.
" Note: This supports fancy count/indent behavior e.g. ysiw<CR>b to surround current
" word by parentheses and put on a new indented line, and supports repeating \1...\1
" style user-input delimiters with '.'. Also 'yss<Key>' gives result identical to
" vim-text-obj-line 'ys<Key>il' See: https://github.com/tpope/vim-surround/issues/140.
noremap <expr> <Plug>Yssetup succinct#setup_motion() . v:count1
noremap <expr> <Plug>Ysuccinct succinct#surround_motion(0)
noremap <expr> <Plug>YSuccinct succinct#surround_motion(1)
noremap <expr> <Plug>Yssuccinct '^' . v:count1 . succinct#surround_motion(0) . 'g_'
noremap <expr> <Plug>YSsuccinct '^' . v:count1 . succinct#surround_motion(1) . 'g_'
noremap <Plug>Ysselect <Cmd>call succinct#surround_select(v:operator)<CR>
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
  for s:key in ['', 's']
    exe 'omap ' . s:key . g:succinct_surround_map . ' <Plug>Ysselect'
  endfor
endif

" Add global delimiters and text objects
" Note: For surrounding with spaces can hit space twice, and for surrounding
" with enter can use e.g. 'yS' intead of 'ys', so '^M' regex works here.
let s:delims = {
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
  \ 'e': '\n\r\n',
  \ 'E': ' \r ',
  \ 'f': '\1function: \1(\r)',
  \ 'A': '\1array: \1[\r]',
\ }
if !g:succinct_nomap_objects
  call succinct#add_delims(s:delims, 0)
endif
