"-----------------------------------------------------------------------------"
" Global plugin settings
"-----------------------------------------------------------------------------"
" Define mappings and delimiters
if !exists('g:succinct_templates_path')
  let g:succinct_templates_path = '~/templates'
endif
if !exists('g:succinct_surround_prefix')
  let g:succinct_surround_prefix = '<C-s>'
endif
if !exists('g:succinct_snippet_prefix')
  let g:succinct_snippet_prefix = '<C-a>'
endif
if !exists('g:succinct_prevdelim_map')
  let g:succinct_prevdelim_map = '<C-h>'
endif
if !exists('g:succinct_nextdelim_map')
  let g:succinct_nextdelim_map = '<C-l>'
endif

"-----------------------------------------------------------------------------"
" Default commands, mappings, delims, and text objects
"-----------------------------------------------------------------------------"
" Template selection with safety measures
" Note: If statement must be embedded in function to avoid race condition issues
function! s:select_template() abort
  let templates = succinct#utils#template_source(expand('%:e'))
  if empty(templates) || !exists('*fzf#run') | return | endif
  call fzf#run(fzf#wrap({
    \ 'source': templates,
    \ 'options': '--no-sort --prompt="Template> "',
    \ 'sink': function('succinct#utils#template_read'),
    \ }))
endfunction
augroup succinct
  au!
  au BufNewFile * call s:select_template()
augroup END

" Fuzzy delimiter and snippet selection
" Note: Arguments passed to function() partial are passed to underlying func first.
inoremap <silent> <Plug>IsnippetPick
  \ <Cmd>if exists('*fzf#run') \| call fzf#run(fzf#wrap({
  \ 'source': succinct#utils#pick_source('snippet'),
  \ 'options': '--no-sort --prompt="Snippet> "',
  \ 'down': '~30%',
  \ 'sink': function('succinct#utils#pick_snippet_sink'),
  \ })) \| endif<CR>
inoremap <Plug>IsurroundPick
  \ <Cmd>if exists('*fzf#run') \| call fzf#run(fzf#wrap({
  \ 'source': succinct#utils#pick_source('surround'),
  \ 'options': '--no-sort --prompt="Surround> "',
  \ 'down': '~30%',
  \ 'sink': function('succinct#utils#pick_surround_sink'),
  \ })) \| endif<CR>
exe 'imap ' . repeat(g:succinct_surround_prefix, 2) . ' <Plug>IsurroundPick'
exe 'imap ' . repeat(g:succinct_snippet_prefix, 2) . ' <Plug>IsnippetPick'

" Delimiter navigation and modification mappings
" Note: <C-u> is required to remove range resulting from <count>: action
" Note: Lowercase Isurround plug inserts delims without newlines. Instead
" they can be added by pressing <CR> before the delim name (similar to space).
inoremap <Plug>ResetUndo <C-g>u
inoremap <expr> <Plug>Isnippet succinct#utils#insert_snippet()
inoremap <expr> <Plug>PrevDelim succinct#utils#pum_close() . succinct#utils#prev_delim()
inoremap <expr> <Plug>NextDelim succinct#utils#pum_close() . succinct#utils#next_delim()
nnoremap <Plug>DeleteDelim <Cmd>call succinct#utils#delete_delims()<CR>
nnoremap <Plug>ChangeDelim <Cmd>call succinct#utils#change_delims()<CR>
exe 'vmap ' . g:succinct_surround_prefix . ' <Plug>VSurround'
exe 'imap ' . g:succinct_surround_prefix . ' <Plug>ResetUndo<Plug>Isurround'
exe 'imap ' . g:succinct_snippet_prefix . ' <Plug>ResetUndo<Plug>Isnippet'
exe 'imap ' . g:succinct_prevdelim_map . ' <Plug>PrevDelim'
exe 'imap ' . g:succinct_nextdelim_map . ' <Plug>NextDelim'
nmap <expr> ds succinct#utils#reset_delims() . "\<Plug>DeleteDelim"
nmap <expr> cs succinct#utils#reset_delims() . "\<Plug>ChangeDelim"


" Define $global$ *delimiters* and text objects
" Note: For surrounding with spaces just hit space twice
call succinct#add_delims({
  \ '': "\n\r\n",
  \ "'": "'\r'",
  \ '"': "\"\r\"",
  \ 'q': "‘\r’",
  \ 'Q': "“\r”",
  \ 'b': "(\r)",
  \ '(': "(\r)",
  \ 'c': "{\r}",
  \ 'B': "{\r}",
  \ '{': "{\r}",
  \ '*': "*\r*",
  \ 'r': "[\r]",
  \ '[': "[\r]",
  \ 'a': "<\r>",
  \ '<': "<\r>",
  \ '\': "\\\"\r\\\"",
  \ 'f': "\1function: \1(\r)",
  \ 'A': "\1array: \1[\r]",
  \ })
