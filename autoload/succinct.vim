"-----------------------------------------------------------------------------"
" Navigate delimiters
"-----------------------------------------------------------------------------"
" Navigate delimeters  ( [ [ ( "  "  asd) sdf    ]  sdd   ]  as) h adfas)
" Todo: Consider using this insert-mode navigation algorithm elsewhere
" Warning: Cannot use search() because it fails to detect current column. Could
" use setpos() but then if fail to find delim that moves cursor. Also note cursor()
" fails in insert mode, even though 'current position' changes inside function.
function! s:find_delim(...) abort
  let name = 'delimitMate_matchpairs'
  let delims = get(b:, name, get(g:, name, &matchpairs))
  let delims = substitute(delims, '[:,]', '', 'g')
  let name = 'delimitMate_quotes'
  let quotes = get(b:, name, get(g:, name, "\" ' `"))
  let quotes = substitute(quotes, '\s\+', '', 'g')
  let regex = '[' . escape(delims . quotes, ']^-\') . ']'
  call search(regex, a:0 ? a:1 : 'e')
endfunction
function! s:goto_delim(lnum, cnum, lorig, corig) abort
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
function! succinct#prev_delim() abort
  let [lorig, corig] = [line('.'), col('.')]
  call s:find_delim('eb')
  if col('.') > corig - 2
    call s:find_delim('eb')
  endif
  return s:goto_delim(line('.'), col('.') + 1, lorig, corig)
endfunction
function! succinct#next_delim() abort
  let [lorig, corig] = [line('.'), col('.')]
  let [lfind, cfind] = [lorig, corig]
  if cfind == 1 | let lfind = max([1, lfind - 1]) | exe lfind | let cfind = col('$') | endif
  call cursor(lfind, cfind - 1)
  call s:find_delim('e')
  return s:goto_delim(line('.'), col('.') + 1, lorig, corig)
endfunction

" Search helper functions
" Note: Typically want '*' to include only traditional keywords but want surround
" and object opultions to include e.g. python method chains, vim scope identifiers,
" tex asterisk flags. Use this to temporarily modify iskeyword while searching.
let s:keyword_mods = {'python': '.', 'tex': '*', 'vim': ':'}
function! s:get_group(...) abort  " verify inside regex group
  if a:0 >= 2  " input line column
    let [lnum, cnum] = a:000
  elseif a:0 >= 1  " input line
    let [lnum, cnum] = [a:1, 1]
  else  " cursor position
    let [lnum, cnum] = [line('.'), col('.')]
  endif
  let expr = "synIDattr(synIDtrans(v:val), 'name')"
  let stack = map(synstack(lnum, cnum), expr)
  return empty(stack) ? [] : [stack[0]]
endfunction
function! s:get_pos(...) abort
  let cmd = a:0 > 3 ? 'searchpairpos' : 'searchpos'
  let mods = get(s:keyword_mods, &l:filetype, '')
  let mods = empty(mods) ? '' : ',' . join(split(mods, '\zs'), ',')
  let keys = &l:iskeyword
  let &l:iskeyword = keys . mods
  try
    let [lnum, cnum] = call(cmd, a:000)
  finally
    let &l:iskeyword = keys
  endtry
  return [lnum, cnum]
endfunction

