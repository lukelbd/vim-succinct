"------------------------------------------------------------------------------"
" Author: Luke Davis (lukelbd@gmail.com)
" Date:   2018-09-10
" This plugin is a wrapper around the 'surround.vim' plugin.
" Add new surround.vim delimiters for LaTeX and HTML files, incorporate
" new delimiters more cleanly with the builtin LaTeX da/di/etc. commands,
" and provide new tool for jumping outside of delimiters.
"------------------------------------------------------------------------------"
" Dependencies
if !g:loaded_surround
  finish
endif
" Tools
if !exists('g:textools_delim_prefix')
  let g:textools_delim_prefix = '<C-s>'
endif
if !exists('g:textools_snippet_prefix')
  let g:textools_snippet_prefix = '<C-z>'
endif
" Delimiters
augroup tex_surround
  au!
  au FileType tex call s:tex_surround()
augroup END
" Remap surround.vim defaults
" Make the visual-mode map same as insert-mode map; by default it is capital S
" Note: Lowercase Isurround surrounds words, ISurround surrounds lines.
exe 'vmap ' . g:textools_delim_prefix . ' <Plug>VSurround'
exe 'imap ' . g:textools_delim_prefix . ' <Plug>Isurround'
" Cancellation
exe 'imap ' . g:textools_delim_prefix . '<Esc> <Nop>'
exe 'imap ' . g:textools_snippet_prefix . '<Esc> <Nop>'

"-----------------------------------------------------------------------------"
" Helper functions
"-----------------------------------------------------------------------------"
" Custom delimiter inserts
function! s:delim(map, start, end, ...) " if final argument passed, this is global
  if a:0 && a:1
    let g:surround_{char2nr(a:map)} = a:start . "\r" . a:end
  else
    let b:surround_{char2nr(a:map)} = a:start . "\r" . a:end
  endif
endfunction

" Inserting snippets
function! s:snippet(map, value, ...)
  if a:0 && a:1
    let noremap = 'inoremap'
  else
    let noremap = 'inoremap <buffer>'
  endif
  exe noremap . ' ' . g:textools_snippet_prefix . a:map . ' ' . a:value
endfunction

" Delete delims function
" Unfortunately vim-surround does not support the 'dsX' and 'csX' maps for
" custom delimiters, only insertion. We make our own maps.
" Pass extra argument '1' to search multiple lines
" NOTE: This is fairly primitive as it relies on last character of each
" delimiter occurs once, and is not part of a regex e.g. \w! Prevents us from
" having to directly manipulate lines as strings.
function! s:surround_delete(left, right, ...)
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
function! s:surround_change(left, right, replace, ...)
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

"------------------------------------------------------------------------------"
" LaTeX-specific 'delimiters' and shortcuts
"------------------------------------------------------------------------------"
" Define global *insertable* vim-surround targets
nmap dsc dsB
nmap csc csB
call s:delim('c', '{', '}', 1)
call s:delim('b', '(', ')', 1)
call s:delim('r', '[', ']', 1)
call s:delim('a', '<', '>', 1)

