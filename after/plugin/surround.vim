"------------------------------------------------------------------------------"
" Author: Luke Davis (lukelbd@gmail.com)
" Date:   2018-09-10
" This plugin is a wrapper around the 'surround.vim' plugin.
" Add new surround.vim delimiters for LaTeX and HTML files, incorporate
" new delimiters more cleanly with the builtin LaTeX da/di/etc. commands,
" and provide new tool for jumping outside of delimiters.
"------------------------------------------------------------------------------"
"Dependencies
if !g:loaded_surround
  echom "Warning: vim-textools requires vim-surround, disabling some features."
  finish
endif
"Tools
if !exists('g:textools_surround_prefix')
  let g:textools_surround_prefix='<C-s>'
endif
if !exists('g:textools_symbol_prefix')
  let g:textools_symbol_prefix='<C-z>'
endif
"Remap surround.vim defaults
"Make the visual-mode map same as insert-mode map; by default it is capital S
"Note: Lowercase Isurround surrounds words, ISurround surrounds lines.
exe 'vmap '.g:textools_surround_prefix.' <Plug>VSurround'
exe 'imap '.g:textools_surround_prefix.' <Plug>Isurround'
"Cancellation
exe 'imap '.g:textools_surround_prefix.'<Esc> <Nop>'
exe 'imap '.g:textools_symbol_prefix.'<Esc> <Nop>'

"------------------------------------------------------------------------------"
"Define additional shortcuts like ys's' for the non-whitespace part
"of this line -- use 'w' for <cword>, 'W' for <CWORD>, 'p' for current paragraph
"------------------------------------------------------------------------------"
nmap ysw ysiw
nmap ysW ysiW
nmap ysp ysip
nmap ys. ysis
nmap ySw ySiw
nmap ySW ySiW
nmap ySp ySip
nmap yS. ySis

"------------------------------------------------------------------------------"
"Function for adding fancy multiple character delimiters
"------------------------------------------------------------------------------"
"These will only be 'placed', never detected; for example, will never work in
"da<target>, ca<target>, cs<target><other>, etc. commands; only should be used for
"ys<target>, yS<target>, visual-mode S, insert-mode <C-s>, et cetera
function! s:target(map,start,end,...) "if final argument passed, this is buffer-local
  if a:0 "surprisingly, below is standard vim script syntax
    let b:surround_{char2nr(a:map)}=a:start."\r".a:end
    " silent! unlet g:surround_{char2nr(a:map)}
  else
    let g:surround_{char2nr(a:map)}=a:start."\r".a:end
  endif
endfunction
"And this function is for declaring symbol maps
function! s:symbol(map,value)
  exe 'inoremap <buffer> '.g:textools_symbol_prefix.a:map.' '.a:value
endfunction

