"------------------------------------------------------------------------------"
" Author: Luke Davis (lukelbd@gmail.com)
" Date:   2018-09-10
" Custom text objects defined with vim-text-obj, and copied from other folks.
" For more info see: https://www.reddit.com/r/vim/comments/48e4ci/vimscript_how_to_create_a_new_text_object/d0iy3ny/
"------------------------------------------------------------------------------"
if !exists('*textobj#user#plugin')
  finish
endif

" Declare text objects
" NOTE: Somewhat hidden feature is you can make maps buffer local by just
" prepending the option to the mapping name.
augroup tex_textobjs
  au!
  au FileType tex call textobj#user#plugin('latex', s:tex_textobjs_dict)
augroup END

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


