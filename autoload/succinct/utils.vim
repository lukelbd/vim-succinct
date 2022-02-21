"-----------------------------------------------------------------------------"
" File template handling
"-----------------------------------------------------------------------------"
" Return list of templates
function! succinct#utils#template_source(ext) abort
  let paths = []
  if exists('g:succinct_templates_path')
    let paths = split(globpath(g:succinct_templates_path, '*.' . a:ext), "\n")
    let paths = filter(paths, '!isdirectory(v:val)')
    let paths = map(paths, 'fnamemodify(v:val, ":t")')
  endif
  if !empty(paths)
    let paths = [''] + paths  " add stand-in for 'load nothing'
  endif
  return paths
endfunction

" Load template contents
function! succinct#utils#template_read(file)
  if exists('g:succinct_templates_path') && !empty(a:file)
    execute '0r ' . g:succinct_templates_path . '/' . a:file
  endif
endfunction

"-----------------------------------------------------------------------------"
" Snippet handling
"-----------------------------------------------------------------------------"
" Process snippet value
function! s:process_snippet(input) abort
  let output = type(a:input) == 2 ? a:input() : a:input  " run funcref function
  return succinct#utils#user_input(output)  " handle \1...\1, \2...\2 pairs
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
function! succinct#utils#insert_snippet() abort
  let pad = ''
  let char = s:get_char()
  if char =~# '\s'  " similar to surround, permit <C-d><Space><Key> to surround with space
    let pad = char
    let char = s:get_char()
  endif
  let snippet = ''
  for scope in [g:, b:]
    if !empty(char) && empty(snippet)  " skip if user cancelled (i.e. empty char)
      let varname = 'snippet_' . char2nr(char)
      let snippet = succinct#process_value(get(scope, varname, ''))
    endif
  endfor
  return pad . snippet . pad
endfunction

"-----------------------------------------------------------------------------"
" Selecting snippets and delimiters with FZF
"-----------------------------------------------------------------------------"
" Pick from source delimiters or snippets
function! succinct#utils#pick_source(string) abort
  let map = {}
  for prefix in ['g:', 'b:']
    let vars = getcompletion(prefix . a:string . '_', 'var')
    for name in vars
      let key = nr2char(substitute(name, prefix . a:string . '_', '', ''))
      let map[key] = eval(name)  " local vars will overwrite global vars
    endfor
  endfor
  let opts = []
  for [key, s:val] in items(map)  " could be funcrefs here
    call add(opts, key . ': ' . string(s:val))
  endfor
  return opts
endfunction

" Apply delimiter or snippet
function! succinct#utils#pick_snippet_sink(item)
  call feedkeys("\<Plug>Isnippet" . split(a:item, ':')[0])
endfunction
function! succinct#utils#pick_surround_sink(item)
  call feedkeys("\<Plug>Isurround" . split(a:item, ':')[0])
endfunction

"-----------------------------------------------------------------------------"
" Delimiter navigation
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
function! succinct#utils#prev_delim() abort
  let [_, lorig, corig, _] = getpos('.')
  call search(s:delim_regex(), 'eb')
  if col('.') > corig - 2 | call search(s:delim_regex(), 'eb') | endif
  return s:move_cursor(line('.'), col('.') + 1, lorig, corig)
endfunction

" Move to right of next delim. Why starting from current position? Even if cursor is on
" delimiter, want to find it and move to the right of it
" Warning: Cannot use search() because it fails to detect current column. Could
" use setpos() but then if fail to find delim that moves cursor which is weird.
function! succinct#utils#next_delim() abort
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
function! succinct#utils#pum_close() abort
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
" Changing and deleting surrounding delim
"-----------------------------------------------------------------------------"
" Driver function that accepts left and right delims, and normal mode commands
" run from the leftmost character of left and right delims. This function sets
" the mark 'z to the end of each delim, so expression can be d`zx
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

" Get left and right 'surround' delimiter from input key
function! s:get_delims(search) abort
  " Handle repeated actions
  if a:search
    let cnum = exists('b:succinct_searchdelim') ? b:succinct_searchdelim : getchar()
    let b:succinct_searchdelim = cnum
  else
    let cnum = exists('b:succinct_replacedelim') ? b:succinct_replacedelim : getchar()
    let b:succinct_replacedelim = cnum
  endif
  " Get delimiters
  if exists('b:surround_' . cnum)
    let string = b:surround_{cnum}
  elseif exists('g:surround_' . cnum)
    let string = g:surround_{cnum}
  else
    let string = nr2char(cnum) . "\r" . nr2char(cnum)
  endif
  let delims = succinct#process_value(string, a:search)
  return split(delims, "\r")
endfunction

" Delete delims function
" Todo: Fix this for identical left/right delimiters!!!
function! succinct#utils#delete_delims() abort
  let [left, right] = s:get_delims(1)  " disallow user input
  call s:pair_action(left, right, '"_d`z"_x', '"_d`z"_x', v:count1)
  if exists('*repeat#set')
    call repeat#set("\<Plug>succinctDeleteDelims")
  endif
endfunction

" Change delims function, use input replacement text or existing mapped surround char
" Todo: Fix this for identical left/right delimiters!!!
function! succinct#utils#change_delims() abort
  let [lold, rold] = s:get_delims(1)  " disallow user input
  let [lnew, rnew] = s:get_delims(0)  " replacement delims possibly with user input
  call s:pair_action(lold, rold, '"_c`z' . lnew . "\<Delete>", '"_c`z' . rnew . "\<Delete>", v:count1)
  if exists('*repeat#set')
    call repeat#set("\<Plug>succinctChangeDelims")
  endif
endfunction

" Reset previous delimiter
function! succinct#utils#reset_delims() abort
  silent! unlet b:succinct_searchdelim b:succinct_replacedelim
  return ''
endfunction
