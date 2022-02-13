Vim succinct
============

A suite of utilities for succincty editing documents using delimiters, text objects,
text snippets, and file templates. Includes the following features:

* Adding custom delimiter keys with `succinct#add_delims()`. This simultaneously defines
  [vim-surround](https://github.com/tpope/vim-surround) delimiters for operations like
  `yss-` and `<C-s>-`, and [vim-textobj](https://github.com/kana/vim-textobj-user) text
  objects for operations like `ca-`, `ci-`, `da-`, `di-`. The delimiters can be function
  handles that prompt for user input and return strings or include `\1...\1` indicators
  (see `:help surround-customizing`).
* Adding custom snippet keys with `succinct#add_snippets()`. Implementation is similar to
  the internal [vim-surround](https://github.com/tpope/vim-surround) implementation;
  `<C-d>-` is used to insert snippets, similar to `<C-s>-` for surround-delimiters.
  Delimiters can be function handles that prompt for user input and return strings or
  include `\1...\1` indicators (see `:help surround-customizing`).
* Changing and deleting custom [vim-surround](https://github.com/tpope/vim-surround)
  delimiters with operations like `cs-` and `ds-`. Natively, vim-surround does not
  support this -- it only supports *inserting* custom delimiters with operations like
  `yss-` and `ysS-`.
* Jumping to the right of the previous or next "bracket" or "quote" delimiter defined by
  [delimitMate](https://github.com/Raimondi/delimitMate) with the insert mode mappings
  `<C-h>` and `<C-l>`, and displaying and selecting from available
  [vim-surround](https://github.com/tpope/vim-surround) snippets and delimiters using
  [fzf](https://github.com/junegunn/fzf) fuzzy-search selection with the insert mode
  mappings `<C-d><C-d>` and `<C-s><C-s>`.
* Loading arbitrary file templates stored in `g:succinct_templates_path` using
  [fzf](https://github.com/junegunn/fzf) fuzzy-search selection. The fuzzy search is
  invoked when creating a new file and when there are files in the templates folder with
  the same extension.


Documentation
=============

Mappings
--------

| Mapping | Description |
| ---- | ---- |
| `<C-d><key>` | Add user-defined snippets in insert mode defined with `succinct#add_snippets()`. |
| `<C-s><key>`, `ysiw<key>`, ... | Add default and user-defined delimiters in insert, visual, or normal mode defined with `succinct#add_delims`. |
| `va<key>`, `ci<key>`, ... | Yank, change, delete, or select inside or around default and user-defined text objects. Note `succinct#add_delims` also adds delimiters as text objects with the same key. |
| `<C-h>`, `<C-l>` | Jump to the left, right of the previous, next quote or delimiter in insert mode. Note delimitMate's `<Plug>delimitMateJumpMany` jumps to the far outside of nested delimiters. |
| `cs<key><key>` | Change default or user-defined delimiter from the given key to the next key. |
| `ds<key>` | Delete default or user-defined delimiter corresponding to the given key. |

Customization
-------------

| Option | Description |
| ---- | ---- |
| `g:succinct_surround_prefix` | Prefix for the insert and visual mode vim-surround mappings. Default is `<C-s>`, which is intuitive but requires adding `bind -r '"\C-s"'` to your `~/.bashrc` or `~/.bash_profile`. |
| `g:succinct_snippet_prefix` | Prefix for the citation label, figure filename, and snippet insert mappings. Default is `<C-d>`. |
| `g:succinct_prevdelim_map` | Insert mode mapping for jumping to the previous bracket. Default is `<C-h>`. |
| `g:succinct_nextdelim_map` | Insert mode mapping for jumping to the previous bracket. Default is `<C-l>`. |
| `g:succinct_templates_path` | Location where templates are stored. These are optionally loaded when creating new files. Default is `~/templates`. |

Installation
============

Install with your favorite [plugin manager](https://vi.stackexchange.com/q/388/8084).
I highly recommend the [vim-plug](https://github.com/junegunn/vim-plug) manager.
To install with vim-plug, add
```
Plug 'lukelbd/vim-succinct'
```
to your `~/.vimrc`.
