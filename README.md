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
  By default, this is `['text','gitconfig','make']`.
  reused
* `'g:filetypetools_outofdelim_map'`: The key to use for the
  insert-mode out-of-current-delimiter mapping, `<Plug>outofdelim`.
  By default, this is `<F2>`,
  because I configure iTerm (my terminal of choice) to remap
  the normally impossible but easy-to-press key-combination
  "`<C-.>`" to the unused function key `<F2>`.
* `g:filetypetools_surround_prefix`: The key to use for the
  insert-mode surround mappings, `<Plug>filetypetools-surround`.
  By default, this is `<C-s>`. Note this may require running
  `bind -r '"\C-s"'` in your terminal or adding this text
  to your `.bashrc` or `.bash_profile`.
* `g:filetypetools_symbol_prefix`:
  insert-mode symbol-insert mappings, `<Plug>filetypetools-symbol`.
  By default, this is `<C-z>`. To prevent accidentally sending
  your vim session to the background of your terminal session,
  I suggest also adding `noremap <C-z> <Nop>` to your `.vimrc`.

## Insert mode maps
* `<Plug>outofdelim`: Jumps to the right of the next closing
  delimiter. This is handy when the cursor is inside a complex
  next of varying types of delimiters.

# Installation
Install with your favorite [plugin manager](https://vi.stackexchange.com/questions/388/what-is-the-difference-between-the-vim-plugin-managers).
I highly recommend the [`vim-plug`](https://github.com/junegunn/vim-plug) manager,
in which case you can install this plugin by adding
```
Plug 'lukelbd/vim-filetypetools'
```
to your `~/.vimrc`.