" Search for identical items and distinct item pairs
" Note: Here searchpairpos(..., 'b') goes to the start of the first delimiter and
" searchpairpos(..., '') goes to the start of the second delimiter.
" Warning: Here searchpairpos(..., 'bc') fails if the cursor is anywhere on a closing
" delimiter and searchpairpos(..., 'c') fails if the cursor is on the first character
" of an opening delimiter or after the first character of a closing delimiter.
function! succinct#search_pairs(left, right, count) abort
  let lnum = line('.')  " prefer matches on current line
  let [line1, col11] = s:get_pos(a:left, '', a:right, 'nbcW')
  let [line2, col21] = s:get_pos(a:left, '', a:right, 'ncW')
  if line1 && !line2 || line1 == lnum && line2 != lnum  " could be on head of open or tail of close
    call cursor(line1, col11) | normal! l
    let [line2, col21] = s:get_pos(a:left, '', a:right, 'ncW')
  endif
  if line2 && !line1 || line2 == lnum && line1 != lnum  " could be somewhere on closing delimiter
    call cursor(line2, col21) | normal! h
    let [line1, col11] = s:get_pos(a:left, '', a:right, 'nbcW')
  endif
  call cursor(line1, col11)  " 'bnW' and 'cnW' will deliberately fail
  for idx in range(2, a:count)  " additional matches beyond current one
    let [line1, col11] = s:get_pos(a:left, '', a:right, 'nbW')
    let [line2, col21] = s:get_pos(a:left, '', a:right, 'ncW')
    call cursor(line1, col11)  " then searches will go beyond cursor
  endfor
  return [line1, col11, line2, col21]
endfunction
function! succinct#search_items(left, right, count) abort
  let keys1 = &l:iskeyword
  let keys2 = &l:filetype ==# 'vim' ? keys1 . ',:' : keys1
  let [lnum, cnum] = [line('.'), col('.')]
  for idx in range(a:count)  " select outer items
    let flags = idx == 0 ? 'bcW' : 'bW'  " include object under cursor *first*
    let [line1, col11] = s:get_pos(a:left, flags)
  endfor
  call cursor(line1, col11)
  for idx in range(a:count)  " select outer items
    let flags = 'W'  " exclude object under cursor
    let [line2, col21] = s:get_pos(a:left, flags)
  endfor
  if a:left =~# '[''"]'  " additional syntax check
    let groups = s:get_group(line1, col11) + s:get_group(line2, col21)
    let inner = line2 > line1 ? range(line1 + 1, line2 - 1) : []
    for inum in inner | call extend(groups, s:get_group(inum)) | endfor
    let groups = uniq(sort(groups))  " unique syntax groups
    if len(groups) > 1 | return [0, 0, 0, 0] | endif
  endif
  return [line1, col11, line2, col21]
endfunction

"-----------------------------------------------------------------------------
" Register snippets, delimiters, and objects
"-----------------------------------------------------------------------------
" Get surround delimiters and associated text object
" Note: Support defining vim-surround delimiters with unescaped \r \n \1
" etc. for convenience (e.g. working with heavily backslashed delimiters).
" Note: This additionally filters to ensure we are capturing e.g. multi-line string
" instead of content between strings. Note e.g. bash $variables and python {format}
" indicators have the lowest-level syntax group 'Constant' so this still works.
function! succinct#get_delims(left, right, count) abort
  let atom = '\(\\_\)\?\(\\(.\+\\)\|\[.\+\]\|\\\?.\)'  " \(\), [], \x, or characters
  let opts = '\(\\[?=]\|\\\@<!\*\)'  " optional-length \? or * indicators
  let check1 = substitute(a:left, atom . opts, '', 'g')  " remove optional groups
  let check2 = substitute(a:right, atom . opts, '', 'g')  " remove optional groups
  let winview = winsaveview()
  let [lnum, cnum] = [line('.'), col('.')]
  if check1 !=# check2  " searchpairpos() is possible (distinct delimiters)
    let [line1, col11, line2, col21] = succinct#search_pairs(a:left, a:right, a:count)
  else  " searchpairpos() not possible (can fail e.g. for docstrings)
    let [line1, col11, line2, col21] = succinct#search_items(a:left, a:right, a:count)
  endif
  if line1 == 0 || line2 == 0  " search failed
    call winrestview(winview) | return [0, 0, 0, 0]
  else  " search succeeded
    return [line1, col11, line2, col21]
  endif
