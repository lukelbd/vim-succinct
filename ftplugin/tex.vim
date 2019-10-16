"-----------------------------------------------------------------------------"
" Author: Luke Davis (lukelbd@gmail.com)
" Date:   2018-09-10
" LaTeX specific settings
"-----------------------------------------------------------------------------"
" Restrict concealmeant to just symbols and stuff
" a=accents/ligatures
" b=bold/italics
" d=delimiters (e.g. $$ math mode)
" m=math symbols
" g=Greek
" s=superscripts/subscripts
let g:tex_conceal = 'agm'

" Allow @ in makeatletter, allow texmathonly outside of math regions (i.e.
" don't highlight [_^] when you think they are outside math zone
let g:tex_stylish = 1

" Disable spell checking in verbatim mode and comments, disable errors
" let g:tex_fast = "" "fast highlighting, but pretty ugly
let g:tex_fold_enable = 1
let g:tex_comment_nospell = 1
let g:tex_verbspell = 0
let g:tex_no_error = 1

" Typesetting LaTeX and displaying PDF viewer
" Copied s:vim8 from autoreload/plug.vim file
let s:vim8 = has('patch-8.0.0039') && exists('*job_start')
let s:path = expand('<sfile>:p:h')
function! s:latex_background(...)
  if !s:vim8
    echom "Error: Latex compilation requires vim >= 8.0"
    return 1
  endif
  " Jump to logfile if it is open, else open one
  " WARNING: Trailing space will be escaped as a flag! So trim it unless
  " we have any options
  let opts = trim(a:0 ? a:1 : '') " flags
  if opts != ''
    let opts = ' ' . opts
  endif
  let texfile = expand('%')
  let logfile = expand('%:t:r') . '.log'
  let lognum = bufwinnr(logfile)
  if lognum == -1
    silent! exe string(winheight('.')/4) . 'split ' . logfile
    silent! exe winnr('#') . 'wincmd w'
  else
    silent! exe bufwinnr(logfile) . 'wincmd w'
    silent! 1,$d
    silent! exe winnr('#') . 'wincmd w'
  endif
  " Run job in realtime
  let num = bufnr(logfile)
  echom s:path . '/../latexmk'
  let g:tex_job = job_start(s:path . '/../latexmk ' . texfile . opts,
      \ { 'out_io': 'buffer', 'out_buf': num })
endfunction

" Latex compiling maps
command! -nargs=* Latexmk call s:latex_background(<q-args>)
noremap <silent> <buffer> <C-z> :call <sid>latex_background()<CR>
noremap <silent> <buffer> <Leader>z :call <sid>latex_background(' --diff')<CR>
noremap <silent> <buffer> <Leader>Z :call <sid>latex_background(' --word')<CR>

