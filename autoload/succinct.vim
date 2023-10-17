"-----------------------------------------------------------------------------
" Snippet and delimiter registering
"-----------------------------------------------------------------------------
" Escape command separator character for strings interpreted as mapping declarations
function! s:map_escape(string) abort
  return escape(a:string, '|')
endfunction

" Add snippet variables
" Note: Funcref cannot be assigned as local variable so do not iterate over items()
function! succinct#add_snippets(map, ...) abort
  let scope = a:0 && a:1 ? b: : g:
  for key in keys(a:map)
    let scope['snippet_' . char2nr(key)] = a:map[key]
  endfor
endfunction

" Add delimiters and text objects simultaneously
" Note: Funcref delimiters cannot be automatically translated to text objects
function! succinct#add_delims(map, ...) abort
  let scope = a:0 && a:1 ? b: : g:
  for key in keys(a:map)
    let scope['surround_' . char2nr(key)] = a:map[key]
  endfor
  let dest = {}
  let flag = a:0 && a:1 ? '<buffer> ' : ''
  for key in keys(a:map)
    if type(a:map[key]) != 1
      echohl WarningMsg
      echom "Warning: Cannot add key '" . key . "' as text object (non-string type)."
      echohl None
      continue
    endif
    let pattern = succinct#process_value(a:map[key], 1)
    let pattern = split(pattern, "\r")
    if pattern[0] ==# pattern[1]  " special handling if delims are identical, e.g. $$
      let dest['textobj_' . char2nr(key) . '_i'] = {
        \ 'pattern': pattern[0] . '\zs.\{-}\ze' . pattern[0],
        \ 'select': flag . 'i' . s:map_escape(key),
        \ }
      let dest['textobj_' . char2nr(key) . '_a'] = {
        \ 'pattern': pattern[0] . '.\{-}' . pattern[0],
        \ 'select': flag . 'a' . s:map_escape(key),
        \ }
    else
      let dest['textobj_' . char2nr(key)] = {
        \ 'pattern': pattern,
        \ 'select-a': flag . 'a' . s:map_escape(key),
        \ 'select-i': flag . 'i' . s:map_escape(key),
        \ }
    endif
  endfor
  let name = a:0 && a:1 ? &filetype : 'global'
  let name = substitute(name, '[._-]', '', 'g')  " compound filetypes and others
  let name = 'succinct' . name  " prepend to avoid conflicts with native plugins
  if exists('*textobj#user#plugin')
    call textobj#user#plugin(name, dest)
  endif
endfunction

"-----------------------------------------------------------------------------"
" Snippet and delimiter processing
"-----------------------------------------------------------------------------"
" Escape special regex characters and replace newline with arbitrary spaces
" to account for automatic indentation
function! s:regex_escape(string) abort
  return substitute(escape(a:string, '[]\.*$~'), "\n", '\\_s*', 'g')
endfunction

" Obtain and process delimiters. If a:search is true return regex suitable for
" *searching* for delimiters with searchpair(), else return delimiters themselves.
" Note: this was adapted from vim-surround source code
function! succinct#process_value(value, ...) abort
  " Acquire user-input for placeholders \1, \2, \3, ...
  let search = a:0 && a:1 ? 1 : 0  " whether to insert or search the result
  let input = type(a:value) == 2 ? a:value() : a:value  " the string or funcref
  if empty(input) | return '' | endif  " e.g. funcs that start asynchronous fzf commands
  for nr in range(7)
    let m = matchstr(input, nr2char(nr) . '.\{-\}\ze' . nr2char(nr))
    if !empty(m)  " \1, \2, \3, ... found inside string
      if search  " search possible user-input values
        let s = '\%(\k\|\.\|\*\)'  " match e.g. foo.bar() or \section*{}
        let repl_{nr} = s . '\@<!' . s . '\+'  " pick longest coherent match
      else  " acquire user-input values
        let m = substitute(strpart(m, 1), '\r.*', '', '')
        let repl_{nr} = input(match(m, '\w\+$') >= 0 ? m . ': ' : m)
      endif
    endif
  endfor
  " Generate the snippet or delimiter string
  let idx = 0
  let output = ''
  while idx < strlen(input)
    let char = strpart(input, idx, 1)
    if char2nr(char) > 7  " simply insert the character, escaping magic charaters
      let part = search ? s:regex_escape(char) : char
    else  " replace \1, \2, \3, ... with user-input values
      let next = stridx(input, char, idx + 1)
      if next == -1
        let part = char  " use the literal \1, \2, etc.
      else
        let part = repl_{char2nr(char)}  " filled in above
        let query = strpart(input, idx + 1, next - idx - 1)  " the query between \1...\1
        let query = matchstr(query, '\r.*')  " a substitute initiation indication
        while query =~# '^\r.*\r'
          let group = matchstr(query, "^\r\\zs[^\r]*\r[^\r]*")  " a match and replace group
          let sub = strpart(group, 0, stridx(group, "\r"))  " the substitute
          let repl = strpart(group, stridx(group, "\r") + 1)  " the replacement
          let repl = search ? s:regex_escape(repl) : repl
          let part = substitute(part, sub, repl, '')  " apply substitution as requested
          let query = strpart(query, strlen(group) + 1)  " skip over the group
        endwhile
        let idx = next
      endif
    endif
    let output .= part
    let idx += 1
  endwhile
  return output
