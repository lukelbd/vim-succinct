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
* Adding [vim-surround](https://github.com/tpope/vim-surround) delimiter mappings with e.g. `succinct#add_delims({'b': "(\r)", 'r': "[\r]", ...})`
  and using them from insert or visual mode with the default prefix `<C-s><Key>`. This
  (see `:help surround-customizing`). To add filetype-specific definitions, pass `1`
  as the final argument with e.g. `succinct#add_delims({'b': "\\textbf{\r}", ...}, 1)`
  and call from either `ftplugin/tex.vim` or with `autocmd FileType tex ...`.
* Adding snippet mappings with `succinct#add_snippets()` and using them in insert
  mode with the default prefix `<C-e><Key>` (selected because the `e` key is relatively
  close to the `s` used for delimiters). Implementation is similar to [vim-surround](https://github.com/tpope/vim-surround),
  and definitions can be simple strings, strings with `\1...\1` style prompt indicators
  (see `:help surround-customizing`), or function handles that prompt for user input.
* Adding global or filetype-specific [vim-textobj](https://github.com/kana/vim-textobj-user) text object mappings `i<Key>` and
  `a<Key>` for every vim-surround delimiter passed to `succinct#add_delims`. The
  objects are selected using `searchpair()` for non-identical bracket-like delimiters
  and `search()` for identical quote-like delimiters, and the `i` mappings exclude
  the delimiters themselves and any leading or trailing whitespace or newlines.
* Inserting delimiters around a given normal-mode motion with the [vim-surround](https://github.com/tpope/vim-surround) mappings
  `<Count>y[sS]<Motion><Count><Pad><Key>` or between the cursor motions `^` and `g_` with the
  mappings `<Count>y[sS][sS]<Mods><Key>` (see `:help surround-mappings`). This is
  similar to native vim-surround, except you can use `<Count>` and `<Pad>` for arbitrary
  repitition or whitespace (e.g. `yss2<Space>b` surrounds lines with `( ( <text> ) )`).
* Deleting or changing arbitrary delimiters around the cursor with the [vim-surround](https://github.com/tpope/vim-surround)
  mappings `<Count>d[sS]<Count><Pad><Key>` and `<Count>c[sS]<Count><Pad><Key><Count><Pad><Key>`.
  This is similar to native vim-surround, except this works with arbitrary user-input
  delimiters and adds the `y[sS]` count and padding options (e.g. `cs<CR>bb` removes
  newlines from surrounding parentheses, while `csb<CR>b` adds surrounding newlines).
* Moving to the right of the previous or next "bracket" or "quote" delimiter defined
  by [delimitMate](https://github.com/Raimondi/delimitMate) with default insert mode mappings `<C-h>` and `<C-l>`, selecting from
  available [vim-surround](https://github.com/tpope/vim-surround) delimiters using [fzf.vim](https://github.com/junegunn/fzf.vim) fuzzy-search windows with the default
  insert/visual mode mappings `<C-s><C-s>` or operator-pending mappings `[ycd]<C-s>`,
  and selecting from available snippets with the default insert mode mapping `<C-e><C-e>`.

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

| `<C-e><Count><Pad><Key>` | Insert a snippet defined with `succinct#add_snippets()` during insert mode. Use `<Count>` e.g. `2b` for repitition and `<Pad>` e.g. `<Space>`/`<CR>` for space/newline padding of the snippet or e.g. `2` for repitition. |
| `<Count><C-s><Count><Pad><Key>` | Insert delimiters defined with `succinct#add_delims()` or included with vim-surround during insert or visual mode. Use `<Space>` e.g. `<Space>`/`<CR>` for space/newline padding or e.g. `2` for repitition. |
| `<Count>y[sS]<Motion><Count><Pad><Key>` | Insert user-defined and default delimiters around the normal mode motion. Use a capital `S` for newlines, a preceding `<Count>` for repitition, or `<Space>` as with `<C-s>`.
| `<Count>y[sS][sS]<Motion><Count><Pad><Key>` | Insert user-defined and default delimiters between the cursor motions `^` to `g_` (same as vim-surround `yss` mappings and similar to [vim-textobj-line](https://github.com/kana/vim-textobj-line)). |
| `<Count>d[sS]<Count><Pad><Key>` | Delete user-defined and default delimiters surrounding the cursor. Use capital `S` or `<CR>` in `<Space>` to include newlines and leading/trailing whitespace, as with the `y[sS]` mappings. |
| `<Count>c[sS]<Count><Pad><Key><Count><Pad><Key>` | Change an arbitrary user-defined or default delimiter around the cursor to another delimiter. Use capital `S` or the first `<Pad>` as with `d[sS]`, or use the second `<Pad>` as with `y[sS]`. |
| `[ycdv]<Count>[ai]<Key>` | Yank, change, delete, or select delimiters defined with `succinct#add_delims()` or included with vim-textobj. This works by auto-translating variables to vim-textobj-user plugin entries. |
| `<C-h>`, `<C-l>` | Jump to the left (right) of the previous (next) delimiter in insert mode. This works for arbtirary delimitmate-defined bracket and quote style delimiters. |

Options
-------

| Option | Description |
| ---- | ---- |
| `g:succinct_snippet_map` | Insert mode snippet mapping prefix. Default is `<C-e>` (simple mnemonic is the "e" in snippets). |
| `g:succinct_surround_map` | Insert and visual mode surround mapping prefix. Default is `<C-s>` (requires adding `bind -r '"\C-s"'` to `~/.bashrc` or `~/.bash_profile`). |
| `g:succinct_prevdelim_map` | Insert mode mapping for jumping to the previous quote or delimiter. Default is `<C-h>`. |
| `g:succinct_nextdelim_map` | Insert mode mapping for jumping to the next quote or delimiter. Default is `<C-l>`. |
| `g:succinct_templates_path` | The folder where templates are stored. These are optionally loaded when creating new files. Default is `~/templates`. |

Installation
============

Install with your favorite [plugin manager](https://vi.stackexchange.com/q/388/8084).
I highly recommend the [vim-plug](https://github.com/junegunn/vim-plug) manager.
To install with vim-plug, add
```
Plug 'lukelbd/vim-succinct'
```
to your `~/.vimrc`.