endfunction
function! succinct#get_object(mode, delim, ...) abort
  let [delim1, delim2] = [a:delim, a:0 ? a:1 : a:delim]
  let delim1 = substitute(delim1, '\\[?=]', '', 'g')
  let delim2 = substitute(delim2, '\\[?=]', '', 'g')
  let delim1 = substitute(delim1, '\*$', '\\+', 'g')  " avoid process_value() [.*] atom
  let delim2 = substitute(delim2, '\*$', '\\+', 'g')  " avoid process_value() [.*] atom
  let [line1, col1, line2, col2] = succinct#get_delims(delim1, delim2, v:count1)
  if line1 == 0 || line2 == 0 | return | endif
  call cursor(line1, col1)
  if a:mode ==# 'i'
    call search(delim1 . '\_s*\(' . delim1 . '\)\@!\S', 'ceW')
  endif
  let pos1 = getpos('.')
  call cursor(line2, col2) | call search(delim2, 'ceW')
  if a:mode ==# 'i'
    call search('\(' . delim2 . '\)\@!\S\_s*' . delim2, 'cbW')
  endif
  let pos2 = getpos('.')
  return ['v', pos1, pos2]
endfunction

" Translate delimiters to text object declarations
" Note: Have to use literals instead of e.g. assigning s:[name] = function() since
" vim-textobj-user calls with function(a:name)() which fails unless defined literally.
" Note: Here 'select-[ai]' point to textobj#user#select_pair and searchpairpos() while
" 'select' points to textobj#user#select and searchpos(..., 'c'). This fails for 'a'
" objects that overlap with others on line (e.g. ya' -> '.\{-}' may go outside the
" closest quotes, but '\zs.\{-}\ze' will not). So now use function definition instead.
let s:literals = {
  \ '1': "\1", '2': "\2", '3': "\3", '4': "\4", '5': "\5",
  \ '6': "\6", '7': "\7", 'r': "\r", 'n': "\n", '\t': "\t",
\ }
function! s:get_surround(arg) abort
  let opts = type(a:arg) == 1 ? s:literals : {}
  let output = type(a:arg) == 1 ? a:arg : ''
  for [char, repl] in items(opts)
    let check = char2nr(repl) > 7 ? '\a\@!' : ''
    let output = substitute(output, '\\' . char . check, repl, 'g')
  endfor
  return empty(output) ? a:arg : output
endfunction
function! succinct#translate_delims(plugin, key, arg, ...) abort
  let head = a:0 && a:1 ? '<buffer> ' : ''
  let args = [s:get_surround(a:arg), 1] + a:000[1:]
  let delim = call('succinct#process_value', args)
  if count(delim, "\r") != 1 | return {} | endif
  let [delim1, delim2] = split(delim, "\r")
  let name = 'textobj_' . a:plugin . '_' . char2nr(a:key)
  let code = [
    \ 'function! s:' . name . '_i() abort',
    \ '  return succinct#get_object("i", ' . string(delim1) . ', ' . string(delim2) . ')',
    \ 'endfunction',
    \ 'function! s:' . name . '_a() abort',
    \ '  return succinct#get_object("a", ' . string(delim1) . ', ' . string(delim2) . ')',
    \ 'endfunction'
  \ ]
  exe join(code, "\n")
  let obj = {
    \ 'sfile': expand('<script>:p'),
    \ 'select-i': head . 'i' . escape(a:key, '|'),
    \ 'select-a': head . 'a' . escape(a:key, '|'),
    \ 'select-i-function': 's:' . name . '_i',
    \ 'select-a-function': 's:' . name . '_a',
  \ }
  let objs = {}
  let objs[name] = obj
  return objs
endfunction

" Register text object plugins and define surround and snippet variables
" Note: Use ad-hoc approach for including python string headers instead of relying
" on user so that built-in change-delim and delete-delim commands that rely on
" buffer and global surround variables still include header, but without including
" regex for built-in visual, insert, and motion based vim-surround insertions.
function! succinct#add_snippets(source, ...) abort
  let scope = a:0 && a:1 ? b: : g:
  let snippets = {}  " for user reference
  for key in keys(a:source)  " funcref cannot be lower case so iterate keys
    let name = 'snippet_' . char2nr(key)
    let scope[name] = s:get_surround(a:source[key])
    let snippets[key] = scope[name]
  endfor
  return snippets
