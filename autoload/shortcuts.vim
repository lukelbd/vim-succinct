"-----------------------------------------------------------------------------"
" Handling file templates
"-----------------------------------------------------------------------------"
" Return list of templates
function! shortcuts#template_source(ext) abort
  let paths = []
  if exists('g:textools_templates_path')
    let paths = split(globpath(g:textools_templates_path, '*.' . a:ext), "\n")
    let paths = map(paths, 'fnamemodify(v:val, ":t")')
  endif
  if !empty(paths)
    let paths = [''] + paths  " add stand-in for 'load nothing'
  endif
  return paths
endfunction

" Load template contents
function! shortcuts#template_read(file)
  if exists('g:textools_templates_path') && !empty(a:file)
    execute '0r ' . g:textools_templates_path . '/' . a:file
  endif
endfunction

"-----------------------------------------------------------------------------"
" Simultaneously adding delimiters and text objects
"-----------------------------------------------------------------------------"
" Todo: Write these!
function! shortcuts#define_objects()
endfunction

"-----------------------------------------------------------------------------"
" Selecting snippets and delimiters with FZF
"-----------------------------------------------------------------------------"
" Todo: Write these!
function! shortcuts#select_object()
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
  return input(a:prompt . ': ', '', 'customlist,NullList')
endfunction
function! shortcuts#user_input(...)
  return function('shortcuts#user_input_driver', a:000)
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

"-----------------------------------------------------------------------------"
" Changing and deleting surrounding delim
"-----------------------------------------------------------------------------"
" Strip leading and trailing spaces
function! s:strip(text) abort
  return substitute(a:text, '^\_s*\(.\{-}\)\_s*$', '\1', '')
endfunction

" Copied from vim-surround source code, use this to obtain string
" delimiters from the b:surround_{num} and g:surround_{num} variables
" even when they accept variable input.
" If a:regex is true return regex suitable for *searching* for delimiters with
" searchpair(), else return delimiters themselves.
" Todo: Use builtin function if it gets moved to autoload
function! s:process_delims(string, regex) abort
  " Get delimiter string with filled replacement placeholders \1, \2, \3, ...
  " Note that char2nr("\1") is 1, char2nr("\2") is 2, etc.
  " Note: We permit overriding the dummy spot with a dummy search pattern. This
  " is used when we want to use the delimiters returned by this function to
  " *search* for matches rather than *insert* them... and if a delimiter accepts
  " arbitrary input then we need to search for arbitrary text in that spot.
  let filled = '\%(\k\|\.\)'  " valid character
  for insert in range(7)
    " Todo: For now try to match superset of all possible items that
    " can be contained inside patterns with variable input. Includes latex
    " environment names, tag names, and python methods and functions.
    let repl_{insert} = ''
    if a:regex
      let repl_{insert} = filled . '\+'  " any valid fill character
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
    if char2nr(char) >= 8
      " Add character, escaping magic characters
      let char = a:regex && char ==# "\n" ? '' : a:regex && char =~# '[][\.*]' ? '\' . char : char  " see :help \]
    else
      " Handle insertions between subsequent \1...\1, \2...\2, etc. occurrences
      " Note: char2nr("\1") is 1, char2nr("\2") is 2, etc.
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
        if a:regex && idx == 0  " add start-of-word marker
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

" Driver function that accepts left and right delims, and normal mode commands
" run from the leftmost character of left and right delims. This function sets
" the mark 'z to the end of each delim, so expression can be d`zx
" Note: Mark motion commands only work up until and excluding the mark, so
" make sure your command accounts for that!
function! s:pair_action(left, right, lexpr, rexpr) abort
  if !exists('*searchpairpos')  " older versions
    return
  endif

  " Get positions for *start* of matches
  " let left = '\V' . a:left  " nomagic
  " let right = '\V' . a:right
  let [l1, c11] = searchpairpos(a:left, '', a:right, 'bnW')  " set '' mark at current location
  let [l2, c21] = searchpairpos(a:left, '', a:right, 'nW')
  if l1 == 0 || l2 == 0
    echohl WarningMsg
    echom 'Warning: Cursor is not inside ' . a:left . a:right . ' pair.'
    echohl None
    return
  endif

  " Delete or change right delim. If this leaves an empty line, delete it.
  " Note: Right must come first!
  call cursor(l2, c21)
  let [l2, c22] = searchpos(a:right, 'cen')
  " echom a:right . ': ' . c21 . '-' . c22
  call setpos("'z", [0, l2, c22, 0])
  set paste | exe 'normal! ' . a:rexpr | set nopaste
  if len(s:strip(getline(l2))) == 0 | exe l2 . 'd' | endif

  " Delete or change left delim
  call cursor(l1, c11)
  let [l1, c12] = searchpos(a:left, 'cen')
  " echom a:left . ': ' . c11 . '-' . c12
  call setpos("'z", [0, l1, c12, 0])
  set paste | exe 'normal! ' . a:lexpr | set nopaste
  if len(s:strip(getline(l1))) == 0 | exe l1 . 'd' | endif
