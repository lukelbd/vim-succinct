# File type plugins
This is a collection of plugins providing filetype-specific tools
for editing various documents.
To enable all features, this requires the
<!-- The `plugin` features require -->
[vim-text-obj](https://github.com/kana/vim-textobj-user), [surround.vim](https://github.com/tpope/vim-surround), and [delimitMate](https://github.com/Raimondi/delimitMate) plugins
(see the files in `after/plugin`).

## Commands
* `:TabToggle`: Toggles `expandtab` on-and-off.

## Global options
* `g:filetypetools_tab_filetypes`: Vim-list of strings specifying
  filetypes for which we want `:TabToggle` to be called by default.
  Generally speaking, these should just be filetypes for which literal
  tab characters are syntactically meaningful.
  The default is `['text','gitconfig','make']`.
* `g:filetypetools_outofdelim_map`: The key to use for the
  insert-mode out-of-current-delimiter mapping, `<Plug>outofdelim`.
  By default, this is `<F2>`,
  because I configure iTerm2 (my terminal of choice) to remap
  the normally impossible but easy-to-press key-combination
  "`<C-.>`" to the unused function key `<F2>`.
* `g:filetypetools_surround_prefix`: The key to use for the
  insert and visual mode `surround.vim` mappings,
  `<Plug>VSurround` and `<Plug>ISurround`. See the `surround.vim`
  documentation for details. The default is `<C-s>`.
  Note this may require running
  `bind -r '"\C-s"'` in your terminal or adding it
  to your `~/.bashrc` or `~/.bash_profile`.
* `g:filetypetools_symbol_prefix`: The key to use for
  insert mode symbol-insert mappings.
  The default is `<C-z>`.
  I suggest adding `noremap <C-z> <Nop>` to your `.vimrc`,
  to prevent accidentally sending
  your vim session to the background of your terminal session,

## Maps
* `<Plug>outofdelim`: Jumps to the right of the next closing
  delimiter. This is handy when the cursor is inside a complex
  next of varying types of delimiters. It stands in contrast to
  delimitMate's `<Plug>delimitMateJumpMany` map, which jumps outside
  of arbitrarily nested delimiters.
* New surround delimiters: Custom delimiters
  integrated with the `surround.vim` plugin in insert and visual
  selection modes. See `surround.vim` for details.

  Example usage includes making a visual selection in a LaTeX document
  then pressing `<C-s>*` to surround with a `\begin{itemize}`
  `\end{itemize}` environment, or running `yswb` in normal mode
  to surround the word under the cursor with a `\textbf{}` command.
  See `after/plugin/surround.vim` to view the new delimiter key codes.
* New symbol insert maps: Custom method for inserting text
  by pressing `g:filetypetools_symbol_prefix` followed by a character.

  Example usage includes running `<C-z>a` in a LaTeX document
  to insert the alpha character `\alpha`.
  See `after/plugin/surround.vim` to view all the new symbol
  key codes.

# Installation
Install with your favorite [plugin manager](https://vi.stackexchange.com/questions/388/what-is-the-difference-between-the-vim-plugin-managers).
I highly recommend the [`vim-plug`](https://github.com/junegunn/vim-plug) manager,
in which case you can install this plugin by adding
```
Plug 'lukelbd/vim-filetypetools'
```
to your `~/.vimrc`.

