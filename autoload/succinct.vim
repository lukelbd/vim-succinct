"-----------------------------------------------------------------------------"
" Navigate simple delimiters
"-----------------------------------------------------------------------------"
" Find delimiter and navigate without triggering InsertLeave
" Note: This is used for insert-mode delimiter jumping maps
" Todo: Consider using this navigation algorithm elsewhere
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

" Navigate delimeters  ( [ [ ( "  "  asd) sdf    ]  sdd   ]  as) h adfas)
" Warning: Cannot use search() because it fails to detect current column. Could
" use setpos() but then if fail to find delim that moves cursor. Also note cursor()
" fails in insert mode, even though 'current position' changes inside function.
function! succinct#prev_delim() abort
  let [_, lorig, corig, _] = getpos('.')
  call s:find_delim('eb')
  if col('.') > corig - 2
    call s:find_delim('eb')
  endif
  let keys = s:goto_delim(line('.'), col('.') + 1, lorig, corig)
  return keys
endfunction
function! succinct#next_delim() abort
  let [_, lorig, corig, _] = getpos('.')
  let [lfind, cfind] = [lorig, corig]
  if cfind == 1
    let lfind = max([1, lfind - 1]) | exe lfind
    let cfind = col('$')
  endif
  call cursor(lfind, cfind - 1)
  call s:find_delim('e')
  let keys = s:goto_delim(line('.'), col('.') + 1, lorig, corig)
  return keys
endfunction

" Get the fzf.vim/autoload/fzf/vim.vim script id for overriding. This is also used
" in dotfiles to override fzf marks command and support jumping to existing tabs.
" See: https://stackoverflow.com/a/49447600/4970632
function! succinct#get_snr(regex, ...) abort
  silent! call fzf#vim#with_preview()  " trigger autoload if not already done
  let [paths, sids] = succinct#get_scripts(1)
  let path = filter(copy(paths), 'v:val =~# a:regex')
  let idx = index(paths, get(path, 0, ''))
  if !empty(path) && idx >= 0
    return "\<snr>" . sids[idx] . '_'
  elseif a:0 && a:1  " optionally suppress warning
    return ''
  else  " emit warning
    echohl WarningMsg
    echom "Warning: Autoload script '" . a:regex . "' not found."
    echohl None | return ''
  endif
endfunction
function! succinct#get_scripts(...) abort
  let suppress = a:0 > 0 ? a:1 : 0
  let regex = a:0 > 1 ? a:2 : ''
  let [paths, sids] = [[], []]  " no dictionary because confusing
  for path in split(execute('scriptnames'), "\n")
    let sid = substitute(path, '^\s*\(\d*\):.*$', '\1', 'g')
    let path = substitute(path, '^\s*\d*:\s*\(.*\)$', '\1', 'g')
    let path = fnamemodify(resolve(expand(path)), ':p')  " then compare to home
    if !empty(regex) && path !~# regex
      continue
    endif
    call add(paths, path)
    call add(sids, sid)
  endfor
  if !suppress | echom 'Script names: ' . join(paths, ', ') | endif
  return [paths, sids]
endfunction

"-----------------------------------------------------------------------------
" Register snippets and delimiters
"-----------------------------------------------------------------------------
" Add surround and snippet variables
" Warning: Funcref cannot be assigned as local variable so do not iterate over items()
" Note: Use ad-hoc approach for including python string headers instead of relying
" on user so that built-in change-delim and delete-delim commands that rely on
" buffer and global surround variables still include header, but without including
" regex for built-in visual, insert, and motion based vim-surround insertions.
let s:literals = {
  \ 'r': "\r", 'n': "\n", '0': "\0", '1': "\1", '2': "\2",
  \ '3': "\3", '4': "\4", '5': "\5", '6': "\6", '7': "\7",
\ }
function! s:parse_input(arg) abort
  let opts = type(a:arg) == 1 ? s:literals : {}
  let output = type(a:arg) == 1 ? a:arg : ''
  for [char, repl] in items(opts)
    let check = char2nr(repl) > 7 ? '\w\@!' : ''
    let output = substitute(output, '\\' . char . check, repl, 'g')
  endfor
  return empty(output) ? a:arg : output
endfunction
function! succinct#add_snippets(source, ...) abort
  let scope = a:0 && a:1 ? b: : g:
  let snippets = {}  " for user reference
  for key in keys(a:source)  " funcref cannot be lower case so iterate keys
    let name = 'snippet_' . char2nr(key)
    let scope[name] = s:parse_input(a:source[key])
    let snippets[key] = scope[name]
  endfor
  return snippets
