"-----------------------------------------------------------------------------"
" Author: Luke Davis (lukelbd@gmail.com)
" Date:   2018-09-10
" LaTeX specific settings
"-----------------------------------------------------------------------------"
" Latexmk integration
" Todo: This should be part of independent plugin, and snippets stuff put into
" idetools plugin... except things like templates, citations integration, and
" graphics path detection are extremely tex-specific so hard to see how to divide
" things up! Maybe consider vim-delimtools plugin or something.
" Todo: For vim-delimtools should add set-and-forget global dictionaries for filetype
" specific text objects, snippets, and delimiters. Then plugin automatically syncs
" those with textobj and defines buffer-local snippet and surround vars.
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
let s:textools_snippet_map = {
  \ '[': textools#ensure_math('\partial'),
  \ ']': textools#ensure_math('\textnormal{d}'),
  \ '\': textools#ensure_math('\textnormal{D}'),
  \ '*': '\item',
  \ '+': textools#ensure_math('\sum'),
  \ ',': textools#make_snippet(function('textools#label_select'), '\autoref{', '}'),
  \ '.': textools#ensure_math('\cdot'),
  \ '/': textools#format_units(textools#user_input('Units'), ''),
  \ '0': '\Huge',
  \ '1': '\tiny',
  \ '2': '\scriptsize',
  \ '3': '\footnotesize',
  \ '4': '\small',
  \ '5': '\normalsize',
  \ '6': '\large',
  \ '7': '\Large',
  \ '8': '\LARGE',
  \ '9': '\huge',
  \ ';': textools#make_snippet(function('textools#cite_select'), '\citep{', '}'),
  \ ':': textools#make_snippet(function('textools#cite_select'), '\citet{', '}'),
  \ "'": textools#make_snippet(function('textools#graphic_select'), '\includegraphics{', '}'),
  \ '"': textools#make_snippet(function('textools#graphic_select'), '\makebox[\textwidth][c]{\includegraphics{', '}}'),
  \ '<': textools#ensure_math('\Longrightarrow'),
  \ '=': textools#ensure_math('\equiv'),
  \ '>': textools#ensure_math('\Longrightarrow'),
  \ '?': '\pause',
  \ 'C': textools#ensure_math('\Xi'),
  \ 'D': textools#ensure_math('\Delta'),
  \ 'E': textools#ensure_math(textools#user_input('Exponent'), '\times 10^{', '}'),
  \ 'F': textools#ensure_math('\Phi'),
  \ 'G': textools#ensure_math('\Gamma'),
  \ 'I': textools#ensure_math('\iint'),
  \ 'K': textools#ensure_math('\kappa'),
  \ 'L': textools#ensure_math('\Lambda'),
  \ 'M': ' \textCR' . "\<CR>",
  \ 'o': textools#ensure_math('^\circ'),
  \ 'P': textools#ensure_math('\Pi'),
  \ 'Q': textools#ensure_math('\Theta'),
  \ 'S': textools#ensure_math('\Sigma'),
  \ 'T': textools#ensure_math('\chi'),
  \ 'U': textools#ensure_math('{-}'),
  \ 'W': textools#ensure_math('\Omega'),
  \ 'X': textools#ensure_math('\prod'),
  \ 'Y': textools#ensure_math('\Psi'),
  \ 'a': textools#ensure_math('\alpha'),
  \ 'b': textools#ensure_math('\beta'),
  \ 'c': textools#ensure_math('\xi'),
  \ 'd': textools#ensure_math('\delta'),
  \ 'e': textools#ensure_math('\epsilon'),
  \ 'f': textools#ensure_math('\phi'),
  \ 'g': textools#ensure_math('\gamma'),
  \ 'h': textools#ensure_math('\eta'),
  \ 'i': textools#ensure_math('\int'),
  \ 'j': textools#ensure_math(textools#user_input('Subscript'), '_{', '}'),
  \ 'k': textools#ensure_math(textools#user_input('Supersript'), '^{', '}'),
  \ 'l': textools#ensure_math('\lambda'),
  \ 'm': textools#ensure_math('\mu'),
  \ 'n': textools#ensure_math('\nabla'),
  \ 'p': textools#ensure_math('\pi'),
  \ 'q': textools#ensure_math('\theta'),
  \ 'r': textools#ensure_math('\rho'),
  \ 's': textools#ensure_math('\sigma'),
  \ 't': textools#ensure_math('\tau'),
  \ 'u': textools#ensure_math('{+}'),
  \ 'v': textools#ensure_math('\nu'),
  \ 'w': textools#ensure_math('\omega'),
  \ 'x': textools#ensure_math('\times'),
  \ 'y': textools#ensure_math('\psi'),
  \ 'z': textools#ensure_math('\zeta'),
  \ '~': textools#ensure_math('\sim'),
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
  \ ';': ['\citep{',                          '}'],
  \ ':': ['\citet{',                          '}'],
  \ '?': ['\dfrac{',                          '}{}'],
  \ 'A': ['\captionof{figure}{',              '}'],
  \ 'D': ['\ddot{',                           '}'],
  \ 'E': ['{\color{red}',                     '}'],
  \ 'J': ['\underset{}{',                     '}'],
  \ 'K': ['\overset{}{',                      '}'],
  \ 'L': ["\href{\1Link: \1}{",               '}'],
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
  \ 'l': ['\mathcal{',                        '}'],
  \ 'm': ['\textnormal{',                     '}'],
  \ 'n': ['\pdfcomment{' . "\n",              "\n}"],
  \ 'o': ['\textbf{',                         '}'],
  \ 'r': ['[',                                ']'],
  \ 's': ['\begin{frame}',                    "\n" . '\end{frame}'],
  \ 't': ["\\\1Command: \1{",                 '}'],
  \ 'u': ['\underline{',                      '}'],
  \ 'v': ['\vec{',                            '}'],
  \ 'x': ['\boxed{',                          '}'],
  \ 'y': ['\texttt{',                         '}'],
  \ 'z': ['\begin{column}{0.5\textwidth}',    "\n" . '\end{column}'],
  \ 'f': [
  \   '\begin{figure}' . "\n" . '\centering' . "\n",
  \   "\n" . '\end{figure}'
  \ ],
  \ 'F': [
  \   '\begin{center}' . "\n" . '\centering' . "\n",
  \   "\n" . '\end{center}'
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
  let b:surround_{char2nr(s:key)} = s:pair[0] . "\r" . s:pair[1]
endfor
