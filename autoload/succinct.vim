"-----------------------------------------------------------------------------
" Snippet and delimiter registering
"-----------------------------------------------------------------------------
" Add snippet variables
" Warning: Funcref cannot be assigned as local variable so do not iterate over items()
function! s:parse_input(input) abort
  let chars = {'r': "\r", 'n': "\n", '1': "\1", '2': "\2", '3': "\3", '4': "\4", '5': "\5", '6': "\6", '7': "\7"}
  let chars = type(a:input) == 1 ? chars : {}
  let output = type(a:input) == 1 ? a:input : ''
  for [char, repl] in items(chars)
    let check = char2nr(repl) > 7 ? '\w\@!' : ''
    let output = substitute(output, '\\' . char . check, repl, 'g')
  endfor
  return empty(output) ? a:input : output
endfunction
function! succinct#add_snippets(source, ...) abort
  let scope = a:0 && a:1 ? b: : g:
  for key in keys(a:source)  " funcref cannot be lower case so iterate keys
    let name = 'snippet_' . char2nr(key)
    let scope[name] = s:parse_input(a:source[key])
  endfor
endfunction

" Add delimiters and text objects simultaneously
" Warning: Funcref delimiters cannot be automatically translated to text objects
function! s:escape_key(key) abort  " escape command separate for map delcarations
  return escape(a:key, '|')
endfunction
function! s:escape_value(value) abort  " escape regular expressions and allow indents
  return substitute(escape(a:value, '[]\.*~^$'), '\(\n\|\\n\)', '\\_s*', 'g')
endfunction
function! succinct#add_delims(source, ...) abort
  let scope = a:0 && a:1 ? b: : g:
  for key in keys(a:source)  " funcref cannot be lower case so iterate keys
    let name = 'surround_' . char2nr(key)
    let scope[name] = s:parse_input(a:source[key])
  endfor
  let flag = a:0 && a:1 ? '<buffer> ' : ''
  let specs = {}
  for key in keys(a:source)
    if type(a:source[key]) != 1
      echohl WarningMsg
      echom "Warning: Cannot add key '" . key . "' as text object (non-string type)."
      echohl None
      continue
    endif
    let pair = s:parse_input(a:source[key])
    let pair = succinct#process_value(pair, 1)
    if count(pair, "\r") != 1 | continue | endif
    let [match1, match2] = split(pair, "\r")
    if match1 ==# match2 || match1 =~# '\\\@<!['  " special handling e.g. '$$'
      let name1 = 'textobj_' . char2nr(key) . '_i'
      let name2 = 'textobj_' . char2nr(key) . '_a'
      let specs[name1] = {
        \ 'pattern': match1 . '\zs\_s*.\{-}\_s*\ze' . match2,
        \ 'select': flag . 'i' . s:escape_key(key),
        \ }
      let specs[name2] = {
        \ 'pattern': match1 . '\_s*.\{-}\_s*' . match2,
        \ 'select': flag . 'a' . s:escape_key(key),
        \ }
    else  " standard handling
      let name = 'textobj_' . char2nr(key)
      let specs[name] = {
        \ 'pattern': [match1, match2],
        \ 'select-a': flag . 'a' . s:escape_key(key),
        \ 'select-i': flag . 'i' . s:escape_key(key),
        \ }
    endif
  endfor
  let plugin = a:0 && a:1 ? &filetype : 'global'
  let plugin = substitute(plugin, '[._-]', '', 'g')  " compound filetypes
  let command = substitute(plugin, '^\(\l\)', '\u\1', 0)  " command name
  if exists('*textobj#user#plugin')
    call textobj#user#plugin(plugin, specs)
    silent! exe 'Textobj' . command . 'DefaultKeyMappings!'
  endif
endfunction

