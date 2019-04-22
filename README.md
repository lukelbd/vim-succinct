# LaTeX tools
This is a collection of enhancements
to the
[vim-text-obj](https://github.com/kana/vim-textobj-user), [surround.vim](https://github.com/tpope/vim-surround), and [delimitMate](https://github.com/Raimondi/delimitMate) plugins
that make editing LaTeX documents unbelievably fast.
Some of these changes are also useful for editing
other files, but LaTeX is the focus here.

This setup is complex and would take quite a
while to document, so
for now I will just give a broad summary of its features and expect any users
to dig into the `vimscript` code to get the full picture.
But it is **extremely** powerful, so I
recommend trying it out.

## Recommendations
If you find this plugin useful, I also highly recommend
two other tools I developed:

* My [vim-scrollwrapped plugin](https://github.com/lukelbd/vim-scrollwrapped), which toggles "wrapped" lines automatically for non-code documents (like markdown, RST, and LaTeX files) and makes scrolling through vim windows with heavily wrapped lines much, much easier.
* My [vimlatex script](https://github.com/lukelbd/dotfiles/blob/master/bin/vimlatex) (found in my `dotfiles` repo), which makes compiling LaTeX documents, running `latexdiff` on files with formatted YYYY-MM-DD strings, and converting LaTeX documents to Word with `pandoc` very easy. [This file](https://github.com/lukelbd/dotfiles/blob/master/.vim/ftplugin/tex.vim) shows how to map to this utility from inside vim.
* My [ctags preference file](https://github.com/lukelbd/dotfiles/blob/master/.ctags), which contains a bunch of new definitions for marking section, figure, table, etc. locations with ctags.
This is best used with my [idetools plugin](https://github.com/lukelbd/vim-idetools).

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

<!--
## Filetype settings
* For most languages, added a normal mode `<C-z>` map
  for "running" the current file. See files in the `ftplugin` folder.
* For LaTeX documents, this relies on having my custom script for typesetting documents,
  `https://github.com/lukelbd/dotfiles/blob/master/vimlatex`, somewhere in your `$PATH`.
-->

## Maps
* `<F2>`: Jumps to the right of the **next closing
  delimiter** (i.e. `]`, `>`, `)`, or `}`). This is handy when the cursor is inside a complex
  next of varying types of delimiters, a common difficulty when writing LaTeX equations. It stands in contrast to
  delimitMate's `<Plug>delimitMateJumpMany` map, which jumps to the far outside of nested delimiters.

  The map can be changed with `g:gextools_outofdelim_map`. It is `<F2>` by default because I configure iTerm2 (my terminal of choice) to remap the normally impossible but easy-to-press key-combination "`<C-.>`" to the unused key `<F2>`.
* New `surround.vim` delimiter key codes: Custom delimiters
  integrated with the `surround.vim` plugin, introducing
  a series of insert, visual, and normal mode maps
  (see `surround.vim` for details).
  The default prefix for visual and insert mode maps is
  `<C-s>` (maps to `<Plug>VSurround` and `<Plug>ISurround`),
  and can be changed with
  `g:textools_surround_prefix`.
  Note the map `<C-s>` may require running
  `bind -r '"\C-s"'` in your terminal or adding it
  to your `~/.bashrc` or `~/.bash_profile`.

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
  in insert mode.
  The default symbol insert prefix is `<C-z>`,
  and can be changed with `g:textools_symbol_prefix`.
  I suggest adding `noremap <C-z> <Nop>` to your `.vimrc`,
  to prevent accidentally sending
  your vim session to the background of your terminal session,

  Example usage includes running `<C-z>a` in a LaTeX document
  to insert the LaTeX alpha character `\alpha`.
  See `after/plugin/surround.vim` to view the new symbol key codes.

# Installation
Install with your favorite [plugin manager](https://vi.stackexchange.com/questions/388/what-is-the-difference-between-the-vim-plugin-managers).
I highly recommend the [`vim-plug`](https://github.com/junegunn/vim-plug) manager,
in which case you can install this plugin by adding
```
Plug 'lukelbd/vim-textools'
```
to your `~/.vimrc`.