endfunction

" Get left and right 'surround' delimiter from input key
function! s:get_delims(regex) abort
  let cnum = getchar()
  if exists('b:surround_' . cnum)
    let string = b:surround_{cnum}
  elseif exists('g:surround_' . cnum)
    let string = g:surround_{cnum}
  else
    let string = nr2char(cnum) . "\r" . nr2char(cnum)
  endif
  let delims = s:process_delims(string, a:regex)
  return map(split(delims, "\r"), 's:strip(v:val)')
endfunction

" Delete delims function
function! shortcuts#delete_delims() abort
  let [left, right] = s:get_delims(1)  " disallow user input
  call s:pair_action(left, right, '"_d`z"_x', '"_d`z"_x')
endfunction

" Change delims function, use input replacement text
" or existing mapped surround character
function! shortcuts#change_delims() abort
  let [left, right] = s:get_delims(1)  " disallow user input
  let [left_new, right_new] = s:get_delims(0)  " replacement delims possibly with user input
  call s:pair_action(
    \ left,
    \ right,
    \ '"_c`z' . left_new . "\<Delete>",
    \ '"_c`z' . right_new . "\<Delete>",
  \ )
endfunction

"-----------------------------------------------------------------------------"
" Complex text objects
"-----------------------------------------------------------------------------"
" Helper function
function! s:lines_helper(pnb, nnb) abort
  let start_line = (a:pnb == 0) ? 1         : a:pnb + 1
  let end_line   = (a:nnb == 0) ? line('$') : a:nnb - 1
  let start_pos = getpos('.') | let start_pos[1] = start_line
  let end_pos   = getpos('.') | let end_pos[1]   = end_line
  return ['V', start_pos, end_pos]
endfunction

" Blank line objects
function! shortcuts#blank_lines() abort
  normal! 0
  let pnb = prevnonblank(line('.'))
  let nnb = nextnonblank(line('.'))
  if pnb == line('.') " also will be true for nextnonblank, if on nonblank
    return 0
  endif
  return s:lines_helper(pnb, nnb)
endfunction

" New and improved paragraphs
function! shortcuts#nonblank_lines() abort
  normal! 0l
  let nnb = search('^\s*\zs$', 'Wnc') " the c means accept current position
  let pnb = search('^\ze\s*$', 'Wnbc') " won't work for backwards search unless to right of first column
  if pnb == line('.')
    return 0
  endif
  return s:lines_helper(pnb, nnb)
endfunction

" Uncommented lines objects
function! shortcuts#uncommented_lines() abort
  normal! 0l
  let nnb = search('^\s*' . Comment() . '.*\zs$', 'Wnc')
  let pnb = search('^\ze\s*' . Comment() . '.*$', 'Wncb')
  if pnb == line('.')
    return 0
  endif
  return s:lines_helper(pnb, nnb)
endfunction

" Functions for current line
function! shortcuts#current_line_a() abort
  normal! 0
  let head_pos = getpos('.')
  normal! $
  let tail_pos = getpos('.')
  return ['v', head_pos, tail_pos]
endfunction
function! shortcuts#current_line_i() abort
  normal! ^
  let head_pos = getpos('.')
  normal! g_
  let tail_pos = getpos('.')
  let non_blank_char_exists_p = (getline('.')[head_pos[2] - 1] !~# '\s')
  return (non_blank_char_exists_p ? ['v', head_pos, tail_pos] : 0)
endfunction

" Related function for searching blocks
function! shortcuts#search_block(regex, forward) abort
  let range = '\%' . (a:forward ? '>' : '<')  . line('.') . 'l'
  if match(a:regex, '\\ze') != -1
    let regex = substitute(a:regex, '\\ze', '\\ze\' . range, '')
  else
    let regex = a:regex . range
  endif
  let lnum = search(regex, 'n' . repeat('b', 1 - a:forward))  " get line number
  if lnum == 0
    return ''
  else
    return lnum . 'G'
  endif
endfunction

" Function that returns regexes used in navigation. This helps us define navigation maps
" for 'the first line in a contiguous block of matching lines'.
function! shortcuts#regex_comment() abort
  return '\s*' . Comment()
endfunction
function! shortcuts#regex_current_indent() abort
  return '[ ]\{0,'
    \ . len(substitute(getline('.'), '^\(\s*\).*$', '\1', ''))
    \ . '}\S\+'
endfunction
function! shortcuts#regex_parent_indent() abort
  return '[ ]\{0,'
    \ . max([0, len(substitute(getline('.'), '^\(\s*\).*$', '\1', '')) - &l:tabstop])
    \ . '}\S\+'
endfunction

