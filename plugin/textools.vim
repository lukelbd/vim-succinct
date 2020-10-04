"-----------------------------------------------------------------------------"
" Global plugin settings
"-----------------------------------------------------------------------------"
" Define mappings and delimiters
if !exists('g:textools_templates_path')
  let g:textools_templates_path = '~/templates'
endif
if !exists('g:textools_surround_prefix')
  let g:textools_surround_prefix = '<C-s>'
endif
if !exists('g:textools_snippet_prefix')
  let g:textools_snippet_prefix = '<C-d>'
endif
if !exists('g:textools_prevdelim_map')
  let g:textools_prevdelim_map = '<C-h>'
endif
if !exists('g:textools_nextdelim_map')
  let g:textools_nextdelim_map = '<C-l>'
endif
if !exists('g:textools_delimjump_regex')
  let g:textools_delimjump_regex = '[()\[\]{}<>]' " list of 'outside' delimiters for jk matching
endif

"-----------------------------------------------------------------------------"
" Local functions
"-----------------------------------------------------------------------------"
" Move to right of previous delim
" ( [ [ ( "  "  asdfad) sdf    ]  sdfad   ]  asdfasdf) hello   asdfas)
" Warning: Think these function shave to be inside plugin and not
" autoload for some reason.
" Note: matchstrpos is relatively new/less portable, e.g. fails on midway
" Used to use matchstrpos, now just use match(); much simpler
" Note: Why up to two places to left of current position (col('.') - 1)? There is
" delimiter to our left, want to ignore that. If delimiter is left of cursor, we are at
" a 'next to the cursor' position; want to test line even further to the left.
function! s:prev_delim()
  let string = getline('.')[:col('.') - 3]
  let string = join(reverse(split(string, '.\zs')), '') " search the *reversed* string
  let pos = 0
  for i in range(max([v:count, 1]))
    let result = match(string, g:textools_delimjump_regex, pos) " get info on *first* match
    if result==-1 | break | endif
    let pos = result + 1  " go to next one
  endfor
  if pos == 0 " relative position is zero, i.e. don't move
    return ''
  else
    return repeat("\<Left>", pos)
  endif
endfunction

" Move to right of next delim
" Why starting from current position? Even if cursor is
" on delimiter, want to find it and move to the right of it
function! s:next_delim()
  let string = getline('.')[col('.')-1:]
  let pos = 0
  for i in range(max([v:count,1]))
    let result = match(string, g:textools_delimjump_regex, pos) " get info on *first* match
    if result==-1 | break | endif
    let pos = result + 1 " go to next one
  endfor
  if mode()!~#'[rRiI]' && pos+col('.') >= col('$') " want to put cursor at end-of-line, but can't because not in insert mode
    let pos = col('$')-col('.')-1
  endif
  if pos == 0 " relative position is zero, i.e. don't move
    return ''
  else
    return repeat("\<Right>", pos)
  endif
endfunction

" Define the maps, with special consideration for whether popup menu is
" open. See: https://github.com/lukelbd/dotfiles/blob/master/.vimrc
function! s:popup_close()
  if !pumvisible()
    return ''
  elseif b:menupos == 0 " exit
    return "\<C-e>"
  else
    let b:menupos = 0 " approve and exit
    return "\<C-y>"
  endif
endfunction

" Functions that list and read templates
function! s:template_list(ext)
  let templates = split(globpath(g:textools_templates_path, '*.' . a:ext), "\n")
  let templates = map(templates, 'fnamemodify(v:val, ":t")')
  return [''] + templates " add blank entry as default choice
endfunction
function! s:template_read(file)
  if !empty(a:file)
    execute '0r ' . g:textools_templates_path . '/' . a:file
  endif
endfunction

"-----------------------------------------------------------------------------"
" Define commands and mappings
"-----------------------------------------------------------------------------"
" Apply plugin mappings
" Note: Lowercase Isurround plug inserts delims without newlines. Instead of
" using ISurround we define special begin end delims with newlines baked in.
inoremap <Plug>ResetUndo <C-g>u
inoremap <silent> <expr> <Plug>PrevDelim <sid>popup_close() . <sid>prev_delim()
inoremap <silent> <expr> <Plug>NextDelim <sid>popup_close() . <sid>next_delim()
inoremap <silent> <Plug>IsurroundShow <C-o>:echo textools#print_bindings('surround')<CR>
inoremap <silent> <Plug>IsnippetShow <C-o>:echo textools#print_bindings('snippet')<CR>
inoremap <expr> <Plug>Isnippet textools#insert_snippet()

" Apply custom prefixes
" Todo: Support surround-like '\1' notation for user input-dependent snippets...
" ...or not. While current method prohibits snippets with function substrings, it
" permits custom user-input functions that call FZF instead of input().
exe 'vmap ' . g:textools_surround_prefix   . ' <Plug>VSurround'
exe 'imap ' . g:textools_surround_prefix   . ' <Plug>ResetUndo<Plug>Isurround'
exe 'imap ' . g:textools_snippet_prefix . ' <Plug>ResetUndo<Plug>Isnippet'
exe 'imap ' . repeat(g:textools_snippet_prefix, 2) . ' <Plug>IsnippetShow'
exe 'imap ' . repeat(g:textools_surround_prefix, 2) . ' <Plug>IsurroundShow'
exe 'imap ' . g:textools_prevdelim_map . ' <Plug>PrevDelim'
exe 'imap ' . g:textools_nextdelim_map . ' <Plug>NextDelim'
nnoremap <silent> ds :call textools#delete_delims()<CR>
nnoremap <silent> cs :call textools#change_delims()<CR>

" Add commands
command! -nargs=0 SnippetShow echo textools#print_bindings('snippet')
command! -nargs=+ SnippetSearch echo textools#search_bindings('snippet', <q-args>)
command! -nargs=0 SurroundShow echo textools#print_bindings('surround')
command! -nargs=+ SurroundSearch echo textools#search_bindings('surround', <q-args>)

" Add autocommands
" Todo: Support additional filetypes!
" Note: Arguments passed to function() partial are passed to underlying func first.
if exists('*fzf#run')
  augroup templates
    au!
    au BufNewFile * call fzf#run({
      \ 'source': s:template_list(expand('<afile>:e')),
      \ 'options': '--no-sort',
      \ 'sink': function('s:template_read'),
      \ 'down': '~30%'
      \ })
  augroup END
endif