"-----------------------------------------------------------------------------"
" Snippet and delimiter processing
"-----------------------------------------------------------------------------"
" Obtain and process delimiters. If a:search is true return regex suitable for
" *searching* for delimiters with searchpair(), else return delimiters themselves.
" Note: this was adapted from vim-surround source code
function! succinct#process_value(value, ...) abort
  " Acquire user-input for placeholders \1, \2, \3, ...
  let search = a:0 ? a:1 : 0  " whether to perform search
  let input = type(a:value) == 2 ? a:value() : a:value  " string or funcref
  if empty(input) | return '' | endif  " e.g. funcref that starts asynchronous fzf
  for nr in range(7)
    let idx = matchstr(input, nr2char(nr) . '.\{-\}\ze' . nr2char(nr))
    if !empty(idx)  " \1, \2, \3, ... found inside string
      if search  " search possible user-input values
        let s = '\%(\k\|\.\|\*\)'  " match e.g. foo.bar() or \section*{}
        let repl_{nr} = s . '\@<!' . s . '\+'  " pick longest coherent match
      else  " acquire user-input values
        let idx = substitute(strpart(idx, 1), '\r.*', '', '')
        let repl_{nr} = input(match(idx, '\w\+$') >= 0 ? idx . ': ' : idx)
      endif
    endif
  endfor
  " Replace inner regions with user input result
  let idx = 0
  let head = input[0] =~# '[''"]' ? '\(\<[frub]\+\)\?' : ''
  let head = &filetype ==# 'python' && search ? head : ''
  let input = search ? s:escape_value(input) : input
  let output = ''
  while idx < strlen(input)
    let part = strpart(input, idx, 1)
    let other = char2nr(part) <= 7 ? stridx(input, part, idx + 1) : -1
    if other > 0  " replace \1, \2, \3, ... with user input using inner text as prompt
      let query = strpart(input, idx + 1, other - idx - 1)  " query between \1...\1
      let query = matchstr(query, '\r.*')  " substitute initiation indication
      let part = repl_{char2nr(part)}  " defined above
      let idx = other  " resume after
      while query =~# '^\r.*\r'
        let group = matchstr(query, '^\r\zs[^\r]*\r[^\r]*')  " match replace group
        let sub = strpart(group, 0, stridx(group, "\r"))  " the substitute
        let repl = strpart(group, stridx(group, "\r") + 1)  " the replacement
        let repl = search ? s:escape_value(repl) : repl
        let part = substitute(part, sub, repl, '')  " apply substitution as requested
        let query = strpart(query, strlen(group) + 1)  " skip over the group
      endwhile
    endif
    let idx += 1
    let output .= part
  endwhile
  return head . output
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
function! s:variable_source(prefix) abort
  let opts = {}
  for scope in ['g:', 'b:']
    let vars = getcompletion(scope . a:prefix . '_', 'var')
    for name in vars
      let key = substitute(name, scope . a:prefix . '_', '', '')
      let opts[nr2char(key)] = eval(name)  " local will overwrite global variables
    endfor
  endfor
  return map(items(opts), 'v:val[0] . '': '' . string(v:val[1])')
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
  if !exists('*fzf#run')
    echohl WarningMsg
    echom 'Warning: FZF plugin not found.'
    echohl None
  endif
  return exists('*fzf#run')
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
    \ 'source': s:variable_source('snippet'),
    \ 'options': '--no-sort --height=100% --prompt="Snippet> "',
    \ })
endfunction
function! succinct#surround_select(mode) abort
  if !s:fzf_check() | return | endif
  call fzf#run({
    \ 'sink': function('s:surround_sink', [a:mode]),
    \ 'source': s:variable_source('surround'),
    \ 'options': '--no-sort --height=100% --prompt="Surround> "',
    \ })
endfunction

"-----------------------------------------------------------------------------"
" Snippet handling
"-----------------------------------------------------------------------------"
" Helper function
" Note: Copied from surround.vim
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

" Add user-defined snippet (either fixed string or input with prefix/suffix)
" Warning: Some dict entries may be funcrefs and cannot assign as local variable
function! succinct#insert_snippet(...) abort
  let pad = ''
  let text = ''
  let char = a:0 ? a:1 : s:get_char()
  if char =~# '\s'  " similar to surround, permit <C-e><Space><Key> to surround spaces
    let pad = char
    let char = s:get_char()
  endif
  if !empty(char)
    let name = 'snippet_' . char2nr(char)
    for scope in [b:, g:]  " note buffer maps have priority
      if !empty(get(scope, name, ''))
        let text = succinct#process_value(scope[name], 0) | break
      endif
    endfor
  endif
  return empty(text) ? '' : pad . text . pad
endfunction

"-----------------------------------------------------------------------------"
" Delimiter handling
"-----------------------------------------------------------------------------"
" Delimiter regular expression using delimitMate and matchpairs
" This is used for delimiter jumping
function! s:find_delim(...) abort
  let delims = &matchpairs  " default
  let delims = get(g:, 'delimitMate_matchpairs', delims)  " global setting
  let delims = get(b:, 'delimitMate_matchpairs', delims)  " buffer setting
  let delims = substitute(delims, '[:,]', '', 'g')
  let quotes = "\" ' `"
  let quotes = get(g:, 'delimitMate_quotes', quotes)  " global setting
  let quotes = get(b:, 'delimitMate_quotes', quotes)  " buffer setting
  let quotes = substitute(quotes, '\s\+', '', 'g')
  let regex = '[' . escape(delims . quotes, ']^-\') . ']'
  call search(regex, a:0 ? a:1 : 'e')
