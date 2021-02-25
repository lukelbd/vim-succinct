"-----------------------------------------------------------------------------"
" Running latexmk in background
"-----------------------------------------------------------------------------"
let s:vim8 = has('patch-8.0.0039') && exists('*job_start')  " copied from autoreload/plug.vim
let s:path = expand('<sfile>:p:h')
function! textools#latex_background(...) abort
  if !s:vim8
    echohl ErrorMsg
    echom 'Error: Latex compilation requires vim >= 8.0'
    echohl None
    return 1
  endif

  " Jump to logfile if it is open, else open one
  " Warning: Trailing space will be escaped as a flag! So trim it unless
  " we have any options
  let opts = trim(a:0 ? a:1 : '') . ' -l=' . string(line('.'))
  let texfile = expand('%')
  let logfile = expand('%:t:r') . '.latexmk'
  let lognum = bufwinnr(logfile)
  if lognum == -1
    silent! exe string(winheight('.') / 4) . 'split ' . logfile
    silent! exe winnr('#') . 'wincmd w'
  else
    silent! exe bufwinnr(logfile) . 'wincmd w'
    silent! 1,$d
    silent! exe winnr('#') . 'wincmd w'
  endif

  " Run job in realtime
  " echom s:path . '/../latexmk'
  let num = bufnr(logfile)
  let g:tex_job = job_start(
    \ s:path . '/../bin/latexmk ' . texfile . ' ' . opts,
    \ { 'out_io': 'buffer', 'out_buf': num }
    \ )
endfunction

"-----------------------------------------------------------------------------"
" Displaying surround and snippet mappings
"-----------------------------------------------------------------------------"
" Return the bindings table given the input variables
function! s:get_bindings_table(type) abort
  let prefix = 'b:' . a:type . '_'  " either b:surround_ or b:snippet_
  let table = {}
  let vars = getcompletion(prefix, 'var')
  for var in vars
    let key = nr2char(substitute(var, '^' . prefix, '', ''))
    let s:val = eval(var)  " cannot assign funcref to local variable!
    if type(s:val) == 2
      let s:val = join(filter(copy(get(s:val, 'args')), 'type(v:val) == 1'), '')
    elseif type(s:val) != 1
      let s:val = string(s:val)
    endif
    let table[key] = substitute(s:val, "[\n\r\1]", '', 'g')
  endfor
  return table
endfunction

" Return a nice displayable list of bindings
function! s:fmt_bindings_table(table) abort
  let space = max(map(keys(a:table), 'len(v:val)'))
  let bindings = []
  for [key, val] in items(a:table)
    let quote = val =~# "'" ? '"' : "'"
    let keystring = key . ':' . repeat(' ', space - len(key) + 1)
    let valstring = quote . val . quote
    call add(bindings, keystring . valstring)
  endfor
  return join(bindings, "\n")
endfunction

" Show the entire table (type must be 'surround' or 'snippet')
function! textools#print_bindings(type) abort
  return a:type . " bindings:\n" . s:fmt_bindings_table(s:get_bindings_table(a:type))
endfunction

" Find the matching entry/entries
function! textools#search_bindings(type, regex) abort
  let table_filtered = {}
  let table = s:get_bindings_table(a:type)
  for [key, value] in items(table)
    if type(value) == 1
      let val = value
    else
      let val = value[0]
    endif
    if val =~# a:regex
      let table_filtered[key] = val
    endif
  endfor
  if len(table_filtered) == 0
    echohl WarningMsg
    echom "Error: No mappings found for regex '" . a:regex . "'"
    echohl None
    return
  endif
  let header = a:type . " bindings matching regex '" . a:regex . "':\n"
  let body = s:fmt_bindings_table(table_filtered)
  return (len(table_filtered) == 1 ? body : header . body)
endfunction

"-----------------------------------------------------------------------------"
" Functions for selecting from tex labels (integration with idetools)
"-----------------------------------------------------------------------------"
" Return graphics paths
function! s:label_source() abort
  if !exists('b:ctags_alph')
    return []
  endif
  let ctags = filter(copy(b:ctags_alph), 'v:val[2] ==# "l"')
  let ctags = map(ctags, 'v:val[0] . " (" . v:val[1] . ")"')  " label (line number)
  if empty(ctags)
    echoerr 'No ctag labels found.'
  endif
  return ctags
endfunction

" Return label text
function! s:label_select() abort
  let items = fzf#run({
    \ 'source': s:label_source(),
    \ 'options': '--prompt="Label> "',
    \ 'down': '~50%',
    \ })
  let items = map(items, 'substitute(v:val, " (.*)$", "", "")')
  return join(items, ',')
