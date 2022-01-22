"-----------------------------------------------------------------------------"
" Global plugin settings
"-----------------------------------------------------------------------------"
" Define mappings and delimiters
if !exists('g:swift_templates_path')
  let g:swift_templates_path = '~/templates'
endif
if !exists('g:swift_surround_prefix')
  let g:swift_surround_prefix = '<C-s>'
endif
if !exists('g:swift_snippet_prefix')
  let g:swift_snippet_prefix = '<C-d>'
endif
if !exists('g:swift_prevdelim_map')
  let g:swift_prevdelim_map = '<C-h>'
endif
if !exists('g:swift_nextdelim_map')
  let g:swift_nextdelim_map = '<C-l>'
endif

"-----------------------------------------------------------------------------"
" Default commands, mappings, delims, and text objects
"-----------------------------------------------------------------------------"
" Template selection
" Note: Arguments passed to function() partial are passed to underlying func first.
augroup swift
  au!
  au BufNewFile * if exists('*fzf#run') | call fzf#run({
    \ 'source': swift#utils#template_source(expand('<afile>:e')),
    \ 'options': '--no-sort --prompt="Template> "',
    \ 'down': '~30%',
    \ 'sink': function('swift#utils#template_read'),
    \ }) | endif
augroup END

" Apply plugin mappings
" Note: Lowercase Isurround plug inserts delims without newlines. Instead of
" using ISurround we define special begin end delims with newlines baked in.
inoremap <Plug>ResetUndo <C-g>u
inoremap <silent> <expr> <Plug>Isnippet swift#utils#insert_snippet()
inoremap <silent> <expr> <Plug>PrevDelim swift#utils#pum_close() . swift#utils#prev_delim()
inoremap <silent> <expr> <Plug>NextDelim swift#utils#pum_close() . swift#utils#next_delim()
inoremap <silent> <Plug>IsnippetPick <C-o>:call fzf#run({
  \ 'source': swift#utils#pick_source('snippet'),
  \ 'options': '--no-sort --prompt="Snippet> "',
  \ 'down': '~30%',
  \ 'sink': function('swift#utils#pick_snippet_sink'),
  \ })<CR>
inoremap <silent> <Plug>IsurroundPick <C-o>:call fzf#run({
  \ 'source': swift#utils#pick_source('surround'),
  \ 'options': '--no-sort --prompt="Surround> "',
  \ 'down': '~30%',
  \ 'sink': function('swift#utils#pick_surround_sink'),
  \ })<CR>

" Apply custom prefixes
" Warning: <C-u> required to remove range resulting from <count>: action
exe 'vmap ' . g:swift_surround_prefix . ' <Plug>VSurround'
exe 'imap ' . g:swift_surround_prefix . ' <Plug>ResetUndo<Plug>Isurround'
exe 'imap ' . g:swift_snippet_prefix . ' <Plug>ResetUndo<Plug>Isnippet'
exe 'imap ' . g:swift_prevdelim_map . ' <Plug>PrevDelim'
exe 'imap ' . g:swift_nextdelim_map . ' <Plug>NextDelim'
exe 'imap ' . repeat(g:swift_surround_prefix, 2) . ' <Plug>IsurroundPick'
exe 'imap ' . repeat(g:swift_snippet_prefix, 2) . ' <Plug>IsnippetPick'
nnoremap <silent> <Plug>SwiftDeleteDelims :<C-u>call swift#utils#delete_delims()<CR>
nnoremap <silent> <Plug>SwiftChangeDelims :<C-u>call swift#utils#change_delims()<CR>
nmap <expr> ds swift#utils#reset_delims() . "\<Plug>SwiftDeleteDelims"
nmap <expr> cs swift#utils#reset_delims() . "\<Plug>SwiftChangeDelims"

" Define $global$ *delimiters* and text objects
" Note: For surrounding with spaces just hit space twice
call swift#add_delims({
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
