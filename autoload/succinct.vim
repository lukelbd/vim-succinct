"-----------------------------------------------------------------------------"
" General search and replace functions {{{1
"-----------------------------------------------------------------------------"
" Patterns for parsing regular expressions
" Note: This is needed to dynamically assign either search() or searchpair() for input
" delimiters and configure the text object and delimiter modifying utilities. Without
" special handling selection of complex or multi-length delimiters can fail, e.g. cannot
" capture lading python [rfub]' string or zero-length \< object 'boundary'.
let s:regex_keys = {'python': '.', 'tex': '*', 'vim': ':'}  " temporary keyword additions
let s:regex_parts = '\\%\?(\(\%(.\%(\\%\?(\)\@!\)\{-}\)\\)'  " \(\) and \%(\) (inner before outer)
let s:regex_space = '\(\_s\|\\_s\|\\[snt]\)'  " space indicators e.g. \n \_s
let s:regex_spec = '\\@\d*<\?[>=!]'  " always zero-length (e.g. \@<!)
let s:regex_star = '\\{-\?\d\?,\?\d\?}\|\%(\\\|\[[^\]]*\)\@<!\*'  " star expansions
let s:regex_mod = '\(\\[?=+]\|' . s:regex_star . '\|' . s:regex_spec . '\)\?'  " e.g. *, \+, \?, \{n,}, \@=
let s:regex_opt = '\(\\[?=]\|' . s:regex_star . '\|' . s:regex_spec . '\)'  " optional-missing modifiers
let s:regex_null = '\(\\z[^se]\|\\[<>cCZ]\|\%(\\_\)\?[$^]\|\\%\[[^\]]*\]'  " e.g. ^, $, \<, \>, \c
let s:regex_null .= '\\%[V#$^]\|\\%[<>]\?\%([.'']\|\d\+\)[lcm]\)'  " e.g. \%#, \%>123l
let s:regex_atom = '\(\%(\\_\)\?\\\@<!\[[^\]]\+\]\|\\%\?(.\+\\)\|\%(\\_\?\)\?.\)'  " check brackets first
let s:regex_oatom = s:regex_atom . s:regex_opt  " atom with optionally zero-length modifier
let s:regex_matom = s:regex_atom . s:regex_mod  " atom with any arbitrary modifier or none
let s:regex_mparts = s:regex_parts . s:regex_mod  " parts grouping with any arbitray modifier

" Helper functions for regex parsing
" Note: Here estimate size of given regex match by selecting \(\|\) group with minimum
" size if 'o' flag was passed or maximum size if 'o' not passed. Idea is to avoid
" succinct#search_items() search for end-of-right delimiter on zero-length delims
function! succinct#chars(regex)  " convert individual atoms to one-character strings
  let isub = 'strcharpart(submatch(%d), strchars(submatch(%d)) - 1)'
  let [spec, star] = ['\(' . s:regex_spec . '\)', '\(\\+\|' . s:regex_star . '\)']
  let [sub1, sub2] = [printf(isub, 1, 1), printf(isub, 2, 2)]  " capture final character
  let reg = substitute(a:regex, s:regex_null, '\=' . sub1, 'g')  " e.g. \> -> '>' (for comparing)
  let reg = substitute(reg, s:regex_atom . spec, '', 'g')  " e.g. \x\@<= -> empty
  let reg = substitute(reg, s:regex_atom . star, '\=' . sub1 . '.' . sub1, 'g')
  let reg = substitute(reg, s:regex_atom . '\(\\[?=]\)\?', '\=' . sub1, 'g')
  return reg  " e.g. \<\W\?\w*\W\@= -> <\W\?\w*\W\@= -> <\W\?\w* -> <\W\?ww -> <Www
