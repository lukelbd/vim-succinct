# LaTeX tools
This is a collection of enhancements
to the
[vim-text-obj](https://github.com/kana/vim-textobj-user), [surround.vim](https://github.com/tpope/vim-surround), and [delimitMate](https://github.com/Raimondi/delimitMate) plugins
that make editing LaTeX documents unbelievably fast.
Some of these changes are useful for all kinds of
other files, but LaTeX is by far the focus here.

This setup is complex and would take quite a
while to document, so
for now I will just give a broad summary of its features and expect any users
to dig into the `vimscript` code to get the full picture.
But it is **extremely** powerful, so I
recommend trying it out.

I also highly recommend checking out my [`vimlatex`
script](`https://github.com/lukelbd/dotfiles/blob/master/bin/vimlatex`) (found in my `dotfiles` repo), which makes
compiling LaTeX documents, running `latexdiff` on
files with formatted YYYY-MM-DD strings, and
converting LaTeX documents to Word with `pandoc`
very easy. [This file](https://github.com/lukelbd/dotfiles/blob/master/.vim/ftplugin/tex.vim) shows how to map to this
utility from inside vim.

<!--
## Commands
* `:TabToggle`: Toggles `expandtab` on-and-off.
-->

<!--
## Syntax highlighting
* Added support for MATLAB, NCL, and "awk" script syntax highlighting. See
  files in the `syntax` folder.
* Added support for highlighting SLURM and PBS supercomputer directives in comments at
  the head of shell scripts. See `after/syntax/sh.vim`.
* Improved the default python and LaTeX highlighting. See
  `syntax/python.vim` and `after/syntax/tex.vim`.
* Improved comment highlighting for fortran and HTML syntax.
  See files in the `after/syntax` folder.
-->

<!-->
## Filetype settings
* For most languages, added a normal mode `<C-z>` map
  for "running" the current file. See files in the `ftplugin` folder.
* For LaTeX documents, this relies on having my custom script for typesetting documents,
  `https://github.com/lukelbd/dotfiles/blob/master/vimlatex`, somewhere in your `$PATH`.
</-->

## Maps
* `<Plug>outofdelim`: Jumps to the right of the next closing
  delimiter. This is handy when the cursor is inside a complex
  next of varying types of delimiters. It stands in contrast to
  delimitMate's `<Plug>delimitMateJumpMany` map, which jumps outside
  of arbitrarily nested delimiters.
* New `surround.vim` delimiter key codes: Custom delimiters
  integrated with the `surround.vim` plugin in insert and visual
  selection modes. See `surround.vim` for details.
  Example usage includes making a visual selection in a LaTeX document
  then pressing `<C-s>*` to surround with a `\begin{itemize}`
  `\end{itemize}` environment, or running `yswb` in normal mode
  to surround the word under the cursor with a `\textbf{}` command.
  See `after/plugin/surround.vim` to view the new delimiter key codes.
* New text object key codes: Custom delimiters integrated
  with the `vim-textobj-user` plugin for selecting, deleting, yanking, etc.
  blocks of text with `ca`, `yi`, `da`, etc. Example usage includes
  selecting a LaTeX `\begin{}` `\end{}` environment with `vaL`, or
  changing text inside a LaTeX command with `cil`.
  See `after/plugin/textobjs.vim` to view all the new text
  objects.
* New symbol insert key codes: Custom maps for inserting text
  by pressing `g:textools_symbol_prefix` followed by a character.
  Example usage includes running `<C-z>a` in a LaTeX document
  to insert the alpha character `\alpha`.
  See `after/plugin/surround.vim` to view the new symbol key codes.

## Global options
* `g:textools_tab_filetypes`: Vim-list of strings specifying
  filetypes for which we want `:TabToggle` to be called by default.
  Generally speaking, these should just be filetypes for which literal
  tab characters are syntactically meaningful.
  The default is `['text','gitconfig','make']`.
* `g:textools_outofdelim_map`: The key to use for the
  insert-mode out-of-current-delimiter mapping, `<Plug>outofdelim`.
  By default, this is `<F2>`,
  because I configure iTerm2 (my terminal of choice) to remap
  the normally impossible but easy-to-press key-combination
  "`<C-.>`" to the unused function key `<F2>`.
* `g:textools_surround_prefix`: The key to use for the
  insert and visual mode `surround.vim` mappings,
  `<Plug>VSurround` and `<Plug>ISurround`. See the `surround.vim`
  documentation for details. The default is `<C-s>`.
  Note this may require running
  `bind -r '"\C-s"'` in your terminal or adding it
  to your `~/.bashrc` or `~/.bash_profile`.
* `g:textools_symbol_prefix`: The key to use for
  insert mode symbol-insert mappings.
  The default is `<C-z>`.
  I suggest adding `noremap <C-z> <Nop>` to your `.vimrc`,
  to prevent accidentally sending
  your vim session to the background of your terminal session,

# Installation
Install with your favorite [plugin manager](https://vi.stackexchange.com/questions/388/what-is-the-difference-between-the-vim-plugin-managers).
I highly recommend the [`vim-plug`](https://github.com/junegunn/vim-plug) manager,
in which case you can install this plugin by adding
```
Plug 'lukelbd/vim-textools'
```
to your `~/.vimrc`.

