"-----------------------------------------------------------------------------"
" Author: Luke Davis (lukelbd@gmail.com)
" Date:   2018-09-10
" LaTeX specific settings
"-----------------------------------------------------------------------------"
" Restrict concealmeant to just accents, Greek symbols, and math symbols
let g:tex_conceal = 'agm'

" Allow @ in makeatletter, allow texmathonly outside of math regions (i.e.
" don't highlight [_^] when you think they are outside math zone)
let g:tex_stylish = 1

" Disable spell checking in verbatim mode and comments, disable errors
let g:tex_fold_enable = 1
let g:tex_comment_nospell = 1
let g:tex_verbspell = 0
let g:tex_no_error = 1
" let g:tex_fast = ''  " fast highlighting, but pretty ugly

" Latex compiling command and mapping
command! -nargs=* Latexmk call textools#latex_background(<q-args>)
if exists('g:textools_latexmk_maps')
  for [s:map,s:flag] in items(g:textools_latexmk_maps)
    exe 'noremap <silent> <buffer> ' . s:map . ' :Latexmk ' . s:flag . '<CR>'
  endfor
endif

" Map prefixes
if !exists('g:textools_snippet_prefix')
  let g:textools_snippet_prefix = '<C-z>'
endif
if !exists('g:textools_surround_prefix')
  let g:textools_surround_prefix = '<C-s>'
endif
if !exists('g:textools_citation_maps')
  let g:textools_citation_maps = {'c': '', 't': 't', 'p': 'p', 'n': 'num'}
endif
if !exists('g:textools_citation_prefix')
  let g:textools_citation_prefix = '<C-b>'
endif

"-----------------------------------------------------------------------------"
" Text object integration
"-----------------------------------------------------------------------------"
if exists('*textobj#user#plugin')
  " TeX plugin definitions
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
  call textobj#user#plugin('latex', s:tex_textobjs_dict)
endif


"-----------------------------------------------------------------------------"
" Useful latex snippets
" Todo: Integrate with some snippets plugin?
"-----------------------------------------------------------------------------"
" Snippet dictionary
" \xi is the weird curly one, pronounced 'zai'
" \chi looks like an x, pronounced 'kai'
" the 'u' used for {-} and {+} is for 'unary'
" '_' '\begin{center}\noindent\rule{' . input('fraction: ') . '\textwidth}{0.7pt}\end{center}'
" \ 'q': '\quad ',
let s:textools_snippets = {
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
  \ '<': '\Longrightarrow',
  \ '>': '\Longrightarrow',
  \ '*': '\item',
  \ '/': '\pause',
  \ 'o': '\partial',
  \ "'": '\mathrm{d}',
  \ '"': '\mathrm{D}',
  \ 'U': '${-}$',
  \ 'u': '${+}$',
  \ 'a': '\alpha',
  \ 'b': '\beta',
  \ 'c': '\xi',
  \ 'C': '\Xi',
  \ 'd': '\delta',
  \ 'D': '\Delta',
  \ 'f': '\phi',
  \ 'F': '\Phi',
  \ 'g': '\gamma',
  \ 'G': '\Gamma',
  \ 'K': '\kappa',
  \ 'l': '\lambda',
  \ 'L': '\Lambda',
  \ 'm': '\mu',
  \ 'n': '\nabla',
  \ 'v': '\nu',
  \ 'e': '\epsilon',
  \ 'h': '\eta',
  \ 'p': '\pi',
  \ 'P': '\Pi',
  \ 'q': '\theta',
  \ 'Q': '\Theta',
  \ 'r': '\rho',
  \ 's': '\sigma',
  \ 'S': '\Sigma',
  \ 't': '\tau',
  \ 'T': '\chi',
  \ 'y': '\psi',
  \ 'Y': '\Psi',
  \ 'w': '\omega',
  \ 'W': '\Omega',
  \ 'z': '\zeta',
  \ 'i': '\int',
  \ 'I': '\iint',
  \ '-': '${-}$',
  \ '+': '\sum',
  \ 'x': '\times',
  \ 'X': '\prod',
  \ 'O': '$^\circ$',
  \ '=': '\equiv',
  \ '~': '{\sim}',
  \ 'k': '^',
  \ 'j': '_',
  \ 'E': '\times10^{}<Left>',
  \ '.': '\cdot',
  \ ',': '\, ',
  \ ':': '\: ',
  \ ';': '\; ',
  \ 'M': ' \textCR<CR>',
\ }

" Apply snippets mappings
exe 'inoremap ' . g:textools_snippet_prefix . '<Esc> <Nop>'
for [s:binding, s:snippet] in items(s:textools_snippets)
  exe 'inoremap <buffer> ' . g:textools_snippet_prefix . s:binding . ' ' . s:snippet
endfor

" Table and find
command! -nargs=0 SnippetShow call textools#show_bindings(g:textools_snippet_prefix, s:textools_snippets)
command! -nargs=+ SnippetFind call textools#find_bindings(g:textools_snippet_prefix, s:textools_snippets, <q-args>)