" Escaped quotes
call s:delim('\', '\"', '\"', 1)
nnoremap <silent> ds\ :call <sid>surround_delete('\\["'."']", '\\["'."']")<CR>

" Function and print statement
call s:delim('p', 'print(', ')', 1)
call s:delim('f', "\1function: \1(", ')', 1) "initial part is for prompt, needs double quotes
nnoremap <silent> dsf :call <sid>surround_delete('\w*(', ')')<CR>
nnoremap <silent> csf :call <sid>surround_change('\(\w*\)(', ')', input('function: '))<CR>

" Next function that declares maps
function! s:tex_surround()
  " Latex commands
  call s:delim('t', "\\\1command: \1{", '}')
  nnoremap <buffer> <silent> dst :call <sid>surround_delete(
    \ '\\\w*{', '}')<CR>
  nnoremap <buffer> <silent> cst :call <sid>surround_change(
    \ '\\\(\w*\){', '}', input('command: '))<CR>
  " Latex environments
  call s:delim('T', "\\begin{\1\\begin{\1}", "\n"."\\end{\1\1}")
  nnoremap <buffer> <silent> dsT :call <sid>surround_delete(
    \ '\\begin{[^}]\+}\_s*', '\_s*\\end{[^}]\+}', 1)
  nnoremap <buffer> <silent> csT :call <sid>surround_change(
    \ '\\begin{\([^}]\+\)}', '\\end{\([^}]\)\+}', input('\begin{'), 1)

  " Quotations
  call s:delim("'", '`',  "'")
  call s:delim('"', '``', "''")
  nnoremap <buffer> ds' :call <sid>surround_delete("`", "'")<CR>
  nnoremap <buffer> ds" :call <sid>surround_delete("``", "''")<CR>
  " Curly quotations
  call s:delim('q', '‘', '’')
  call s:delim('Q', '“', '”')
  nnoremap <buffer> dsq :call <sid>surround_delete("‘", "’")<CR>
  nnoremap <buffer> dsQ :call <sid>surround_delete("“", "”")<CR>

  " Math mode brackets
  call s:delim('|', '\left\|', '\right\|')
  call s:delim('{', '\left\{', '\right\}')
  call s:delim('(', '\left(',  '\right)')
  call s:delim('[', '\left[',  '\right]')
  call s:delim('<', '\left<',  '\right>')
  nnoremap <buffer> <silent> ds( :call <sid>surround_delete('\\left(', '\\right)')<CR>
  nnoremap <buffer> <silent> ds[ :call <sid>surround_delete('\\left\[', '\\right\]')<CR>
  nnoremap <buffer> <silent> ds{ :call <sid>surround_delete('\\left\\{', '\\right\\}')<CR>
  nnoremap <buffer> <silent> ds< :call <sid>surround_delete('\\left<', '\\right>')<CR>
  nnoremap <buffer> <silent> cs( :call <sid>surround_change('\\left(', '\\right)', '')<CR>
  nnoremap <buffer> <silent> cs[ :call <sid>surround_change('\\left\[', '\\right\]', '')<CR>
  nnoremap <buffer> <silent> cs{ :call <sid>surround_change('\\left\\{', '\\right\\}', '')<CR>
  nnoremap <buffer> <silent> cs< :call <sid>surround_change('\\left<', '\\right>', '')<CR>

  " Arrays and whatnot; analagous to above, just point to right
  call s:delim('}', '\left\{\begin{array}{ll}', "\n".'\end{array}\right.')
  call s:delim(')', '\begin{pmatrix}',          "\n".'\end{pmatrix}')
  call s:delim(']', '\begin{bmatrix}',          "\n".'\end{bmatrix}')

  " Font types
  call s:delim('e', '\emph{'  ,     '}')
  call s:delim('E', '{\color{red}', '}') " e for red, needs \usepackage[colorlinks]{hyperref}
  call s:delim('u', '\underline{',  '}')
  call s:delim('i', '\textit{',     '}')
  call s:delim('o', '\textbf{',     '}') " o for bold
  call s:delim('O', '\mathbf{',     '}')
  call s:delim('m', '\mathrm{',     '}')
  call s:delim('M', '\mathbb{',     '}') " usually for denoting sets of numbers
  call s:delim('L', '\mathcal{',    '}')

  " Verbatim
  call s:delim('y', '\texttt{',     '}') " typewriter text
  call s:delim('Y', '\pyth$',       '$') " python verbatim
  call s:delim('V', '\verb$',       '$') " verbatim

  " Math modifiers for symbols
  call s:delim('v', '\vec{',        '}')
  call s:delim('d', '\dot{',        '}')
  call s:delim('D', '\ddot{',       '}')
  call s:delim('h', '\hat{',        '}')
  call s:delim('`', '\tilde{',      '}')
  call s:delim('-', '\overline{',   '}')
  call s:delim('_', '\cancelto{}{', '}')

  " Boxes; the second one allows stuff to extend into margins, possibly
  call s:delim('x', '\boxed{',      '}')
  call s:delim('X', '\fbox{\parbox{\textwidth}{', '}}\medskip')

  " Simple enivronments, exponents, etc.
  call s:delim('\', '\sqrt{',       '}')
  call s:delim('$', '$',            '$')
  call s:delim('/', '\frac{',       '}{}')
  call s:delim('?', '\dfrac{',      '}{}')
  call s:delim('k', '^{',    '}')
  call s:delim('j', '_{',    '}')
  call s:delim('K', '\overset{}{',  '}')
  call s:delim('J', '\underset{}{', '}')

  " Sections and titles
  call s:delim('~', '\title{',          '}')
  call s:delim('1', '\section{',        '}')
  call s:delim('2', '\subsection{',     '}')
  call s:delim('3', '\subsubsection{',  '}')
  call s:delim('4', '\section*{',       '}')
  call s:delim('5', '\subsection*{',    '}')
  call s:delim('6', '\subsubsection*{', '}')

  " Beamer
  call s:delim('n', '\pdfcomment{'."\n", "\n}") "not sure what this is used for
  call s:delim('!', '\frametitle{', '}')

  " Shortcuts for citations and such
  call s:delim('7', '\ref{',               '}') " just the number
  call s:delim('8', '\autoref{',           '}') " name and number; autoref is part of hyperref package
  call s:delim('9', '\label{',             '}') " declare labels that ref and autoref point to
  call s:delim('0', '\tag{',               '}') " change the default 1-2-3 ordering; common to use *
  call s:delim('a', '\caption{',           '}') " amazingly 'a' not used yet
  call s:delim('A', '\captionof{figure}{', '}') " alternative

  " Beamer slides and stuff
  call s:delim('>', '\uncover<X>{%', "\n".'}')
  call s:delim('g', '\includegraphics[width=\textwidth]{', '}') " center across margins
  call s:delim('G', '\makebox[\textwidth][c]{\includegraphics[width=\textwidth]{', '}}') " center across margins
  call s:delim('w', '{\usebackgroundtemplate{}\begin{frame}', "\n".'\end{frame}}') " white frame
  call s:delim('s', '\begin{frame}',                 "\n".'\end{frame}')
  call s:delim('S', '\begin{frame}[fragile]',        "\n".'\end{frame}')
  call s:delim('z', '\begin{column}{0.5\textwidth}', "\n".'\end{column}') "l for column
  call s:delim('Z', '\begin{columns}',               "\n".'\end{columns}')

  " Figure environments, and pages
  " call s:delim('F', '\begin{subfigure}{.5\textwidth}'."\n".'\centering'."\n".'\includegraphics{', "}\n".'\end{subfigure}')
  call s:delim('f', '\begin{center}'."\n".'\centering'."\n".'\includegraphics{', "}\n".'\end{center}')
  call s:delim('F', '\begin{figure}'."\n".'\centering'."\n".'\includegraphics{', "}\n".'\end{figure}')
  call s:delim('P', '\begin{minipage}{\linewidth}', "\n".'\end{minipage}') "not sure what this is used for
  call s:delim('W', '\begin{wrapfigure}{r}{.5\textwidth}'."\n".'\centering'."\n".'\includegraphics{', "}\n".'\end{wrapfigure}')

  " Equations
  call s:delim('%', '\begin{align*}', "\n".'\end{align*}') "because it is next to the '$' key
  call s:delim('^', '\begin{equation*}', "\n".'\end{equation*}')
  call s:delim(',', '\begin{tabular}{', "}\n".'\end{tabular}')
  call s:delim('.', '\begin{table}'."\n".'\centering'."\n".'\caption{}'."\n".'\begin{tabular}{', "}\n".'\end{tabular}'."\n".'\end{table}')

  " Itemize environments
  call s:delim('*', '\begin{itemize}', "\n".'\end{itemize}')
  call s:delim('&', '\begin{description}', "\n".'\end{description}') "d is now open
  call s:delim('#', '\begin{enumerate}', "\n".'\end{enumerate}')
  call s:delim('@', '\begin{enumerate}[label=\alph*.]', "\n".'\end{enumerate}') "because ampersand looks like alpha

  " Not currently used
  " call s:delim(':', '\newpage\hspace{0pt}\vfill', "\n".'\vfill\hspace{0pt}\newpage')
  " call s:delim(';', '\begin{center}',       "\n".'\end{center}')
  " call s:delim('y', '\begin{python}',       "\n".'\end{python}')
  " call s:delim('b', '\begin{block}{}',      "\n".'\end{block}')
  " call s:delim('B', '\begin{alertblock}{}', "\n".'\end{alertblock}')
  " call s:delim('v', '\begin{verbatim}',     "\n".'\end{verbatim}')
  " call s:delim('V', '\begin{code}',         "\n".'\end{code}')

  " Font sizing
  call s:snippet('1', '\tiny')
  call s:snippet('2', '\scriptsize')
  call s:snippet('3', '\footnotesize')
  call s:snippet('4', '\small')
  call s:snippet('5', '\normalsize')
  call s:snippet('6', '\large')
  call s:snippet('7', '\Large')
  call s:snippet('8', '\LARGE')
  call s:snippet('9', '\huge')
  call s:snippet('0', '\Huge')

  " Misc symbols and stuff
  " call s:snippet('<', '\Longrightarrow')
  call s:snippet('>', '\Longrightarrow')
  call s:snippet('*', '\item')
  call s:snippet('/', '\pause')
  call s:snippet('o', '\partial')
  call s:snippet("'", '\mathrm{d}')
  call s:snippet('"', '\mathrm{D}')
  call s:snippet('U', '${-}$') " the u is for unary
  call s:snippet('u', '${+}$')

  " Greek letters
  call s:snippet('a', '\alpha')
  call s:snippet('b', '\beta')
  call s:snippet('c', '\xi') " the weird curly one, pronounced 'zai'
  call s:snippet('C', '\Xi')
  call s:snippet('d', '\delta')
  call s:snippet('D', '\Delta')
  call s:snippet('f', '\phi')
  call s:snippet('F', '\Phi')
  call s:snippet('g', '\gamma')
  call s:snippet('G', '\Gamma')
  call s:snippet('K', '\kappa')
  call s:snippet('l', '\lambda')
  call s:snippet('L', '\Lambda')
  call s:snippet('m', '\mu')
  call s:snippet('n', '\nabla')
  call s:snippet('v', '\nu')
  call s:snippet('e', '\epsilon')
  call s:snippet('h', '\eta')
  call s:snippet('p', '\pi')
  call s:snippet('P', '\Pi')
  call s:snippet('q', '\theta')
  call s:snippet('Q', '\Theta')
  call s:snippet('r', '\rho')
  call s:snippet('s', '\sigma')
  call s:snippet('S', '\Sigma')
  call s:snippet('t', '\tau')
  call s:snippet('x', '\chi') " looks like an x, pronounced 'kai'
  call s:snippet('y', '\psi')
  call s:snippet('Y', '\Psi')
  call s:snippet('w', '\omega')
  call s:snippet('W', '\Omega')
  call s:snippet('z', '\zeta')

  " Mathematical operations
  call s:snippet('i', '\int')
  call s:snippet('I', '\iint')
  call s:snippet('-', '${-}$')
  call s:snippet('+', '\sum')
  call s:snippet('x', '\times')
  call s:snippet('X', '\prod')
  call s:snippet('O', '$^\circ$')
  call s:snippet('=', '\equiv')
  call s:snippet('~', '{\sim}')
  call s:snippet('k', '^')
  call s:snippet('j', '_')
  call s:snippet('E', '\times10^{}<Left>') " more like a symbol conceptually
  call s:snippet('.', '\cdot')

  " Spaces
  call s:snippet(',', '\, ')
  call s:snippet(':', '\: ')
  call s:snippet(';', '\; ')
  call s:snippet('q', '\quad ')
  call s:snippet('M', ' \textCR<CR>') " for pdfcomment newlines

  " Complex snippets
  " TODO: Why does this still raise error?
  " exe "inoremap <buffer> <expr> " . g:textools_snippet_prefix . "_ '\begin{center}\noindent\rule{' . input('fraction: ') . '\textwidth}{0.7pt}\end{center}'"
endfunction

