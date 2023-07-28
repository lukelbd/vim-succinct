Vim succinct
============

A suite of utilities for succinctly editing documents using delimiters, text objects,
text snippets, and file templates. Includes the following features:

* Adding custom snippet keys with `succinct#add_snippets()`. Implementation is similar
  to the [vim-surround](https://github.com/tpope/vim-surround) internals.
  `<C-e>-` is used to insert snippets, selected because the `e` key is relatively
  close to the `s` used for delimiters, but not so close that it can be easily
  confused with `<C-s>-`. Snippets can be function handles that prompt for user
  input or include `\1...\1` prompt indicators (see `:help surround-customizing`).
* Adding custom delimiter keys with `succinct#add_delims()`. This simultaneously defines
  [vim-surround](https://github.com/tpope/vim-surround) delimiters for normal mode
  operations like `yss-` and visual and insert mode operations like `<C-s>-`, as well as
  [vim-textobj](https://github.com/kana/vim-textobj-user) text objects for normal mode
  operations like `ca-`, `ci-`, `da-`, `di-`. Delimiters can include `\1...\1` prompt
  indicators (see `:help surround-customizing`).
* Changing and deleting custom [vim-surround](https://github.com/tpope/vim-surround)
  delimiters with operations like `cs-` and `ds-`. Natively, vim-surround does not
  support this -- it only supports *inserting* custom delimiters with operations like
  `yss-` and `ysS-`.
* Jumping to the right of the previous or next "bracket" or "quote" delimiter defined by
  [delimitMate](https://github.com/Raimondi/delimitMate) with the insert mode mappings
  `<C-h>` and `<C-l>`, and displaying and selecting from available
  [vim-surround](https://github.com/tpope/vim-surround) snippets and delimiters using
  [fzf](https://github.com/junegunn/fzf) fuzzy-search selection with the insert mode
  mappings `<C-e><C-e>` and `<C-s><C-s>`.
* Loading arbitrary file templates stored in `g:succinct_templates_path` using
  [fzf](https://github.com/junegunn/fzf) fuzzy-search selection. The fuzzy search is
  invoked when creating a new file and when there are files in the templates folder
  that have the same extension.


Documentation
=============

Mappings
--------

| Mapping | Description |
| ---- | ---- |
| `<C-e><key>` | Add a snippet defined with `succinct#add_snippets()` during insert mode. |
| `<C-s><key>`, `ys<motion><key>`, `ys<block><key>`... | Add a default delimiter or a delimiter defined with `succinct#add_delims()` during insert, visual, or normal mode. |
| `cs<key><key>` | Change a default or manually defined delimiter from the given key to the next key. |
| `ds<key>` | Delete a default or manually defined delimiter surrounding the cursor. |
| `ya<key>`, `ci<key>`, ... | Yank, change, delete, or select inside or around a default or manually defined delimiter during normal mode. |
| `<C-h>`, `<C-l>` | Jump to the left (right) of the previous (next) quote or delimiter in insert mode. |

Customization
-------------

| Option | Description |
| ---- | ---- |
| `g:succinct_snippet_defs`, `b:succinct_snippet_defs`  | Global or buffer-local snippet definitions. Keys are the bindings (pressed after `<C-e>`), values are the inserted snippets. |
| `g:succinct_surround_defs`, `b:succinct_surround_defs`  | Global or buffer-local surround definitions. Keys are the bindings (pressed after `<C-s>`), values are delimiters (separated by `"\r"` -- see `surround.vim` docs). |
| `g:succinct_snippet_map` | Prefix for the insert mode snippet mappings. Default is `<C-e>` (mnemonic is the "e" in snippets). |
| `g:succinct_surround_map` | Prefix for the insert and visual mode surround mappings. Default is `<C-s>` (requires adding `bind -r '"\C-s"'` to `~/.bashrc` or `~/.bash_profile`). |
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
