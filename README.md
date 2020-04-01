# LaTeX tools
This is a collection of custom tools and plugin enhancements for working with LaTeX files in vim, similar to [vimtex](https://github.com/lervag/vimtex).

It includes integration with the [vim-text-obj](https://github.com/kana/vim-textobj-user), [vim-surround](https://github.com/tpope/vim-surround), [delimitMate](https://github.com/Raimondi/delimitMate), and [citation.vim](https://github.com/rafaqz/citation.vim) plugins that make editing LaTeX documents a breeze, and a custom [latexmk](latexmk) script that omits some features from the more ubiquitous [program of the same name](https://mg.readthedocs.io/latexmk.html) and adds useful new features. It also adds a templating engine -- when you open a new `.tex` file, a popup window allows you to load arbitrary `.tex` file templates stored in a `~/latex` folder. This requires the [FZF](https://github.com/junegunn/fzf) vim plugin.

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
| `:Latexmk` | Runs the custom [latexmk script](latexmk). This typesets the document asynchronously, shows a condensed log in a popup split window, and opens the file in the [Skim PDF viewer](https://en.wikipedia.org/wiki/Skim_(software)). It automatically detects the number of times the typesetting command must be called, like the original `latexmk`, automatically figures out which typesetting engine to use based on the packages imported, automatically copies over custom user style and theme files from a `~/latex` folder, and deletes extra files generated during typesetting. Run `:Latexmk --help` for more info. Note that `latexmk` requires GNU sed to function properly (this can be installed on macOS using [Homebrew](https://brew.sh) with `brew install gnu-sed`). |
| `:SnippetFind` | Find the snippet mapping that matches the input regex. |
| `:SnippetShow` | Show a table of the current snippet mappings. |
| `:SurroundFind` | Find the delimiter mapping that matches the input regex. |
| `:SurroundShow` | Show a table of the current delimiter mappings. |
| `:SourceToggle` | Toggles between [citation.vim](https://github.com/rafaqz/citation.vim) using bibtex or Zotero for retrieving citations for the current file. The default is bibtex. |

## Mappings

| Mapping | Description |
| ---- | ---- |
| `<C-z><key>` | These are maps for inserting text snippets in insert mode (see [surround.vim](after/plugin/surround.vim) for details).  Example usage includes running `<C-z>a` in a LaTeX document to insert the LaTeX alpha character `\alpha`. |
| `<C-s><key>`, `ys<obj><key>`, ... | New `surround.vim` delimiter mappings. These are custom delimiters integrated with the `surround.vim` plugin, introducing a series of insert, visual, and normal mode maps (see [surround.vim](after/plugin/surround.vim) for details). Example usage includes making a visual selection in a LaTeX document then pressing `<C-s>*` to surround with a `\begin{itemize}` `\end{itemize}` environment, or running `yswb` in normal mode to surround the word under the cursor with a `\textbf{}` command.
| `va<key>`, `vi<key>`, ... | New text object mappings. These are custom delimiters integrated with the `vim-textobj-user` plugin for selecting, yanking, changing, and deleting blocks of text with `va<key>`, `ya<key>`, etc (see [textobjs.vim](after/plugin/textobjs.vim) for details). Example usage includes selecting a LaTeX `\begin{}` `\end{}` environment with `vaT`, or changing text inside a LaTeX command with `cit`. |
| `<C-b><key>` | New citation insert mappings. These insert citations from a local bibliography or from your Zotero sqlite database (see [citation.vim](after/plugin/citation.vim) for details). Adds ability to use bibliographies local to specific buffers. |
| `<C-h>`, `<C-l>` | Jumps to the right of the previous, next bracket in insert mode (i.e. any of the characters `[]<>(){}`). This is handy when the cursor is inside a complex next of varying types of delimiters, a common difficulty when writing LaTeX equations. It stands in contrast to delimitMate's `<Plug>delimitMateJumpMany` map, which jumps to the far outside of nested delimiters. |

## Functions
| Function | Description |
  | ---- | ---- |
| `textools#delete_delims` | The existing [vim-surround](https://github.com/tpope/vim-surround) API can only handle deleting certain types of delimiters, not custom delimiters set with `g:surround_{num}` or `b:surround_{num}`. Calling this function deletes the *arbitrary* delimiter corresponding to the next keystroke (usage is `ds<key>`). |
| `textools#change_delims` | The existing [vim-surround](https://github.com/tpope/vim-surround) API can only handle changing certain types of delimiters, not custom delimiters set with `g:surround_{num}` or `b:surround_{num}`. Calling this function changes the delimiter corresponding to the first keystroke to the *arbitrary* delimiter corresponding to the second keystroke (usage is `cs<key1><key2>`). |

## Customization

| Option | Description |
| ---- | ---- |
| `g:textools_surround_prefix` | Prefix for the insert and visual mode vim-surround mappings. The default is `<C-s>`, which is intuitive but requires adding `bind -r '"\C-s"'` to your `~/.bashrc` or `~/.bash_profile`. |
| `g:textools_snippet_prefix` | Prefix for the snippet insert mappings. The default is `<C-z>`. |
| `g:textools_citation_prefix` | Prefix for the citation insert mappings. The default is `<C-b>`. |
| `g:textools_citation_maps` | Dictionary of citation insert mapping suffixes and LaTeX cite commands. The default is `let g:textools_citation_maps = {'c':'', 't':'t', 'p':'p', 'n':'num'}`, which inserts `\cite{ref}` when `<C-b>c` is pressed, `\citet{ref}` when `<C-b>t` is pressed, etc. |
| `g:textools_prevdelim_map` | Insert mode mapping for jumping to the previous bracket. The default is `<C-h>`. |
| `g:textools_nextdelim_map` | Insert mode mapping for jumping to the previous bracket. The default is `<C-l>`. |
| `g:textools_latexmk_maps` | Dictionary of normal mode mappings and flags for the `:Latexmk`. This is empty by default. For example, `let g:textools_latexmk_maps = {'<C-x>':'', '<Leader>x':'--diff'}` adds maps that call `:Latexmk` with no flags and the `--diff` flag. |

<!--
TODO:
| `g:textools_tex_surround_maps` | Dictionary of keys corresponding to the vim-surround mappings. |
| `g:textools_{filetype}_surround_maps` | As with `g:textools_tex_surround_maps` but for arbitrary filetypes -- because this feature is not just useful with TeX documents. |
| `g:textools_surround_maps` | As with `g:textools_tex_surround_maps` but for all filetypes. |
-->

# Installation
Install with your favorite [plugin manager](https://vi.stackexchange.com/questions/388/what-is-the-difference-between-the-vim-plugin-managers).
I highly recommend the [vim-plug](https://github.com/junegunn/vim-plug) manager. To install with vim-plug, add
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

