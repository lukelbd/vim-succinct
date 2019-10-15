# LaTeX tools
This is a collection of custom tools and plugin enhancements for working with LaTeX files in vim, similar to [vimtex](https://github.com/lervag/vimtex).

It includes integration with the [vim-text-obj](https://github.com/kana/vim-textobj-user), [surround.vim](https://github.com/tpope/vim-surround), [delimitMate](https://github.com/Raimondi/delimitMate), and [citation.vim](https://github.com/rafaqz/citation.vim) plugins that make editing LaTeX documents unbelievably fast, and a custom [latexmk](latexmk) script that omits some features from the more ubiquitous [program of the same name](https://mg.readthedocs.io/latexmk.html) and adds several useful new features.

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
This plugin defines the following commands.

| Command | Description |
| ---- | ---- |
| `:Latexmk` | Runs a custom [latexmk script](latexmk) packaged with this project. This  typesets the document asynchronously, shows a condensed log in a popup split window, and opens the file in the [Skim PDF viewer](https://en.wikipedia.org/wiki/Skim_(software\)). It automatically detects the number of times the typesetting command must be called, like the original `latexmk`, automatically figures out which typesetting engine to use (e.g. pdflatex, xelatex, etc.) based on the packages used, and automatically copies over custom user packages from a `~/latex` folder. Run `:Latexmk --help` for more info. |
| `:BibtexToggle` | Toggles between [citation.vim](https://github.com/rafaqz/citation.vim) using bibtex or Zotero for retrieving citations for a given file. The default is bibtex. |

This plugin defines the following mappings.

| Mapping | Description |
| ---- | ---- |
| `<C-z>`, `<Leader>z`, `<Leader>Z` | Invokes `:Latexmk` with no flags, the `--diff` flag, and the `--doc` flag, respectively. `z` is used because I tend to also use this for executing scripts in vim. |
| `<Leader>b` | Invokes `:BibtexToggle`, switching between bibtex or Zotero. |
| `<F1>`, `<F2>` | In insert mode, jumps to the right of the previous or next **delimiter** (i.e. any of the characters `[]<>(){}`). This is handy when the cursor is inside a complex next of varying types of delimiters, a common difficulty when writing LaTeX equations. It stands in contrast to delimitMate's `<Plug>delimitMateJumpMany` map, which jumps to the far outside of nested delimiters. |
| `<C-s><key>` | New `surround.vim` delimiter mappings. These are custom delimiters integrated with the `surround.vim` plugin, introducing a series of insert, visual, and normal mode maps (see [surround.vim](after/plugin/surround.vim) for details). Example usage includes making a visual selection in a LaTeX document then pressing `<C-s>*` to surround with a `\begin{itemize}` `\end{itemize}` environment, or running `yswb` in normal mode to surround the word under the cursor with a `\textbf{}` command.
| `<C-z>key` | New symbol insert mappings. These are maps for inserting text snippets in insert mode (see [surround.vim](after/plugin/surround.vim) for details).  Example usage includes running `<C-z>a` in a LaTeX document to insert the LaTeX alpha character `\alpha`. |
| `[vycd]a<key>`, `[vycd]i<key>` | New text object mappings. These are custom delimiters integrated with the `vim-textobj-user` plugin for selecting, yanking, changing, and deleting blocks of text with `va<key>`, `ya<key>`, etc (see [textobjs.vim](after/plugin/textobjs.vim) for details). Example usage includes selecting a LaTeX `\begin{}` `\end{}` environment with `vaT`, or changing text inside a LaTeX command with `cit`. |
| `<C-b>[ctpn]` | New citation insert mappings. These insert citations from a local bibliography or from your Zotero sqlite database (see [citation.vim](after/plugin/citation.vim) for details). Adds ability to use bibliographies local to specific buffers. |

This plugin defines the following options.

| Option | Description |
| ---- | ---- |
| `g:textools_prevdelim_map`, `g:textools_nextdelim_map` | Alternate definitions for the `<F1>` and `<F2>` maps. `<F1>` and `<F2>` are the default because I configure iTerm2 to map the normally impossible key combinations `<C-,>` and `<C-.>` to FN key presses. This is done by creating maps in Preferences that send the `<F1>` and `<F2>` ASCII HEX codes `0x1b 0x4f 0x50` and `0x1b 0x4f 0x51`, respectively. |
| `g:textools_surround_prefix` | Alternate definition for the `<C-s>` map. Note the map `<C-s>` may require running `bind -r '"\C-s"'` in your terminal or adding it to your `~/.bashrc` or `~/.bash_profile`. |
| `g:textools_symbol_prefix` | Alternate definition for the `<C-z>` map. If you use the default, I suggest adding `noremap <C-z> <Nop>` to your `.vimrc`, to prevent accidentally sending your vim session to the background of your terminal session. |

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