endfunction

"-----------------------------------------------------------------------------"
" Functions for selecting citations from bibtex files
" See: https://github.com/msprev/fzf-bibtex
"-----------------------------------------------------------------------------"
" The gsed executable
let s:gsed = '/usr/local/bin/gsed'  " Todo: defer to 'gsed' alias?
if !executable(s:gsed)
  echoerr 'GNU sed not available. Please install it with brew install gnu-sed.'
  finish
endif

" Basic function called every time
function! s:cite_source() abort
  " Set the plugin source variables
  " Get biligraphies using grep, copied from latexmk
  " Easier than using search() because we want to get *all* results
  let biblist = []
  let bibfiles = system(
    \ 'grep -o ''^[^%]*'' ' . shellescape(@%) . ' | '
    \ . s:gsed . ' -n ''s@^\s*\\\(bibliography\|nobibliography\|addbibresource\){\(.*\)}@\2@p'''
    \ )

  " Check that files all exist
  if v:shell_error == 0
    let filedir = expand('%:h')
    for bibfile in split(bibfiles, "\n")
      if bibfile !~? '.bib$'
        let bibfile .= '.bib'
      endif
      let bibpath = filedir . '/' . bibfile
      if filereadable(bibpath)
        call add(biblist, bibpath)
      else
        echohl WarningMsg
        echom "Warning: Bib file '" . bibpath . "' does not exist.'"
        echohl None
      endif
    endfor
  endif

  " Set the environment variable and return command-line command used to
  " generate fuzzy list from the selected files.
  let result = []
  if len(biblist) == 0
    echoerr 'Bib files were not defined or do not exist.'
  elseif ! executable('bibtex-ls')
    echoerr 'Command bibtex-ls not found.'
  else
    let $FZF_BIBTEX_SOURCES = join(biblist, ':')
    let result = 'bibtex-ls ' . join(biblist, ' ')
  endif
  return result
endfunction

" Return citation text
" We can them use this function as an insert mode <expr> mapping
" Note: To get multiple items just hit <Tab>
function! s:cite_select() abort
  let items = fzf#run({
    \ 'source': s:cite_source(),
    \ 'options': '--prompt="Source> "',
    \ 'down': '~50%',
    \ })
  let result = ''
  if executable('bibtex-cite')
    let result = system('bibtex-cite ', items)
    let result = substitute(result, '@', '', 'g')
  endif
  return result
endfunction

"-----------------------------------------------------------------------------"
" Functions for selecting from available graphics files
"-----------------------------------------------------------------------------"
" Related function that prints graphics files
function! s:graphic_source() abort
  " Get graphics paths
  " Note: Negative indexing evidently does not work with strings
  " Todo: Make this work when \graphicspath takes up more than one line
  " Not high priority because latexmk rarely accounts for this anyway
  let paths = system(
    \ 'grep -o ''^[^%]*'' ' . shellescape(@%) . ' | '
    \ . s:gsed . ' -n ''s@\\graphicspath{\(.*\)}@\1@p'''
    \ )
  let paths = substitute(paths, "\n", '', 'g')  " in case multiple \graphicspath calls, even though this is illegal
  if !empty(paths) && (paths[0] !=# '{' || paths[len(paths) - 1] !=# '}')
    echohl WarningMsg
    echom "Incorrect syntax '" . paths . "'. Surround paths with curly braces."
    echohl None
    let paths = '{' . paths . '}'
  endif

  " Check syntax
  " Make paths relative to *latex file* not cwd
  let filedir = expand('%:h')
  let pathlist = []
  for path in split(paths[1:len(paths) - 2], '}{')
    let abspath = expand(filedir . '/' . path)
    if isdirectory(abspath)
      call add(pathlist, abspath)
    else
      echohl WarningMsg
      echom "Warning: Directory '" . abspath . "' does not exist."
      echohl None
    endif
  endfor

  " Get graphics files in each path
  let figlist = []
  call add(pathlist, expand('%:h'))
  for path in pathlist
    for ext in ['png', 'jpg', 'jpeg', 'pdf', 'eps']
      call extend(figlist, globpath(path, '*.' . ext, v:true, v:true))
    endfor
  endfor
  let figlist = map(figlist, 'fnamemodify(v:val, ":p:h:t") . "/" . fnamemodify(v:val, ":t")')

  " Return figure files
  if len(figlist) == 0
    echoerr 'No graphics files found.'
  endif
  return figlist
endfunction

" Return graphics text
" We can them use this function as an insert mode <expr> mapping
function! s:graphic_select() abort
  let items = fzf#run({
    \ 'source': s:graphic_source(),
    \ 'options': '--prompt="Figure> "',
    \ 'down': '~50%',
    \ })
  let items = map(items, 'fnamemodify(v:val, ":t")')
  return join(items, ',')