endfunction

"-----------------------------------------------------------------------------
" Fuzzy complete templates, snippets, and delimiters
"-----------------------------------------------------------------------------
" Template source and sink
function! s:template_sink(file) abort
  if exists('g:succinct_templates_path') && !empty(a:file)
    let templates = expand(g:succinct_templates_path)
    execute '0r ' . templates . '/' . a:file
    filetype detect
  endif
endfunction
function! s:template_source(ext) abort
  let paths = []
  if exists('g:succinct_templates_path')
    let templates = expand(g:succinct_templates_path)
    let paths = globpath(templates, '*.' . a:ext, 0, 1)
    let paths = filter(paths, '!isdirectory(v:val)')
    let paths = map(paths, 'fnamemodify(v:val, ":t")')
  endif
  if !empty(paths)
    let paths = [''] + paths  " add stand-in for 'load nothing'
  endif
  return paths
endfunction

" Delimiter and snippet sources and sinks
" Note: See below for more on fzf limitations.
function! s:snippet_surround_source(string) abort
  let opts = {}
  for scope in ['g:', 'b:']
    let vars = getcompletion(scope . a:string . '_', 'var')
    for name in vars
      let key = nr2char(substitute(name, scope . a:string . '_', '', ''))
      let opts[key] = eval(name)  " local vars will overwrite global vars
    endfor
  endfor
  return map(items(opts), "v:val[0] . ': ' . string(v:val[1])")
endfunction
function! s:snippet_sink(item) abort
  let key = split(a:item, ':')[0]
  call feedkeys("\<Plug>Isnippet" . key, 'ti')
endfunction
function! s:surround_sink(mode, item) abort
  let key = split(a:item, ':')[0]
  call feedkeys("\<Plug>" . a:mode . 'surround' . key, 'ti')
endfunction

" Fuzzy select functions
" Warning: Currently calling default fzf#run with any window options (e.g. by calling
" fzf#wrap) causes vim to exit insert mode (seems to be related to triggering use_term=1
" inside fzf#run), requiring us to recover cursor position and sometimes triggering
" obscure E565 error that effectly disables insert mode until vim session is restarted
" (seems to be related to feedkeys('a...' invocation)). Workaround is to call fzf#run()
" with no window options and letting it fill the screen (use --height=100% to ensure
" all entries shown). In future may have to make this work but for now this is fine.
function! s:fzf_check() abort
  let flag = exists('*fzf#run')
  if !flag | echohl WarningMsg | echom 'Warning: FZF plugin not found.' | echohl None | endif
  return flag
endfunction
function! succinct#template_select() abort
  let templates = s:template_source(expand('%:e'))
  if empty(templates) | return | endif
  if !s:fzf_check() | return | endif
  call fzf#run(fzf#wrap({
    \ 'sink': function('s:template_sink'),
    \ 'source': templates,
    \ 'options': '--no-sort --height=100% --prompt="Template> "',
    \ }))
endfunction
function! succinct#snippet_select() abort
  if !s:fzf_check() | return | endif
  call fzf#run({
    \ 'sink': function('s:snippet_sink'),
    \ 'source': s:snippet_surround_source('snippet'),
    \ 'options': '--no-sort --height=100% --prompt="Snippet> "',
    \ })
