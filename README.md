Vim succinct
============

A suite of utilities for succinctly editing documents using delimiters, text objects,
text snippets, and file templates. Includes the following features:

* Filling empty buffers with text from arbitrary file templates stored in
  `g:succinct_templates_path` (default `'~/templates'`) with the same path extension
  as the buffer. This works by opening [fzf](https://github.com/junegunn/fzf) fuzzy-search windows on new buffers and
  populating the window with the relevant template files. Note the template window will
  not open if there are no matching templates in `g:succinct_templates_path`.
* Adding custom snippet maps with `succinct#add_snippets()` and using them in insert
  mode with the default prefix `<C-e><Key>` (selected because the `e` key is relatively
  close to the `s` used for delimiters). Implementation is similar to [vim-surround](https://github.com/tpope/vim-surround),
  and definitions can be simple strings, strings with `\1...\1` style prompt indicators
  (see `:help surround-customizing`), or function handles that prompt for user input.
* Adding custom delimiter maps with `succinct#add_delims()` and using them with the
  default insert/visual mode prefix `<C-s><Key>` and normal-mode vim-surround prefixes
  `ys`, `yss`, `yS`, and `ySS`. This simultaneously defines delimiter variables for
  built-in [vim-surround](https://github.com/tpope/vim-surround) operations and registers [vim-textobj](https://github.com/kana/vim-textobj-user) objects by translating
  the input delimiters to the proper regular expressions or functions.
* Changing and deleting custom [vim-surround](https://github.com/tpope/vim-surround) delimiters with the vim-surround prefixes
  `c[sS]` and `d[sS]`, then auto-indenting the result and removing trailing whitespace
  (native vim-surround does not support changing or deleting custom delimiters). Use
  e.g. `cs<CR>bb` or `csb<CR>b` to remove (add) newlines from (to) parentheses, and use
  e.g. `cs2b` or `ds2b` to target outer parentheses within nested sequences.
* Moving to the right of the previous or next "bracket" or "quote" delimiters defined
  by [delimitMate](https://github.com/Raimondi/delimitMate) with the default insert mode mappings `<C-h>` and `<C-l>`, and
  selecting from available [vim-surround](https://github.com/tpope/vim-surround) snippets and delimiters using [fzf](https://github.com/junegunn/fzf) fuzzy-search
  windows with the default insert mode mapping `<C-e><C-e>`, insert and visual-mode
  `<C-s><C-s>`, and normal-mode `y<C-s>`, `c<C-s>`, `d<C-s>`.


Documentation
=============

Mappings
--------

| Mapping | Description |
| ---- | ---- |
| `<C-e><Mods><Key>` | Use a snippet defined with `succinct#add_snippets()` during insert mode. |
| `<C-s><Mods><Key>`, `y[sS][sS]<Motion><Mods><Key>` | Use a default delimiter or a delimiter defined with `succinct#add_delims()` during insert, visual, or normal mode. |
| `c[sS]<Mods><Key><Mods><Key>` | Change a default or manually defined delimiter from the given key to the next key. |
| `d[sS]<Mods><Key>` | Delete a default or manually defined delimiter surrounding the cursor. |
| `[ycd][ai]<Mods><Key>` | Yank, change, delete, or select inside or around a default or manually defined delimiter during normal mode. |
| `<C-h>`, `<C-l>` | Jump to the left (right) of the previous (next) quote or delimiter in insert mode. |

Customization
-------------

| Option | Description |
| ---- | ---- |
| `g:succinct_snippet_map` | Insert mode snippet mapping prefix. Default is `<C-e>` (mnemonic is the "e" in snippets). |
| `g:succinct_surround_map` | Insert and visual mode surround mapping prefix. Default is `<C-s>` (requires adding `bind -r '"\C-s"'` to `~/.bashrc` or `~/.bash_profile`). |
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