endfunction

"-----------------------------------------------------------------------------"
" Functions for checking math mode and making units
"-----------------------------------------------------------------------------"
" Wrap in math environment only if cursor is not already inside one
" Use TeX syntax to detect any and every math environment
" Note: Check syntax of point to *left* of cursor because that's the environment
" where we are inserting text. Does not wrap if in first column.
function! s:ensure_math(...) abort
  let output = call('s:make_snippet', a:000)
  if empty(filter(synstack(line('.'), col('.') - 1), 'synIDattr(v:val, "name") =~? "math"'))
    let output = '$' . output . '$'
  endif
  return output
endfunction

" Format unit string for LaTeX for LaTeX for LaTeX for LaTeX
function! s:format_units(...) abort
  let input = call('s:make_snippet', a:000)
  if empty(input)
    return ''
  endif
  let input = substitute(input, '/', ' / ', 'g')  " pre-process
  let parts = split(input)
  let regex = '^\([a-zA-Z0-9.]\+\)\%(\^\|\*\*\)\?\([-+]\?[0-9.]\+\)\?$'
  let output = '\, '  " add space between number and unit
  for idx in range(len(parts))
    if parts[idx] ==# '/'
      let part = parts[idx]
    else
      let items = matchlist(parts[idx], regex)
      if empty(items)
        echohl WarningMsg | echom 'Warning: Invalid units string.' | echohl None
        return ''
      endif
      let part = '\textnormal{' . items[1] . '}'
      if !empty(items[2])
        let part .= '^{' . items[2] . '}'
      endif
    endif
    if idx != len(parts) - 1
      let part = part . ' \, '
    endif
    let output .= part
  endfor
  return s:ensure_math(output)
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

" Return the string or evaluate a funcref, then optionally add a prefix and suffix
function! s:make_snippet(input, ...) abort
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

" Functions that return funcrefs for assignment in snippet dictionary
function! s:user_input(prompt) abort  " general user input request with no-op tab expansion
  return input(a:prompt . ': ', '', 'customlist,NullList')
endfunction
function! textools#user_input(...)
  return function('s:user_input', a:000)
endfunction
function! textools#make_snippet(...)
  return function('s:make_snippet', a:000)
endfunction
function! textools#ensure_math(...) abort
  return function('s:ensure_math', a:000)
endfunction
function! textools#format_units(...) abort
  return function('s:format_units', a:000)
endfunction
function! textools#label_select(...) abort
  return function('s:label_select', a:000)
endfunction
function! textools#cite_select(...) abort
  return function('s:cite_select', a:000)
endfunction
function! textools#graphic_select(...) abort
  return function('s:graphic_select', a:000)
endfunction