endfunction
function! succinct#surround_select(mode) abort
  if !s:fzf_check() | return | endif
  call fzf#run({
    \ 'sink': function('s:surround_sink', [a:mode]),
    \ 'source': s:snippet_surround_source('surround'),
    \ 'options': '--no-sort --height=100% --prompt="Surround> "',
    \ })
endfunction

"-----------------------------------------------------------------------------"
" Snippet handling
"-----------------------------------------------------------------------------"
" Process snippet value
function! s:process_snippet(input) abort
  let output = type(a:input) == 2 ? a:input() : a:input  " run funcref function
  return succinct#user_input(output)  " handle \1...\1, \2...\2 pairs
endfunction

" Get character (copied from surround.vim)
function! s:get_char() abort
  let char = getchar()
  if char =~# '^\d\+$'
    let char = nr2char(char)
  endif
  if char =~# "\<Esc>" || char =~# "\<C-C>"
    return ''
  else
    return char
  endif
endfunction

" Add user-defined snippet, either a fixed string or user input with prefix/suffix
" Warning: Some dict entries may be funcrefs and cannot assign as local variable
function! succinct#insert_snippet(...) abort
  let pad = ''
  let snippet = ''
  let char = a:0 ? a:1 : s:get_char()
  if char =~# '\s'  " similar to surround, permit <C-a><Space><Key> to surround with space
    let pad = char
    let char = s:get_char()
  endif
  if !empty(char)
    let key = 'snippet_' . char2nr(char)
    for scope in ['b:', 'g:']  " note buffer maps have priority
      if exists(scope . key) && !empty(eval(scope . key))
        let snippet = succinct#process_value(eval(scope . key))
        break
      endif
    endfor
  endif
  return empty(snippet) ? '' : pad . snippet . pad
endfunction

"-----------------------------------------------------------------------------"
" Delimiter handling
"-----------------------------------------------------------------------------"
" Navigation without triggering InsertLeave
" Consider using this in many other situations
function! s:move_cursor(lnum, cnum, lorig, corig) abort
  if a:lnum == a:lorig
    let cdiff = a:cnum - a:corig
    return repeat(cdiff > 0 ? "\<Right>" : "\<Left>", abs(cdiff))
  else
    let ldiff = a:lnum - a:lorig
    return "\<Home>" . repeat(ldiff > 0 ? "\<Down>" : "\<Up>", abs(ldiff)) . repeat("\<Right>", a:cnum - 1)
  endif
endfunction

" Delimiter regular expression using delimitMate and matchpairs
" This is used for delimiter jumping
function! s:delim_regex() abort
  let delims = exists('b:delimitMate_matchpairs') ? b:delimitMate_matchpairs
    \ : exists('g:delimitMate_matchpairs') ? g:delimitMate_matchpairs : &matchpairs
  let delims = substitute(delims, '[:,]', '', 'g')
  let quotes = exists('b:delimitMate_quotes') ? b:delimitMate_quotes
    \ : exists('g:delimitMate_quotes') ? g:delimitMate_quotes : "\" ' `"
  let quotes = substitute(quotes, '\s\+', '', 'g')
  return '[' . escape(delims . quotes, ']^-\') . ']'
endfunction

" Move to right of previous delim  ( [ [ ( "  "  asd) sdf    ]  sdd   ]  as) h adfas)
" Warning: Calls to e.g. cursor() fail to move cursor in insert mode, even though
" 'current position' (i.e. getpos('.') after e.g. cursor()) changes inside function
function! succinct#prev_delim() abort
  let [_, lorig, corig, _] = getpos('.')
  call search(s:delim_regex(), 'eb')
  if col('.') > corig - 2 | call search(s:delim_regex(), 'eb') | endif
  return s:move_cursor(line('.'), col('.') + 1, lorig, corig)
endfunction

" Move to right of next delim. Why starting from current position? Even if cursor is on
" delimiter, want to find it and move to the right of it
" Warning: Cannot use search() because it fails to detect current column. Could
" use setpos() but then if fail to find delim that moves cursor which is weird.
function! succinct#next_delim() abort
  let [_, lorig, corig, _] = getpos('.')
  let [lsearch, csearch] = [lorig, corig]
  if csearch == 1
    let lsearch = max([1, lsearch - 1])
    exe lsearch
    let csearch = col('$')
  endif
  call cursor(lsearch, csearch - 1)
  call search(s:delim_regex(), 'e')
  return s:move_cursor(line('.'), col('.') + 1, lorig, corig)
