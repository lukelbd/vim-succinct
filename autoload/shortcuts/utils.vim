"-----------------------------------------------------------------------------"
" File template handling
"-----------------------------------------------------------------------------"
" Return list of templates
function! shortcuts#utils#template_source(ext) abort
  let paths = []
  if exists('g:shortcuts_templates_path')
    let paths = split(globpath(g:shortcuts_templates_path, '*.' . a:ext), "\n")
    let paths = map(paths, 'fnamemodify(v:val, ":t")')
  endif
  if !empty(paths)
    let paths = [''] + paths  " add stand-in for 'load nothing'
  endif
  return paths
endfunction

" Load template contents
function! shortcuts#utils#template_read(file)
  if exists('g:shortcuts_templates_path') && !empty(a:file)
    execute '0r ' . g:shortcuts_templates_path . '/' . a:file
  endif
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
" Shortcuts delimiter jumping is improved
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
function! shortcuts#utils#prev_delim() abort
  let [_, lorig, corig, _] = getpos('.')
  call search(s:delim_regex(), 'ebW')
  if col('.') > corig - 2 | call search(s:delim_regex(), 'ebW') | endif
  return s:move_cursor(line('.'), col('.') + 1, lorig, corig)
endfunction

" Move to right of next delim. Why starting from current position? Even if cursor is on
" delimiter, want to find it and move to the right of it
function! shortcuts#utils#next_delim() abort
  let [_, lorig, corig, _] = getpos('.')
  call search(s:delim_regex(), 'eW')
  return s:move_cursor(line('.'), col('.') + 1, lorig, corig)
endfunction

" Special popup menu behavior just for me and my .vimrc!
" No one has to know ;)
function! shortcuts#utils#pum_close() abort
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
" Selecting snippets and delimiters with FZF
"-----------------------------------------------------------------------------"
" Todo: Write this!
function! shortcuts#utils#pick_delim() abort
endfunction

" Todo: Write this!
function! shortcuts#utils#pick_snippet() abort
endfunction

"-----------------------------------------------------------------------------"
" Changing and deleting surrounding delim
"-----------------------------------------------------------------------------"
" Driver function that accepts left and right delims, and normal mode commands
" run from the leftmost character of left and right delims. This function sets
" the mark 'z to the end of each delim, so expression can be d`zx
" Todo: Support vim#repeat behavior like all other maps
" Note: Mark motion commands only work up until and excluding the mark, so
" make sure your command accounts for that!
function! s:pair_action(left, right, lexpr, rexpr, count) abort
  " Get positions for *start* of matches
  if !exists('*searchpairpos')  " older versions
    return
  endif
  for _ in range(a:count)
    " Find positions
    let [l1, c11] = searchpairpos(a:left, '', a:right, 'bnW')  " set '' mark at current location
    let [l2, c21] = searchpairpos(a:left, '', a:right, 'nW')
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
    let cnum = exists('b:shortcuts_searchdelim') ? b:shortcuts_searchdelim : getchar()
    let b:shortcuts_searchdelim = cnum
  else
    let cnum = exists('b:shortcuts_replacedelim') ? b:shortcuts_replacedelim : getchar()
    let b:shortcuts_replacedelim = cnum
  endif
  " Get delimiters
  if exists('b:surround_' . cnum)
    let string = b:surround_{cnum}
  elseif exists('g:surround_' . cnum)
    let string = g:surround_{cnum}
  else
    let string = nr2char(cnum) . "\r" . nr2char(cnum)
  endif
  let delims = shortcuts#process_delims(string, a:search)
  return split(delims, "\r")
endfunction

" Delete delims function
function! shortcuts#utils#delete_delims() abort
  let [left, right] = s:get_delims(1)  " disallow user input
  call s:pair_action(left, right, '"_d`z"_x', '"_d`z"_x', v:count1)
  if exists('*repeat#set')
    call repeat#set("\<Plug>ShortcutsDeleteDelims")
  endif
endfunction

" Change delims function, use input replacement text or existing mapped surround char
function! shortcuts#utils#change_delims() abort
  let [lold, rold] = s:get_delims(1)  " disallow user input
  let [lnew, rnew] = s:get_delims(0)  " replacement delims possibly with user input
  call s:pair_action(lold, rold, '"_c`z' . lnew . "\<Delete>", '"_c`z' . rnew . "\<Delete>", v:count1)
  if exists('*repeat#set')
    call repeat#set("\<Plug>ShortcutsChangeDelims")
  endif
endfunction

" Reset previous delimiter
function! shortcuts#utils#reset_delims() abort
  silent! unlet b:shortcuts_searchdelim b:shortcuts_replacedelim
  return ''
endfunction

"-----------------------------------------------------------------------------"
" Complex text objects
"-----------------------------------------------------------------------------"
" The leading comment character (with stripped whitespace)
function! s:comment_char()
  let string = substitute(&commentstring, '%s.*', '', '')
  return substitute(string, '\s\+', '', 'g')
endfunction

" Helper function returning lines
function! s:lines_helper(pnb, nnb) abort
  let start_line = a:pnb == 0 ? 1         : a:pnb + 1
  let end_line   = a:nnb == 0 ? line('$') : a:nnb - 1
  let start_pos = getpos('.') | let start_pos[1] = start_line
  let end_pos   = getpos('.') | let end_pos[1]   = end_line
  return ['V', start_pos, end_pos]
endfunction

" Blank line objects
function! shortcuts#utils#blank_lines() abort
  normal! 0
  let pnb = prevnonblank(line('.'))
  let nnb = nextnonblank(line('.'))
  if pnb == line('.') " also will be true for nextnonblank, if on nonblank
    return 0
  endif
  return s:lines_helper(pnb, nnb)
endfunction

" New and improved paragraphs
function! shortcuts#utils#nonblank_lines() abort
  normal! 0l
  let nnb = search('^\s*\zs$', 'Wnc') " the c means accept current position
  let pnb = search('^\ze\s*$', 'Wnbc') " won't work for backwards search unless to right of first column
  if pnb == line('.')
    return 0
  endif
  return s:lines_helper(pnb, nnb)
endfunction

" Uncommented lines objects
function! shortcuts#utils#uncommented_lines() abort
  normal! 0l
  let nnb = search('^\s*' . s:comment_char() . '.*\zs$', 'Wnc')
  let pnb = search('^\ze\s*' . s:comment_char() . '.*$', 'Wncb')
  if pnb == line('.')
    return 0
  endif
  return s:lines_helper(pnb, nnb)
endfunction

" Functions for current line
function! shortcuts#utils#current_line_a() abort
  normal! 0
  let head_pos = getpos('.')
  normal! $
  let tail_pos = getpos('.')
  return ['v', head_pos, tail_pos]
endfunction
function! shortcuts#utils#current_line_i() abort
  normal! ^
  let head_pos = getpos('.')
  normal! g_
  let tail_pos = getpos('.')
  let non_blank_char_exists_p = (getline('.')[head_pos[2] - 1] !~# '\s')
  return non_blank_char_exists_p ? ['v', head_pos, tail_pos] : 0
endfunction
