Vim succinct
============

A suite of utilities for succinctly editing documents using delimiters, text objects,
text snippets, and file templates. Includes the following features:

* Adding custom delimiter keys with `succinct#add_delims()`. This simultaneously defines
  [vim-surround](https://github.com/tpope/vim-surround) delimiters for normal mode
  operations like `yss-` and visual and insert mode operations like `<C-a>-`, as well as
  [vim-textobj](https://github.com/kana/vim-textobj-user) text objects for normal mode
  operations like `ca-`, `ci-`, `da-`, `di-`. Delimiters can include `\1...\1` prompt
  indicators (see `:help surround-customizing`).
* Adding custom snippet keys with `succinct#add_snippets()`. Implementation is similar
  to the internal [vim-surround](https://github.com/tpope/vim-surround) implementation;
  `<C-s>-` is used to insert snippets, similar to `<C-a>-` for delimiters.
  Delimiters can be function handles that prompt for user input or include `\1...\1`
  prompt indicators (see `:help surround-customizing`).
* Changing and deleting custom [vim-surround](https://github.com/tpope/vim-surround)
  delimiters with operations like `cs-` and `ds-`. Natively, vim-surround does not
  support this -- it only supports *inserting* custom delimiters with operations like
  `yss-` and `ysS-`.
* Jumping to the right of the previous or next "bracket" or "quote" delimiter defined by
  [delimitMate](https://github.com/Raimondi/delimitMate) with the insert mode mappings
  `<C-h>` and `<C-l>`, and displaying and selecting from available
  [vim-surround](https://github.com/tpope/vim-surround) snippets and delimiters using
  [fzf](https://github.com/junegunn/fzf) fuzzy-search selection with the insert mode
  mappings `<C-s><C-s>` and `<C-a><C-a>`.
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
| `<C-s><key>` | Add a user-defined `succinct#add_snippets()` snippet during insert mode. |
| `<C-a><key>`, `ysiw<key>`, ... | Add a default or user-defined `succinct#add_delims()` delimiter during insert, visual, or normal mode. |
| `ya<key>`, `ci<key>`, ... | Yank, change, delete, or select inside or around a default or user-defined delimiter during normal mode. |
| `<C-h>`, `<C-l>` | Jump to the left (right) of the previous (next) quote or delimiter in insert mode. |
| `cs<key><key>` | Change the default or user-defined delimiter from the given key to the next key. |
| `ds<key>` | Delete the default or user-defined delimiter corresponding to the given key. |

Customization
-------------

| Option | Description |
| ---- | ---- |
| `g:succinct_surround_prefix` | Prefix for the insert and visual mode surround mappings. Default is `<C-a>` (mnemonic is to evoke the "a" used with vim text objects). |
| `g:succinct_snippet_prefix` | Prefix for the insert mode snippet mappings. Default is `<C-s>` (mnemonic is "s" for snippets). Note this requires adding `bind -r '"\C-s"'` to `~/.bashrc` or `~/.bash_profile`. |
| `g:succinct_prevdelim_map` | Insert mode mapping for jumping to the previous quote or delimiter. Default is `<C-h>`. |
| `g:succinct_nextdelim_map` | Insert mode mapping for jumping to the next quote or delimiter. Default is `<C-l>`. |
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
