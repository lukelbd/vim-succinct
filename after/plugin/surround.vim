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
if !exists('g:textools_surround_prefix')
  let g:textools_surround_prefix = '<C-s>'
endif
if !exists('g:textools_symbol_prefix')
  let g:textools_symbol_prefix = '<C-z>'
endif
" Delimiters
augroup tex_delimit
  au!
  au FileType tex call s:texsurround()
augroup END
" Remap surround.vim defaults
" Make the visual-mode map same as insert-mode map; by default it is capital S
" Note: Lowercase Isurround surrounds words, ISurround surrounds lines.
exe 'vmap ' . g:textools_surround_prefix . ' <Plug>VSurround'
exe 'imap ' . g:textools_surround_prefix . ' <Plug>Isurround'
" Cancellation
exe 'imap ' . g:textools_surround_prefix . '<Esc> <Nop>'
exe 'imap ' . g:textools_symbol_prefix . '<Esc> <Nop>'

"------------------------------------------------------------------------------"
" Function for adding fancy multiple character delimiters
"------------------------------------------------------------------------------"
" These will only be 'placed', never detected; for example, will never work in
" da<target>, ca<target>, cs<target><other>, etc. commands; only should be used for
" ys<target>, yS<target>, visual-mode S, insert-mode <C-s>, et cetera
function! s:target(map, start, end) " if final argument passed, this is buffer-local
  let b:surround_{char2nr(a:map)} = a:start . "\r" . a:end
endfunction
" And this function is for declaring symbol maps
function! s:snippet(map, value)
  exe 'inoremap <buffer> ' . g:textools_symbol_prefix . a:map . ' ' . a:value
endfunction