"------------------------------------------------------------------------------"
"Define global, *insertable* vim-surround targets
"Multichar Delims: Surround can 'put' them, but cannot 'find' them
"e.g. in a ds<custom-target> or cs<custom-target><other-target> command.
"Single Delims: Delims *can* be 'found' if they are single character, but
"setting g:surround_does not do so -- instead, just map commands
"------------------------------------------------------------------------------"
"* Hit ga to get ASCII code (leftmost number; not the HEX code!)
"* Note that if you just enter some uncoded character, will
"  use that as a delimiter -- e.g. yss` surrounds with backticks
"* Note double quotes are required, because surround-vim wants
"  the literal \r return character.
"c for curly brace
" let g:surround_{char2nr('c')}="{\r}"
call s:target('c', '{', '}')
nmap dsc dsB
nmap csc csB
"\ for \" escaped quotes \"
call s:target('\', '\"', '\"')
nmap ds\ /\\"<CR>xxdN
nmap cs\ /\\"<CR>xNx
"p for print
"then just use dsf, csf, et cetera to delete
call s:target('p', 'print(', ')')
"f for functions, with user prompting
call s:target('f', "\1function: \1(", ')') "initial part is for prompt, needs double quotes
nnoremap dsf mzF(bdt(xf)x`z
nnoremap <expr> csf 'F(hciw'.input('function: ').'<Esc>'

"------------------------------------------------------------------------------"
"LaTeX-specific 'delimiters' and shortcuts
"------------------------------------------------------------------------------"
augroup tex_delimit
  au!
  au FileType tex call s:texsurround()
augroup END
function! s:texsurround()
  "----------------------------------------------------------------------------"
  " First the delimiters
  "----------------------------------------------------------------------------"
  "'l' for commands
  call s:target('l', "\\\1command: \1{", '}')
  nmap <buffer> dsl F{F\dt{dsB
  nmap <buffer> <expr> csl 'F{F\lct{'.input('command: ').'<Esc>F\'

  "'L' for environments
  "Note uppercase registers *append* to previous contents
  call s:target('L', "\\begin{\1\\begin{\1}", "\n"."\\end{\1\1}")
  nnoremap <buffer> dsL :let @/='\\end{[^}]\+}.*\n'<CR>dgn:let @/='\\begin{[^}]\+}.*\n'<CR>dgN
  nnoremap <expr> <buffer> csL ':let @/="\\\\end{\\zs[^}]\\+\\ze}"<CR>cgn'
           \ .input('\begin{')
           \ .'<Esc>h:let @z="<C-r><C-w>"<CR>:let @/="\\\\begin{\\zs[^}]\\+\\ze}"<CR>cgN<C-r>z<Esc>'
  " nmap <buffer> dsL /\\end{<CR>:noh<CR><Up>V<Down>^%<Down>dp<Up>V<Up>d
  " nmap <buffer> <expr> csL '/\\end{<CR>:noh<CR>A!!!<Esc>^%f{<Right>ciB'
  " \.input('\begin{').'<Esc>/!!!<CR>:noh<CR>A {<C-r>.}<Esc>2F{dt{'
  "Quotations
  call s:target('q', '`',  "'",  1)
  call s:target('Q', '``', "''", 1)
  nnoremap <buffer> dsq f'xF`x
  nnoremap <buffer> dsQ 2f'F'2x2F`2x

  "Curly quotations
  call s:target("'", '‘', '’', 1)
  call s:target('"', '“', '”', 1)
  nnoremap <buffer> ds' f’xF‘x
  nnoremap <buffer> ds" f”xF“x

  "Next delimiters generally not requiring new lines
  "Math mode brackets
  call s:target('|', '\left\|', '\right\|', 1)
  call s:target('{', '\left\{', '\right\}', 1)
  call s:target('(', '\left(',  '\right)',  1)
  call s:target('[', '\left[',  '\right]',  1)
  call s:target('<', '\left<',  '\right>',  1)

  "Arrays and whatnot; analagous to above, just point to right
  call s:target('}', '\left\{\begin{array}{ll}', "\n".'\end{array}\right.', 1)
  call s:target(')', '\begin{pmatrix}',          "\n".'\end{pmatrix}',      1)
  call s:target(']', '\begin{bmatrix}',          "\n".'\end{bmatrix}',      1)

  "Font types
  call s:target('o', '{\color{red}', '}', 1) "requires \usepackage[colorlinks]{hyperref}
  call s:target('u', '\underline{',  '}', 1)
  call s:target('i', '\textit{',     '}', 1)
  call s:target('E', '\emph{'  ,     '}', 1) "use e for times 10 to the whatever
  call s:target('b', '\textbf{',     '}', 1)
  call s:target('B', '\mathbf{',     '}', 1)
  call s:target('r', '\mathrm{',     '}', 1)
  call s:target('R', '\mathbb{',     '}', 1) "usually for denoting sets of numbers
  call s:target('z', '\mathcal{',    '}', 1)

  "Verbatim
  call s:target('y', '\texttt{',     '}', 1) "typewriter text
  call s:target('Y', '\pyth$',       '$', 1) "python verbatim
  call s:target('V', '\verb$',       '$', 1) "verbatim

  "Math modifiers for symbols
  call s:target('v', '\vec{',        '}', 1)
  call s:target('d', '\dot{',        '}', 1)
  call s:target('D', '\ddot{',       '}', 1)
  call s:target('h', '\hat{',        '}', 1)
  call s:target('`', '\tilde{',      '}', 1)
  call s:target('-', '\overline{',   '}', 1)
  call s:target('_', '\cancelto{}{', '}', 1)

  "Boxes; the second one allows stuff to extend into margins, possibly
  call s:target('x', '\boxed{',      '}', 1)
  call s:target('X', '\fbox{\parbox{\textwidth}{', '}}\medskip', 1)

  "Simple enivronments, exponents, etc.
  call s:target('\', '\sqrt{',       '}',   1)
  call s:target('$', '$',            '$',   1)
  call s:target('e', '\times10^{',   '}',   1)
  " call s:target('k', '^\mathrm{',           '}',   1)
  " call s:target('j', '_\mathrm{',           '}',   1)
  call s:target('k', '\overset{}{',  '}',   1)
  call s:target('j', '\underset{}{', '}',   1)
  call s:target('/', '\frac{',      '}{}', 1)
  call s:target('?', '\dfrac{',      '}{}', 1)

  "Sections and titles
  call s:target('~', '\title{',     '}',   1)
  call s:target('1', '\section{',        '}',   1)
  call s:target('2', '\subsection{',     '}',   1)
  call s:target('3', '\subsubsection{',  '}',   1)
  call s:target('4', '\section*{',       '}',   1)
  call s:target('5', '\subsection*{',    '}',   1)
  call s:target('6', '\subsubsection*{', '}',   1)

  "Beamer
  call s:target('n', '\pdfcomment{', '}', 1) "not sure what this is used for
  call s:target('!', '\frametitle{', '}', 1)
  " call s:target('c', '\begin{column}{',  "}\n".'\end{column}', 1)
  " call s:target('C', '\begin{columns}[', ']\end{columns}',     1)
  call s:target('c', '\begin{column}{0.5\textwidth}',  "\n".'\end{column}', 1)
  call s:target('C', '\begin{columns}', "\n".'\end{columns}')
  " call s:target('z', '\note{',    '}', 1) "notes are for beamer presentations, appear in separate slide

  "Shortcuts for citations and such
  call s:target('7', '\ref{',     '}', 1) "just the number
  call s:target('8', '\autoref{', '}', 1) "name and number; autoref is part of hyperref package
  call s:target('9', '\label{',   '}', 1) "declare labels that ref and autoref point to
  call s:target('0', '\tag{',     '}', 1) "change the default 1-2-3 ordering; common to use *
  call s:target('a', '\caption{', '}', 1) "amazingly 'a' not used yet
  call s:target('A', '\captionof{figure}{', '}', 1) "alternative

  "Other stuff like citenum/citep (natbib) and textcite/authorcite (biblatex) must be done manually
  "NOTE: Now use Zotero citation thing, do not need these.
  " call s:target('n', '\cite{',   '}',     1) "second most common one
  " call s:target('N', '\citenum{',    '}', 1) "most common
  " call s:target('m', '\citep{',   '}',    1) "second most common one
  " call s:target('M', '\citet{', '}',      1) "most common
  " call s:target('G', '\vcenteredhbox{\includegraphics[width=\textwidth]{', '}}', 1) "use in beamer talks

  "The next enfironments will also insert *newlines*
  "Frame; fragile option makes verbatim possible (https://tex.stackexchange.com/q/136240/73149)
  "note that fragile make compiling way slower
  "Slide with 'w'hite frame is the w map
  call s:target('g', '\includegraphics[width=\textwidth]{', '}', 1) "center across margins
  call s:target('G', '\makebox[\textwidth][c]{\includegraphics[width=\textwidth]{', '}}', 1) "center across margins
  call s:target('s', '\begin{frame}',                          "\n".'\end{frame}' , 1)
  call s:target('S', '\begin{frame}[fragile]',                 "\n".'\end{frame}' , 1)
  call s:target('w', '{\usebackgroundtemplate{}\begin{frame}', "\n".'\end{frame}}', 1)

  "Figure environments, and pages
  call s:target('m', '\begin{minipage}{\linewidth}', "\n".'\end{minipage}', 1) "not sure what this is used for
  call s:target('f', '\begin{center}'."\n".'\centering'."\n".'\includegraphics{', "}\n".'\end{center}', 1)
  call s:target('F', '\begin{figure}'."\n".'\centering'."\n".'\includegraphics{', "}\n".'\end{figure}', 1)
  call s:target('W', '\begin{wrapfigure}{r}{.5\textwidth}'."\n".'\centering'."\n".'\includegraphics{', "}\n".'\end{wrapfigure}', 1)
  " call s:target('F', '\begin{subfigure}{.5\textwidth}'."\n".'\centering'."\n".'\includegraphics{', "}\n".'\end{subfigure}', 1)

  "Equations
  call s:target('%', '\begin{equation*}', "\n".'\end{equation*}', 1)
  call s:target('^', '\begin{align*}', "\n".'\end{align*}', 1)
  call s:target('t', '\begin{tabular}{', "}\n".'\end{tabular}', 1)
  call s:target('T', '\begin{table}'."\n".'\centering'."\n".'\caption{}'."\n".'\begin{tabular}{', "}\n".'\end{tabular}'."\n".'\end{table}', 1)
  call s:target('>', '\uncover<X>{%', "\n".'}', 1)

  "Itemize environments
  call s:target('*', '\begin{itemize}',                  "\n".'\end{itemize}', 1)
  call s:target('&', '\begin{description}',              "\n".'\end{description}', 1) "d is now open
  call s:target('#', '\begin{enumerate}',                "\n".'\end{enumerate}', 1)
  call s:target('@', '\begin{enumerate}[label=\alph*.]', "\n".'\end{enumerate}', 1)

  "Versions of the above, but this time puting them on own lines
  "TODO: fix these
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

  "------------------------------------------------------------------------------"
  "Shortcuts
  "------------------------------------------------------------------------------"
  "Basics
  call s:symbol('[', '[]<Left>')
  call s:symbol('(', '()<Left>')
  call s:symbol('<', '<><Left>')
  call s:symbol('{', '{}<Left>')

  "Font sizing
  call s:symbol('1', '\tiny')
  call s:symbol('2', '\scriptsize')
  call s:symbol('3', '\footnotesize')
  call s:symbol('4', '\small')
  call s:symbol('5', '\normalsize')
  call s:symbol('6', '\large')
  call s:symbol('7', '\Large')
  call s:symbol('8', '\LARGE')
  call s:symbol('9', '\huge')
  call s:symbol('0', '\Huge')

  "First arrows, most commonly used ones anyway
  call s:symbol('>', '\Rightarrow')
  call s:symbol('<', '\Longrightarrow')
  "Misc symbotls, want quick access
  call s:symbol(';', '\item')
  call s:symbol('/', '\pause')
  "Math symbols
  call s:symbol('a', '\alpha')
  call s:symbol('b', '\beta')
  call s:symbol('c', '\xi')
  "weird curly one
  "the upper case looks like 3 lines
  call s:symbol('C', '\Xi')
  "looks like an x so want to use this map
  "pronounced 'zi', the 'i' in 'tide'
  call s:symbol('x', '\chi')

  "Greek letters
  call s:symbol('d', '\delta')
  call s:symbol('D', '\Delta')
  call s:symbol('f', '\phi')
  call s:symbol('F', '\Phi')
  call s:symbol('g', '\gamma')
  call s:symbol('G', '\Gamma')
  call s:symbol('K', '\kappa')
  call s:symbol('l', '\lambda')
  call s:symbol('L', '\Lambda')
  call s:symbol('m', '\mu')
  call s:symbol('n', '\nabla')
  call s:symbol('N', '\nu')
  call s:symbol('e', '\epsilon')
  call s:symbol('E', '\eta')
  call s:symbol('p', '\pi')
  call s:symbol('P', '\Pi')
  call s:symbol('q', '\theta')
  call s:symbol('Q', '\Theta')
  call s:symbol('r', '\rho')
  call s:symbol('s', '\sigma')
  call s:symbol('S', '\Sigma')
  call s:symbol('t', '\tau')
  call s:symbol('y', '\psi')
  call s:symbol('Y', '\Psi')
  call s:symbol('w', '\omega')
  call s:symbol('W', '\Omega')
  call s:symbol('z', '\zeta')

  "Needed for pdfcomment newlines
  call s:symbol('M', '\textCR<CR>')

  "Derivatives
  call s:symbol(':', '\partial')
  call s:symbol("'", '\mathrm{d}')
  call s:symbol('"', '\mathrm{D}')

  "u is for unary
  call s:symbol('U', '${-}$')
  call s:symbol('u', '${+}$')

  "Integration
  call s:symbol('i', '\int')
  call s:symbol('I', '\iint')

  "3 levels of differentiation; each one stronger
  call s:symbol('-', '${-}$')
  call s:symbol('+', '\sum')
  call s:symbol('*', '\prod')
  call s:symbol('x', '\times')
  call s:symbol('.', '\cdot')
  call s:symbol('o', '$^\circ$')
  call s:symbol('=', '\equiv')
  call s:symbol('~', '{\sim}')
  call s:symbol('k', '^{}<Left>')
  call s:symbol('j', '_{}<Left>')
  call s:symbol('K', '^\mathrm{}<Left>')
  call s:symbol('J', '_\mathrm{}<Left>')
  call s:symbol(',', '\,')

  "Insert a line (feel free to modify width), will prompt user for fraction of page
  "Note centering fails inside itemize environments, so use begin/end center instead
  " _ '{\centering\noindent\rule{'.input('fraction: ').'\textwidth}{0.7pt}}'
  " call s:symbol('_', "'\begin{center}\noindent\rule{'.input('fraction: ').'\textwidth}{0.7pt}\end{center}'")
endfunction

"------------------------------------------------------------------------------"
"HTML macros
"------------------------------------------------------------------------------"
"For now pretty empty, but we should add to this
"Note that tag delimiters are *built in* to vim-surround
"Just use the target 't', and prompt will ask for description
augroup html_delimit
  au!
  au FileType html call s:htmlmacros()
augroup END
function! s:htmlmacros()
  call s:target('h', '<head>',   '</head>',   1)
  call s:target('b', '<body>',   '</body>',   1)
  call s:target('t', '<title>',  '</title>',  1)
  call s:target('e', '<em>',     '</em>',     1)
  call s:target('t', '<strong>', '</strong>', 1)
  call s:target('p', '<p>',      '</p>',      1)
  call s:target('1', '<h1>',     '</h1>',     1)
  call s:target('2', '<h2>',     '</h2>',     1)
  call s:target('3', '<h3>',     '</h3>',     1)
  call s:target('4', '<h4>',     '</h4>',     1)
  call s:target('5', '<h5>',     '</h5>',     1)
endfunction

