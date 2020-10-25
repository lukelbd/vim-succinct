"-----------------------------------------------------------------------------"
" Author: Luke Davis (lukelbd@gmail.com)
" Date:   2018-09-10
" LaTeX specific settings
"-----------------------------------------------------------------------------"
" Latexmk integration
" Todo: This should be aprt of independent plugin, and snippets stuff put into
" idetools plugin... except things like templates, citations integration, and
" graphics path detection are extremely tex-specific so hard to see how to divide
" things up! Maybe consider vim-delimtools plugin or something.
" Warning: Imperfection is ok! This stuff is still really useful!
command! -buffer -nargs=* Latexmk call textools#latex_background(<q-args>)

" DelimitMate integration
let b:delimitMate_quotes = '$ |'
let b:delimitMate_matchpairs = "(:),{:},[:],`:'"

" Text object integration
" Copied from: https://github.com/rbonvall/vim-textobj-latex/blob/master/ftplugin/tex/textobj-latex.vim
" so the names could be changed. Also changed begin end modes so they make more sense.
" 'pattern': ['\\begin{[^}]\+}.*\n\s*', '\n^\s*\\end{[^}]\+}.*$'],
let s:tex_textobjs_dict = {
  \   'environment': {
  \     'pattern': ['\\begin{[^}]\+}.*\n', '\\end{[^}]\+}'],
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

" Add maps with textobj API
if exists('*textobj#user#plugin')
  call textobj#user#plugin('latex', s:tex_textobjs_dict)
endif

" Snippet dictionaries. Each snippet is made into an <expr> map by prepending
" and appending the strings with single quotes. This lets us make input()
" dependent snippets as shown for the 'j', 'k', and 'E' mappings.
" * \xi is the weird curly one, pronounced 'zai'
" * \chi looks like an x, pronounced 'kai'
" * the 'u' used for {-} and {+} is for 'unary'
" * rejected options:
" \ ':': '$\:$',
" \ ';': '$\;$',
" \ ',': '\, ',
" \ ':': '\: ',
" \ ';': '\; ',
" \ 'q': '\quad ',
let s:textools_snippet_map = {
  \ 'M': ' \textCR<CR>',
  \ '1': '\tiny',
  \ '2': '\scriptsize',
  \ '3': '\footnotesize',
  \ '4': '\small',
  \ '5': '\normalsize',
  \ '6': '\large',
  \ '7': '\Large',
  \ '8': '\LARGE',
  \ '9': '\huge',
  \ '0': '\Huge',
  \ '*': '\item',
  \ '?': '\pause',
  \ 'u': 'textools#math_wrap("{+}")',
  \ 'U': 'textools#math_wrap("{-}")',
  \ 'o': 'textools#math_wrap("\\\\partial")',
  \ "'": 'textools#math_wrap("\\\\textnormal{d}")',
  \ '"': 'textools#math_wrap("\\\\textnormal{D}")',
  \ '<': 'textools#math_wrap("\\\\Longrightarrow")',
  \ '>': 'textools#math_wrap("\\\\Longrightarrow")',
  \ 'a': 'textools#math_wrap("\\\\alpha")',
  \ 'b': 'textools#math_wrap("\\\\beta")',
  \ 'c': 'textools#math_wrap("\\\\xi")',
  \ 'C': 'textools#math_wrap("\\\\Xi")',
  \ 'd': 'textools#math_wrap("\\\\delta")',
  \ 'D': 'textools#math_wrap("\\\\Delta")',
  \ 'f': 'textools#math_wrap("\\\\phi")',
  \ 'F': 'textools#math_wrap("\\\\Phi")',
  \ 'g': 'textools#math_wrap("\\\\gamma")',
  \ 'G': 'textools#math_wrap("\\\\Gamma")',
  \ 'K': 'textools#math_wrap("\\\\kappa")',
  \ 'l': 'textools#math_wrap("\\\\lambda")',
  \ 'L': 'textools#math_wrap("\\\\Lambda")',
  \ 'm': 'textools#math_wrap("\\\\mu")',
  \ 'n': 'textools#math_wrap("\\\\nabla")',
  \ 'v': 'textools#math_wrap("\\\\nu")',
  \ 'e': 'textools#math_wrap("\\\\epsilon")',
  \ 'h': 'textools#math_wrap("\\\\eta")',
  \ 'p': 'textools#math_wrap("\\\\pi")',
  \ 'P': 'textools#math_wrap("\\\\Pi")',
  \ 'q': 'textools#math_wrap("\\\\theta")',
  \ 'Q': 'textools#math_wrap("\\\\Theta")',
  \ 'r': 'textools#math_wrap("\\\\rho")',
  \ 's': 'textools#math_wrap("\\\\sigma")',
  \ 'S': 'textools#math_wrap("\\\\Sigma")',
  \ 't': 'textools#math_wrap("\\\\tau")',
  \ 'T': 'textools#math_wrap("\\\\chi")',
  \ 'y': 'textools#math_wrap("\\\\psi")',
  \ 'Y': 'textools#math_wrap("\\\\Psi")',
  \ 'w': 'textools#math_wrap("\\\\omega")',
  \ 'W': 'textools#math_wrap("\\\\Omega")',
  \ 'z': 'textools#math_wrap("\\\\zeta")',
  \ 'i': 'textools#math_wrap("\\\\int")',
  \ 'I': 'textools#math_wrap("\\\\iint")',
  \ '+': 'textools#math_wrap("\\\\sum")',
  \ 'x': 'textools#math_wrap("\\\\times")',
  \ 'X': 'textools#math_wrap("\\\\prod")',
  \ '=': 'textools#math_wrap("\\\\equiv")',
  \ '~': 'textools#math_wrap("\\\\sim")',
  \ '.': 'textools#math_wrap("\\\\cdot")',
  \ 'O': 'textools#math_wrap("^\\\\circ")',
  \ ';': 'textools#cite_select()',
  \ ':': 'textools#graphic_select()',
  \ ',': 'textools#label_select()',
  \ '/': 'textools#format_units(input("Units: ", "", "customlist,NullList"))',
  \ 'k': 'textools#math_wrap("^{" . input("Superscript: ", "", "customlist,NullList") . "}")',
  \ 'j': 'textools#math_wrap("_{" . input("Subscript: ", "", "customlist,NullList") . "}")',
  \ 'E': 'textools#math_wrap("\\\\times 10^{" . input("Exponent: ", "", "customlist,NullList") . "}")',
\ }

" Define snippet variables (analogous to vim-surround approach)
for [s:key, s:snippet] in items(s:textools_snippet_map)
  let b:snippet_{char2nr(s:key)} = s:snippet
endfor

" Surround tools
" * rejected maps:
" \ ':': ['\newpage\hspace{0pt}\vfill', "\n".'\vfill\hspace{0pt}\newpage'],
" \ 'F': ['\begin{subfigure}{.5\textwidth}'."\n".'\centering'."\n".'\includegraphics{', "}\n".'\end{subfigure}'],
" \ 'y': ['\begin{python}',       "\n".'\end{python}'],
" \ 'b': ['\begin{block}{}',      "\n".'\end{block}'],
" \ 'B': ['\begin{alertblock}{}', "\n".'\end{alertblock}'],
" \ 'v': ['\begin{verbatim}',     "\n".'\end{verbatim}'],
" \ 'a': ['<',                                '>'],
let s:textools_surround_map = {
  \ "'": ['`',                                "'"],
  \ '!': ['\frametitle{',                     '}'],
  \ '~': ['\title{',                          '}'],
  \ '"': ['``',                               "''"],
  \ '$': ['$',                                '$'],
  \ '#': ['\begin{enumerate}',                "\n" . '\end{enumerate}'],
  \ '*': ['\begin{itemize}',                  "\n" . '\end{itemize}'],
  \ '^': ['\begin{align}',                    "\n" . '\end{align}'],
  \ '%': ['\begin{align*}',                   "\n" . '\end{align*}'],
  \ '&': ['\begin{description}',              "\n" . '\end{description}'],
  \ '@': ['\begin{enumerate}[label=\alph*.]', "\n" . '\end{enumerate}'],
  \ ',': ['\begin{tabular}{',                 "}\n" . '\end{tabular}'],
  \ '(': ['\left(',                           '\right)'],
  \ '[': ['\left[',                           '\right]'],
  \ '{': ['\left\{',                          '\right\}'],
  \ '<': ['\left<',                           '\right>'],
  \ '|': ['\left\|',                          '\right\|'],
  \ '}': ['\left\{\begin{array}{ll}',         "\n" . '\end{array}\right.'],
  \ ']': ['\begin{bmatrix}',                  "\n" . '\end{bmatrix}'],
  \ ')': ['\begin{pmatrix}',                  "\n" . '\end{pmatrix}'],
  \ '>': ['\uncover<X>{%',                    "\n" . '}'],
  \ '\': ['\sqrt{',                           '}'],
  \ '_': ['\cancelto{}{',                     '}'],
  \ '`': ['\tilde{',                          '}'],
  \ '-': ['\overline{',                       '}'],
  \ '/': ['\frac{',                           '}{}'],
  \ '0': ['\tag{',                            '}'],
  \ '1': ['\section{',                        '}'],
  \ '2': ['\subsection{',                     '}'],
  \ '3': ['\subsubsection{',                  '}'],
  \ '4': ['\section*{',                       '}'],
  \ '5': ['\subsection*{',                    '}'],
  \ '6': ['\subsubsection*{',                 '}'],
  \ '7': ['\ref{',                            '}'],
  \ '8': ['\autoref{',                        '}'],
  \ '9': ['\label{',                          '}'],
  \ ';': ['\citet{',                          '}'],
  \ ':': ['\citep{',                          '}'],
  \ '?': ['\dfrac{',                          '}{}'],
  \ 'A': ['\captionof{figure}{',              '}'],
  \ 'D': ['\ddot{',                           '}'],
  \ 'E': ['{\color{red}',                     '}'],
  \ 'J': ['\underset{}{',                     '}'],
  \ 'K': ['\overset{}{',                      '}'],
  \ 'L': ['\mathcal{',                        '}'],
  \ 'M': ['\mathbb{',                         '}'],
  \ 'O': ['\mathbf{',                         '}'],
  \ 'S': ['\begin{frame}[fragile]',           "\n" . '\end{frame}'],
  \ 'T': ["\\begin{\1\\begin{\1}",            "\n" . "\\end{\1\1}"],
  \ 'V': ['\verb$',                           '$'],
  \ 'X': ['\fbox{\parbox{\textwidth}{',       '}}\medskip'],
  \ 'Y': ['\pyth$',                           '$'],
  \ 'Z': ['\begin{columns}',                  "\n" . '\end{columns}'],
  \ 'a': ['\caption{',                        '}'],
  \ 'b': ['(',                                ')'],
  \ 'c': ['{',                                '}'],
  \ 'd': ['\dot{',                            '}'],
  \ 'e': ['\emph{'  ,                         '}'],
  \ 'h': ['\hat{',                            '}'],
  \ 'i': ['\textit{',                         '}'],
  \ 'j': ['_{',                               '}'],
  \ 'k': ['^{',                               '}'],
  \ 'm': ['\textnormal{',                     '}'],
  \ 'n': ['\pdfcomment{' . "\n",              "\n}"],
  \ 'o': ['\textbf{',                         '}'],
  \ 'r': ['[',                                ']'],
  \ 's': ['\begin{frame}',                    "\n" . '\end{frame}'],
  \ 't': ["\\\1command: \1{",                 '}'],
  \ 'u': ['\underline{',                      '}'],
  \ 'v': ['\vec{',                            '}'],
  \ 'x': ['\boxed{',                          '}'],
  \ 'y': ['\texttt{',                         '}'],
  \ 'z': ['\begin{column}{0.5\textwidth}',    "\n" . '\end{column}'],
  \ 'f': [
  \   '\begin{figure}' . "\n" . '\centering' . "\n" . '\includegraphics{',
  \   "}\n" . '\end{figure}'
  \ ],
  \ 'F': [
  \   '\begin{center}' . "\n" . '\centering' . "\n" . '\includegraphics{',
  \   "}\n" . '\end{center}'
  \ ],
  \ 'g': [
  \   '\includegraphics{',
  \   '}'
  \ ],
  \ 'G': [
  \   '\makebox[\textwidth][c]{\includegraphics{',
  \   '}}'
  \ ],
  \ 'p': [
  \   '\begin{minipage}{\linewidth}',
  \   "\n" . '\end{minipage}'
  \ ],
  \ '.': [
  \   '\begin{table}' . "\n" . '\centering' . "\n" . '\caption{}' . "\n" . '\begin{tabular}{',
  \   "}\n" . '\end{tabular}' . "\n" . '\end{table}'
  \ ],
  \ 'w': [
  \   '{\usebackgroundtemplate{}\begin{frame}',
  \   "\n" . '\end{frame}}'
  \ ],
  \ 'W': [
  \   '\begin{wrapfigure}{r}{0.5\textwidth}' . "\n" . '\centering' . "\n" . '\includegraphics{',
  \   "}\n" . '\end{wrapfigure}'
  \ ],
\ }

" Apply delimiter mappings
for [s:key, s:pair] in items(s:textools_surround_map)
  let [s:left, s:right] = s:pair
  let b:surround_{char2nr(s:key)} = s:left . "\r" . s:right
endfor