endfunction
function! succinct#add_delims(source, ...) abort
  let scope = a:0 && a:1 ? b: : g:
  let delims = {}
  for key in keys(a:source)  " funcref cannot be lower case so iterate keys
    let name = 'surround_' . char2nr(key)
    let scope[name] = s:get_surround(a:source[key])
    let delims[key] = scope[name]
  endfor
  let plugin = a:0 && a:1 ? &l:filetype : 'global'  " plugin name
  let plugin = substitute(plugin, '\A', '', 'g')  " alpahbetic required
  let plugin = substitute(plugin, '\(\u\)', '\l', 'g')  " lower-case required
  call call('succinct#add_objects', [plugin, a:source] + a:000)
  return delims
endfunction
function! succinct#add_objects(plugin, source, ...) abort
  let name = substitute(a:plugin, '^\(\l\)', '\u\1', 0)
  let cmd = 'Textobj' . name . 'DefaultKeyMappings'
  if !exists('*textobj#user#plugin')  " see: https://vi.stackexchange.com/a/14911/8084
    runtime autoload/textobj/user.vim
    if !exists('*textobj#user#plugin')  " plugin not available
      echohl WarningMsg
      echom 'Warning: Cannot define text objects (vim-textobj-user not found).'
      echohl None | return {}
    endif
  endif
  if exists(':' . cmd) | return {} | endif
  let defaults = a:0 > 1 ? a:2 : 0
  let objects = {}
  for key in keys(a:source)
    if defaults  " check existing maps
      let outer = maparg('a' . key, 'o')
      let inner = maparg('i' . key, 'o')
      if !empty(outer) || !empty(inner) | continue | endif
    endif
    if type(a:source[key]) != 1
      echohl WarningMsg
      echom "Warning: Cannot add key '" . key . "' as text object (non-string type)."
      echohl None | continue
    endif
    let args = [a:plugin, key, a:source[key], a:0 ? a:1 : 0]
    call extend(args, a:000[2:])
    let objs = call('succinct#translate_delims', args)
    call extend(objects, objs)
  endfor
  call textobj#user#plugin(a:plugin, objects)  " enforces lowercase alphabet
  exe cmd . '!' | return objects
endfunction

"-----------------------------------------------------------------------------
" Select templates, snippets, and delimiters
"-----------------------------------------------------------------------------
" Find and read from template files
" Note: See below for more on fzf limitations.
function! s:template_sink(file) abort
  if exists('g:succinct_templates_path') && !empty(a:file)
    let templates = expand(g:succinct_templates_path)
    let path = templates . '/' . a:file
    execute '0r ' . path | doautocmd BufRead
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

" Find and use delimiters and snippets
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
  if a:mode =~# '^[ydc]$'  " e.g. ys, ds, cs maps which do not use operator pending
    call feedkeys(a:mode . 's' . key, 't')
  else  " e.g. <Plug>Isurround and <Plug>Vsurround
    call feedkeys("\<Plug>" . a:mode . 'surround' . key, 'ti')
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
  noautocmd call fzf#run({
    \ 'sink': function('s:snippet_sink'),
    \ 'source': s:variable_source('snippet'),
    \ 'options': '--no-sort --height=100% --prompt="Snippet> "',
    \ })
endfunction
function! succinct#surround_select(mode) abort
  if !s:fzf_check() | return | endif
  noautocmd call fzf#run({
    \ 'sink': function('s:surround_sink', [a:mode]),
    \ 'source': s:variable_source('surround'),
    \ 'options': '--no-sort --height=100% --prompt="Surround> "',
    \ })
endfunction