endfunction

" Special popup menu behavior just for me and my .vimrc!
" No one has to know ;)
function! succinct#pum_close() abort
  if !pumvisible() || !exists('b:pum_pos')
    return ''
  elseif b:pum_pos
    let b:pum_pos = 0
    return "\<C-y>\<C-]>"
  else
    return "\<C-e>"
  endif
endfunction

"-----------------------------------------------------------------------------"
" Changing and deleting surrounding delimiters
"-----------------------------------------------------------------------------"
" Get delimiters from input key
function! s:get_delims(search) abort
  if a:search  " handle repeated actions
    let nr = exists('b:succinct_search_delim') ? b:succinct_search_delim : getchar()
    let b:succinct_search_delim = nr
  else
    let nr = exists('b:succinct_replace_delim') ? b:succinct_replace_delim : getchar()
    let b:succinct_replace_delim = nr
  endif
  if exists('b:surround_' . nr)
    let string = b:surround_{nr}
  elseif exists('g:surround_' . nr)
    let string = g:surround_{nr}
  else
    let string = nr2char(nr) . "\r" . nr2char(nr)
  endif
  let delims = succinct#process_value(string, a:search)
  return split(delims, "\r")
endfunction

" Driver function that accepts left and right delims, and runs normal mode commands
" from the leftmost character of left and right delims. This function sets the mark
" 'z to the end of each delim, so expression can be d`zx
" Note: Mark motion commands only work up until and excluding the mark, so
" make sure your command accounts for that!
function! s:pair_action(left, right, lexpr, rexpr, count) abort
  " Get positions for *start* of matches
  if !exists('*searchpairpos')  " older versions
    return
  endif
  for _ in range(a:count)
    " Find positions
    if a:left ==# a:right
      let [l1, c11] = searchpos(a:left, 'bnW')
      let [l2, c21] = searchpos(a:left, 'nW')
    else
      let [l1, c11] = searchpairpos(a:left, '', a:right, 'bnW')  " set '' mark at current location
      let [l2, c21] = searchpairpos(a:left, '', a:right, 'nW')
    endif
    if l1 == 0 || l2 == 0
      continue
    endif
    " Delete or change right delim. If this leaves an empty line, delete it.
    " Note: Right must come first!
    call cursor(l2, c21)
    let [l2, c22] = searchpos(a:right, 'cen')
    call setpos("'z", [0, l2, c22, 0])
    set paste
    exe 'normal! ' . a:rexpr
    set nopaste
    if empty(substitute(getline(l2), '^\_s*\(.\{-}\)\_s*$', '\1', ''))  " strip whitespace
      exe l2 . 'd'
    endif
    " Delete or change left delim
    call cursor(l1, c11)
    let [l1, c12] = searchpos(a:left, 'cen')
    call setpos("'z", [0, l1, c12, 0])
    set paste
    exe 'normal! ' . a:lexpr
    set nopaste
    if empty(substitute(getline(l1), '^\_s*\(.\{-}\)\_s*$', '\1', ''))  " strip whitespace
      exe l1 . 'd'
    endif
  endfor
endfunction

" Change surrounding delimiters
function! succinct#change_delims() abort
  let [prev1, prev2] = s:get_delims(1)
  let [new1, new2] = s:get_delims(0)
  call s:pair_action(prev1, prev2, '"_c`z' . new1 . "\<Delete>", '"_c`z' . new2 . "\<Delete>", v:count1)
  if exists('*repeat#set')
    call repeat#set("\<Plug>ChangeDelims")
  endif
endfunction

" Delete surrounding delimiters
function! succinct#delete_delims() abort
  let [delim1, delim2] = s:get_delims(1)  " disallow user input
  call s:pair_action(delim1, delim2, '"_d`z"_x', '"_d`z"_x', v:count1)
  if exists('*repeat#set')
    call repeat#set("\<Plug>DeleteDelims")
  endif
endfunction

" Reset internal characters
" Note: This supports repeated actions with '.'
function! succinct#reset_delims() abort
  silent! unlet b:succinct_search_delim
  silent! unlet b:succinct_replace_delim
endfunction