endfunction
function! succinct#add_delims(source, ...) abort
  let scope = a:0 && a:1 ? b: : g:
  let [delims, objects] = [{}, {}]
  for key in keys(a:source)  " funcref cannot be lower case so iterate keys
    let name = 'surround_' . char2nr(key)
    let scope[name] = s:parse_input(a:source[key])
    let delims[key] = scope[name]
  endfor
  for key in keys(a:source)
    if type(a:source[key]) != 1
      echohl WarningMsg
      echom "Warning: Cannot add key '" . key . "' as text object (non-string type)."
      echohl None | continue
    endif
    let objs = call('succinct#get_textobj', [key, a:source[key]] + a:000)
    call extend(objects, objs)
  endfor
  let plugin = a:0 && a:1 ? &l:filetype : 'global'
  let plugin = substitute(plugin, '[._-]', '', 'g')  " compound filetypes
  let command = substitute(plugin, '^\(\l\)', '\u\1', 0)  " command name
  if exists('*textobj#user#plugin')
    call textobj#user#plugin(plugin, objects)
    silent! exe 'Textobj' . command . 'DefaultKeyMappings!'
  endif
endfunction

" Translate delimiters to text object declarations
" Warning: Funcref delimiters below cannot be automatically translated to text objects
" Note: This figures out the required text object declaration based on uniqueness of
" left-right delimiters after removing group regexes. The finall approach is currently
" only needed for python docstring since searchpairpos() fails for identical delimiters
" and textobj#user workaround only supports single-character e.g. quote delimiters.
function! s:get_inside(...) abort  " verify inside regex group
  let [lnum, cnum] = [line('.'), col('.')]
  let expr = "synIDattr(synIDtrans(v:val), 'name')"
  let stack = map(synstack(lnum, cnum), expr)
  for item in a:000  " iterate over options
    if index(stack, item) != -1 | return 1 | endif
  endfor | return 0
endfunction
function! succinct#get_object(mode, delim, ...) abort
  let ldelim = a:delim
  let rdelim = a:0 ? a:1 : a:delim
  if !s:get_inside('Constant', 'Comment') | return | endif
  if !search(ldelim, 'bW') | return | endif
  if !s:get_inside('Constant', 'Comment') | return | endif
  if a:mode ==# 'a'
    let pos1 = getpos('.')  " jump to start of match
    call search(ldelim, 'eW')
  elseif a:mode ==# 'i'  " match first character after tripple quote
    call search(ldelim . '\_s*\zs', 'W')
    let pos1 = getpos('.')
  endif
  if !search(rdelim, 'eW') | return | endif  " ending quote not found
  if !s:get_inside('Constant', 'Comment') | return | endif
  if a:mode ==# 'i' | call search('\S\_s*' . rdelim, 'bW') | endif
  let pos2 = getpos('.')
  return ['v', pos1, pos2]
