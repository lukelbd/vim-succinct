# LaTeX tools
This is a collection of custom tools and plugin enhancements for working with LaTeX files in vim, similar to [vimtex](https://github.com/lervag/vimtex).

It includes integration with the [vim-text-obj](https://github.com/kana/vim-textobj-user), [surround.vim](https://github.com/tpope/vim-surround), [delimitMate](https://github.com/Raimondi/delimitMate), and [citation.vim](https://github.com/rafaqz/citation.vim) plugins that make editing LaTeX documents a breeze, and a custom [latexmk](latexmk) script that omits some features from the more ubiquitous [program of the same name](https://mg.readthedocs.io/latexmk.html) and adds useful new features. It also adds a templating engine -- when you open a new `.tex` file, a popup window allows you to load arbitrary `.tex` file templates stored in a `~/latex` folder. This requires the [FZF](https://github.com/junegunn/fzf) vim plugin.

This set of tools is complex and would take quite a while to document. For now I will just give a broad summary of the features and expect any users to dig into the vimscript code to get the full picture.

<!--
## Commands
* `:TabToggle`: Toggles `expandtab` on-and-off.
-->

<!--
## Syntax highlighting
* Added support for MATLAB, NCL, and "awk" script syntax highlighting. See
  files in the `syntax` folder.
* Added support for highlighting SLURM and PBS supercomputer directives in comments at
  the head of shell scripts. See `after/syntax/sh.vim`.
* Improved the default python and LaTeX highlighting. See
  `syntax/python.vim` and `after/syntax/tex.vim`.
* Improved comment highlighting for fortran and HTML syntax.
  See files in the `after/syntax` folder.
-->

<!--
## Filetype settings
* For most languages, added a normal mode `<C-z>` map
  for "running" the current file. See files in the `ftplugin` folder.
* For LaTeX documents, this relies on having my custom script for typesetting documents,
  `https://github.com/lukelbd/dotfiles/blob/master/vimlatex`, somewhere in your `$PATH`.
-->

# Documentation
## Commands

| Command | Description |
| ---- | ---- |
| `:Latexmk` | Runs the custom [latexmk script](latexmk). This typesets the document asynchronously, shows a condensed log in a popup split window, and opens the file in the [Skim PDF viewer](https://en.wikipedia.org/wiki/Skim_(software)). It automatically detects the number of times the typesetting command must be called, like the original `latexmk`, automatically figures out which typesetting engine to use based on the packages imported, automatically copies over custom user style and theme files from a `~/latex` folder, and deletes extra files generated during typesetting. Run `:Latexmk --help` for more info. |
| `:BibtexToggle` | Toggles between [citation.vim](https://github.com/rafaqz/citation.vim) using bibtex or Zotero for retrieving citations for the current file. The default is bibtex. |

## Mappings

| Mapping | Description |
| ---- | ---- |
| `<C-z>` | Invokes `:Latexmk` with no flags. |
| `<Leader>z` | Invokes `:Latexmk` with the `--diff` flag. |
| `<Leader>Z` | Invokes `:Latexmk` with the `--doc` flag. |
| `<Leader>b` | Invokes `:BibtexToggle`. |
| `<F1>`, `<F2>` | In insert mode, jumps to the right of the previous or next delimiter, i.e. any of the characters `[]<>(){}`. This is handy when the cursor is inside a complex next of varying types of delimiters, a common difficulty when writing LaTeX equations. It stands in contrast to delimitMate's `<Plug>delimitMateJumpMany` map, which jumps to the far outside of nested delimiters. |
| `<C-b>[ctpn]` | New citation insert mappings. These insert citations from a local bibliography or from your Zotero sqlite database (see [citation.vim](after/plugin/citation.vim) for details). Adds ability to use bibliographies local to specific buffers. |
| `<C-z><key>` | These are maps for inserting text snippets in insert mode (see [surround.vim](after/plugin/surround.vim) for details).  Example usage includes running `<C-z>a` in a LaTeX document to insert the LaTeX alpha character `\alpha`. |
| `<C-s><key>`, `ys<obj><key>`, ... | New `surround.vim` delimiter mappings. These are custom delimiters integrated with the `surround.vim` plugin, introducing a series of insert, visual, and normal mode maps (see [surround.vim](after/plugin/surround.vim) for details). Example usage includes making a visual selection in a LaTeX document then pressing `<C-s>*` to surround with a `\begin{itemize}` `\end{itemize}` environment, or running `yswb` in normal mode to surround the word under the cursor with a `\textbf{}` command.
| `va<key>`, `vi<key>`, ... | New text object mappings. These are custom delimiters integrated with the `vim-textobj-user` plugin for selecting, yanking, changing, and deleting blocks of text with `va<key>`, `ya<key>`, etc (see [textobjs.vim](after/plugin/textobjs.vim) for details). Example usage includes selecting a LaTeX `\begin{}` `\end{}` environment with `vaT`, or changing text inside a LaTeX command with `cit`. |

## Options

| Option | Description |
| ---- | ---- |
| `g:textools_prevdelim_map`, `g:textools_nextdelim_map` | Alternate definitions for the `<F1>` and `<F2>` maps. `<F1>` and `<F2>` are the default because I configure iTerm2 to map the normally impossible key combinations `<C-,>` and `<C-.>` to FN key presses. This is done by creating maps in Preferences that send the `<F1>` and `<F2>` ASCII HEX codes `0x1b 0x4f 0x50` and `0x1b 0x4f 0x51`, respectively. |
| `g:textools_delim_prefix` | Alternate key for the `<C-s>` mappings. Note the `<C-s>` mapping may require running `bind -r '"\C-s"'` in your terminal or adding it to your `~/.bashrc` or `~/.bash_profile`. |
| `g:textools_snippet_prefix` | Alternate key for the `<C-z>` mappings. If you use the default, I suggest adding `noremap <C-z> <Nop>` to your `.vimrc`, to prevent accidentally sending your vim session to the background of your terminal session. |
| `g:textools_citation_prefix` | Alternate key for the `<C-b>` mappings. |

## Functions
| Function | Description |
| ---- | ---- |
| `textools#delete_delims` | Deletes arbitrary delimiters around the cursor, detected on this line or on all lines in the file. Arguments are a left delimiter regex and a right delimiter regex. This is best used in a normal mode mapping that looks like `ds<key>`. |
| `textools#change_delims` | Changes arbitrary delimiters, detected on this line or on all lines in the file. Arguments are a left delimiter regex, right delimiter regex, and a replacement indicator. This can be a non-empty string, used for both left and right delimiters, or an empty string, in which case the function reads the next character pressed by the user and uses the corresponding delimiter. This is best used in a normal mode mapping that looks like `cs<key>`. |

# Installation
Install with your favorite [plugin manager](https://vi.stackexchange.com/questions/388/what-is-the-difference-between-the-vim-plugin-managers).
I highly recommend the [`vim-plug`](https://github.com/junegunn/vim-plug) manager,
in which case you can install this plugin by adding
```
Plug 'lukelbd/vim-textools'
```
to your `~/.vimrc`.

# See also
If you find this plugin useful, I also highly recommend
two other tools I developed:

* My [vim-scrollwrapped plugin](https://github.com/lukelbd/vim-scrollwrapped), which toggles "wrapped" lines automatically for non-code documents (like markdown, RST, and LaTeX files) and makes scrolling through vim windows with heavily wrapped lines much, much easier.
* My [ctags preference file](https://github.com/lukelbd/dotfiles/blob/master/.ctags), which contains a bunch of new definitions for marking section, figure, table, etc. locations with ctags.
* My [idetools plugin](https://github.com/lukelbd/vim-idetools), which includes various refactoring commands and tools for jumping around documents based on ctags locations.