"-----------------------------------------------------------------------------"
" Helper functions for processing snippets and delimiters
"-----------------------------------------------------------------------------"
" Get and parse user-input delimiter key and spaces
" Note: This permits typing arbitrary numbers to select outer delimiters, e.g. 2b
" for the second ensted parentheses, and aribtrary spaces for padding the end of
" the first delimiter and start of the second delimiter (see s:post_process)
function! s:get_char() abort
  let char = getchar()  " returns number only if successful translation
  let char = string(char) =~# '^\d\+$' ? nr2char(char) : char
  return char
endfunction
function! s:get_target(snippet) abort
  let [cnt, pad] = ['', '']
  let key = s:get_char()
  let head = a:snippet ? 'snippet_' : 'surround_'
  let name = head . char2nr(key)
  if !has_key(b:, name) && !has_key(g:, name)  " allow e.g. '1' delimiters
    while key =~# '^\d\+$'
      let cnt .= key  " user is providing count
      let key = s:get_char()
    endwhile
    while key =~# '\_s\|\r'
      let pad .= key =~# '\r' ? "\n" : key  " user is providing padding
      let key = s:get_char()
    endwhile
  endif
  let key = key =~# '\p' ? key : ''
  let cnt = empty(cnt) || cnt ==# '0' ? 1 : str2nr(cnt)
  return [key, pad, cnt]
endfunction

" Get and process user-input delimiter, combining spaces and counts
" Note: Unlike vim-surround this permits passing whitespace in arbitrary vim-surround
" modes with e.g. ysiw<CR>b, viw<C-s><CR>b, cs<CR>rb, csr<CR>b, ds<CR>b, or a<C-s><CR>b
" and result is always be the same. Note that 'cs<CR><Key>' remove newlines and any
" leading/trailing whitespace while 'cs<Key><CR>' adds newlines. This also supports
" passing spaces and/or counts to pad and/or repeat delimiters e.g. ysiw2<Space>b.
function! s:get_cached(search, ...) abort
  let target = get(b:, 'succinct_target', [])
  let replace = get(b:, 'succinct_replace', [])
  if a:search && !empty(target)
    let parts = target
  elseif !a:search && !empty(replace)
    let parts = replace
  else  " user-input
    let parts = call('s:get_value', [0, a:search] + a:000)
  endif
  if a:search  " target value
    let b:succinct_target = parts
  else  " replace value
    let b:succinct_replace = parts
  endif
  return parts
endfunction
function! s:get_value(snippet, search, ...) abort
  let [key, pad, cnt] = s:get_target(a:snippet)  " user input target
  let pad .= a:0 && a:1 ? "\n" : ''  " e.g. 'yS' instead of 'ys'
  if a:snippet
    let [head, value] = ['snippet', '']
  else
    let [head, value] = ['surround', empty(key) ? key : key . "\r" . key]
  endif
  let name = head . '_' . char2nr(key)  " note char2nr('') == 0
  let text = succinct#process_value(get(b:, name, get(g:, name, value)), a:search)
  if empty(text)  " e.g. empty 'key', empty 'surround_{key}', or input cancellation
    return a:snippet ? ['', cnt] : ['', '', cnt]
  endif
  if a:snippet
    let [part1, part2] = ['', text]
  else
    let [part1, part2] = split(text, "\r", 1)
  endif
  if a:search  " convert e.g. literal '\n  ' to regex '\_s*'
    let [pad1, pad2] = [s:search_value(pad), s:search_value(pad)]
  else  " e.g. <Space><CR><Cursor><CR><Space>
    let [pad1, pad2] = [pad, join(reverse(split(pad, '\zs')), '')]
  endif
  if &l:filetype ==# 'tex' && pad1 =~# '^\s*\n' && part1 =~# '{$'
    let part1 = part1 . '%'
  endif
  if a:snippet
    return [part1 . pad1 . pad2 . part2, cnt]
  else
    return [part1 . pad1, pad2 . part2, cnt]
  endif
