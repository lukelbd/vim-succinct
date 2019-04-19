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

# Installation
Install with your favorite [plugin manager](https://vi.stackexchange.com/questions/388/what-is-the-difference-between-the-vim-plugin-managers).
I highly recommend the [`vim-plug`](https://github.com/junegunn/vim-plug) manager,
in which case you can install this plugin by adding
```
Plug 'lukelbd/vim-ftplugins'
```
to your `.vimrc`.