"-----------------------------------------------------------------------------"
" Vim-surround integration
"-----------------------------------------------------------------------------"
if exists('g:loaded_surround') && g:loaded_surround
  " Brackets and environments
  " Todo: Make delete-change features more like this.
  " ':': ['\newpage\hspace{0pt}\vfill', "\n".'\vfill\hspace{0pt}\newpage'],
  " \ 'F': ['\begin{subfigure}{.5\textwidth}'."\n".'\centering'."\n".'\includegraphics{', "}\n".'\end{subfigure}'],
  " \ 'y': ['\begin{python}',       "\n".'\end{python}'],
  " \ 'b': ['\begin{block}{}',      "\n".'\end{block}'],
  " \ 'B': ['\begin{alertblock}{}', "\n".'\end{alertblock}'],
  " \ 'v': ['\begin{verbatim}',     "\n".'\end{verbatim}'],
  " \ 'a': ['<',                                '>'],
  let s:textools_surround = {
    \ 't': ["\\\1command: \1{",                 '}'],
    \ 'T': ["\\begin{\1\\begin{\1}",            "\n" . "\\end{\1\1}"],
    \ 'b': ['(',                                ')'],
    \ 'c': ['{',                                '}'],
    \ 'B': ['{',                                '}'],
    \ 'r': ['[',                                ']'],
    \ '{': ['\left\{',                          '\right\}'],
    \ '(': ['\left(',                           '\right)'],
    \ '[': ['\left[',                           '\right]'],
    \ '<': ['\left<',                           '\right>'],
    \ '|': ['\left\|',                          '\right\|'],
    \ '}': ['\left\{\begin{array}{ll}',         "\n" . '\end{array}\right.'],
    \ ')': ['\begin{pmatrix}',                  "\n" . '\end{pmatrix}'],
    \ ']': ['\begin{bmatrix}',                  "\n" . '\end{bmatrix}'],
    \ '>': ['\uncover<X>{%',                    "\n" . '}'],
    \ "'": ['`',                                "'"],
    \ '"': ['``',                               "''"],
    \ 'y': ['\texttt{',                         '}'],
    \ 'Y': ['\pyth$',                           '$'],
    \ 'V': ['\verb$',                           '$'],
    \ 'e': ['\emph{'  ,                         '}'],
    \ 'E': ['{\color{red}',                     '}'],
    \ 'u': ['\underline{',                      '}'],
    \ 'i': ['\textit{',                         '}'],
    \ 'o': ['\textbf{',                         '}'],
    \ 'O': ['\mathbf{',                         '}'],
    \ 'm': ['\mathrm{',                         '}'],
    \ 'M': ['\mathbb{',                         '}'],
    \ 'L': ['\mathcal{',                        '}'],
    \ 'v': ['\vec{',                            '}'],
    \ 'd': ['\dot{',                            '}'],
    \ 'D': ['\ddot{',                           '}'],
    \ 'h': ['\hat{',                            '}'],
    \ '`': ['\tilde{',                          '}'],
    \ '-': ['\overline{',                       '}'],
    \ '_': ['\cancelto{}{',                     '}'],
    \ '\': ['\sqrt{',                           '}'],
    \ '$': ['$',                                '$'],
    \ '/': ['\frac{',                           '}{}'],
    \ '?': ['\dfrac{',                          '}{}'],
    \ 'k': ['^{',                               '}'],
    \ 'j': ['_{',                               '}'],
    \ 'K': ['\overset{}{',                      '}'],
    \ 'J': ['\underset{}{',                     '}'],
    \ 'x': ['\boxed{',                          '}'],
    \ 'X': ['\fbox{\parbox{\textwidth}{',       '}}\medskip'],
    \ '~': ['\title{',                          '}'],
    \ '1': ['\section{',                        '}'],
    \ '2': ['\subsection{',                     '}'],
    \ '3': ['\subsubsection{',                  '}'],
    \ '4': ['\section*{',                       '}'],
    \ '5': ['\subsection*{',                    '}'],
    \ '6': ['\subsubsection*{',                 '}'],
    \ '!': ['\frametitle{',                     '}'],
    \ 'n': ['\pdfcomment{' . "\n",              "\n}"],
    \ '7': ['\ref{',                            '}'],
    \ '8': ['\autoref{',                        '}'],
    \ '9': ['\label{',                          '}'],
    \ '0': ['\tag{',                            '}'],
    \ 'a': ['\caption{',                        '}'],
    \ 'A': ['\captionof{figure}{',              '}'],
    \ 's': ['\begin{frame}',                    "\n" . '\end{frame}'],
    \ 'S': ['\begin{frame}[fragile]',           "\n" . '\end{frame}'],
    \ 'z': ['\begin{column}{0.5\textwidth}',    "\n" . '\end{column}'],
    \ 'Z': ['\begin{columns}',                  "\n" . '\end{columns}'],
    \ '%': ['\begin{align}',                    "\n" . '\end{align}'],
    \ '^': ['\begin{align*}',                   "\n" . '\end{align*}'],
    \ ',': ['\begin{tabular}{',                 "}\n" . '\end{tabular}'],
    \ '*': ['\begin{itemize}',                  "\n" . '\end{itemize}'],
    \ '&': ['\begin{description}',              "\n" . '\end{description}'],
    \ '#': ['\begin{enumerate}',                "\n" . '\end{enumerate}'],
    \ '@': ['\begin{enumerate}[label=\alph*.]', "\n" . '\end{enumerate}'],
    \ 'g': [
    \   '\includegraphics{',
    \   '}'
    \ ],
    \ 'G': [
    \   '\makebox[\textwidth][c]{\includegraphics{',
    \   '}}'
    \ ],
    \ 'f': [
    \   '\begin{figure}' . "\n" . '\centering' . "\n" . '\includegraphics{',
    \   "}\n" . '\end{figure}'
    \ ],
    \ 'C': [
    \   '\begin{center}' . "\n" . '\centering' . "\n" . '\includegraphics{',
    \   "}\n" . '\end{center}'
    \ ],
    \ 'w': [
    \   '{\usebackgroundtemplate{}\begin{frame}',
    \   "\n" . '\end{frame}}'
    \ ],
    \ 'W': [
    \   '\begin{wrapfigure}{r}{0.5\textwidth}' . "\n" . '\centering' . "\n" . '\includegraphics{',
    \   "}\n" . '\end{wrapfigure}'
    \ ],
    \ 'p': [
    \   '\begin{minipage}{\linewidth}',
    \   "\n" . '\end{minipage}'
    \ ],
    \ '.': [
    \   '\begin{table}' . "\n" . '\centering' . "\n" . '\caption{}' . "\n" . '\begin{tabular}{',
    \   "}\n" . '\end{tabular}' . "\n" . '\end{table}'
    \ ],
  \ }

  " Apply prefix mapping
  " Note: Lowercase Isurround plug inserts delims without newlines. Instead of
  " using ISurround we define special begin end delims with newlines baked in.
  inoremap <Plug>ResetUndo <C-g>u
  exe 'vmap <buffer> ' . g:textools_surround_prefix   . ' <Plug>VSurround'
  exe 'imap <buffer> ' . g:textools_surround_prefix   . ' <Plug>ResetUndo<Plug>Isurround'

  " Apply delimiters mappings
  exe 'inoremap <buffer> ' . g:textools_surround_prefix   . '<Esc> <Nop>'
  for [s:binding, s:pair] in items(s:textools_surround)
    let [s:left, s:right] = s:pair
    let b:surround_{char2nr(s:binding)} = s:left . "\r" . s:right
  endfor

  " Apply mappings for *changing* and *deleting* these matches
  nnoremap <buffer> <silent> ds :call textools#delete_delims()<CR>
  nnoremap <buffer> <silent> cs :call textools#change_delims()<CR>

  " Table and find
  command! -nargs=0 SurroundShow call textools#show_bindings(g:textools_surround_prefix, s:textools_surround)
  command! -nargs=+ SurroundFind call textools#find_bindings(g:textools_surround_prefix, s:textools_surround, <q-args>)
