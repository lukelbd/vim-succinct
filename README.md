# File type plugins
This is a collection of plugins providing filetype-specific tools
for editing various documents. The `plugin` features require
[vim-text-obj]() and [surround.vim]().

## Commands
* `:TabToggle`: Toggles `expandtab` on-and-off.

## Global options
* `g:filetypetools_tab_filetypes`: Vim-list of strings specifying
  filetypes for which we want `:TabToggle` to be called by default.
  By default, this is `['text','gitconfig','make']`.
  reused
* `'g:filetypetools_outofdelim_map'`: The key to use for the
  out-of-current-delimiter mapping. By default, this is `<F2>`,
  because I configure iTerm (my terminal of choice) to remap
  the normally impossible but easy-to-press key-combination
  "`<C-.>`" to the unused function key `<F2>`.

# Installation
Install with your favorite [plugin manager](https://vi.stackexchange.com/questions/388/what-is-the-difference-between-the-vim-plugin-managers).
I highly recommend the [`vim-plug`](https://github.com/junegunn/vim-plug) manager,
in which case you can install this plugin by adding
```
Plug 'lukelbd/vim-ftplugins'
```
to your `.vimrc`.