"-----------------------------------------------------------------------------"
" Text objects
"-----------------------------------------------------------------------------"
if exists('*textobj#user#plugin')
  " TeX plugin definitions
  " Copied from: https://github.com/rbonvall/vim-textobj-latex/blob/master/ftplugin/tex/textobj-latex.vim
  " so the names could be changed
  let s:tex_textobjs_dict = {
    \   'environment': {
    \     'pattern': ['\\begin{[^}]\+}.*\n', '\\end{[^}]\+}.*$'],
    \     'select-a': '<buffer> aT',
    \     'select-i': '<buffer> iT',
    \   },
    \  'command': {
    \     'pattern': ['\\\S\+{', '}'],
    \     'select-a': '<buffer> at',
    \     'select-i': '<buffer> it',
    \   },
    \  'paren-math': {
    \     'pattern': ['\\left(', '\\right)'],
    \     'select-a': '<buffer> a(',
    \     'select-i': '<buffer> i(',
    \   },
    \  'bracket-math': {
    \     'pattern': ['\\left\[', '\\right\]'],
    \     'select-a': '<buffer> a[',
    \     'select-i': '<buffer> i[',
    \   },
    \  'curly-math': {
    \     'pattern': ['\\left\\{', '\\right\\}'],
    \     'select-a': '<buffer> a{',
    \     'select-i': '<buffer> i{',
    \   },
    \  'angle-math': {
    \     'pattern': ['\\left<', '\\right>'],
    \     'select-a': '<buffer> a<',
    \     'select-i': '<buffer> i<',
    \   },
    \  'abs-math': {
    \     'pattern': ['\\left\\|', '\\right\\|'],
    \     'select-a': '<buffer> a\|',
    \     'select-i': '<buffer> i\|',
    \   },
    \  'dollar-math-a': {
    \     'pattern': '[$][^$]*[$]',
    \     'select': '<buffer> a$',
    \   },
    \  'dollar-math-i': {
    \     'pattern': '[$]\zs[^$]*\ze[$]',
    \     'select': '<buffer> i$',
    \   },
    \  'quote': {
    \     'pattern': ['`', "'"],
    \     'select-a': "<buffer> a'",
    \     'select-i': "<buffer> i'",
    \   },
    \  'quote-double': {
    \     'pattern': ['``', "''"],
    \     'select-a': '<buffer> a"',
    \     'select-i': '<buffer> i"',
    \   },
    \ }

  " Add maps
  call textobj#user#plugin('latex', s:tex_textobjs_dict)
endif


