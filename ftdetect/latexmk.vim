" Filetype declaration for latexmk files
augroup latexmk
  au!
  au BufNewFile,BufRead latexmk.log set filetype=latexmk
augroup END
