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
  let opts = trim(a:0 ? a:1 : '') " flags
  if opts !=# ''
    let opts = ' ' . opts
  endif
  let texfile = expand('%')
  let logfile = 'latexmk.log'
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
    \ s:path . '/../latexmk ' . texfile . opts,
    \ { 'out_io': 'buffer', 'out_buf': num }
    \ )
endfunction

"-----------------------------------------------------------------------------"
" Displaying surround and snippet mappings
"-----------------------------------------------------------------------------"
function! s:bindings_table(table) abort
  " Return a nice displayable list of bindings
  let nspace = max(map(keys(a:table), 'len(v:val)'))
  let mspace = max(map(values(a:table), 'type(v:val) == 1 ? len(v:val) : len(v:val[0])'))  " might be just string
  let bindings = []
  for [key, value] in items(a:table)
    " Support for tables with 'value' and ['left', 'right'] values
    if type(value) == 1  " string
      let values = [value]
    elseif type(value) == 3  " list
      let values = value
    else
      echohl WarningMsg
      echom 'Error: Invalid table dictionary'
      echohl None
      return
    endif
    " Get key and value strings
    let keystring = key . ':' . repeat(' ', nspace - len(key) + 1)
    let valstring = ''
    for i in range(len(values))
      let val = substitute(values[i], "\n", '\\n', 'g')
      let quote = (val =~# "'" ? '"' : "'")
      let suffix = (i < len(values) - 1 && len(values) > 1 ? ',' : '')
      let suffix .= (i == 0 ? repeat(' ', mspace - len(val) + 3) : '')
      let valstring .= quote . val . quote . suffix
    endfor
    call add(bindings, keystring . valstring)
  endfor
  return join(bindings, "\n")
endfunction

function! textools#show_bindings(prefix, table) abort
  " Show the entire table
  let header = 'Table of ' . a:prefix . "<KEY> bindings:\n"
  return header . s:bindings_table(a:table)
endfunction

function! textools#find_bindings(prefix, table, regex) abort
  " Find the matching entry/entries
  let table_filtered = {}
  for [key, value] in items(a:table)
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
  let header = (len(table_filtered) == 1 ? '' : "Bindings matching regex '" . a:regex . "':\n")
  return header . s:bindings_table(table_filtered)
endfunction

"-----------------------------------------------------------------------------"
" Inserting complicatd snippets
"-----------------------------------------------------------------------------"
" Add user-defined snippet with fixed prefix and suffix. If the user
" *cancels* input or writes nothing, insert nothing.
function! textools#insert_snippet(prompt, prefix, suffix)
  let result = input(a:prompt)
  if empty(result)
    return ''
  else
    return a:prefix . result . a:suffix
  endif
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
  let [l1, c11] = searchpairpos(a:left, '', a:right, 'bnW') " set '' mark at current location
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
  call setpos("'z", [0, l2, c22, 0])
  set paste | exe 'normal! ' . a:rexpr | set nopaste
  if len(s:strip(getline(l2))) == 0 | exe l2 . 'd' | endif

  " Delete or change left delim
  call cursor(l1, c11)
  let [l1, c12] = searchpos(a:left, 'cen')
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
" Functions for selecting citations from bibtex files
" See: https://github.com/msprev/fzf-bibtex
"-----------------------------------------------------------------------------"
" The gsed executable
let s:gsed = '/usr/local/bin/gsed'  " Todo: defer to 'gsed' alias?
if !executable(s:gsed)
  echohl ErrorMsg
  echom 'Error: gsed not available. Please install it with brew install gnu-sed.'
  echohl None
  finish
endif

" Basic function called every time
function! s:cite_source() abort
  " Set the plugin source variables
  " Get biligraphies using grep, copied from latexmk
  " Easier than using search() because we want to get *all* results
  let bibfiles = system(
    \ 'grep -o ''^[^%]*'' ' . shellescape(@%) . ' | '
    \ . s:gsed . ' -n ''s/\\\(bibliography\|nobibliography\|addbibresource\){\(.*\)}/\2/p'''
    \ )
  if v:shell_error != 0
    echohl ErrorMsg
    echom 'Error: Failed to get list of bibliography files.'
    echohl None
  endif

  " Check that files all exist
  let filedir = expand('%:h')
  let biblist = []
  for bibfile in split(bibfiles, "\n")
    if bibfile !~? '.bib$'
      let bibfile .= '.bib'
    endif
    let bibpath = filedir . '/' . bibfile
    if filereadable(bibpath)
      call add(biblist, bibpath)
    else
      echohl WarningMsg
      echom 'Warning: Bibtex file ''' . bibpath . ''' does not exist.''
      echohl None
    endif
  endfor

  " Set the environment variable and return command-line command used to
  " generate fuzzy list from the selected files.
  let $FZF_BIBTEX_SOURCES = join(biblist, ':')
  if len(biblist) == 0
    echohl WarningMsg
    echom 'Warning: No bibtex files found.'
    echohl None
  endif
  if executable('bibtex-ls')
    return 'bibtex-ls ' . join(biblist, ' ')
  else
    echohl ErrorMsg
    echom 'Error: bibtex-ls not found.'
    echohl None
    return ''
  endif
  " return biblist
endfunction

" Return citation text
" We can them use this function as an insert mode <expr> mapping
" Note: To get multiple items just hit <Tab>
function! textools#cite_select() abort
  let result = ''
  let items = fzf#run({
    \ 'source': s:cite_source(),
    \ 'options': '--prompt="Source> "',
    \ 'down': '~50%',
    \ })
  if executable('bibtex-cite')
    let result = system('bibtex-cite ', items)
    let result = substitute(result, '@', '', 'g')
  else
    echohl ErrorMsg
    echom 'Error: bibtex-cite not found.'
    echohl None
  endif
  return result
endfunction

"-----------------------------------------------------------------------------"
" Functions for selecting from available graphics files
"-----------------------------------------------------------------------------"
" Related function that prints graphics files
function! s:graphics_source() abort
  " Get graphics paths
  " Todo: Make this work when \graphicspath takes up more than one line
  " Not high priority because latexmk rarely accounts for this anyway
  let paths = system(
    \ 'grep -o ''^[^%]*'' ' . shellescape(@%) . ' | '
    \ . s:gsed . ' -n ''s/\\graphicspath{\(.*\)}/\1/p'''
    \ )
  if v:shell_error != 0
    echohl ErrorMsg
    echom 'Error: Failed to get list of graphics paths.'
    echohl None
  endif
  let paths = substitute(paths, "\n", '', 'g')  " in case multiple \graphicspath calls, even though this is illegal

  " Check syntax
  " Note: Negative indexing evidently does not work with strings
  let filedir = expand('%:h')
  let pathlist = []
  if paths[0] !=# '{' || paths[len(paths) - 1] !=# '}'
    " Syntax is \graphicspath{{path1}{path2}}
    echohl WarningMsg
    echom 'Warning: Incorrect syntax ''' . paths . ''''
    echohl None
  else
    " Make paths relative to *latex file* not cwd
    let pathlist = []
    for path in split(paths[1:len(paths) - 2], '}{')
      let abspath = expand(filedir . '/' . path)
      if isdirectory(abspath)
        call add(pathlist, abspath)
      else
        echohl WarningMsg
        echom 'Warning: Directory ''' . abspath . ''' does not exist.'
        echohl None
      endif
    endfor
  endif

  " Get graphics files in each path
  let figlist = []
  echom join(pathlist, ', ')
  call add(pathlist, expand('%:h'))
  for path in pathlist
    for ext in ['png', 'jpg', 'jpeg', 'pdf', 'eps']
      call extend(figlist, globpath(path, '*.' . ext, v:true, v:true))
    endfor
  endfor
  let figlist = map(figlist, 'fnamemodify(v:val, ":p:h:t") . "/" . fnamemodify(v:val, ":t")')

  " Return figure files
  if len(figlist) == 0
    echohl WarningMsg
    echom 'Warning: No graphics files found.'
    echohl None
  endif
  return figlist
endfunction

" Return graphics text
" We can them use this function as an insert mode <expr> mapping
function! textools#graphics_select() abort
  let items = fzf#run({
    \ 'source': s:graphics_source(),
    \ 'options': '--prompt="Figure> "',
    \ 'down': '~50%',
    \ })
  let items = map(items, 'fnamemodify(v:val, ":t")')
  return join(items, ',')
endfunction
