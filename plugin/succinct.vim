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
augroup succinct
  au!
  au BufNewFile * call succinct#internal#template_select()
augroup END

" Fuzzy delimiter and snippet selection
" Note: Arguments passed to function() partial are passed to underlying func first.
" Warning: Again the <Plug> name cannot start with <Plug>Isnippet or <Plug>Isurround
" or else vim will wait until another keystroke to figure out which <Plug> is meant.
inoremap <Plug>SelectIsnippet <Cmd>call succinct#internal#snippet_select()<CR>
inoremap <Plug>SelectIsurround <Cmd>call succinct#internal#surround_select('I')<CR>
inoremap <Plug>SelectVsurround <Cmd>call succinct#internal#surround_select('V')<CR>
exe 'imap ' . repeat(g:succinct_snippet_prefix, 2) . ' <Plug>SelectIsnippet'
exe 'imap ' . repeat(g:succinct_surround_prefix, 2) . ' <Plug>SelectIsurround'
exe 'vmap ' . repeat(g:succinct_surround_prefix, 2) . ' <Plug>SelectVsurround'

" Delimiter navigation and modification mappings
" Note: <C-r>= notation to insert snippets is consistent with <Plug>SelectIsurround.
" Note: Lowercase SelectIsurround plug inserts delims without newlines. Instead they
" can be added by pressing <CR> before the delim name (similar to space).
inoremap <expr> <Plug>PrevDelim succinct#internal#pum_close() . succinct#internal#prev_delim()
inoremap <expr> <Plug>NextDelim succinct#internal#pum_close() . succinct#internal#next_delim()
inoremap <Plug>ResetUndo <C-g>u
inoremap <Plug>Isnippet <C-r>=succinct#internal#insert_snippet()<CR>
nnoremap <Plug>DeleteDelim <Cmd>call succinct#internal#delete_delims()<CR>
nnoremap <Plug>ChangeDelim <Cmd>call succinct#internal#change_delims()<CR>
exe 'imap ' . g:succinct_prevdelim_map . ' <Plug>PrevDelim'
exe 'imap ' . g:succinct_nextdelim_map . ' <Plug>NextDelim'
exe 'imap ' . g:succinct_snippet_prefix . ' <Plug>ResetUndo<Plug>Isnippet'
exe 'imap ' . g:succinct_surround_prefix . ' <Plug>ResetUndo<Plug>Isurround'
exe 'vmap ' . g:succinct_surround_prefix . ' <Plug>VSurround'
nmap <expr> ds succinct#internal#reset_delims() . "\<Plug>DeleteDelim"
nmap <expr> cs succinct#internal#reset_delims() . "\<Plug>ChangeDelim"

" Add $global$ *delimiters* and text objects
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
