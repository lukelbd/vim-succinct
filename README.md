Vim shortcuts
=============

A set of utilities for efficiently working with delimiters, text objects, text snippets,
and file templates. Includes the following features:

* Adding custom snippets with `shortcuts#add_snippets()`. Implementation is similar
  to the internal [vim-surround](https://github.com/tpope/vim-surround) implementation;
  `<C-d>-` is used to insert snippets, similar to `<C-s>-` for surround-delimiters.
  Delimiters can be function handles that prompt for user input and return strings or
  include `\1...\1` indicators (see `:help surround-customizing`).
* Adding custom delimiter keys with `shortcuts#add_delims()`. This
  simultaneously defines [vim-surround](https://github.com/tpope/vim-surround)
  delimiters for operations like `yss-` and `<C-s>-`, and [vim-textobj](https://github.com/kana/vim-textobj-user)
  text objects for operations like `ca-`, `ci-`, `da-`, `di-`.
  Delimiters can be function handles that prompt for user input and
  return strings or include `\1...\1` indicators (see `:help surround-customizing`).
* Changing and deleting custom [vim-surround](https://github.com/tpope/vim-surround)
  delimiters with operations like `cs-` and `ds-`. Natively, vim-surround does
  not support this -- it only supports *inserting* custom delimiters with
  operations like `yss-` and `ysS-`.
* Displaying and selecting the available snippets and delimiters using
  [fzf](https://github.com/junegunn/fzf) fuzzy-search selection. The fuzzy search
  is invoked using `<C-d><C-d>` or `<C-s><C-s>` in insert mode.
* Loading arbitrary file templates stored in `g:shortcuts_templates_path`
  using [fzf](https://github.com/junegunn/fzf) fuzzy-search selection. The fuzzy
  search is invoked when creating a new file and there are files in the templates
  folder with the same extension.


Documentation
=============

Mappings
--------

| Mapping | Description |
| ---- | ---- |
| `<C-d><key>` | Add user-defined snippets in insert mode defined with `shortcuts#add_snippets()`. |
| `<C-s><key>`, `ysiw<key>`, ... | Add default and user-defined delimiters in insert, visual, or normal mode defined with `shortcuts#add_delims`. |
| `va<key>`, `ci<key>`, ... | Yank, change, delete, or select inside or around default and user-defined text objects. Note `shortcuts#add_delims` also adds delimiters as text objects with the same key. |
| `<C-h>`, `<C-l>` | Jump to the left, right of the previous, next quote or delimiter in insert mode. Note delimitMate's `<Plug>delimitMateJumpMany` jumps to the far outside of nested delimiters. |
| `cs<key><key>` | Change default or user-defined delimiter from the given key to the next key. |
| `ds<key>` | Delete default or user-defined delimiter corresponding to the given key. |

Customization
-------------

| Option | Description |
| ---- | ---- |
| `g:shortcuts_surround_prefix` | Prefix for the insert and visual mode vim-surround mappings. Default is `<C-s>`, which is intuitive but requires adding `bind -r '"\C-s"'` to your `~/.bashrc` or `~/.bash_profile`. |
| `g:shortcuts_snippet_prefix` | Prefix for the citation label, figure filename, and snippet insert mappings. Default is `<C-d>`. |
| `g:shortcuts_prevdelim_map` | Insert mode mapping for jumping to the previous bracket. Default is `<C-h>`. |
| `g:shortcuts_nextdelim_map` | Insert mode mapping for jumping to the previous bracket. Default is `<C-l>`. |
| `g:shortcuts_templates_path` | Location where templates are stored. These are optionally loaded when creating new files. Default is `~/templates`. |

Installation
============

Install with your favorite [plugin manager](https://vi.stackexchange.com/q/388/8084).
I highly recommend the [vim-plug](https://github.com/junegunn/vim-plug) manager.
To install with vim-plug, add
```
Plug 'lukelbd/vim-shortcuts'
```
to your `~/.vimrc`.