"-----------------------------------------------------------------------------"
" vim-surround integration
"-----------------------------------------------------------------------------"
if g:loaded_surround
  " Tools
  if !exists('g:textools_delim_prefix')
    let g:textools_delim_prefix = '<C-s>'
  endif
  if !exists('g:textools_snippet_prefix')
    let g:textools_snippet_prefix = '<C-z>'
  endif
  " Make the visual-mode map same as insert-mode map
  " Note: Lowercase Isurround plug inserts delims without newlines. Instead of
  " using ISurround we define special begin end environment delims with
  " newlines baked in.
  exe 'vmap ' . g:textools_delim_prefix . ' <Plug>VSurround'
  exe 'imap ' . g:textools_delim_prefix . ' <Plug>Isurround'
  " Cancellation
  exe 'imap ' . g:textools_delim_prefix . '<Esc> <Nop>'
  exe 'imap ' . g:textools_snippet_prefix . '<Esc> <Nop>'

  " Custom delimiter and snippet inserts
  function! s:add_delim(map, start, end) " if final argument passed, this is global
    let b:surround_{char2nr(a:map)} = a:start . "\r" . a:end
  endfunction
  function! s:add_snippet(map, value)
    exe 'inoremap <buffer> ' . g:textools_snippet_prefix . a:map . ' ' . a:value
  endfunction

  " Delete delims function
  " Unfortunately vim-surround does not support the 'dsX' and 'csX' maps for
  " custom delimiters, only insertion. We make our own maps.
  " NOTE: This is fairly primitive as it relies on last character of each
  " delimiter occurs once, and is not part of a regex e.g. \w! Prevents us from
  " having to directly manipulate lines as strings.
  function! DeleteDelims(left, right, ...) " pass 1 to search multiple lines
    if a:0 && a:1
      let l1 = 1
      let l2 = line('$')
    else
      let l1 = line('.') " search only current line
      let l2 = l1
    endif
    if search(a:right, 'n', l2) == 0 || search(a:left, 'nb', l1) == 0
      return
    endif
    " NOTE: For some reason cannot use -ve indexing for strings, only lists
    call search(a:right, '')
    if len(a:right) == 1
      exe 'normal! x'
    else
      exe 'normal! df' . a:right[len(a:right)-1]
    endif
    call search(a:left, 'b')
    if len(a:left) == 1
      exe 'normal! x'
    else
      exe 'normal! df' . a:left[len(a:left)-1]
    endif
  endfunction

  " Replace delims func
  " Pass extra argument '1' to search multiple lines
  " NOTE: If replace is empty, we look for left and right delims from existing
  " surround variables! Useful for \left(\right) delims!
  " NOTE: Make these funcs global so they can be used
  " in the plugins setup
  function! ChangeDelims(left, right, replace, ...)
    if a:0 && a:1
      let l1 = 1
      let l2 = line('$')
    else
      let l1 = line('.') " search only current line
      let l2 = l1
    endif
    if search(a:right, 'n', l2) == 0 || search(a:left, 'nb', l1) == 0
      return
    endif
    " Get replacement strings
    if a:replace != ''
      let group = '\\(.*\\)' " match for group
      let left = substitute(a:left, group, a:replace, '')
      let right = substitute(a:right, group, a:replace, '')
    else
      let cnum = getchar()
      if exists('b:surround_' . cnum)
        let [left, right] = split(b:surround_{cnum}, "\r")
      elseif exists('g:surround_' . cnum)
        let [left, right] = split(g:surround_{cnum}, "\r")
      else
        echohl WarningMsg
        echom 'Warning: Replacement delim code "' . nr2char(cnum) . '" not found.'
        echohl None
        return
      endif
      echo "hi! " . cnum . ' ' . left . ' ' . right
    endif
    " Replace
    call search(a:right, '')
    if len(a:right) == 1
      let cmd = 'cf' . a:right[len(a:right)-1]
    else
      let cmd = 'cl'
    endif
    exe 'normal! ' . cmd . right
    call search(a:left, 'b')
    if len(a:left) == 1
      let cmd = 'cf' . a:left[len(a:left)-1]
    else
      let cmd = 'cl'
    endif
    exe 'normal! ' . cmd . left
  endfunction

  " Define bracket insert targets so that users can switch between
  " \left and \right style braces and ordinary ones
  nmap <buffer> dsc dsB
  nmap <buffer> csc csB
  call s:add_delim('b', '(', ')')
  call s:add_delim('c', '{', '}')
  call s:add_delim('B', '{', '}')
  call s:add_delim('r', '[', ']')
  call s:add_delim('a', '<', '>')

  " Latex commands
  call s:add_delim('t', "\\\1command: \1{", '}')
  nnoremap <buffer> <silent> dst :call DeleteDelims(
    \ '\\\w*{', '}')<CR>
  nnoremap <buffer> <silent> cst :call ChangeDelims(
    \ '\\\(\w*\){', '}', input('command: '))<CR>
  " Latex environments
  call s:add_delim('T', "\\begin{\1\\begin{\1}", "\n"."\\end{\1\1}")
  nnoremap <buffer> <silent> dsT :call DeleteDelims(
    \ '\\begin{[^}]\+}\_s*', '\_s*\\end{[^}]\+}', 1)
  nnoremap <buffer> <silent> csT :call ChangeDelims(
    \ '\\begin{\([^}]\+\)}', '\\end{\([^}]\)\+}', input('\begin{'), 1)

  " Quotations
  call s:add_delim("'", '`',  "'")
  call s:add_delim('"', '``', "''")
  nnoremap <buffer> ds' :call DeleteDelims("`", "'")<CR>
  nnoremap <buffer> ds" :call DeleteDelims("``", "''")<CR>
  " Curly quotations
  call s:add_delim('q', '‘', '’')
  call s:add_delim('Q', '“', '”')
  nnoremap <buffer> dsq :call DeleteDelims("‘", "’")<CR>
  nnoremap <buffer> dsQ :call DeleteDelims("“", "”")<CR>

  " Math mode brackets
  call s:add_delim('{', '\left\{', '\right\}')
  call s:add_delim('(', '\left(',  '\right)')
  call s:add_delim('[', '\left[',  '\right]')
  call s:add_delim('<', '\left<',  '\right>')
  call s:add_delim('|', '\left\|', '\right\|')
  nnoremap <buffer> <silent> ds( :call DeleteDelims('\\left(', '\\right)')<CR>
  nnoremap <buffer> <silent> ds[ :call DeleteDelims('\\left\[', '\\right\]')<CR>
  nnoremap <buffer> <silent> ds{ :call DeleteDelims('\\left\\{', '\\right\\}')<CR>
  nnoremap <buffer> <silent> ds< :call DeleteDelims('\\left<', '\\right>')<CR>
  nnoremap <buffer> <silent> ds\| :call DeleteDelims('\\left\\|', '\\right\\|')<CR>
  nnoremap <buffer> <silent> cs( :call ChangeDelims('\\left(', '\\right)', '')<CR>
  nnoremap <buffer> <silent> cs[ :call ChangeDelims('\\left\[', '\\right\]', '')<CR>
  nnoremap <buffer> <silent> cs{ :call ChangeDelims('\\left\\{', '\\right\\}', '')<CR>
  nnoremap <buffer> <silent> cs< :call ChangeDelims('\\left<', '\\right>', '')<CR>
  nnoremap <buffer> <silent> cs\| :call ChangeDelims('\\left\\|', '\\right\\|', '')<CR>

  " Arrays and whatnot; analagous to above, just point to right
  call s:add_delim('}', '\left\{\begin{array}{ll}', "\n".'\end{array}\right.')
  call s:add_delim(')', '\begin{pmatrix}',          "\n".'\end{pmatrix}')
  call s:add_delim(']', '\begin{bmatrix}',          "\n".'\end{bmatrix}')

  " Font types
  call s:add_delim('e', '\emph{'  ,     '}')
  call s:add_delim('E', '{\color{red}', '}') " e for red, needs \usepackage[colorlinks]{hyperref}
  call s:add_delim('u', '\underline{',  '}')
  call s:add_delim('i', '\textit{',     '}')
  call s:add_delim('o', '\textbf{',     '}') " o for bold
  call s:add_delim('O', '\mathbf{',     '}')
  call s:add_delim('m', '\mathrm{',     '}')
  call s:add_delim('M', '\mathbb{',     '}') " usually for denoting sets of numbers
  call s:add_delim('L', '\mathcal{',    '}')

  " Verbatim
  call s:add_delim('y', '\texttt{',     '}') " typewriter text
  call s:add_delim('Y', '\pyth$',       '$') " python verbatim
  call s:add_delim('V', '\verb$',       '$') " verbatim

  " Math modifiers for symbols
  call s:add_delim('v', '\vec{',        '}')
  call s:add_delim('d', '\dot{',        '}')
  call s:add_delim('D', '\ddot{',       '}')
  call s:add_delim('h', '\hat{',        '}')
  call s:add_delim('`', '\tilde{',      '}')
  call s:add_delim('-', '\overline{',   '}')
  call s:add_delim('_', '\cancelto{}{', '}')

  " Boxes; the second one allows stuff to extend into margins, possibly
  call s:add_delim('x', '\boxed{',      '}')
  call s:add_delim('X', '\fbox{\parbox{\textwidth}{', '}}\medskip')

  " Simple enivronments, exponents, etc.
  call s:add_delim('\', '\sqrt{',       '}')
  call s:add_delim('$', '$',            '$')
  call s:add_delim('/', '\frac{',       '}{}')
  call s:add_delim('?', '\dfrac{',      '}{}')
  call s:add_delim('k', '^{',    '}')
  call s:add_delim('j', '_{',    '}')
  call s:add_delim('K', '\overset{}{',  '}')
  call s:add_delim('J', '\underset{}{', '}')

  " Sections and titles
  call s:add_delim('~', '\title{',          '}')
  call s:add_delim('1', '\section{',        '}')
  call s:add_delim('2', '\subsection{',     '}')
  call s:add_delim('3', '\subsubsection{',  '}')
  call s:add_delim('4', '\section*{',       '}')
  call s:add_delim('5', '\subsection*{',    '}')
  call s:add_delim('6', '\subsubsection*{', '}')
  call s:add_delim('!', '\frametitle{', '}')
  call s:add_delim('n', '\pdfcomment{'."\n", "\n}")

  " Shortcuts for citations and such
  call s:add_delim('7', '\ref{',               '}') " just the number
  call s:add_delim('8', '\autoref{',           '}') " name and number; autoref is part of hyperref package
  call s:add_delim('9', '\label{',             '}') " declare labels that ref and autoref point to
  call s:add_delim('0', '\tag{',               '}') " change the default 1-2-3 ordering; common to use *
  call s:add_delim('a', '\caption{',           '}') " amazingly 'a' not used yet
  call s:add_delim('A', '\captionof{figure}{', '}') " alternative

  " Beamer slides and stuff
  call s:add_delim('>', '\uncover<X>{%', "\n".'}')
  call s:add_delim('g', '\includegraphics[width=\textwidth]{', '}') " center across margins
  call s:add_delim('G', '\makebox[\textwidth][c]{\includegraphics[width=\textwidth]{', '}}') " center across margins
  call s:add_delim('w', '{\usebackgroundtemplate{}\begin{frame}', "\n".'\end{frame}}') " white frame
  call s:add_delim('s', '\begin{frame}',                 "\n".'\end{frame}')
  call s:add_delim('S', '\begin{frame}[fragile]',        "\n".'\end{frame}')
  call s:add_delim('z', '\begin{column}{0.5\textwidth}', "\n".'\end{column}') "l for column
  call s:add_delim('Z', '\begin{columns}',               "\n".'\end{columns}')

  " Misc floating environments and blocks
  " call s:add_delim('F', '\begin{subfigure}{.5\textwidth}'."\n".'\centering'."\n".'\includegraphics{', "}\n".'\end{subfigure}')
  " call s:add_delim(':', '\newpage\hspace{0pt}\vfill', "\n".'\vfill\hspace{0pt}\newpage')
  " call s:add_delim(';', '\begin{center}',       "\n".'\end{center}')
  " call s:add_delim('y', '\begin{python}',       "\n".'\end{python}')
  " call s:add_delim('b', '\begin{block}{}',      "\n".'\end{block}')
  " call s:add_delim('B', '\begin{alertblock}{}', "\n".'\end{alertblock}')
  " call s:add_delim('v', '\begin{verbatim}',     "\n".'\end{verbatim}')
  " call s:add_delim('V', '\begin{code}',         "\n".'\end{code}')
  call s:add_delim('f', '\begin{center}'."\n".'\centering'."\n".'\includegraphics{', "}\n".'\end{center}')
  call s:add_delim('F', '\begin{figure}'."\n".'\centering'."\n".'\includegraphics{', "}\n".'\end{figure}')
  call s:add_delim('P', '\begin{minipage}{\linewidth}', "\n".'\end{minipage}') "not sure what this is used for
  call s:add_delim('W', '\begin{wrapfigure}{r}{.5\textwidth}'."\n".'\centering'."\n".'\includegraphics{', "}\n".'\end{wrapfigure}')

  " Equations
  call s:add_delim('%', '\begin{align*}', "\n".'\end{align*}') "because it is next to the '$' key
  call s:add_delim('^', '\begin{equation*}', "\n".'\end{equation*}')
  call s:add_delim(',', '\begin{tabular}{', "}\n".'\end{tabular}')
  call s:add_delim('.', '\begin{table}'."\n".'\centering'."\n".'\caption{}'."\n".'\begin{tabular}{', "}\n".'\end{tabular}'."\n".'\end{table}')

  " Itemize environments
  call s:add_delim('*', '\begin{itemize}', "\n".'\end{itemize}')
  call s:add_delim('&', '\begin{description}', "\n".'\end{description}') "d is now open
  call s:add_delim('#', '\begin{enumerate}', "\n".'\end{enumerate}')
  call s:add_delim('@', '\begin{enumerate}[label=\alph*.]', "\n".'\end{enumerate}') "because ampersand looks like alpha

  " Font sizing
  call s:add_snippet('1', '\tiny')
  call s:add_snippet('2', '\scriptsize')
  call s:add_snippet('3', '\footnotesize')
  call s:add_snippet('4', '\small')
  call s:add_snippet('5', '\normalsize')
  call s:add_snippet('6', '\large')
  call s:add_snippet('7', '\Large')
  call s:add_snippet('8', '\LARGE')
  call s:add_snippet('9', '\huge')
  call s:add_snippet('0', '\Huge')

  " Misc symbols and stuff
  " call s:add_snippet('<', '\Longrightarrow')
  call s:add_snippet('>', '\Longrightarrow')
  call s:add_snippet('*', '\item')
  call s:add_snippet('/', '\pause')
  call s:add_snippet('o', '\partial')
  call s:add_snippet("'", '\mathrm{d}')
  call s:add_snippet('"', '\mathrm{D}')
  call s:add_snippet('U', '${-}$') " the u is for unary
  call s:add_snippet('u', '${+}$')

  " Greek letters
  call s:add_snippet('a', '\alpha')
  call s:add_snippet('b', '\beta')
  call s:add_snippet('c', '\xi') " the weird curly one, pronounced 'zai'
  call s:add_snippet('C', '\Xi')
  call s:add_snippet('d', '\delta')
  call s:add_snippet('D', '\Delta')
  call s:add_snippet('f', '\phi')
  call s:add_snippet('F', '\Phi')
  call s:add_snippet('g', '\gamma')
  call s:add_snippet('G', '\Gamma')
  call s:add_snippet('K', '\kappa')
  call s:add_snippet('l', '\lambda')
  call s:add_snippet('L', '\Lambda')
  call s:add_snippet('m', '\mu')
  call s:add_snippet('n', '\nabla')
  call s:add_snippet('v', '\nu')
  call s:add_snippet('e', '\epsilon')
  call s:add_snippet('h', '\eta')
  call s:add_snippet('p', '\pi')
  call s:add_snippet('P', '\Pi')
  call s:add_snippet('q', '\theta')
  call s:add_snippet('Q', '\Theta')
  call s:add_snippet('r', '\rho')
  call s:add_snippet('s', '\sigma')
  call s:add_snippet('S', '\Sigma')
  call s:add_snippet('t', '\tau')
  call s:add_snippet('x', '\chi') " looks like an x, pronounced 'kai'
  call s:add_snippet('y', '\psi')
  call s:add_snippet('Y', '\Psi')
  call s:add_snippet('w', '\omega')
  call s:add_snippet('W', '\Omega')
  call s:add_snippet('z', '\zeta')

  " Mathematical operations
  call s:add_snippet('i', '\int')
  call s:add_snippet('I', '\iint')
  call s:add_snippet('-', '${-}$')
  call s:add_snippet('+', '\sum')
  call s:add_snippet('x', '\times')
  call s:add_snippet('X', '\prod')
  call s:add_snippet('O', '$^\circ$')
  call s:add_snippet('=', '\equiv')
  call s:add_snippet('~', '{\sim}')
  call s:add_snippet('k', '^')
  call s:add_snippet('j', '_')
  call s:add_snippet('E', '\times10^{}<Left>') " more like a symbol conceptually
  call s:add_snippet('.', '\cdot')

  " Spaces
  call s:add_snippet(',', '\, ')
  call s:add_snippet(':', '\: ')
  call s:add_snippet(';', '\; ')
  call s:add_snippet('q', '\quad ')
  call s:add_snippet('M', ' \textCR<CR>') " for pdfcomment newlines

  " Complex snippets
  " TODO: Why does this still raise error?
  " exe "inoremap <buffer> <expr> " . g:textools_snippet_prefix . "_ '\begin{center}\noindent\rule{' . input('fraction: ') . '\textwidth}{0.7pt}\end{center}'"
endif