endfunction

" Navigation without triggering InsertLeave
" Consider using this in many other situations
function! s:move_delim(lnum, cnum, lorig, corig) abort
  let scroll = get(b:, 'scroll_state', 0)  " internal .vimrc setting
  let action = !pumvisible() ? '' : scroll ? "\<C-y>\<C-]>" : "\<C-e>"
  if a:lnum == a:lorig
    let cnr = a:cnum - a:corig
    let key = cnr > 0 ? "\<Right>" : "\<Left>"
    let motion = repeat(key, abs(cnr))
  else
    let cnr = a:lnum - a:lorig
    let key = cnr > 0 ? "\<Down>" : "\<Up>"
    let motion = "\<Home>" . repeat(key, abs(cnr)) . repeat("\<Right>", a:cnum - 1)
  endif
  return action . motion
endfunction

" Move to right of previous delim  ( [ [ ( "  "  asd) sdf    ]  sdd   ]  as) h adfas)
" Warning: Calls to e.g. cursor() fail to move cursor in insert mode, even though
" 'current position' (i.e. getpos('.') after e.g. cursor()) changes inside function
function! succinct#prev_delim() abort
  let [_, lorig, corig, _] = getpos('.')
  call s:find_delim('eb')
  if col('.') > corig - 2
    call s:find_delim('eb')
  endif
  let keys = s:move_delim(line('.'), col('.') + 1, lorig, corig)
  return keys
endfunction

" Move to right of next delim. Why starting from current position? Even if cursor is on
" delimiter, want to find it and move to the right of it
" Warning: Cannot use search() because it fails to detect current column. Could
" use setpos() but then if fail to find delim that moves cursor which is weird.
function! succinct#next_delim() abort
  let [_, lorig, corig, _] = getpos('.')
  let [lfind, cfind] = [lorig, corig]
  if cfind == 1
    let lfind = max([1, lfind - 1]) | exe lfind
    let cfind = col('$')
  endif
  call cursor(lfind, cfind - 1)
  call s:find_delim('e')
  let keys = s:move_delim(line('.'), col('.') + 1, lorig, corig)
  return keys
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
  let text = succinct#process_value(string, a:search)
  let head = text[0] =~# '[''"]' ? '\(\<[frub]\+\)\?' : ''
  let head = &filetype ==# 'python' ? head : ''
  let head = ''
  return split(head . text, "\r")
endfunction

" Driver function that accepts left and right delims, and runs normal mode commands
" from the leftmost character of left and right delims. This function sets the mark
" 'z to the end of each delim, so expression can be d`zx
" Note: Mark motion commands only work up until and excluding the mark, so
" make sure your command accounts for that!
function! s:pair_action(left, right, lexpr, rexpr, count) abort
  " Get positions for *start* of matches
  for _ in range(a:count)
    " Find positions
    if a:left ==# a:right || a:left =~# '\\\@<!['  " python string headers
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
    call cursor(l2, c21)
    let [l2, c22] = searchpos(a:right, 'cen')
    call setpos("'z", [0, l2, c22, 0])
    set paste
    exe 'normal! ' . a:rexpr
    set nopaste
    if empty(trim(getline(l2))) | exe l2 . 'd' | endif
    " Delete or change left delim
    call cursor(l1, c11)
    let [l1, c12] = searchpos(a:left, 'cen')
    call setpos("'z", [0, l1, c12, 0])
    set paste
    exe 'normal! ' . a:lexpr
    set nopaste
    if empty(trim(getline(l1))) | exe l1 . 'd' | endif
  endfor
endfunction

" Change surrounding delimiters
function! succinct#change_delims() abort
  let [prev1, prev2] = s:get_delims(1)  " disallow user input
  let [repl1, repl2] = s:get_delims(0)  " request user input
  let expr1 = '"_c`z' . repl1 . "\<Delete>"
  let expr2 = '"_c`z' . repl2 . "\<Delete>"
  call s:pair_action(prev1, prev2, expr1, expr2, v:count1)
  if exists('*repeat#set')
    call repeat#set("\<Plug>ChangeDelims")
  endif
endfunction

" Delete surrounding delimiters
function! succinct#delete_delims() abort
  let [delim1, delim2] = s:get_delims(1)  " disallow user input
  let expr1 = '"_d`z"_x'
  let expr2 = '"_d`z"_x'
  call s:pair_action(delim1, delim2, expr1, expr2, v:count1)
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