endfunction
function! succinct#get_textobj(key, arg, ...) abort
  let regex = '\(\\_\)\?\(\\(.\+\\)\|\[.\+\]\|\\\?.\)\(\\?\|\\\@<!\*\)'  " \(\) groups
  let [objs, flag] = [{}, a:0 && a:1 ? '<buffer> ' : '']
  let delim = succinct#process_value(s:parse_input(a:arg), 1)
  if count(delim, "\r") != 1 | return objs | endif
  let [delim1, delim2] = split(delim, "\r")
  let check1 = substitute(delim1, regex, '', 'g')  " remove \(\) groups
  let check2 = substitute(delim2, regex, '', 'g')  " remove \(\) groups
  let rcheck = substitute(check1, '\', '', 'g')  " e.g. escaped * * delimiters
  if check1 !=# check2  " distinct delimiters
    let name = 'textobj_' . char2nr(a:key)
    let objs[name] = {
      \ 'pattern': [delim1, delim2],
      \ 'select-a': flag . 'a' . escape(a:key, '|'),
      \ 'select-i': flag . 'i' . escape(a:key, '|'),
    \ }
  elseif len(rcheck) <= 1  " single-line identical delimiters
    let inner = 'textobj_' . char2nr(a:key) . '_i'
    let outer = 'textobj_' . char2nr(a:key) . '_a'
    let objs[inner] = {
      \ 'pattern': delim1 . '\zs.\{-}\ze' . delim2,
      \ 'select': flag . 'i' . escape(a:key, '|'),
    \ }
    let objs[outer] = {
      \ 'pattern': delim1 . '.\{-}' . delim2,
      \ 'select': flag . 'a' . escape(a:key, '|'),
    \ }
  else  " multi-line identical delimiters
    let code = [
      \ 'function! s:textobj_' . char2nr(a:key) . '_i() abort',
      \ '  return succinct#get_object("i", ' . string(delim1) . ', ' . string(delim2) . ')',
      \ 'endfunction',
      \ 'function! s:textobj_' . char2nr(a:key) . '_a() abort',
      \ '  return succinct#get_object("a", ' . string(delim1) . ', ' . string(delim2) . ')',
      \ 'endfunction'
    \ ]
    exe join(code, "\n")
    let plugin = 'textobj_' . char2nr(a:key)
    let objs[plugin] = {
      \ 'sfile': expand('<script>:p'),
      \ 'select-i': flag . 'i' . escape(a:key, '|'),
      \ 'select-a': flag . 'a' . escape(a:key, '|'),
      \ 'select-i-function': 's:textobj_' . char2nr(a:key) . '_i',
      \ 'select-a-function': 's:textobj_' . char2nr(a:key) . '_a',
    \ }
  endif
  return objs
endfunction

"-----------------------------------------------------------------------------
" Select templates, snippets, and delimiters
"-----------------------------------------------------------------------------
" Template source and sink
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
  if a:mode =~# '^[ydc]$'  " e.g. ys, ds, cs maps which do not use operator pending
    call feedkeys(a:mode . 's' . key, 't')
  else  " e.g. <Plug>Isurround and <Plug>Vsurround
    call feedkeys("\<Plug>" . a:mode . 'surround' . key, 'ti')
  endif
endfunction

" Fuzzy select functions
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
" Process snippets and delimiters
"-----------------------------------------------------------------------------"
" Get delimiter key and other properties
" Note: This permits typing arbitrary numbers to select outer delimiters, e.g. 2b
" for the second ensted parentheses, and aribtrary spaces for padding the end of
" the first delimiter and start of the second delimiter (see succinct#post_process)
function! s:get_char() abort
  let char = getchar()  " returns number only if successful translation
  let char = char =~# '^\d\+$' ? nr2char(char) : char
  return char
endfunction
function! s:get_target() abort
  let [cnt, pad] = ['', '']
  let key = s:get_char()
  while key =~# '^\d\+$'  " user is providing a count
    let cnt .= key
    let key = s:get_char()
  endwhile
  while key =~# '\_s\|\r'  " user is requesting padding
    let pad .= key =~# '\r' ? "\n" : key
    let key = s:get_char()
  endwhile
  let key = key =~# '\p' ? key : ''
  let cnt = empty(cnt) || cnt ==# '0' ? 1 : str2nr(cnt)
  return [key, pad, cnt]
endfunction
function! s:get_cached(search, ...) abort
  let target = get(b:, 'succinct_target', [])
  let replace = get(b:, 'succinct_replace', [])
  if a:search && !empty(target)
    let parts = target
  elseif !a:search && !empty(replace)
    let parts = replace
  else  " user-input
    let parts = call('succinct#process_result', [0, a:search] + a:000)
  endif
  if a:search  " target value
    let b:succinct_target = parts
  else  " replace value
    let b:succinct_replace = parts
  endif
  return parts
endfunction


" Obtain and process delimiters. If a:search is true return regex suitable for
" *searching* for delimiters with searchpair(), else return delimiters themselves.
" Note: This was adapted from vim-surround/plugin/surround.vim. Note is critical to
" escape characters one-by-one or \r\r groups inside user-input delimiters are caught.
function! s:regex_value(value) abort  " escape regular expressions and allow indents
  return substitute(escape(a:value, '[]\.*~^$'), '\_s\+', '\\_s*', 'g')
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
      if search  " search possible user-input values
        let regex = '\%(\k\|[:.*]\)'  " e.g. foo.bar() or \section*{} or s:function
        let repl_{nr} = regex . '\@<!' . regex . '\+'  " pick longest coherent match
      else  " acquire user-input values
        let idx = substitute(strpart(idx, 1), '\r.*', '', '')
        let repl_{nr} = input(match(idx, '\w\+$') >= 0 ? idx . ': ' : idx)
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
      let part = !search ? char : s:regex_value(char)
    else  " replace \1, \2, \3, ... with user input using inner text as prompt
      let part = repl_{char2nr(char)}  " defined above
      let query = strpart(input, idx + 1, jdx - idx - 1)  " query between \1...\1
      let query = matchstr(query, '\r.*')  " substitute initiation indication
      while query =~# '^\r.*\r'
        let group = matchstr(query, "^\r\\zs[^\r]*\r[^\r]*")  " match replace group
        let sub = strpart(group, 0, stridx(group, "\r"))  " the substitute
        let repl = strpart(group, stridx(group, "\r") + 1)  " the replacement
        let repl = !search ? repl : s:regex_value(repl)
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

" Process user-defined snippet (either fixed string or input with prefix/suffix)
" Note: Previously inserted indentations manually but now override with a separate
"  post-processing command. Generally gives more reliable results e.g. in python.
function! succinct#post_process(...) abort
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
function! succinct#process_result(snippet, search, ...) abort
  let [key, pad, cnt] = s:get_target()
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
  if a:0 && a:1 | let pad .= "\n" | endif
  if a:search  " convert e.g. literal '\n  ' to regex '\_s*'
    let [pad1, pad2] = [s:regex_value(pad), s:regex_value(pad)]
  else  " e.g. <Space><CR><Cursor><CR><Space>
    let [pad1, pad2] = [pad, reverse(pad)]
  endif
  if a:snippet
    return [part1 . pad1 . pad2 . part2, cnt]
  else
    return [part1 . pad1, pad2 . part2, cnt]
  endif
endfunction

"-----------------------------------------------------------------------------"
" Insert and change snippets and delimiters
"-----------------------------------------------------------------------------"
" Insert the requested snippet or delimiter
" Note: This permits e.g. <C-e><Space><Snippet> to surround with spaces or
" <C-e><CR><Snippet> to surround with newlines, similar to vim-surround.
" Note: Have to effectively use two operator functions here, one as the 'initial'
" function for queueing and sending to vim-surround (below) and another as a thin
" wrapper tha simply calls vim-surround opfunc() then post-processes the result.
function! s:feed_repeat(keys, ...) abort
  if !exists('*repeat#set') | return | endif
  let cmd = 'call repeat#set("' . a:keys . '", ' . (a:0 ? a:1 : v:count) . ')'
  call feedkeys("\<Cmd>" . cmd . "\<CR>", 'n')
endfunction
function! s:find_opfunc() abort
  let funcname = get(s:, 'surround_opfunc', '')
  if empty(funcname)  " attemp to assign
    let snr = succinct#get_snr('vim-surround/plugin/surround.vim', 1)
    let funcname = !empty(snr) && exists('*' . snr . 'opfunc') ? snr . 'opfunc' : ''
  endif
  let s:surround_opfunc = funcname | return funcname
endfunction
function! succinct#surround_delims(type) abort
  if exists('b:surround_indent')  " record default
    let s:surround_indent = b:surround_indent
  endif
  let b:surround_indent = 0  " override with manual approach
  let opfunc = s:find_opfunc()
  call call(opfunc, [a:type])  " native vim-surround function
  call succinct#post_process()
endfunction
function! succinct#surround_finish(type) range abort
  let [delim1, delim2, cnt] = succinct#process_result(0, 0, s:surround_break)
  setlocal operatorfunc=succinct#surround_delims  " '.' -> 'g@<motion>' -> here
  let cmd = "\<Cmd>call succinct#surround_delims(" . string(a:type) . ")\<CR>"
  echom 'Delimiters: ' . delim1 . ' ' . delim2
  if empty(delim1) && empty(delim2)  " padding not applied if delimiter not passed
    let &l:operatorfunc = '' | return
  endif
  let delims = repeat(delim1, cnt) . "\r" . repeat(delim2, cnt)
  let b:surround_1 = delims  " assign name that should never conflict with users
  call feedkeys(cmd, 'n')  " pass built-in operator function
  call feedkeys("\1", 't')  " force vim-surround to read b:surround_1
  if a:type =~? "v\\|\<C-v>"  " disable repeition
    call s:feed_repeat("\<Ignore>")
  else  " ensure repeition
    call s:feed_repeat("\<Plug>SurroundRepeat" . "\1")
  endif
endfunction

" Insert normal and visual mode delimiters
" Note: The surround.vim function s:insert() applies special settings including
" s:reindent() only for line-mode mapping ISurround not Isurround. So pass here.
" Note: Post-processing features allow using e.g. yss<CR> to easily surround the
" cursor line with empty lines without trailing whitespace, or e.g. ysib<CR><Key>
" or even ysibm to convert a single-line parenthetical to black-style parentheses.
function! succinct#reset_cache() abort
  silent! exe 'unlet b:surround_1'
  let b:succinct_target = []
  let b:succinct_replace = []
endfunction
function! succinct#snippet_insert() abort
  let [text, cnt] = succinct#process_result(1, 0)
  let value = empty(text) ? '' : repeat(text, cnt)
  return value  " insert mode typing
endfunction
function! succinct#surround_normal(break) abort
  let opfunc = s:find_opfunc()
  if empty(opfunc)  " revert to native method
    let name = a:break ? 'YSurround' : 'Ysurround'  " native plugin name
    return "\<Plug>" . name  " note Ysuccinct sends 'inner line' motion already
  else  " call override function after motion
    setlocal operatorfunc=succinct#surround_finish
    let s:surround_break = a:break | return 'g@'  " await operator motion
  endif
endfunction
function! succinct#surround_visual() abort
  let opfunc = s:find_opfunc()
  if empty(opfunc)  " revert to native method
    let keys = "\<Plug>VSurround"
    call feedkeys(keys, 'n')
  else  " call override after motion
    let s:surround_break = visualmode() ==# 'V'  " handle ourselves
    call succinct#surround_finish(visualmode())
  endif
endfunction
function! succinct#surround_insert() abort
  let [delim1, delim2, cnt] = succinct#process_result(0, 0)
  if empty(delim1) && empty(delim2) | return '' | endif
  let [delim1, delim2] = [repeat(delim1, cnt), repeat(delim2, cnt)]
  if delim1 =~# '\n\s*$' && delim2 =~# '^\s*\n'  " surround plugin
    let plug = "\<Plug>ISurround"
  else  " surround plugin
    let plug = "\<Plug>Isurround"
  endif
  let delim1 = substitute(delim1, '\n\s*$', '', 'g')
  let delim2 = substitute(delim2, '^\s*\n', '', 'g')
  let b:surround_1 = delim1 . "\r" . delim2  " see succinct#surround_finish
  call feedkeys(plug, 'm') | call feedkeys("\1", 't') | return ''
endfunction

" Run normal mode commands between leftmost character of left and right delims. This
" sets the mark 'z to the end of each delimiter, so expression can be e.g. d`zx
" Note: Here use count as in vim-surround to identify nested exterior delimiters.
" Note the backwards search when on a delimiter will fail so loop should move
" outwards. Apply delimiters using succinct but processing input here
function! s:modify_delims(left, right, lexpr, rexpr, ...) abort
  for _ in range(a:0 ? a:1 : 1)
    if a:left ==# a:right || a:left =~# '\\\@<!['  " python string headers
      let [l1, c11] = searchpos(a:left, 'bnW')
      let [l2, c21] = searchpos(a:right, 'nW')
    else  " set '' mark at current location
      let [l1, c11] = searchpairpos(a:left, '', a:right, 'bnW')
      let [l2, c21] = searchpairpos(a:left, '', a:right, 'nW')
    endif
    if !l1 || !l2 | return | endif
    call cursor(l1, c11)  " then searches will go beyond cursor
  endfor
  call cursor(l2, c21)  " delete or change right delimiter
  let [l2, c22] = searchpos(a:right, 'cen')
  call setpos("'z", [0, l2, c22, 0])
  keepjumps exe 'normal! ' . a:rexpr
  let line2 = line("']")
  call cursor(l1, c11)  " delete or change left delimiter
  let [l1, c12] = searchpos(a:left, 'cen')
  call setpos("'z", [0, l1, c12, 0])
  keepjumps exe 'normal! ' . a:lexpr
  let line1 = line("'[")
  let line2 += count(a:lexpr, "\n")
  call succinct#post_process(line1, line2)
endfunction

" Modify delimiters across normal mode expressions ( ( ( ( [  [  ] ] ) ) ) )
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
    call s:modify_delims(delim1, delim2, expr1, expr2, cnt)
  endfor
  call s:feed_repeat("\<Plug>Dsuccinct", a:count)  " capital-S not needed
endfunction
function! succinct#change_delims(count, break) abort
  let [prev1, prev2, cnt] = s:get_cached(1, a:break)  " disable user input
  if empty(prev1) || empty(prev2) | return | endif
  let [repl1, repl2, _] = s:get_cached(0, a:break)  " request user input
  if empty(repl1) || empty(repl2) | return | endif
  let expr1 = '"_c`z' . repl1 . "\<Delete>" . "x\<BS>"
  let expr2 = '"_c`z' . repl2 . "\<Delete>"
  for _ in range(a:count ? a:count : 1)
    call s:modify_delims(prev1, prev2, expr1, expr2, cnt)
  endfor
  call s:feed_repeat("\<Plug>Csuccinct", a:count)  " capital-S not needed
endfunction
