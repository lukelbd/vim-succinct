"-----------------------------------------------------------------------------"
" Snippet and delimiter registering
"-----------------------------------------------------------------------------"
" Escape command separator character for strings interpreted as mapping declarations
function! s:map_escape(string) abort
  return escape(a:string, '|')
endfunction

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
  if exists('*textobj#user#plugin')
    let name = a:0 && a:1 ? &filetype : 'global'  " assign name, avoiding conflicts
    call textobj#user#plugin(name . 'shortcuts', dest)
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
" Note: Adapted from vim-surround source code
function! shortcuts#process_value(value, ...) abort
  " Get delimiter string with filled replacement placeholders \1, \2, \3, ...
  " Note: We override the user input spot with a dummy search pattern when *searching*
  let search = a:0 && a:1 ? 1 : 0  " whether we are finding this delimiter or inserting it
  let input = type(a:value) == 2 ? a:value() : a:value  " permit funcref input
  for insert in range(7)
    let m = matchstr(input, nr2char(insert) . '.\{-\}\ze' . nr2char(insert))
    if !empty(m)  " get user input if pair was found
      if search
        " Search chars for latex names, tag names, python methods and funcs
        " Note: First part required or searchpairpos() selects shortest match (e.g. only part of function call)
        let repl_{insert} = '\%(\k\|\.\)\@<!\%(\k\|\.\)\+'
      else
        " Insert user-input chars
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
    if char2nr(char) > 7
      " Add character, escaping magic characters
      " Note: char2nr("\1") is 1, char2nr("\2") is 2, etc.
      let part = search ? s:regex_escape(char) : char
    else
      " Handle insertions between subsequent \1...\1, \2...\2, etc. occurrences and any
      " <prompt>\r<match>\r<replace>\r<match>\r<replace>... groups within insertions
      let next = stridx(input, char, idx + 1)
      if next == -1
        let part = char  " use the literal \1, \2, etc.
      else
        let part = repl_{char2nr(char)}
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
