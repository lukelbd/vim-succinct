Vim shortcuts
=============

A set of utilities for efficiently working with delimiters, text objects, text snippets,
and file templates. Includes the following features:

* Adding custom delimiter keys with `shortcuts#add_delims`. This
  simultaneously defines [vim-surround](https://github.com/tpope/vim-surround)
  delimiters for operations like `yss-` and `<C-s>-`, and [vim-textobj](https://github.com/kana/vim-textobj-user)
  text objects for operations like `ca-`, `ci-`, `da-`, `di-`.
  Delimiters can include prompts requiring user input.
* Changing and deleting custom [vim-surround](https://github.com/tpope/vim-surround)
  delimiters with operations like `cs-` and `ds-`. Natively, vim-surround does
  not support this -- it only supports *inserting* custom delimiters with
  operations like `yss-` and `ysS-`.
* Adding custom snippets with `shortcuts#add_snippets`. Implementation is similar
  to the internal [vim-surround](https://github.com/tpope/vim-surround) implementation;
  `<C-d>-` is used to insert snippets, similar to `<C-s>-` for surround-delimiters.
  Snippets can be function handles that prompt for user input and return strings.
* Displaying the custom snippets and surround-delimiters or fuzzy-search selecting
  them using [fzf](https://github.com/junegunn/fzf). The fuzzy search
  is invoked using `<C-d><C-d>` or `<C-s><C-s>`.
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
| `<C-d><key>` | These are maps for inserting citation labels (`<C-d>;`), figure filenames (`<C-d>:`), and text snippets (`<C-d><KEY>`) in insert mode (see [surround.vim](after/plugin/surround.vim) for details).  Example usage includes typing `<C-d>a` in insert mode to insert the TeX alpha character `\alpha`. |
| `<C-s><key>`, `ys<obj><key>`, ... | New `surround.vim` delimiter mappings. These are custom delimiters integrated with the `surround.vim` plugin, introducing a series of insert, visual, and normal mode maps (see [surround.vim](after/plugin/surround.vim) for details). Example usage includes making a visual selection and pressing `<C-s>*` to surround the selection with a `\begin{itemize}` `\end{itemize}` environment, or running `yswb` in normal mode to surround the word under the cursor with `\textbf{}`.
| `va<key>`, `vi<key>`, ... | New text object mappings. These are custom delimiters integrated with the `vim-textobj-user` plugin for selecting, yanking, changing, and deleting blocks of text with `va<key>`, `ya<key>`, etc (see [textobjs.vim](after/plugin/textobjs.vim) for details). Example usage includes selecting a LaTeX `\begin{}` `\end{}` environment with `vaT`, or changing text inside a LaTeX command with `cit`. |
| `<C-h>`, `<C-l>` | Jumps to the left, right of the previous, next bracket in insert mode (i.e. any of the characters `[]<>(){}`). This is handy when the cursor is inside a complex next of varying types of delimiters, a common difficulty when writing LaTeX equations. It stands in contrast to delimitMate's `<Plug>delimitMateJumpMany` map, which jumps to the far outside of nested delimiters. |

Functions
---------

| Function | Description |
| ---- | ---- |
| `shortcuts#delete_delims` | The existing [vim-surround](https://github.com/tpope/vim-surround) API can only handle deleting certain types of delimiters, not custom delimiters set with `g:surround_{num}` or `b:surround_{num}`. Calling this function deletes the *arbitrary* delimiter corresponding to the next keystroke (usage is `ds<key>`). |
| `shortcuts#change_delims` | The existing [vim-surround](https://github.com/tpope/vim-surround) API can only handle changing certain types of delimiters, not custom delimiters set with `g:surround_{num}` or `b:surround_{num}`. Calling this function changes the delimiter corresponding to the first keystroke to the *arbitrary* delimiter corresponding to the second keystroke (usage is `cs<key1><key2>`). |

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
