"-----------------------------------------------------------------------------"
" Adding snippets and delimiters
"-----------------------------------------------------------------------------"
" Adding snippet variables
function! shortcuts#add_snippets(map, ...) abort
  let src = a:0 && a:1 ? b: : g:
  for [key, s:val] in items(a:map)
    let src['snippet_' . char2nr(key)] = s:val  " must be s: scope in case it is a function!
  endfor
endfunction

" Simultaneously adding delimiters and text objects
function! shortcuts#add_delims(map, ...) abort
  let src = a:0 && a:1 ? b: : g:
  for [key, s:val] in items(a:map)
    let src['surround_' . char2nr(key)] = s:val
  endfor
  let dest = {}
  let flag = a:0 && a:1 ? '<buffer> ' : ''
  for [key, delim] in items(a:map)
    let dest['textobj_' . char2nr(key)] = {
      \ 'pattern': split(shortcuts#process_delims(delim, 1), "\r"),
      \ 'select-a': flag . 'a' . escape(key, '|'),
      \ 'select-i': flag . 'i' . escape(key, '|'),
      \ }
  endfor
  if exists('*textobj#user#plugin')
    call textobj#user#plugin(a:0 && a:1 ? &filetype : 'global', dest)
  endif
endfunction

" Obtain and process delimiters. If a:search is true return regex suitable for
" *searching* for delimiters with searchpair(), else return delimiters themselves.
" Note: Adapted from vim-surround source code
function! shortcuts#process_delims(string, search) abort
  " Get delimiter string with filled replacement placeholders \1, \2, \3, ...
  " Note: We override the user input spot with a dummy search pattern when *searching*
  let filled = '\%(\k\|\.\)'  " valid character for latex names, tag names, python methods and funcs
  for insert in range(7)
    let repl_{insert} = ''
    if a:search
      let repl_{insert} = filled . '\+'
    else
      let m = matchstr(a:string, nr2char(insert) . '.\{-\}\ze' . nr2char(insert))
      if m !=# ''  " get user input if pair was found
        let m = substitute(strpart(m, 1), '\r.*', '', '')
        let repl_{insert} = input(match(m, '\w\+$') >= 0 ? m . ': ' : m)
      endif
    endif
  endfor
  " Build up string
  let idx = 0
  let string = ''
  while idx < strlen(a:string)
    let char = strpart(a:string, idx, 1)
    if char2nr(char) > 7
      " Add character, escaping magic characters
      " Note: char2nr("\1") is 1, char2nr("\2") is 2, etc.
      let char = a:search && char ==# "\n" ? '' : a:search && char =~# '[][\.*]' ? '\' . char : char  " see :help \]
    else
      " Handle insertions between subsequent \1...\1, \2...\2, etc. occurrences
      " Optionally insert user input
      let next = stridx(a:string, char, idx + 1)
      if next != -1  " found more than one \1 instance
        let char = repl_{char2nr(char)}
        let substring = strpart(a:string, idx + 1, next - idx - 1)
        let substring = matchstr(substring, '\r.*')
        while substring =~# '^\r.*\r'
          let matchstring = matchstr(substring, "^\r\\zs[^\r]*\r[^\r]*")
          let substring = strpart(substring, strlen(matchstring) + 1)
          let r = stridx(matchstring, "\r")
          let char = substitute(char, strpart(matchstring, 0, r), strpart(matchstring, r + 1), '')
        endwhile
        if a:search && idx == 0  " add start-of-word marker
          let char = filled . '\@<!' . char
        endif
        let idx = next
      endif
    endif
    let string .= char
    let idx += 1
  endwhile
  return string
endfunction

"-----------------------------------------------------------------------------"
" Inserting complex snippets
"-----------------------------------------------------------------------------"
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

" General user input request with no-op tab expansion
function! shortcuts#user_input_driver(prompt) abort
  return input(a:prompt . ': ', '', 'customlist,shortcuts#null_list')
endfunction
function! shortcuts#user_input(...)
  return function('shortcuts#user_input_driver', a:000)
endfunction
function! shortcuts#null_list(...) abort
  return []
endfunction

" Return the string or evaluate a funcref, then optionally add a prefix and suffix
function! shortcuts#make_snippet_driver(input, ...) abort
  let prefix = a:0 > 0 ? a:1 : ''
  let suffix = a:0 > 1 ? a:2 : ''
  if type(a:input) == 2  " funcref
    let output = a:input()
  else
    let output = a:input
  endif
  if !empty(output)
    let output = prefix . output . suffix
  endif
  return output
endfunction
function! shortcuts#make_snippet(...)
  return function('shortcuts#make_snippet_driver', a:000)
endfunction

" Add user-defined snippet, either a fixed string or user input with prefix/suffix
function! shortcuts#insert_snippet()
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
      let snippet = shortcuts#make_snippet_driver(get(scope, varname, ''))
    endif
  endfor
  return pad . snippet . pad
endfunction