endfunction

" Process delimiter or snippet value. If a:search is true return regex suitable for
" *searching* for delimiters with searchpair(), else return delimiters themselves.
" Note: This was adapted from vim-surround/plugin/surround.vim. Note is critical to
" escape characters one-by-one or \r\r groups inside user-input delimiters are caught.
function! s:search_value(value, ...) abort  " escape regular expressions and allow indents
  let value = a:0 && a:1 ? a:value : escape(a:value, '[]\.*~^$')
  let value = substitute(value, '\_s\+', '\\_s*', 'g')
  return value
endfunction
function! succinct#process_value(value, ...) abort
  " Acquire user-input for placeholders \1, \2, \3, ...
  let search = a:0 ? a:1 : 0  " whether to perform search
  let input = type(a:value) == 2 ? a:value() : a:value  " string or funcref
  let head = input[0] =~# '[''"]' ? '\(\<[frub]\+\)\?' : ''  " see add_delims()
  let head = search && &l:filetype ==# 'python' ? head : ''  " see add_delims()
  if empty(input) | return '' | endif  " e.g. funcref that starts asynchronous fzf
  for nr in range(7)
    let idx = matchstr(input, nr2char(nr) . '.\{-\}\ze' . nr2char(nr))
    if !empty(idx)  " \1, \2, \3, ... found inside string
      if !search  " acquire user-input values
        let idx = substitute(strpart(idx, 1), '\r.*', '', '')
        let repl_{nr} = input(match(idx, '\w\+$') >= 0 ? idx . ': ' : idx)
      else " search possible user-input values
        let regex = '\<\k\+'  " see s:search_item() for iskeyword modifications
        let repl_{nr} = regex
      endif
    endif
  endfor
  " Replace inner regions with user input result
  let idx = 0
  let output = ''
  while idx < strlen(input)
    let char = strpart(input, idx, 1)
    let jdx = char2nr(char) > 7 ? -1 : stridx(input, char, idx + 1)
    if jdx == -1  " match individual character
      let args = [char] + a:000[1:]  " additional configuration
      let part = !search ? char : call('s:search_value', args)
    else  " replace \1, \2, \3, ... with user input using inner text as prompt
      let part = repl_{char2nr(char)}  " defined above
      let query = strpart(input, idx + 1, jdx - idx - 1)  " query between \1...\1
      let query = matchstr(query, '\r.*')  " substitute initiation indication
      while query =~# '^\r.*\r'
        let group = matchstr(query, "^\r\\zs[^\r]*\r[^\r]*")  " match replace group
        let sub = strpart(group, 0, stridx(group, "\r"))  " the substitute
        let repl = strpart(group, stridx(group, "\r") + 1)  " the replacement
        let repl = !search ? repl : s:search_value(repl)
        let part = substitute(part, sub, repl, '')  " apply substitution as requested
        let query = strpart(query, strlen(group) + 1)  " skip over the group
      endwhile
      let idx = jdx  " resume after
    endif
    let output .= part
    let idx += 1
  endwhile
  return head . output
endfunction

" Helper functions for normal-mode mappings
" Note: Use two operator functions here, one setup function for queueing and sending
" to vim-surround and another as a thin wrapper tha simply calls vim-surround opfunc()
" then post-processes the result. Get the script-local name of opfunc() by sending
" <Plug>Ysurround<Esc> which consumes v:count, so send count as input argument.
function! succinct#surround_setup() abort
  silent! exe 'unlet b:surround_1'
  let b:succinct_target = [] | let b:succinct_replace = []
  return "\<Plug>Ysurround\<Esc>" . v:count1
endfunction
function! succinct#surround_repeat(type) abort
  if exists('b:surround_indent')  " record default
    let s:surround_indent = b:surround_indent
  endif
  let b:surround_indent = 0  " override with manual approach
  let opfunc = s:surround_args[0]
  call call(opfunc, [a:type])  " native vim-surround function
  call s:post_process()
