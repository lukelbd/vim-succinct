"-----------------------------------------------------------------------------"
" Global plugin settings
"-----------------------------------------------------------------------------"
" Define mappings and delimiters
if !exists('g:shortcuts_templates_path')
  let g:shortcuts_templates_path = '~/templates'
endif
if !exists('g:shortcuts_surround_prefix')
  let g:shortcuts_surround_prefix = '<C-s>'
endif
if !exists('g:shortcuts_snippet_prefix')
  let g:shortcuts_snippet_prefix = '<C-d>'
endif
if !exists('g:shortcuts_prevdelim_map')
  let g:shortcuts_prevdelim_map = '<C-h>'
endif
if !exists('g:shortcuts_nextdelim_map')
  let g:shortcuts_nextdelim_map = '<C-l>'
endif

" Function used with input() to prevent tab expansion and literal tab insertion
function! NullList(...) abort
  return []
endfunction

"-----------------------------------------------------------------------------"
" Default commands, mappings, delims, and text objects
"-----------------------------------------------------------------------------"
" Template selection
" Note: Arguments passed to function() partial are passed to underlying func first.
augroup shortcuts
  au!
  au BufNewFile * if exists('*fzf#run') | call fzf#run({
    \ 'source': shortcuts#template_source(expand('<afile>:e')),
    \ 'options': '--no-sort --prompt="Template> "',
    \ 'down': '~30%',
    \ 'sink': function('shortcuts#template_read'),
    \ }) | endif
augroup END

" Apply plugin mappings
" Note: Lowercase Isurround plug inserts delims without newlines. Instead of
" using ISurround we define special begin end delims with newlines baked in.
inoremap <Plug>ResetUndo <C-g>u
inoremap <silent> <Plug>IsurroundPick <C-o>:call shortcuts#pick_surround()<CR>
inoremap <silent> <Plug>IsnippetPick <C-o>:call shortcuts#pick_snippet()<CR>
inoremap <silent> <expr> <Plug>Isnippet shortcuts#insert_snippet()
inoremap <silent> <expr> <Plug>PrevDelim shortcuts#pum_close() . shortcuts#prev_delim()
inoremap <silent> <expr> <Plug>NextDelim shortcuts#pum_close() . shortcuts#next_delim()

" Apply custom prefixes
" Warning: <C-u> required to remove range resulting from <count>: action
exe 'vmap ' . g:shortcuts_surround_prefix   . ' <Plug>VSurround'
exe 'imap ' . g:shortcuts_surround_prefix   . ' <Plug>ResetUndo<Plug>Isurround'
exe 'imap ' . g:shortcuts_snippet_prefix . ' <Plug>ResetUndo<Plug>Isnippet'
exe 'imap ' . repeat(g:shortcuts_surround_prefix, 2) . ' <Plug>IsurroundPick'
exe 'imap ' . repeat(g:shortcuts_snippet_prefix, 2) . ' <Plug>IsnippetPick'
exe 'imap ' . g:shortcuts_prevdelim_map . ' <Plug>PrevDelim'
exe 'imap ' . g:shortcuts_nextdelim_map . ' <Plug>NextDelim'
nnoremap <silent> <Plug>ShortcutsDeleteDelims :<C-u>call shortcuts#delete_delims()<CR>
nnoremap <silent> <Plug>ShortcutsChangeDelims :<C-u>call shortcuts#change_delims()<CR>
nmap <expr> ds shortcuts#reset_delims() . "\<Plug>ShortcutsDeleteDelims"
nmap <expr> cs shortcuts#reset_delims() . "\<Plug>ShortcutsChangeDelims"

" Define simple *global* surround mappings
let s:global_surround = {
  \ "'": "'\r'",
  \ '"': "\"\r\"",
  \ 'q': "‘\r’",
  \ 'Q': "“\r”",
  \ 'b': "(\r)",
  \ '(': "(\r)",
  \ 'c': "{\r}",
  \ 'B': "{\r}",
  \ '{': "{\r}",
  \ 'r': "[\r]",
  \ '[': "[\r]",
  \ 'a': "<\r>",
  \ '<': "<\r>",
  \ '\': "\\\"\r\\\"",
  \ 'p': "print(\r)",
  \ 'f': "\1function: \1(\r)",
  \ 'A': "\1array: \1[\r]",
  \ "\t": " \r ",
  \ '': "\n\r\n",
\ }
for [s:binding, s:pair] in items(s:global_surround)
  let g:surround_{char2nr(s:binding)} = s:pair
endfor

" Define simple custom text objects
" Todo: Auto-define ] and [ navigation of text objects and delimiters?
if exists('*textobj#user#plugin')
  let s:universal_textobjs_map = {
    \   'line': {
    \     'sfile': expand('<sfile>:p'),
    \     'select-a-function': 'shortcuts#current_line_a',
    \     'select-a': 'al',
    \     'select-i-function': 'shortcuts#current_line_i',
    \     'select-i': 'il',
    \   },
    \   'blanklines': {
    \     'sfile': expand('<sfile>:p'),
    \     'select-a-function': 'shortcuts#blank_lines',
    \     'select-a': 'a<Space>',
    \     'select-i-function': 'shortcuts#blank_lines',
    \     'select-i': 'i<Space>',
    \   },
    \   'nonblanklines': {
    \     'sfile': expand('<sfile>:p'),
    \     'select-a-function': 'shortcuts#nonblank_lines',
    \     'select-a': 'aP',
    \     'select-i-function': 'shortcuts#nonblank_lines',
    \     'select-i': 'iP',
    \   },
    \   'uncommented': {
    \     'sfile': expand('<sfile>:p'),
    \     'select-a-function': 'shortcuts#uncommented_lines',
    \     'select-i-function': 'shortcuts#uncommented_lines',
    \     'select-a': 'aC',
    \     'select-i': 'iC',
    \   },
    \   'function': {
    \     'pattern': ['\<\K\k*(', ')'],
    \     'select-a': 'af',
    \     'select-i': 'if',
    \   },
    \   'method': {
    \     'pattern': ['\_[^A-Za-z_.]\zs\h[0-9A-Za-z_.]*(', ')'],
    \     'select-a': 'am',
    \     'select-i': 'im',
    \   },
    \   'array': {
    \     'pattern': ['\<\K\k*\[', '\]'],
    \     'select-a': 'aA',
    \     'select-i': 'iA',
    \   },
    \  'curly': {
    \     'pattern': ['‘', '’'],
    \     'select-a': 'aq',
    \     'select-i': 'iq',
    \   },
    \  'curly-double': {
    \     'pattern': ['“', '”'],
    \     'select-a': 'aQ',
    \     'select-i': 'iQ',
    \   },
    \ }
  call textobj#user#plugin('universal', s:universal_textobjs_map)
endif
