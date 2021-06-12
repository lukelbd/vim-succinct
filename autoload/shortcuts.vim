"-----------------------------------------------------------------------------"
" Snippet and delimiter registering
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
    let pattern = split(shortcuts#process_value(delim, 1), "\r")
    if pattern[0] ==# pattern[1]  " special handling if delims are identical, e.g. $$
      let dest['textobj_' . char2nr(key) . '_i'] = {
        \ 'pattern': pattern[0] . '\zs.\{-}\ze' . pattern[0],
        \ 'select': flag . 'i' . escape(key, '|'),
        \ }
      let dest['textobj_' . char2nr(key) . '_a'] = {
        \ 'pattern': pattern[0] . '.\{-}' . pattern[0],
        \ 'select': flag . 'a' . escape(key, '|'),
        \ }
    else
      let dest['textobj_' . char2nr(key)] = {
        \ 'pattern': pattern,
        \ 'select-a': flag . 'a' . escape(key, '|'),
        \ 'select-i': flag . 'i' . escape(key, '|'),
        \ }
    endif
  endfor
  if exists('*textobj#user#plugin')
    let name = a:0 && a:1 ? &filetype : 'global'  " assign name, avoiding conflicts
    call textobj#user#plugin(name . 'shortcuts', dest)
  endif
endfunction

"-----------------------------------------------------------------------------"
" Snippet and delimiter processing
"-----------------------------------------------------------------------------"
" Obtain and process delimiters. If a:search is true return regex suitable for
" *searching* for delimiters with searchpair(), else return delimiters themselves.
" Note: Adapted from vim-surround source code
function! shortcuts#process_value(value, ...) abort
  " Get delimiter string with filled replacement placeholders \1, \2, \3, ...
  " Note: We override the user input spot with a dummy search pattern when *searching*
  let search = a:0 && a:1 ? 1 : 0  " whether we are finding this delimiter or inserting it
  let filled = '\%(\k\|\.\)'  " valid character for latex names, tag names, python methods and funcs
  let input = type(a:value) == 2 ? a:value() : a:value  " permit funcref input
  for insert in range(7)
    let repl_{insert} = ''
    if search
      let repl_{insert} = filled . '\+'
    else
      let m = matchstr(input, nr2char(insert) . '.\{-\}\ze' . nr2char(insert))
      if m !=# ''  " get user input if pair was found
        let m = substitute(strpart(m, 1), '\r.*', '', '')
        let repl_{insert} = input(match(m, '\w\+$') >= 0 ? m . ': ' : m)
      endif
    endif
  endfor
  " Build up string
  let idx = 0
  let output = ''
  while idx < strlen(input)
    let char = strpart(input, idx, 1)
    let part = char
    if char2nr(char) > 7
      " Add character, escaping magic characters
      " Note: char2nr("\1") is 1, char2nr("\2") is 2, etc.
      if search && char ==# "\n"  " account for indentation for delimiters with built-in newlines
        let part = '\_s*'
      elseif search && char =~# '[][\.*$]'  " escape regex patterns
        let part = '\' . char
      endif
    else
      " Handle insertions between subsequent \1...\1, \2...\2, etc. occurrences and any
      " <prompt>\r<match>\r<replace>\r<match>\r<replace>... groups within insertions
      let next = stridx(input, char, idx + 1)
      if next != -1  " have more than one \1, otherwise use the literal \1
        let part = repl_{char2nr(char)}
        let query = strpart(input, idx + 1, next - idx - 1)  " the query between \1...\1
        let query = matchstr(query, '\r.*')  " a substitute initiation indication
        while query =~# '^\r.*\r'
          let replace = matchstr(query, "^\r\\zs[^\r]*\r[^\r]*")  " a match and replace group
          let r = stridx(replace, "\r")  " the delimiter between match and replace
          let part = substitute(part, strpart(replace, 0, r), strpart(replace, r + 1), '')  " apply substitution as requested
          let query = strpart(query, strlen(replace) + 1)  " skip over the group
        endwhile
        if search && idx == 0  " add start-of-word marker
          let part = filled . '\@<!' . part
        endif
        let idx = next
      endif
    endif
    let output .= part
    let idx += 1
  endwhile
  return output
endfunction