endfunction
function! succinct#group(regex, ...)  " convert \(\) group to maximum size \| option
  let flags = substitute(a:0 ? a:1 : '', 'a', '', 'g')
  let items = matchlist(a:regex, s:regex_mparts)  " inner groups come first
  let regs = split(get(items, 1, ''), '\\|', 1)  " capture group components
  let regs = len(regs) == 1 && empty(regs[0]) ? [] : regs  " require one non-empty
  let sizes = map(copy(regs), 'strchars(succinct#regex(v:val, "aonm" . flags))')
  let size = flags =~# 'o' ? min(sizes) : max(sizes)  " preferred object
  let reg = get(regs, index(sizes, size), '')  " get() handles e.g. \(\)
  let reg = substitute(a:regex, s:regex_parts, escape(reg, '\'), '')  " replace
  let reg = succinct#regex(reg, flags)
  return reg  " e.g. \([abc]\|\>\)* with flag 'o' is \>, without flag 'o' is [abc]
endfunction

" Translate and modify regular expressions
" Note: Here succinct#regex() is used to improve textobj selection behavior and auto
" dispatch either search() or searchpairpos() for succinct#get_delims() searching. Uses
" above regex to figure out lengths and uniqueness of left and right delims.
function! succinct#regex(regex, flags) abort
  let [cnt, reg, subs] = [3, a:regex, []]  " various substitutions
  let acount = a:flags =~# 'a' ? cnt : 0  " convert regex atoms to single characters
  let ocount = a:flags =~# 'o' ? cnt : 0  " remove zero or optional-length modifiers
  let mcount = a:flags =~# 'm' ? cnt : 0  " remove modifier expressions themselves
  let ncount = a:flags =~# 'n' ? 1 : 0  " remove null-length atoms e.g. \c or \zs
  let scount = a:flags =~# 's' ? 1 : 0  " remove whitespace expressions
  call extend(subs, repeat([['\(.*\\zs\|\\ze.*\)', '']], acount))
  call extend(subs, repeat([[s:regex_oatom, '']], ocount))
  call extend(subs, repeat([[s:regex_matom, '\1']], mcount))
  call extend(subs, repeat([[s:regex_null, '']], ncount))
  call extend(subs, repeat([[s:regex_space, '']], scount))
  for [sub1, sub2] in subs  " carry out substitutions
    let reg = substitute(reg, sub1, sub2, 'g')
  endfor
  if a:flags =~# 'a'  " convert atoms e.g. \(\), [], \_a, \a, a to '.', or \a* to '..'
    for _ in range(3)
      let reg = succinct#group(reg, a:flags)
    endfor
    for _ in range(3)
      let reg = succinct#chars(reg)
    endfor
  endif | return reg
endfunction

" Helper functions for searching and navigating
" Note: Here succinct#syntax() is used to filter succinct#search_items() to end-points
" with identical syntax groups, and succinct#search() is used to temporarily modify
" iskeyword and enable case sensitivity (e.g. include python method chains foo.bar()
" for \k\+() search and tex asterisks \command*{} for \\\k\+{} search).
function! succinct#goto(line, col, ...) abort
  let [lnum, cnum] = a:0 ? a:000 : [line('.'), col('.')]
  let state = get(b:, 'scroll_state', 0)  " internal .vimrc setting
  let keys = !pumvisible() ? '' : state ? "\<C-y>\<C-]>" : "\<C-e>"
  if a:line == lnum
    let key = a:col > cnum ? "\<Right>" : "\<Left>"
    let keys .= repeat(key, abs(a:col - cnum))
  else  " delimiter on different line
    let key = a:line > lnum ? "\<Down>" : "\<Up>"
    let keys .= "\<Home>" . repeat(key, abs(a:line - lnum)) . repeat("\<Right>", a:col - 1)
  endif | return keys
endfunction
function! succinct#syntax(...) abort  " verify inside regex group
  if a:0 >= 2  " input line column
    let [lnum, cnum] = a:000
  elseif a:0 >= 1  " input line
    let [lnum, cnum] = [a:1, col([a:1, '$'])]
  else  " cursor position
    let [lnum, cnum] = [line('.'), col('.')]
  endif
  let expr = "synIDattr(synIDtrans(v:val), 'name')"
  let stack = map(synstack(lnum, cnum), expr)
  return empty(stack) ? ['Unknown'] : [stack[0]]
endfunction
function! succinct#search(...) abort
  let mods = get(s:regex_keys, &l:filetype, '')
  let mods = empty(mods) ? '' : ',' . join(split(mods, '\zs'), ',')
  let [keys, ignore] = [&l:iskeyword, &l:ignorecase]
  try
    let &l:iskeyword = keys . mods
    let &l:ignorecase = 0
    return call(a:0 > 3 ? 'searchpairpos' : 'searchpos', a:000)
  finally
    let &l:iskeyword = keys
    let &l:ignorecase = ignore
  endtry
endfunction

" Navigate delimeters  ( [ [ ( ' ' foo) bar] baz] xyz)
" Note: Cannot use search() because it fails to detect current column. Could
" use setpos() but then if fail to find delim that moves cursor. Also note cursor()
" fails in insert mode, even though 'current position' changes inside function.
function! succinct#prev_delim() abort
  let [lnum, cnum] = [line('.'), col('.')]
  call succinct#search_delim('eb')
  if col('.') > cnum - 2
    call succinct#search_delim('eb')
  endif
  let keys = succinct#goto(line('.'), col('.') + 1, lnum, cnum)
  return keys
endfunction
function! succinct#next_delim() abort
  let [lnum, cnum] = [line('.'), col('.')]
  if cnum > 1  " current line
    call cursor(lnum, cnum - 1)
  else  " previous line
    call cursor(max([1, lnum - 1]), max([col([lnum - 1, '$']) - 1, 1]))
  endif
  call succinct#search_delim('e')
  return succinct#goto(line('.'), col('.') + 1, lnum, cnum)
endfunction
function! succinct#search_delim(...) abort
  let name = 'delimitMate_matchpairs'
  let delims = get(b:, name, get(g:, name, &matchpairs))
  let delims = substitute(delims, '[:,]', '', 'g')
  let name = 'delimitMate_quotes'
  let quotes = get(b:, name, get(g:, name, "\" ' `"))
  let quotes = substitute(quotes, '\s\+', '', 'g')
  let regex = '[' . escape(delims . quotes, ']^-\') . ']'
  call search(regex, a:0 ? a:1 : 'e')
endfunction

" Search for identical items and distinct item pairs
" Note: Previously tried starting search_items() right-delimiter search from end
" of left delimiter using 'ceW' but that fails for optional zero-length matches. Now
" just remove the optional parts to detect whether initial search must be repeated
" Note: Here search_items() tries to ensure we are capturing e.g. multi-line strings
" instead of content between strings with syntax check. Note e.g. bash $variables and
" python {format} indicators share same group 'Constant' so this still works.
" Note: Here searchpairpos(..., 'b') goes to the start of the first delimiter and
" searchpairpos(..., '') goes to the start of the second delimiter. Also note
" searchpairpos(..., 'bc') fails if the cursor is anywhere on a closing delimiter
" and searchpairpos(..., 'c') fails if the cursor is on the first character of
" an opening delimiter or after the first character of a closing delimiter.
function! succinct#search_pairs(left, right, ...) abort
  let cnt = max([1, a:0 ? a:1 : 1])
  let [lnum, cnum] = [line('.'), col('.')]  " prefer matches on current line
  let [line1, col11] = succinct#search(a:left, '', a:right, 'nbcW')
  let [line2, col21] = succinct#search(a:left, '', a:right, 'ncW')
  if line1 && !line2 || line1 == lnum && line2 != lnum  " could be on head of open or tail of close
    call cursor(line1, col11) | normal! l
    let [line2, col21] = succinct#search(a:left, '', a:right, 'ncW')
  endif
  if line2 && !line1 || line2 == lnum && line1 != lnum  " could be somewhere on closing delimiter
    call cursor(line2, col21) | normal! h
    let [line1, col11] = succinct#search(a:left, '', a:right, 'nbcW')
  endif
  call cursor(line1, col11)  " 'bnW' and 'cnW' will deliberately fail
  for idx in range(2, cnt)  " additional matches beyond current one
    let [line1, col11] = succinct#search(a:left, '', a:right, 'nbW')
    let [line2, col21] = succinct#search(a:left, '', a:right, 'ncW')
    call cursor(line1, col11)  " then searches will go beyond cursor
  endfor
  return [line1, col11, line2, col21]
endfunction
function! succinct#search_items(left, right, ...) abort
  let cnt = max([1, a:0 ? a:1 : 1])
  let [lnum, cnum] = [line('.'), col('.')]
  let [line0, col0] = [lnum, cnum]
  for idx in range(cnt)  " select outer items
    let flags = idx == 0 ? 'bcW' : 'bW'  " include object under cursor *first*
    let [line1, col11] = succinct#search(a:left, flags)
    let [line0, col0] = idx == 0 ? [line1, col11] : [line0, col0]
  endfor
  call cursor(line0, col0)  " start from rightmost left delimiter
  if strchars(succinct#regex(a:left, 'an')) > 1  " number ignoring nulls e.g. \<
    call succinct#search(a:left, 'ecW')
  endif
  for idx in range(cnt)  " select outer items
    let [line2, col21] = succinct#search(a:right, 'W')
  endfor
  if a:left =~# '[''"]' && a:right =~# '[''"]'  " additional syntax check
    let inner = line2 > line1 ? range(line1 + 1, line2 - 1) : []
    let groups = succinct#syntax(lnum, cnum)
    call extend(groups, succinct#syntax(line1, col11))
    call extend(groups, succinct#syntax(line2, col21))
    for inum in inner | call extend(groups, succinct#syntax(inum)) | endfor
    if len(uniq(sort(groups))) > 1 | return [0, 0, 0, 0] | endif
  endif
  return [line1, col11, line2, col21]
endfunction

"-----------------------------------------------------------------------------"
" Register snippets, delimiters, and objects {{{1
"-----------------------------------------------------------------------------"
" Register delimiters from settings
" Warning: For some reason search('\n\s*$', 'e') fails to jump to next line if it
" is empty. Have to force the jump by adding '\zs' after every '\n' in match.
" Note: This is alternative to vim-surround style of using manual FileType
" autocommands and managing 'ftplugin' files. Triggered with general augroup.
function! s:get_source(...) abort
  let suffix = a:0 && a:1 ? 'snippets' : 'delims'
  let ftype = substitute(&l:filetype, '\..*$', '', 'g')  " ignore composites
  let name1 = 'succinct_' . suffix
  let name2 = 'succinct_' . ftype . '_' . suffix
  let types = get(g:, 'succinct_filetype_' . suffix, {})
  if exists('b:' . name1)
    return get(b:, name1, {})
  elseif exists('g:' . name2)
    return get(g:, name2, {})
  elseif has_key(types, ftype)
    return types[ftype]
  else  " fallback
    return {}
  endif
endfunction
function! succinct#filetype_delims(...) abort
  let source = s:get_source(0)
  return call('succinct#add_delims', [source, 1] + a:000)
endfunction
function! succinct#filetype_snippets(...) abort
  let source = s:get_source(1)
  return call('succinct#add_snippets', [source, 1] + a:000)
endfunction

" Get surround delimiters and associated text object
" Note: These drive all operator-pending textobj mappings and vim-surround delimiter
" modifications. Supports process_value mods (e.g. python [frub] prefix, tex %-suffix)
" Note: These defer to searchpairpos() for non-identical delimiters more than one atom
" in legth, searchpos() otherwise (e.g. quotes, word boundaries, optional length bounds)
function! succinct#get_delims(left, right, ...) abort
  let winview = winsaveview()
  let regex1 = substitute(a:left, '^\\_s\*$', '\^\\s*\\n', 'g')  " 'e' translation
  let regex2 = substitute(a:right, '^\\_s\*$', '\\n\\s*\$', 'g')  " 'e' translation
  let compare1 = succinct#regex(regex1, 'mons')  " remove optional-length atoms, modifiers, null atoms
  let compare2 = succinct#regex(regex2, 'mons')
  let atoms11 = succinct#regex(regex1, 'aons')  " ignoring optional length
  let atoms12 = succinct#regex(regex1, 'as')  " single character atoms
  let atoms21 = succinct#regex(regex2, 'aons')
  let atoms22 = succinct#regex(regex2, 'as')
  let safe = strchars(atoms11) < strchars(atoms12) || strchars(atoms21) < strchars(atoms22)
  let safe = safe && strchars(atoms11) <= 1 && strchars(atoms21) <= 1  " only if singleton
  let safe = safe || compare1 ==# compare2  " e.g. quotes, whitespace (filtered to '')
  let func = safe ? 'succinct#search_items' : 'succinct#search_pairs'
  let [line1, col11, line2, col21] = call(func, [regex1, regex2] + a:000)
  if line1 == 0 || line2 == 0  " search failed
    call winrestview(winview) | return ['', '', 0, 0, 0, 0]
  else  " search succeeded
    return [regex1, regex2, line1, col11, line2, col21]
  endif
endfunction
function! succinct#get_object(mode, name, ...) abort
  let [winview, lnum, cnum] = [winsaveview(), line('.'), col('.')]
  let noesc = a:0 ? a:1 : 0  " whether to skip escaping patterns
  let value = succinct#process_value(get(s:, a:name, ''), 1, noesc)
  let [left, right] = count(value, "\r") == 1 ? split(value, "\r", 1) : ['', '']
  let [regex1, regex2, line1, col1, line2, col2] = succinct#get_delims(left, right, v:count1)
  if !line1 || !line2 || !col1 || !col2 | return | endif
  let space1 = strchars(succinct#regex(regex1, 'aons')) ? '\_s*' : ''
  let space2 = strchars(succinct#regex(regex2, 'aons')) ? '\_s*' : ''
  let iregex = substitute(regex2, '\\n', '\\n\\zs', 'g')  " ensure jump (see above)
  call cursor(line1, col1)  " start of left delim or after zero-length match
  if a:mode ==# 'i'  " inner selection only
    call succinct#search(regex1 . space1 . '\S', 'ceW')
  endif
  let pos1 = getpos('.')
  call cursor(line2, col2)  " start of right delim or after zero length match
  let chars = succinct#regex(regex2, 'aon')
  if strchars(chars)  " jump to end if non-zero length is *required*
    call succinct#search(iregex, 'ceW')  " WARNING: fails for unsuccessful optional modifiers
  endif
  if !strchars(chars) || a:mode ==# 'i'  " start of right delim or before zero length match
    call succinct#search('\S' . space2 . regex2, 'cbW')
  endif
  let pos2 = getpos('.')
  if lnum < pos1[1] || lnum == pos1[1] && cnum < pos1[2]
    call winrestview(winview) | return
  elseif lnum > pos2[1] || lnum == pos2[1] && cnum > pos2[2]
    call winrestview(winview) | return
  endif  " return positions and queue post-processing
  let cmd = 'call succinct#post_process(' . pos1[1] . ', ' . pos2[1] . ')'
  exe 'augroup succinct_process_' . bufnr() | exe 'au!'
  exe 'au TextChanged,InsertLeave,CursorHold <buffer> ' . cmd . ' | au! succinct_process_' . bufnr()
  exe 'augroup END'
  let reg1 = getline(pos1[1]) =~# '^\s*' . regex1 . '\s*$'
  let reg2 = getline(pos2[1]) =~# '^\s*' . regex2 . '\s*$'
  let char = a:mode !=# 'i' && reg1 && reg2 ? 'V' : 'v'
  return [char, pos1, pos2]
endfunction

" Translate and register text object plugins
" Note: Have to use literals instead of e.g. assigning s:[name] = function() since
" vim-textobj-user calls with function(a:name)() which fails unless defined literally,
" and have to delay succinct#process_value() e.g. to support python string prefixes.
" Note: Here 'select-[ai]' point to textobj#user#select_pair and searchpairpos() while
" 'select' points to textobj#user#select and searchpos(..., 'c'). This fails for 'a'
" objects that overlap with others on line (e.g. ya' -> '.\{-}' may go outside the
" closest quotes, but '\zs.\{-}\ze' will not). So now use function definition instead.
function! s:get_object(plugin, key, arg, ...) abort
  let flags = a:0 && a:1 ? '<buffer> ' : ''
  let noesc = a:0 > 1 ? a:2 : 0  " possibly skip escaping patterns
  let name = 'textobj_' . a:plugin . '_' . char2nr(a:key)
  let s:[name] = succinct#_pre_process(a:arg)
  let code = [
    \ 'function! s:' . name . '_i() abort',
    \ '  return succinct#get_object("i", ' . string(name) . ', ' . noesc . ')',
    \ 'endfunction',
    \ 'function! s:' . name . '_a() abort',
    \ '  return succinct#get_object("a", ' . string(name) . ', ' . noesc . ')',
    \ 'endfunction'
  \ ]
  exe join(code, "\n")
  let obj = {
    \ 'sfile': expand('<script>:p'),
    \ 'select-i': flags . 'i' . escape(a:key, '|'),
    \ 'select-a': flags . 'a' . escape(a:key, '|'),
    \ 'select-i-function': 's:' . name . '_i',
    \ 'select-a-function': 's:' . name . '_a',
  \ }
  return {char2nr(a:key): obj}  " textobj uses this for [ia]<Key> <Plug> maps
endfunction
function! succinct#add_objects(plugin, source, ...) abort
  let objects = {}
  if !exists('*textobj#user#plugin')  " see: https://vi.stackexchange.com/a/14911/8084
    runtime autoload/textobj/user.vim
    if !exists('*textobj#user#plugin')  " plugin not available
      let msg = 'Warning: Cannot define text objects (vim-textobj-user not found).'
      redraw | echohl WarningMsg | echom msg | echohl None | return {}
    endif
  endif
  for key in keys(a:source)
    if type(a:source[key]) != 1
      let msg = 'Warning: Cannot add key ' . string(key) . ' as text object (non-string type).'
      redraw | echohl WarningMsg | echom msg | echohl None | continue
    endif
    let args = [a:plugin, key, a:source[key]]
    let objs = call('s:get_object', args + a:000)
    call extend(objects, objs)
  endfor
  if !empty(objects)  " enforces lowercase alphabet
    let name = substitute(a:plugin, '^\(\l\)', '\u\1', 0)
    call textobj#user#plugin(a:plugin, objects)
    exe 'Textobj' . name . 'DefaultKeyMappings!'
  endif
  return objects
endfunction

" Register surround and snippet definitions
" Note: Use ad-hoc approach for including python string headers instead of relying
" on user so that built-in change-delim and delete-delim commands that rely on
" buffer and global surround variables still include header, but without including
" regex for built-in visual, insert, and motion based vim-surround insertions.
function! succinct#_pre_process(arg) abort
  let chars = ['r', 'n', 't', '1', '2', '3', '4', '5', '6', '7']
  let [chars, result] = type(a:arg) > 1 ? [[], ''] : [chars, a:arg]
  for char in chars
    let repl = eval('"\' . char . '"')
    let check = char2nr(repl) > 7 ? '\a\@!' : ''
    let result = substitute(result, '\\' . char . check, repl, 'g')
  endfor
  return empty(result) ? a:arg : result
endfunction
function! succinct#add_snippets(source, ...) abort
  let scope = a:0 && a:1 ? b: : g:
  let snippets = {}  " for user reference
  for key in keys(a:source)  " funcref cannot be lower case so iterate keys
    let name = 'snippet_' . char2nr(key)
    let scope[name] = succinct#_pre_process(a:source[key])
    let snippets[key] = scope[name]
  endfor
  return snippets
endfunction
function! succinct#add_delims(source, ...) abort
  let scope = a:0 && a:1 ? b: : g:
  let delims = {}
  for key in keys(a:source)  " funcref cannot be lower case so iterate keys
    let name = 'surround_' . char2nr(key)
    let scope[name] = succinct#_pre_process(a:source[key])
    let delims[key] = scope[name]
  endfor
  let plugin = a:0 && a:1 ? &l:filetype : a:0 ? 'global' : 'default'  " plugin name
  let plugin = substitute(plugin, '\A', '', 'g')  " alpahbetic required
  let plugin = substitute(plugin, '\(\u\)', '\l', 'g')  " lower-case required
  call call('succinct#add_objects', [plugin, a:source] + a:000)
  return delims
endfunction

"-----------------------------------------------------------------------------
" Select templates, snippets, and delimiters {{{1
"-----------------------------------------------------------------------------
" Helper functions for template file search
" Note: See below for more on fzf limitations.
function! s:template_source(ext) abort
  if !exists('g:succinct_templates_path')
    return []
  endif
  let base = expand(g:succinct_templates_path)
  let paths = globpath(base, '*.' . a:ext, 0, 1)
  let paths = filter(paths, '!isdirectory(v:val)')
  let paths = map(paths, 'fnamemodify(v:val, ":t")')
  if !empty(paths) | call insert(paths, '') | endif  " stand-in for 'load nothing'
  return paths
endfunction
function! s:template_sink(file) abort
  if !exists('g:succinct_templates_path') || empty(a:file)
    return
  endif
  let base = expand(g:succinct_templates_path)
  let path = base . '/' . a:file
  execute '0r ' . path | doautocmd BufRead
endfunction

" Helper functions for delimiter and snippet search
" Note: See below for more on fzf limitations.
function! s:select_source(name) abort
  let [items, labels] = [[], []]
  for scope in ['g:', 'b:']
    let head = scope . a:name . '_'
    for name in getcompletion(head . '[0-9]', 'var')
      let char = nr2char(substitute(name, '^' . head, '', ''))
      if char =~# "\<CSI>" | continue | endif  " internal (see below)
      if char =~# '\d\|\s' | continue | endif  " impossible to use
      let key = char =~# '\p' ? char : strtrans(char)
      call add(items, [key, name])
    endfor
  endfor
  let size = max(map(copy(items), 'len(v:val[0]) + len(v:val[1])'))
  for [key, name] in items
    let label = repeat(' ', size - len(key) - len(name))
    let label .= name . ' ' . key . ': ' . string(eval(name))
    call add(labels, label)
  endfor | return reverse(labels)
endfunction
function! s:select_sink(mode, args, item) abort
  let regex = '^\s*[gb]:\%(snippet\|surround\)_\(\d\+\).*$'
  let key = nr2char(matchlist(a:item, regex)[1])
  if empty(key) | return | endif
  if !type(a:mode) && !a:mode  " snippet sink
    let feed = "\<Plug>Isnippet" . key
    call feedkeys(feed, 'ti')
  elseif !type(a:mode) || a:mode ==? 'v'  " e.g. ys<Motion> map arguments
    let args = [a:args[0], key] + a:args[1:]
    call call('s:feed_motion', args)
  elseif a:mode ==? 'i'  " e.g. <Plug>Isuccinct and <Plug>Vsuccinct
    let args = [key] + a:args[1:]
    call call('s:feed_insert', args)
  else  " e.g. ds, cs maps with more complex destinations
    let search = a:mode =~# '\l'  " whether to search or replace
    let name = search ? 'succinct_delete' : 'succinct_change'
    let break = len(a:args) > 2 ? a:args[3] : 0
    let [text1, text2] = s:get_surround(key, a:args[1], search, break)
    let b:[name] = [text1, text2, a:args[2]]  " delimiters with count
    let feed = "\<Plug>" . toupper(a:mode) . 'succinct'
    call feedkeys(feed, 'm')  " skips 'setup' and uses cache
  endif
endfunction

" Show templates, snippets, and delimiters in fzf menu
" Note: Have to disable autocommands when not using fzf#wrap or screen flashes twice,
" Note: Currently calling default fzf#run with any window options (e.g. by calling
" fzf#wrap) causes vim to exit insert mode (seems to be related to triggering use_term=1
" inside fzf#run), requiring us to recover cursor position and sometimes triggering
" obscure E565 error that effectly disables insert mode until vim session is restarted
" (seems to be related to feedkeys('a...' invocation)). Workaround is to call fzf#run()
" with no window options and letting it fill the screen (use --height=100% to ensure
" all entries shown). In future may have to make this work but for now this is fine.
function! s:fzf_check() abort
  if exists('*fzf#run') | return 1 | endif
  let msg = 'Error: fzf.vim plugin not available.'
  redraw | echohl ErrorMsg | echom msg | echohl None
endfunction
function! succinct#fzf_template() abort
  let templates = s:template_source(expand('%:e'))
  if empty(templates) | return | endif
  if !s:fzf_check() | return | endif
  let opts = '--tiebreak index --height=100%'
  call fzf#run(fzf#wrap({
    \ 'sink': function('s:template_sink'),
    \ 'source': templates,
    \ 'options': opts . " --prompt='Template> '",
    \ }))
endfunction
function! succinct#fzf_select(mode, ...) abort
  if !s:fzf_check() | return | endif
  let name = !type(a:mode) && !a:mode ? 'snippet' : 'surround'
  let opts =  '-d''_'' --nth 2.. --tiebreak index --height=100%'
  noautocmd call fzf#run({
    \ 'sink': function('s:select_sink', [a:mode] + a:000),
    \ 'source': s:select_source(name),
    \ 'options': opts . ' --prompt=' . string(toupper(name[0]) . name[1:] . '> '),
  \ })
endfunction

"-----------------------------------------------------------------------------"
" Helper functions for processing snippets and delimiters {{{1
"-----------------------------------------------------------------------------"
" Get and parse user-input delimiter key and spaces
" Todo: Consider supporting multi-character succinct and surround maps.
" Note: This permits typing arbitrary numbers to select outer delimiters, e.g. 2b
" for the second ensted parentheses, and aribtrary spaces for padding the end of
" the first delimiter and start of the second delimiter (see succinct#post_process)
function! s:get_char() abort
  let char = getchar()  " returns number only if successful translation
  let char = string(char) =~# '^\d\+$' ? nr2char(char) : char
  return char
endfunction
function! s:get_maps(mode) abort
  let name = !type(a:mode) && !a:mode ? 'snippet_map' : 'surround_map'
  let map = !type(a:mode) && !a:mode ? '<C-e>' : '<C-s>'
  let arg = maparg(get(g:, 'succinct_' . name, map), 'i', 0, 1)
  let lhs1 = get(arg, 'lhsraw', '')  " literal byte sequences
  let lhs2 = get(arg, 'lhsrawalt', '')
  return filter([lhs1, lhs2], 'strchars(v:val)')
endfunction
function! s:get_target(mode, ...) abort
  let [cnt, pad] = ['', '']
  let key = s:get_char()
  let head = !type(a:mode) && !a:mode ? 'snippet' : 'surround'
  let name = head . '_' . char2nr(key)
  if !has_key(b:, name) && !has_key(g:, name)  " allow e.g. '1' delimiters
    while key ==# "\<CursorHold>"  " iterm 3.5+ bug
      let key = s:get_char()
    endwhile
    while key =~# '^\d\+$'
      let cnt .= key  " user is providing count
      let key = s:get_char()
    endwhile
    while key =~# '\_s\|\r'
      let pad .= key =~# '\r' ? "\n" : key  " user is providing padding
      let key = s:get_char()
    endwhile
  endif
  let cnt = empty(cnt) || cnt ==# '0' ? 1 : str2nr(cnt)
  let cnt *= !type(a:mode) ? max([a:mode, 1]) : 1  " e.g. 'ys' user input count
  let maps = s:get_maps(a:mode)
  if index(maps, key) >= 0  " interactive select
    let args = [a:0 ? a:1 : 'char', pad, cnt] + a:000[1:]
    call succinct#fzf_select(a:mode, args) | return ['', '', 0]
  else  " continue with operation
    let key = key =~# '\p' ? key : ''
    return [key, pad, cnt]
  endif
endfunction

" Get and process user-input delimiter, combining spaces and counts
" Note: Unlike vim-surround this permits passing whitespace in arbitrary vim-surround
" modes e.g. ysiw<CR>b, viw<C-s><CR>b, ds<CR>b, or a<C-s><CR>b. Note that e.g. cs<CR>rb
" removes newlines and leading/trailing whitespace while csr<CR>b adds newlines. This
" also supports spaces/counts to pad/repeat delimiters e.g. with ysiw2<Space>b.
function! s:get_padding(pad, ...) abort
  let search = a:0 > 0 ? a:1 : 0  " whether to search
  let inner = a:0 > 1 && a:2 ? "\n" : ''  " e.g. 'yS' instead of 'ys'
  if search  " convert e.g. literal '\n  ' to regex '\_s*'
    let pad = s:process_value(a:pad . inner)
    return [pad, pad]
  else  " e.g. <Space><CR><Cursor><CR><Space>
    let rpad = join(reverse(split(a:pad, '\zs')), '')
    return [a:pad . inner, inner . rpad]
  endif
endfunction
function! s:get_snippet(key, pad, ...) abort
  let default = a:key  " default 'snippet' is the input key
  let search = a:0 > 0 ? a:1 : 0  " whether to search for the value
  let name = 'snippet_' . char2nr(a:key)  " note char2nr('') == 0
  let text = succinct#process_value(get(b:, name, get(g:, name, default)), search)
  if empty(text) | return '' | endif  " e.g. empty key or missing value
  let [pad1, pad2] = call('s:get_padding', [a:pad] + a:000)
  return pad1 . text . pad2
endfunction
function! s:get_surround(key, pad, ...) abort
  let default = empty(a:key) || a:key =~# '\a' ? '' : a:key . "\r" . a:key  " default
  let search = a:0 > 0 ? a:1 : 0  " whether to search for the value
  let name = 'surround_' . char2nr(a:key)  " note char2nr('') == 0
  let text = succinct#process_value(get(b:, name, get(g:, name, default)), search)
  if empty(text) || count(text, "\r") != 1 | return ['', ''] | endif
  let [text1, text2] = split(text, "\r", 1)
  let [pad1, pad2] = call('s:get_padding', [a:pad] + a:000)
  if text1 =~# '{$' && &l:filetype ==# 'tex'  " e.g. \title{%\nvery_long_title\n}
    let pad1 = (a:0 && a:1 ? '\(%\s*\n\@=\)\?' : a:pad =~# '^\s*\n' ? '%' : '') . pad1
  endif
  return [text1 . pad1, pad2 . text2]
endfunction

" Process delimiter or snippet value. If a:search is true return regex suitable for
" *searching* for delimiters with searchpair(), else return delimiters themselves.
" Note: This was adapted from vim-surround/plugin/surround.vim. Note is critical to
" escape characters one-by-one or \r\r groups inside user-input delimiters are caught.
function! s:process_value(value, ...) abort
  let value = a:0 && a:1 ? a:value : escape(a:value, '[]\.*~^$')
  let value = substitute(value, '\_s\+', '\\_s*', 'g')  " allow arbitrary padding
  return value
endfunction
function! succinct#process_value(value, ...) abort
  " Acquire user-input for placeholders \1, \2, \3, ...
  let search = a:0 > 0 ? a:1 : 0  " whether to perform search
  let noesc = a:0 > 1 ? a:2 : 0  " whether to bypass escape
  let input = type(a:value) == 2 ? succinct#_pre_process(a:value()) : a:value  " func or str
  if empty(input) | return '' | endif  " e.g. funcref that starts asynchronous fzf
  for nr in range(7)
    let idx = matchstr(input, nr2char(nr) . '.\{-\}\ze' . nr2char(nr))
    if !empty(idx)  " \1, \2, \3, ... found inside string
      if !search  " acquire user-input values
        let idx = substitute(strpart(idx, 1), '\r.*', '', '')
        let repl_{nr} = input(match(idx, '\w\+$') >= 0 ? idx . ': ' : idx)
      else " search possible user-input values
        let regex = '\<\k\+'  " see succinct#search_item() for iskeyword modifications
        let repl_{nr} = regex
      endif
      if empty(repl_{nr}) | return '' | endif
    endif
  endfor
  " Replace inner regions with user input result
  let idx = 0
  let output = ''
  while idx < strlen(input)
    let char = strpart(input, idx, 1)
    let jdx = char2nr(char) > 7 ? -1 : stridx(input, char, idx + 1)
    if jdx == -1  " match individual character
      let part = !search ? char : s:process_value(char, noesc)
    else  " replace \1, \2, \3, ... with user input using inner text as prompt
      let part = repl_{char2nr(char)}  " defined above
      let query = strpart(input, idx + 1, jdx - idx - 1)  " query between \1...\1
      let query = matchstr(query, '\r.*')  " substitute initiation indication
      while query =~# '^\r.*\r'
        let group = matchstr(query, "^\r\\zs[^\r]*\r[^\r]*")  " match replace group
        let sub = strpart(group, 0, stridx(group, "\r"))  " prompt delimiters
        let repl = strpart(group, stridx(group, "\r") + 1)  " user-input
        let repl = !search ? repl : s:process_value(repl)
        let part = substitute(part, sub, repl, '')  " apply substitution as requested
        let query = strpart(query, strlen(group) + 1)  " skip over the group
      endwhile
      let idx = jdx  " resume after
    endif
    let output .= part
    let idx += 1
  endwhile
  let head = input[0] =~# '[''"]' ? '\(\<[frub]\+\)\?' : ''  " see add_delims()
  let head = search && &l:filetype ==# 'python' ? head : ''  " see add_delims()
  return head . output
endfunction

" Helper functions for initiating delimiter surround
" Note: Get the script-local name of opfunc() by sending <Plug>Ysurround<Esc>
" which consumes v:count, so have to send count as input argument.
" Note: Use <CSI> for custom vim-surround delimiter since encoded as single byte
" sequence and impossible to use manually. Previously used \1 but this is equivalent
" to <C-a> and want to keep support for delimiters defined by control sequences.
function! s:feed_repeat(keys, ...) abort
  let cmd = 'call repeat#set("\' . a:keys . '", ' . (a:0 ? a:1 : v:count) . ')'
  call feedkeys(exists('*repeat#set') ? "\<Cmd>" . cmd . "\<CR>" : '', 'n')
endfunction
function! s:feed_surround(text) abort
  let nr = char2nr("\<CSI>") | let b:['surround_' . nr] = a:text
  call feedkeys("\<CSI>", 't')
endfunction
function! succinct#setup_insert() abort  " reset insert-mode undo
  if exists('*edit#insert_undo') | return edit#insert_undo() | endif
  return "\<C-g>u"
endfunction
function! succinct#setup_motion() abort  " reset buffer variables
  unlet! b:succinct_change b:succinct_delete b:surround_{char2nr("\<CSI>")}
  return "\<Plug>Ysurround\<Esc>"
endfunction
function! succinct#setup_operator(...) abort
  if v:operator !~? '^[cdy]$' | return '' | endif
  return "\<Plug>" . toupper(v:operator) . (a:0 && a:1 ? 'S' : 's') . 'uccinct'
endfunction

"-----------------------------------------------------------------------------"
" Insert and change snippets and delimiters {{{1
"-----------------------------------------------------------------------------"
" Restore indentation and remove trailing whitespace for multi-line results
" Note: Previously inserted indentations manually but now override vim-surround
" indentation explicitly (see try-finally group). This is more extensible and
" easier to combine and maintain consistency with change/delete algorithms and
" visual-mode <C-s><CR> style of adding newlines.
function! succinct#post_process(...) abort
  let [line1, line2] = a:0 ? a:000 : [line("'['"), line("']'")]
  if line1 == line2 | return | endif
  let winview = winsaveview()
  let auto = &lisp || &cindent || &smartindent  " auto indent properties
  let avail = !empty(&equalprg) || !empty(&indentexpr)  " normal mode equal
  let indent = get(s:, 'surround_indent', get(g:, 'surround_indent', 1))
  try
    if indent  " remove trailing
      keepjumps silent! exe line1 . ',' . line2 . 's/\s*$//g'
    endif
    if indent && (auto || avail)  " repair indentation
      keepjumps silent! exe 'normal! ' . line1 . 'gg=' . line2 . 'gg'
    endif
  finally
    if exists('s:surround_indent')  " restore previous value
      let b:surround_indent = s:surround_indent | exe 'unlet s:surround_indent'
    elseif exists('b:surround_indent')  " restore absence of value
      exe 'unlet b:surround_indent'
    endif
    call winrestview(winview)
  endtry
endfunction

" Surround text with delimiter using input opfunc type
" Note: Use two operator functions here, one setup function for queueing and sending
" to vim-surround and another as a thin wrapper tha simply calls vim-surround opfunc()
" then post-processes the result below.
function! succinct#surround_run(type) abort
  if exists('b:surround_indent')  " record default
    let s:surround_indent = b:surround_indent
  endif
  let b:surround_indent = 0  " override with manual approach
  let name = 'surround_' . char2nr("\<CSI>")  " see s:feed_surround()
  let text = split(get(b:, name, "\r"), "\r", 1)
  let [ibuf, line1, col1, off1] = getpos("'[")
  let [ibuf, line2, col2, off2] = getpos("']")
  if line2 < line1 || line2 == line1 && col2 < col1
    let [line1, col1, off1, line2, col2, off2] = [line2, col2, off2, line1, col1, off1]
  endif
  if a:type ==# 'line'  " e.g. 'vip' puts cursor on first column of last line
    let [line1, col1, line2, col2] = [line1, 1, line2, col([line2, '$'])]
  endif
  if line2 && col2 == col([line2, '$'])  " adjust bounds
    let line2 = col2 > 1 ? line2 : line2 - 1  " must come before
    let col2 = col2 > 1 ? col2 - 1 : col([line2, '$']) - 1  " must come after
    let b:[name] .= text[0] ==# text[-1] && text[0] =~# '^\n\+$' ? "\n" : ''
  endif
  call setpos("'[", [ibuf, line1, col1, off1])
  call setpos("']", [ibuf, line2, col2, off2])
  call call(s:surround_args[0], [a:type])  " native vim-surround function
  call succinct#post_process()
endfunction

" Generate visual and normal-mode delimiters
" Note: Here can use e.g. yss<CR> to surround the cursor line with empty lines without
" trailing whitespace, or e.g. ysib<CR><Key> or ysibm to convert a single-line
" parenthetical to indented multi-line block. Input counts will repeat the delimiter.
function! s:feed_motion(type, key, pad, cnt, ...)
  let [text1, text2] = s:get_surround(a:key, a:pad, 0, a:0 ? a:1 : 0)
  if empty(text1) && empty(text2) | setlocal operatorfunc= | return | endif
  let [text1, text2] = [repeat(text1, a:cnt), repeat(text2, a:cnt)]
  setlocal operatorfunc=succinct#surround_run
  let cmd = 'call succinct#surround_run(' . string(a:type) . ')'
  call feedkeys("\<Cmd>" . cmd . "\<CR>", 'n')  " runs vim-surround operator function
  call s:feed_surround(text1 . "\r" . text2)
  call s:feed_repeat('<Plug>SurroundRepeat\<CSI>', 1)  " see s:feed_surround()
endfunction
function! succinct#surround_motion(...) abort
  let s:surround_args = [&l:opfunc, v:count, a:0 ? a:1 : 0]  " capture surround.vim function
  setlocal operatorfunc=succinct#surround_init  " wrap surround.vim method
  let [init, motion] = a:0 > 2 ? a:000[1:] : ['', '']  " optional manual motion
  call feedkeys(init . 'g@' . motion, 'ni')
endfunction
function! succinct#surround_init(type) range abort
  let [opfunc, opcount, oparg] = s:surround_args
  if type(oparg)  " visual-mode argument passed manually
    let [mode, type, break] = ['v', oparg, oparg =~# '^[A-Z]']  " e.g. V not v
  else  " automatic opfunc argument provided by vim
    let [mode, type, break] = [max([opcount, 1]), a:type, oparg]
  endif
  let [key, pad, cnt] = s:get_target(mode, type, break)  " user input target
  call s:feed_motion(type, key, pad, cnt, break)
endfunction

" Generate insert mode delimiters and snippets
" Note: This permits e.g. <C-e><Space><Snippet> to surround with spaces or
" <C-e><CR><Snippet> to surround with newlines, similar to vim-surround.
function! s:feed_insert(key, pad, cnt) abort
  let [text1, text2] = s:get_surround(a:key, a:pad, 0)
  if empty(text1) && empty(text2) | return '' | endif
  let [text1, text2] = [repeat(text1, a:cnt), repeat(text2, a:cnt)]
  let name = text1 =~# '\n\s*$' && text2 =~# '^\s*\n' ? 'ISurround' : 'Isurround'
  let text1 = substitute(text1, '\n\s*$', '', 'g')
  let text2 = substitute(text2, '^\s*\n', '', 'g')
  call feedkeys("\<Plug>" . name, 'm')
  call s:feed_surround(text1 . "\r" . text2)  " see succinct#surround_init
endfunction
function! succinct#surround_insert() abort
  let [key, pad, cnt] = s:get_target('i')  " user input target
  call s:feed_insert(key, pad, cnt)
endfunction
function! succinct#snippet_insert() abort
  let [key, pad, cnt] = s:get_target(0)  " user input target
  call feedkeys(repeat(s:get_snippet(key, pad, 0), cnt), 'ti')
endfunction

" Capture and manipulate arbitrary left and right delimiters. This sets
" the mark 'z to the end of each delimiter, so use with e.g. lexpr='d`zx'.
" Note: Here use count as in vim-surround to identify nested exterior delimiters.
" Note the backwards search when on a delimiter will fail so loop should move
" outwards. Apply delimiters using succinct but processing input here
function! s:modify_replace(line1, col1, line2, col2, ...) abort
  let text1 = getline(a:line1) . "\n"
  let text2 = getline(a:line2) . "\n"
  let head = strcharpart(text1, 0, charidx(text1, a:col1 - 1))  " before open
  let tail = strcharpart(text2, charidx(text2, a:col2 - 1) + 1)  " after close
  let text = head . (a:0 ? a:1 : '') . tail  " e.g. line 'abc\n' col2 '4' empty
  let text .= empty(tail) ? getline(a:line2 + 1) . "\n" : ''  " extra line
  let [del1, del2] = [a:line1 + 1, a:line2 + empty(tail)]
  silent call deletebufline(bufnr(), del1, del2)
  let text = substitute(text, '\n$', '', 'g')  " ignore trailing newline
  let lines = split(text, "\n", 1)  " inserted lines
  silent call setline(a:line1, lines)
  return [a:line1, a:line1 + len(lines) - 1]
endfunction
function! succinct#modify_delims(left, right, ...) abort
  if a:0 > 1  " change delimiters
    let [repl1, repl2; rest] = a:000
  else  " delete delimiters
    let [repl1, repl2, rest] = ['', '', a:000]
  endif
  let [lnum, cnum] = [line('.'), col('.')]
  let args = [a:left, a:right, empty(rest) ? 1 : rest[0]]
  let [regex1, regex2, line11, col11, line21, col21] = call('succinct#get_delims', args)
  if line11 == 0 || line21 == 0 | return | endif
  let winview = winsaveview()
  call cursor(line11, col11)
  let [line12, col12] = succinct#search(regex1, 'cen')
  call cursor(line21, col21)
  let [line22, col22] = succinct#search(regex2, 'cen')
  let outside = lnum > line22 || lnum == line22 && cnum > col22
  let outside = outside || lnum < line11 || lnum == line11 && cnum < col11
  if outside | call winrestview(winview) | return | endif
  let [line21, line22] = s:modify_replace(line21, col21, line22, col22, repl2)
  let [line11, line12] = s:modify_replace(line11, col11, line12, col12, repl1)
  let line22 += (line12 - line12)  " in case newlines added
  call cursor(line11, col11)  " restore cursor position
  call succinct#post_process(line11, line22)
endfunction

" Change and delete arbitrary surrounding delimiters ( ( ( ( [ [ ] ] ) ) ) )
" Warning: Here fzf-selection invocation indicated by count of zero. Critical
" to return early or else cache applied by fzf sink function is overwritten
" Note: Native succinct does not record results of input delimiters so cannot
" repeat user-input results. This lets us hit '.' and keep the results.
" Note: Typing e.g. ds2b deletes the second bracket outside from cursor while
" typing e.g. 2dsb repeats the delete bracket command twice.
function! s:get_cached(mode, ...) abort  " cached replacement
  let search = a:0 ? a:1 : 0  " whether to search input
  let break = a:0 > 1 ? a:2 : 0  " whether to add line break
  let name = search ? 'succinct_delete' : 'succinct_change'
  if empty(get(b:, name, []))
    let [key, pad, cnt] = s:get_target(a:mode, '', break)
    if cnt <= 0 | return ['', '', 0] | endif
    let [text1, text2] = s:get_surround(key, pad, search, break)
    let b:[name] = [text1, text2, cnt]
  endif | return b:[name]
endfunction
function! succinct#delete_delims(count, break) abort
  let [text1, text2, cnt] = s:get_cached('d', 1, a:break)  " disable user input
  if empty(text1) || empty(text2) | return | endif
  let [dexpr, xexpr] = ['"_d`z', '"_x']
  for _ in range(a:count ? a:count : 1)
    call succinct#modify_delims(text1, text2, cnt)
  endfor
  call s:feed_repeat('<Plug>Dsuccinct', a:count)  " capital-S not needed
endfunction
function! succinct#change_delims(count, break) abort
  let [prev1, prev2, cnt] = s:get_cached('c', 1, a:break)  " disable user input
  if empty(prev1) || empty(prev2) | return | endif
  let [repl1, repl2, rep] = s:get_cached('C', 0)  " request user input
  if empty(repl1) || empty(repl2) | return | endif
  for _ in range(a:count ? a:count : 1)
    call succinct#modify_delims(prev1, prev2, repeat(repl1, rep), repeat(repl2, rep), cnt)
  endfor
  call s:feed_repeat('<Plug>Csuccinct', a:count)  " capital-S not needed
endfunction