endfunction
function! succinct#surround_start(type) range abort
  let [opfunc, opcount, oparg] = s:surround_args
  if type(oparg)  " visual-mode argument passed manually
    let [break, type] = [oparg =~# '^[A-Z]', oparg]  " e.g. V not v
  else  " automatic opfunc argument provided by vim
    let [break, type] = [oparg, a:type]
  endif
  let [delim1, delim2, cnt] = s:get_value(0, 0, break)
  if empty(delim1) && empty(delim2)  " padding not applied if delimiter not passed
    let &l:operatorfunc = '' | return
  endif
  let cnt *= max([opcount, 1])  " after motion or before 'ys'
  let [delim1, delim2] = [repeat(delim1, cnt), repeat(delim2, cnt)]
  let b:surround_1 = delim1 . "\r" . delim2  " final processed delimiters
  setlocal operatorfunc=succinct#surround_repeat
  let cmd = "\<Cmd>call succinct#surround_repeat(" . string(a:type) . ")\<CR>"
  call feedkeys(cmd, 'n')  " runs vim-surround operator function
  call feedkeys("\1", 't')  " force vim-surround to read b:surround_1
  call s:feed_repeat('<Plug>SurroundRepeat' . "\1", 1)  " count already applied
endfunction

"-----------------------------------------------------------------------------"
" Insert and change snippets and delimiters
"-----------------------------------------------------------------------------"
" Restore indentation and remove trailing whitespace for multi-line results
" Note: Previously inserted indentations manually but now override vim-surround
" indentation explicitly (see try-finally group). This is more extensible and
" easier to combine and maintain consistency with change/delete algorithms and
" visual-mode <C-s><CR> style of adding newlines.
function! s:post_process(...) abort
  let auto = &lisp || &cindent || &smartindent  " auto indent properties
  let avail = !empty(&equalprg) || !empty(&indentexpr)  " normal mode equal
  let indent = get(s:, 'surround_indent', get(g:, 'surround_indent', 1))
  let [line1, line2] = a:0 ? a:000 : [line("'['"), line("']'")]
  try
    if line1 != line2  " remove whitespace
      keepjumps silent exe line1 . ',' . line2 . 's/\s*$//g'
    endif
    if line1 != line2 && indent && (auto || avail)  " repair indentation
      keepjumps silent exe 'normal! ' . line1 . 'gg=' . line2 . 'gg'
    endif
  finally
    if exists('s:surround_indent')  " restore previous value
      let b:surround_indent = s:surround_indent | exe 'unlet s:surround_indent'
    elseif exists('b:surround_indent')  " restore absence of value
      exe 'unlet b:surround_indent'
    endif
  endtry
endfunction

" Capture and manipulate arbitrary left and right delimiters. This sets
" the mark 'z to the end of each delimiter, so use with e.g. lexpr='d`zx'.
" Note: Here use count as in vim-surround to identify nested exterior delimiters.
" Note the backwards search when on a delimiter will fail so loop should move
" outwards. Apply delimiters using succinct but processing input here
function! s:feed_repeat(keys, ...) abort
  if !exists('*repeat#set') | return | endif
  let cmd = 'call repeat#set("\' . a:keys . '", ' . (a:0 ? a:1 : v:count) . ')'
  call feedkeys("\<Cmd>" . cmd . "\<CR>", 'n')
endfunction
function! s:expr_delims(left, right, lexpr, rexpr, ...) abort
  let args = [a:left, a:right, a:0 ? a:1 : 1]
  let [line1, col11, line2, col21] = call('succinct#get_delims', args)
  if line1 == 0 || line2 == 0 | return | endif
  call cursor(line2, col21)  " delete or change right delimiter
  let [line2, col22] = s:get_pos(a:right, 'cen')
  call setpos("'z", [0, line2, col22, 0])
  exe 'keepjumps normal! ' . a:rexpr
  let line2 = line("']")
  call cursor(line1, col11)  " delete or change left delimiter
  let [line1, col12] = s:get_pos(a:left, 'cen')
  call setpos("'z", [0, line1, col12, 0])
  exe 'keepjumps normal! ' . a:lexpr
  let line1 = line("'[")
  let line2 += count(a:lexpr, "\n")
  call s:post_process(line1, line2)
endfunction

" Generate insert, visual, and normal-mode delimiters
" Note: This permits e.g. <C-e><Space><Snippet> to surround with spaces or
" <C-e><CR><Snippet> to surround with newlines, similar to vim-surround.
" Note: Here can use e.g. yss<CR> to surround the cursor line with empty lines without
" trailing whitespace, or e.g. ysib<CR><Key> or ysibm to convert a single-line
" parenthetical to indented multi-line block. Input counts will repeat the delimiter.
function! succinct#surround_motion(...) abort
  let iargs = [&l:opfunc, v:count, a:0 ? a:1 : 0]  " capture surround.vim function
  setlocal operatorfunc=succinct#surround_start  " wrap surround.vim method
  let s:surround_args = iargs | return 'g@'
endfunction
function! succinct#snippet_insert() abort
  let [text, cnt] = s:get_value(1, 0)
  let snippet = empty(text) ? '' : repeat(text, cnt)
  return snippet  " permit repeating with count
endfunction
function! succinct#surround_insert() abort
  let [delim1, delim2, cnt] = s:get_value(0, 0)
  if empty(delim1) && empty(delim2) | return '' | endif
  let [delim1, delim2] = [repeat(delim1, cnt), repeat(delim2, cnt)]
  if delim1 =~# '\n\s*$' && delim2 =~# '^\s*\n'  " surround plugin
    let plug = "\<Plug>ISurround"
  else  " surround plugin
    let plug = "\<Plug>Isurround"
  endif
  let delim1 = substitute(delim1, '\n\s*$', '', 'g')
  let delim2 = substitute(delim2, '^\s*\n', '', 'g')
  let b:surround_1 = delim1 . "\r" . delim2  " see succinct#surround_start
  call feedkeys(plug, 'm') | call feedkeys("\1", 't') | return ''
endfunction

" Change and delete arbitrary surrounding delimiters ( ( ( ( [ [ ] ] ) ) ) )
" Note: Native succinct does not record results of input delimiters so cannot
" repeat user-input results. This lets us hit '.' and keep the results.
" Note: Typing e.g. ds2b deletes the second bracket outside from cursor while
" typing e.g. 2dsb repeats the delete bracket command twice.
function! succinct#delete_delims(count, break) abort
  let [delim1, delim2, cnt] = s:get_cached(1, a:break)  " disable user input
  if empty(delim1) || empty(delim2) | return | endif
  let expr1 = '"_d`z"_x'
  let expr2 = '"_d`z"_x'
  for _ in range(a:count ? a:count : 1)
    call s:expr_delims(delim1, delim2, expr1, expr2, cnt)
  endfor
  call s:feed_repeat('<Plug>Dsuccinct', a:count)  " capital-S not needed
endfunction
function! succinct#change_delims(count, break) abort
  let [prev1, prev2, cnt] = s:get_cached(1, a:break)  " disable user input
  if empty(prev1) || empty(prev2) | return | endif
  let [repl1, repl2, rep] = s:get_cached(0, a:break)  " request user input
  if empty(repl1) || empty(repl2) | return | endif
  let expr1 = '"_c`z' . repeat(repl1, rep) . "\<Delete>" . "x\<BS>"
  let expr2 = '"_c`z' . repeat(repl2, rep) . "\<Delete>"
  for _ in range(a:count ? a:count : 1)
    call s:expr_delims(prev1, prev2, expr1, expr2, cnt)
  endfor
  call s:feed_repeat('<Plug>Csuccinct', a:count)  " capital-S not needed
endfunction
