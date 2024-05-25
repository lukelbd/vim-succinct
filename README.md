Vim succinct
============

A suite of utilities for succinctly editing documents using vim-surround delimiters,
vim-textobj objects, insert-mode snippets, and file templates.

Includes the following features:

* Filling empty buffers with text from arbitrary file templates stored in
  `g:succinct_templates_path` (default `'~/templates'`). This works by opening [fzf.vim](https://github.com/junegunn/fzf.vim)
  fuzzy-search windows on new buffers and allowing users to select from template files
  whose extension matches the buffer extension. The window will not open if no matching
  templates are found. Use e.g. `:edit` from any empty buffer to trigger manually.
* Adding [vim-surround](https://github.com/tpope/vim-surround) mappings with e.g. `let g:succinct_delims = {'b': "(\r)", 'r': "[\r]"}`
  and using them from insert or visual mode with the default prefix `<C-s><Key>`. To
  add filetype-specific definitions, add a `'python'` key to the dictionary variable
  `g:succinct_filetype_delims`, or use the global variable `g:succinct_python_delims`
  or the buffer-local variable `b:succinct_delims` (see below).
* Adding snippet mappings with e.g. `let g:succinct_snippets = {}` and using them in insert
  mode with the default prefix `<C-e><Key>` (selected because the `e` key is relatively
  close to the `s` used for delimiters). Implementation is similar to [vim-surround](https://github.com/tpope/vim-surround),
  and definitions can be strings with optional `\1...\1` style prompt indicators (see
  `:help surround-customizing`) or function refs that optionally prompt for user input.
* Adding global or filetype-specific [vim-textobj](https://github.com/kana/vim-textobj-user) text object mappings `i<Key>` and
  `a<Key>` for every delimiter defined with e.g. `g:succinct_delims`. The objects are
  selected using `searchpair()` for non-identical bracket-like delimiters and `search()`
  for identical quote-like delimiters, and the `i` mappings exclude the delimiters
  themselves and any leading or trailing whitespace or line breaks.
* Inserting delimiters around arbitrary normal-mode motions with the [vim-surround](https://github.com/tpope/vim-surround) mappings
  `<Count>y[sS]<Motion><Count><Pad><Key>` or between the motions `^` and `g_` with
  `<Count>y[sS][sS]<Count><Pad><Key>` (see `:help surround-mappings`). This is similar to
  native vim-surround, except you can use `<Count>` and `<Pad>` for arbitrary repitition
  or whitespace (e.g. `yss2<Space>b` surrounds lines with `( ( <text> ) )`).
* Deleting or changing arbitrary delimiters around the cursor with the [vim-surround](https://github.com/tpope/vim-surround)
  mappings `<Count>d[sS]<Count><Pad><Key>` and `<Count>c[sS]<Count><Pad><Key><Count><Pad><Key>`.
  This is similar to native vim-surround, except this works with arbitrary custom
  delimiters and supports `y[sS]` style counts and padding (e.g. `cs<CR>bb` removes
  newlines from surrounding parentheses, while `csb<CR>b` adds newlines).
* Moving to the right of the previous or next "bracket" or "quote" delimiter defined
  by [delimitMate](https://github.com/Raimondi/delimitMate) with default insert/normal mappings `<C-h>` and `<C-l>`, selecting from
  available [vim-surround](https://github.com/tpope/vim-surround) delimiters via [fzf.vim](https://github.com/junegunn/fzf.vim) with the default insert/visual mode
  mappings `<C-s><C-s>` or operator-pending mappings `[ycd]<C-s>`, and selecting from
  snippets with the default insert mode mapping `<C-e><C-e>`.

Note this plugin defines several global delimiters and text objects by default (see
`plugin/succinct.vim` for details). Also note that if any of the above operations
create mulptile lines (e.g. `ySSb`, `yss<CR>b`, or `csb<CR>b`), any trailing whitespace
is automatically removed, and the result is auto-indented with the normal-mode `=`
operation unless `b:surround_indent` (if defined) or `g:surround_indent` is set to `0`.

Documentation
=============

Mappings
--------

| Mapping | Description |
| ---- | ---- |
| `<C-e><Count><Pad><Key>` | Insert a snippet defined with e.g. `g:succinct_snippets` during insert mode. Use `<Count>` e.g. `2b` to repeat the snippet and `<Pad>` e.g. `<Space>`/`<CR>` to add space(s) or auto-indented newline(s) around the snippet. |
| `<Count><C-s><Count><Pad><Key>` | Insert delimiters defined with e.g. `g:succinct_delims` or included with vim-surround during insert or visual mode. Use `<Count>` e.g. `2b` to repeat the delimiter and `<Pad>` e.g. `<Space>`/`<CR>` to add space(s) or newline(s) around the delimiters. |
| `<Count>y[sS]<Motion><Count><Pad><Key>` | Insert user-defined and default delimiters around the normal mode motion. Use a capital `S` to add newlines around the delimiters, or use `<Count>` or `<Pad>` for arbitrary repitition or padding (as with `<C-s>` and `<C-e>`). |
| `<Count>y[sS][sS]<Motion><Count><Pad><Key>` | Insert user-defined and default delimiters between the cursor motions `^` to `g_` (i.e. around the first and last non-whitespace character, as with the vim-surround `yss` mappings and the [vim-textobj-line](https://github.com/kana/vim-textobj-line) object). |
| `<Count>d[sS]<Count><Pad><Key>` | Delete user-defined and default delimiters surrounding the cursor. Use a capital `S` or `<CR>` in `<Pad>` to include newlines and leading/trailing whitespace (as with the `y[sS]` mappings), or use the first `<Count>` to delete multiple delimiters or the second `<Count>` to target nested outer delimiters. |
| `<Count>c[sS]<Count><Pad><Key><Count><Pad><Key>` | Change an arbitrary user-defined or default delimiter around the cursor to another delimiter. Use capital `S` or the first `<Count>` and `<Pad>` to change deletion behavior (as with the `d[sS]` mappings). Use the second `<Count>` and `<Pad>` to change insertion behavior (as with the `y[sS]` mappings).
| `[ycdv]<Count>[ai]<Key>` | Yank, change, delete, or select delimiters defined with e.g. `g:succinct_delims` or included with vim-textobj. This works by auto-translating variables to vim-textobj-user plugin entries. |
| `<C-h>`, `<C-l>` | Jump to the left (right) of the previous (next) delimiter in insert mode. This works for arbitrary delimitmate-defined bracket and quote style delimiters. |

Options
-------

| Option | Description |
| ---- | ---- |
| `g:succinct_nomap` | Whether to disable the default maps. Default is `0`. If `1` you must add all maps manually (see `plugin/succinct.vim`). |
| `g:succinct_nomap_actions` | Whether to disable the maps that insert or modify delimiters and snippets (e.g. `ys`, `cs`, etc.). Default is `g:succinct_nomap`. |
| `g:succinct_nomap_objects` | Whether to disable the default (global) delimiter definition maps (e.g. the `b` used for parentheses `(\r)`). Default is `g:succinct_nomap`. |
| `g:succinct_snippet_map` | Insert mode snippet mapping prefix. Default is `<C-e>` (simple mnemonic is the "e" in snippets). |
| `g:succinct_surround_map` | Insert and visual mode surround mapping prefix. Default is `<C-s>` (requires adding `bind -r '"\C-s"'` to `~/.bashrc` or `~/.bash_profile`). |
| `g:succinct_prevdelim_map` | Normal and insert mode mapping for jumping to the previous quote or delimiter. Default is `<C-h>`. |
| `g:succinct_nextdelim_map` | Normal and insert mode mapping for jumping to the next quote or delimiter. Default is `<C-l>`. |
| `g:succinct_templates_path` | The folder where templates are stored. These are optionally loaded when creating new files. Default is `~/templates`. |
| `g:succinct_delims` | Optional global delimiter and text object mappings. Delimiter pairs should be separated by `'\r'` or `"\r"` (see `:help surround-customizing`). |
| `b:succinct_delims` | Optional buffer-local delimiter and text object mappings. These can be set with `au FileType type` autocommands or `ftplugin/type.vim` files. |
| `g:succinct_filetype_delims` | Optional filetype-specific delimiter and text object mappings. Each key should be a file type and each value a dictionary of mappings. |
| `g:succinct_snippets` | Optional global snippet mappings. Snippets are parsed the same as delimiters (e.g. can include `vim-surround` `\1..\1` prompts). |
| `b:succinct_snippets` | Optional buffer-local snippet mappings. These can be set with `au FileType type` autocommands or `ftplugin/type.vim` files. |
| `g:succinct_filetype_snippets` | Optional filetype-specific snippet mappings. Each key should be a file type and each value a dictionary of mappings. |

Installation
============

Install with your favorite [plugin manager](https://vi.stackexchange.com/q/388/8084).
I highly recommend the [vim-plug](https://github.com/junegunn/vim-plug) manager.
To install with vim-plug, add
```
Plug 'lukelbd/vim-succinct'
```
to your `~/.vimrc`.