" Add user-defined snippet, either a fixed string or input string with defined
" prefix and suffix. If user *cancels* input or writes nothing, insert nothing.
" Todo: Support literal functions in surround definitions too
function! textools#insert_snippet()
  let pad = ''
  let char = s:get_char()
  if char ==# ' '  " similar to surround, permit <C-d><Space><Key> to surround with space
    let pad = char
    let char = s:get_char()
  endif
  let snippet = ''
  for scope in [g:, b:]
    if !empty(char) && empty(snippet)
      let varname = 'snippet_' . char2nr(char)
      let snippet = s:make_snippet(get(scope, varname, ''))
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
" even when they accept variable input. Can return delimiters themselves or
" regex suitable for *searching* for delimiters with searchpair().
" Todo: Use builtin function if it gets moved to autoload
function! s:process(string, regex) abort
  " Get delimiter string with filled replacement placeholders \1, \2, \3, ...
  " Note that char2nr("\1") is 1, char2nr("\2") is 2, etc.
  " Note: We permit overriding the dumjy spot with a dummy search pattern. This
  " is used when we want to use the delimiters returned by this function to
  " *search* for matches rather than *insert* them... and if a delimiter accepts
  " arbitrary input then we need to search for arbitrary text in that spot.
  let fill = '\%(\k\|\.\)'  " valid character
  for i in range(7)
    if a:regex
      " Todo: For now try to match superset of all possible items that
      " can be contained inside patterns with variable input. Includes latex
      " environment names, tag names, and python methods and functions.
      " let repl_{i} = '\S\{-1,}'
      " let repl_{i} = '\k\+'
      let repl_{i} = fill . '\+'  " any valid fill character
    else
      let repl_{i} = ''
      let m = matchstr(a:string, nr2char(i) . '.\{-\}\ze' . nr2char(i))
      if m !=# ''
        let m = substitute(strpart(m, 1), '\r.*', '', '')
        let repl_{i} = input(match(m, '\w\+$') >= 0 ? m . ': ' : m)
      endif
    endif
  endfor

  " Build up string
  let i = 0
  let string = ''
  while i < strlen(a:string)
    let char = strpart(a:string, i, 1)
    if a:regex && char =~# '[.\\\[\]]'
      " Escape character
      let string .= '\' . char
    elseif a:regex && char ==# "\n"
      " Ignore newlines e.g. from \begin{}...\end{} environments
      let string .= ''
    elseif char2nr(char) >= 8
      " Nothing needs to be done
      let string .= char
    else
      " Handle insertions between subsequent \1...\1, \2...\2, etc. occurrences
      let next = stridx(a:string, char, i + 1)
      if next == -1
        let string .= char  " if we just found one \1, etc. instance, put back
      else
        let insertion = repl_{char2nr(char)}
        let substring = strpart(a:string, i + 1, next - i - 1)
        let substring = matchstr(substring, '\r.*')
        while substring =~# '^\r.*\r'
          let matchstring = matchstr(substring, "^\r\\zs[^\r]*\r[^\r]*")
          let substring = strpart(substring, strlen(matchstring) + 1)
          let r = stridx(matchstring, "\r")
          let insertion = substitute(insertion, strpart(matchstring, 0, r), strpart(matchstring, r + 1), '')
        endwhile
        if a:regex && i == 0  " add start-of-word marker
          " asdfa.heloo.asdfasd( asdfasa )
          let insertion = fill . '\@<!' . insertion
        endif
        let i = next
        let string .= insertion
      endif
    endif
    let i += 1
  endwhile
  return string
endfunction

" Driver function that accepts left and right delims, and normal mode commands
" run from the leftmost character of left and right delims. This function sets
" the mark 'z to the end of each delim, so expression can be d`zx
" Note: Mark motion commands only work up until and excluding the mark, so
" make sure your command accounts for that!
function! s:pair_action(left, right, lexpr, rexpr) abort
  if !exists('*searchpairpos') " older versions
    return
  endif

  " Get positions for *start* of matches
  let left = '\V' . a:left  " nomagic
  let right = '\V' . a:right
  let [l1, c11] = searchpairpos(left, '', right, 'bnW') " set '' mark at current location
  let [l2, c21] = searchpairpos(left, '', right, 'nW')
  if l1 == 0 || l2 == 0
    echohl WarningMsg
    echom 'Warning: Cursor is not inside ' . a:left . a:right . ' pair.'
    echohl None
    return
  endif

  " Delete or change right delim. If this leaves an empty line, delete it.
  " Note: Right must come first!
  call cursor(l2, c21)
  let [l2, c22] = searchpos(right, 'cen')
  call setpos("'z", [0, l2, c22, 0])
  set paste | exe 'normal! ' . a:rexpr | set nopaste
  if len(s:strip(getline(l2))) == 0 | exe l2 . 'd' | endif

  " Delete or change left delim
  call cursor(l1, c11)
  let [l1, c12] = searchpos(left, 'cen')
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
  let delims = s:process(string, a:regex)
  return map(split(delims, "\r"), 's:strip(v:val)')
endfunction

" Delete delims function
function! textools#delete_delims() abort
  let [left, right] = s:get_delims(1)  " disallow user input
  call s:pair_action(left, right, '"_d`z"_x', '"_d`z"_x')
endfunction

" Change delims function, use input replacement text
" or existing mapped surround character
function! textools#change_delims() abort
  let [left, right] = s:get_delims(1)  " disallow user input
  let [left_new, right_new] = s:get_delims(0)
  call s:pair_action(
    \ left,
    \ right,
    \ '"_c`z' . left_new . "\<Delete>",
    \ '"_c`z' . right_new . "\<Delete>",
  \ )
endfunction

"-----------------------------------------------------------------------------"
" Template functions
"-----------------------------------------------------------------------------"
" Return list of templates
function! textools#template_source(ext) abort
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
function! textools#template_read(file)
  if exists('g:textools_templates_path') && !empty(a:file)
    execute '0r ' . g:textools_templates_path . '/' . a:file
  endif
endfunction