endif


"-----------------------------------------------------------------------------"
" Citation vim integration
"-----------------------------------------------------------------------------"
" Requires pybtex and bibtexparser python modules, and unite.vim plugin
" Note: Set up with macports. By default the +python vim was compiled with
" is not on path; access with port select --set pip <pip36|python36>. To
" install module dependencies, use that pip. Can also install most packages
" with 'port install py36-module_name' but often get error 'no module
" named pkg_resources'; see this thread: https://stackoverflow.com/a/10538412/4970632
if g:loaded_unite && &rtp =~# 'citation.vim'
  " Default settings
  let b:citation_vim_mode = 'bibtex'
  let b:citation_vim_bibtex_file = ''

  " Global settings
  " Local settings are applied as global variables before calling cite command,
  " and note they are always defined since this is an ftplugin file!
  let g:unite_data_directory = '~/.unite'
  let g:citation_vim_cache_path = '~/.unite'
  let g:citation_vim_outer_prefix = ''
  let g:citation_vim_inner_prefix = ''
  let g:citation_vim_suffix = '}'
  let g:citation_vim_et_al_limit = 3 " show et al if more than 2 authors
  let g:citation_vim_zotero_path = '~/Zotero' " location of .sqlite file
  let g:citation_vim_zotero_version = 5
  let g:citation_vim_opts = '-start-insert -buffer-name=citation -ignorecase -default-action=append citation/key'

  " Command and mappings
  command! SourceToggle call textools#citation_vim_toggle()
  for [s:map, s:tex] in items(g:textools_citation_maps)
    exe 'inoremap <silent> <buffer> ' . g:textools_citation_prefix
      \ . s:map . ' <Esc>:call textools#citation_vim_run("'
      \ . s:tex . '", g:citation_vim_opts)<CR>'
      \ . '")'
  endfor
endif