"------------------------------------------------------------------------------"
" LaTeX-specific 'delimiters' and shortcuts
"------------------------------------------------------------------------------"
function! s:texsurround()
  " First the delimiters
  " ',' for commands
  call s:target('t', "\\\1command: \1{", '}')
  nmap <buffer> <expr> cst 'F{F\lct{'.input('command: ').'<Esc>F\'
  nnoremap <buffer> ds( ?\\left(<CR>d/\\right)<CR>df)
  nnoremap <buffer> ds[ ?\\left[<CR>d/\\right]<CR>df]
  nnoremap <buffer> ds{ ?\\left{<CR>d/\\right}<CR>df}
  nnoremap <buffer> ds< ?\\left<<CR>d/\\right><CR>df>
  nnoremap <buffer> dst F{F\dt{dsB

  " '.' for environments
  " Note uppercase registers *append* to previous contents
  call s:target('T', "\\begin{\1\\begin{\1}", "\n"."\\end{\1\1}")
  nnoremap <buffer> dsT :let @/ = '\\end{[^}]\+}.*\n'<CR>dgn:let @/ = '\\begin{[^}]\+}.*\n'<CR>dgN
  nnoremap <expr> <buffer> csT ':let @/ = "\\\\end{\\zs[^}]\\+\\ze}"<CR>cgn'
           \ .input('\begin{')
           \ .'<Esc>h:let @z = "<C-r><C-w>"<CR>:let @/ = "\\\\begin{\\zs[^}]\\+\\ze}"<CR>cgN<C-r>z<Esc>'
  " nmap <buffer> dsL /\\end{<CR>:noh<CR><Up>V<Down>^%<Down>dp<Up>V<Up>d
  " nmap <buffer> <expr> csL '/\\end{<CR>:noh<CR>A!!!<Esc>^%f{<Right>ciB'
  " \.input('\begin{').'<Esc>/!!!<CR>:noh<CR>A {<C-r>.}<Esc>2F{dt{'

  " Quotations
  call s:target("'", '`',  "'")
  call s:target('"', '``', "''")
  nnoremap <buffer> ds' f'xF`x
  nnoremap <buffer> ds" 2f'F'2x2F`2x
  " Curly quotations
  call s:target('q', '‘', '’')
  call s:target('Q', '“', '”')
  nnoremap <buffer> dsq f’xF‘x
  nnoremap <buffer> dsQ f”xF“x

  " Next delimiters generally not requiring new lines
  " Math mode brackets
  call s:target('|', '\left\|', '\right\|')
  call s:target('{', '\left\{', '\right\}')
  call s:target('(', '\left(',  '\right)')
  call s:target('[', '\left[',  '\right]')
  call s:target('<', '\left<',  '\right>')

  " Arrays and whatnot; analagous to above, just point to right
  call s:target('}', '\left\{\begin{array}{ll}', "\n".'\end{array}\right.')
  call s:target(')', '\begin{pmatrix}',          "\n".'\end{pmatrix}')
  call s:target(']', '\begin{bmatrix}',          "\n".'\end{bmatrix}')

  " Font types
  call s:target('e', '\emph{'  ,     '}')
  call s:target('E', '{\color{red}', '}') " e for red, needs \usepackage[colorlinks]{hyperref}
  call s:target('u', '\underline{',  '}')
  call s:target('i', '\textit{',     '}')
  call s:target('o', '\textbf{',     '}') " o for bold
  call s:target('O', '\mathbf{',     '}')
  call s:target('m', '\mathrm{',     '}')
  call s:target('M', '\mathbb{',     '}') " usually for denoting sets of numbers
  call s:target('L', '\mathcal{',    '}')

  " Verbatim
  call s:target('y', '\texttt{',     '}') " typewriter text
  call s:target('Y', '\pyth$',       '$') " python verbatim
  call s:target('V', '\verb$',       '$') " verbatim

  " Math modifiers for symbols
  call s:target('v', '\vec{',        '}')
  call s:target('d', '\dot{',        '}')
  call s:target('D', '\ddot{',       '}')
  call s:target('h', '\hat{',        '}')
  call s:target('`', '\tilde{',      '}')
  call s:target('-', '\overline{',   '}')
  call s:target('_', '\cancelto{}{', '}')

  " Boxes; the second one allows stuff to extend into margins, possibly
  call s:target('x', '\boxed{',      '}')
  call s:target('X', '\fbox{\parbox{\textwidth}{', '}}\medskip')

  " Simple enivronments, exponents, etc.
  " call s:target('k', '^\mathrm{',           '}')
  " call s:target('j', '_\mathrm{',           '}')
  call s:target('\', '\sqrt{',       '}')
  call s:target('$', '$',            '$')
  call s:target('k', '\overset{}{',  '}')
  call s:target('j', '\underset{}{', '}')
  call s:target('/', '\frac{',       '}{}')
  call s:target('?', '\dfrac{',      '}{}')

  " Sections and titles
  call s:target('~', '\title{',          '}')
  call s:target('1', '\section{',        '}')
  call s:target('2', '\subsection{',     '}')
  call s:target('3', '\subsubsection{',  '}')
  call s:target('4', '\section*{',       '}')
  call s:target('5', '\subsection*{',    '}')
  call s:target('6', '\subsubsection*{', '}')

  " Beamer
  call s:target('n', '\pdfcomment{'."\n", "\n}") "not sure what this is used for
  call s:target('!', '\frametitle{', '}')
  " call s:target('c', '\begin{column}{',  "}\n".'\end{column}')
  " call s:target('C', '\begin{columns}[', ']\end{columns}')
  " call s:target('z', '\note{',    '}') "notes are for beamer presentations, appear in separate slide

  " Shortcuts for citations and such
  call s:target('7', '\ref{',               '}') " just the number
  call s:target('8', '\autoref{',           '}') " name and number; autoref is part of hyperref package
  call s:target('9', '\label{',             '}') " declare labels that ref and autoref point to
  call s:target('0', '\tag{',               '}') " change the default 1-2-3 ordering; common to use *
  call s:target('a', '\caption{',           '}') " amazingly 'a' not used yet
  call s:target('A', '\captionof{figure}{', '}') " alternative

  " The next enfironments will also insert *newlines*
  " Frame; fragile option makes verbatim possible (https://tex.stackexchange.com/q/136240/73149)
  " note that fragile make compiling way slower
  " Slide with 'w'hite frame is the w map
  " call s:target('<', '\uncover<X>{\item ', '}')
  call s:target('>', '\uncover<X>{%', "\n".'}')
  call s:target('g', '\includegraphics[width=\textwidth]{', '}') " center across margins
  call s:target('G', '\makebox[\textwidth][c]{\includegraphics[width=\textwidth]{', '}}') " center across margins
  call s:target('w', '{\usebackgroundtemplate{}\begin{frame}', "\n".'\end{frame}}')
  call s:target('s', '\begin{frame}',                 "\n".'\end{frame}')
  call s:target('S', '\begin{frame}[fragile]',        "\n".'\end{frame}')
  call s:target('z', '\begin{column}{0.5\textwidth}', "\n".'\end{column}') "l for column
  call s:target('Z', '\begin{columns}',               "\n".'\end{columns}')

  " Figure environments, and pages
  " call s:target('F', '\begin{subfigure}{.5\textwidth}'."\n".'\centering'."\n".'\includegraphics{', "}\n".'\end{subfigure}')
  call s:target('f', '\begin{center}'."\n".'\centering'."\n".'\includegraphics{', "}\n".'\end{center}')
  call s:target('F', '\begin{figure}'."\n".'\centering'."\n".'\includegraphics{', "}\n".'\end{figure}')
  call s:target('P', '\begin{minipage}{\linewidth}', "\n".'\end{minipage}') "not sure what this is used for
  call s:target('W', '\begin{wrapfigure}{r}{.5\textwidth}'."\n".'\centering'."\n".'\includegraphics{', "}\n".'\end{wrapfigure}')

  " Equations
  call s:target('%', '\begin{align*}', "\n".'\end{align*}') "because it is next to the '$' key
  call s:target('^', '\begin{equation*}', "\n".'\end{equation*}')
  call s:target(',', '\begin{tabular}{', "}\n".'\end{tabular}')
  call s:target('.', '\begin{table}'."\n".'\centering'."\n".'\caption{}'."\n".'\begin{tabular}{', "}\n".'\end{tabular}'."\n".'\end{table}')

  " Itemize environments
  call s:target('*', '\begin{itemize}', "\n".'\end{itemize}')
  call s:target('&', '\begin{description}', "\n".'\end{description}') "d is now open
  call s:target('#', '\begin{enumerate}', "\n".'\end{enumerate}')
  call s:target('@', '\begin{enumerate}[label=\alph*.]', "\n".'\end{enumerate}') "because ampersand looks like alpha

  " Versions of the above, but this time puting them on own lines
  " TODO: fix these
  " * The onlytextwidth option keeps two-columns (any arbitrary widths) aligned
  "   with default single column; see: https://tex.stackexchange.com/a/366422/73149
  " * Use command \rule{\textwidth}{<any height>} to visualize blocks/spaces in document
  " call s:target(',;', '\begin{center}',             '\end{center}')               "because ; was available
  " call s:target(',:', '\newpage\hspace{0pt}\vfill', '\vfill\hspace{0pt}\newpage') "vertically centered page
  " call s:target(',y', '\begin{python}',             '\end{python}')
  "   "not sure what these args are for; c will vertically center
  " call s:target(',b', '\begin{block}{}',                  '\end{block}')
  " call s:target(',B', '\begin{alertblock}{}',             '\end{alertblock}')
  " call s:target(',v', '\begin{verbatim}',                 '\end{verbatim}')
  " call s:target(',V', '\begin{code}',                     '\end{code}')

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

  " First arrows, most commonly used ones anyway
  " call s:snippet('<', '\Longrightarrow')
  call s:snippet('>', '\Longrightarrow')
  " Misc symbotls, want quick access
  call s:snippet('*', '\item')
  call s:snippet('/', '\pause')
  " Math symbols
  call s:snippet('a', '\alpha')
  call s:snippet('b', '\beta')
  call s:snippet('c', '\xi')
  " Weird curly one
  " the upper case looks like 3 lines
  call s:snippet('C', '\Xi')
  " Looks like an x so want to use this map
  " pronounced 'zi', the 'i' in 'tide'
  call s:snippet('x', '\chi')

  " Greek letters
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
  call s:snippet('y', '\psi')
  call s:snippet('Y', '\Psi')
  call s:snippet('w', '\omega')
  call s:snippet('W', '\Omega')
  call s:snippet('z', '\zeta')

  " Needed for pdfcomment newlines
  call s:snippet('M', ' \textCR<CR>')

  " Derivatives
  call s:snippet('o', '\partial')
  call s:snippet("'", '\mathrm{d}')
  call s:snippet('"', '\mathrm{D}')

  " u is for unary
  call s:snippet('U', '${-}$')
  call s:snippet('u', '${+}$')

  " Integration
  call s:snippet('i', '\int')
  call s:snippet('I', '\iint')

  " 3 levels of differentiation; each one stronger
  call s:snippet('-', '${-}$')
  call s:snippet('+', '\sum')
  call s:snippet('x', '\times')
  call s:snippet('X', '\prod')
  call s:snippet('O', '$^\circ$')
  call s:snippet('=', '\equiv')
  call s:snippet('~', '{\sim}')
  call s:snippet('k', '^{}<Left>')
  call s:snippet('j', '_{}<Left>')
  call s:snippet('K', '^\mathrm{}<Left>')
  call s:snippet('J', '_\mathrm{}<Left>')
  call s:snippet('E', '\times10^{}<Left>') " more like a symbol conceptually
  call s:snippet('.', '\cdot')

  " Spaces
  call s:snippet(',', '\, ')
  call s:snippet(':', '\: ')
  call s:snippet(';', '\; ')
  call s:snippet('q', '\quad ')

  " Insert a line (feel free to modify width), will prompt user for fraction of page
  " Note centering fails inside itemize environments, so use begin/end center instead
  " _ '{\centering\noindent\rule{'.input('fraction: ').'\textwidth}{0.7pt}}'
  " call s:snippet('_', "'\begin{center}\noindent\rule{'.input('fraction: ').'\textwidth}{0.7pt}\end{center}'")
endfunction

