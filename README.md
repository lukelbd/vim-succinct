TeX tools
=========

This is a collection of custom tools and plugin enhancements for working with LaTeX
files in vim, reproducing most of [vimtex](https://github.com/lervag/vimtex)'s
features but with a different, minimal flavor.

* Includes a simplified [latexmk](latexmk) shell script compared to the popular
  [PERL script of the same name](https://mg.readthedocs.io/latexmk.html).
  The latexmk script runs in a popup window parallel with your
  vim session, opens/refreshes the [Skim PDF viewer](https://skim-app.sourceforge.io),
  and optionally moves dependency files in a `~/latex` folder to the current directory.
  See `~/.vim/plugged/vim-textools/bin/latexmk --help` for the full documentation.
* Integrates with the
  [vim-text-obj](https://github.com/kana/vim-textobj-user)
  and [vim-surround](https://github.com/tpope/vim-surround) plugins
  by adding LaTeX-specific delimiters and text objects
  that make editing LaTeX documents a breeze.
* Permits inserting citation labels from `.bib` files added with
  `\bibliography` and `\addbibresource` using fuzzy name selection powered by
  [fzf-bibtex](https://github.com/msprev/fzf-bibtex).
* Permits adding figures inside the `\graphicspath` directories
  with fuzzy name selection powered by [fzf](https://github.com/junegunn/fzf).
* Permits loading arbitrary file templates stored in `g:textools_templates_path`
  (defaults to `~/templates`) when creating new files files using fuzzy name
  selection powered by [fzf](https://github.com/junegunn/fzf).

This set of tools is complex and would take quite a while to document. For now I will
just give a broad summary of the features.

**Note**: In the future, this package may be split up into a generalized
`vim-delimtools` package that supports delimiters and snippets for
several different languages and a `vim-latexmk` package that contains
just the custom `latexmk` script.

Documentation
=============

Commands
--------

| Command | Description |
| ---- | ---- |
| `:Latexmk` | Runs the custom [latexmk script](latexmk). This typesets the document asynchronously, shows a condensed log in a popup split window, and opens the file in the [Skim PDF viewer](https://en.wikipedia.org/wiki/Skim_(software)). It automatically detects the number of times the typesetting command must be called, like the original `latexmk`, automatically figures out which typesetting engine to use based on the packages imported, automatically copies over custom user style and theme files from a `~/latex` folder, and deletes extra files generated during typesetting. Run `:Latexmk --help` for more info. Note that `latexmk` requires GNU sed to function properly (this can be installed on macOS using [Homebrew](https://brew.sh) with `brew install gnu-sed`). |
| `:SnippetFind` | Find the snippet mapping that matches the input regex. |
| `:SnippetShow` | Show a table of the current snippet mappings. |
| `:SurroundFind` | Find the delimiter mapping that matches the input regex. |
| `:SurroundShow` | Show a table of the current delimiter mappings. |

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
| `textools#delete_delims` | The existing [vim-surround](https://github.com/tpope/vim-surround) API can only handle deleting certain types of delimiters, not custom delimiters set with `g:surround_{num}` or `b:surround_{num}`. Calling this function deletes the *arbitrary* delimiter corresponding to the next keystroke (usage is `ds<key>`). |
| `textools#change_delims` | The existing [vim-surround](https://github.com/tpope/vim-surround) API can only handle changing certain types of delimiters, not custom delimiters set with `g:surround_{num}` or `b:surround_{num}`. Calling this function changes the delimiter corresponding to the first keystroke to the *arbitrary* delimiter corresponding to the second keystroke (usage is `cs<key1><key2>`). |

Customization
-------------

| Option | Description |
| ---- | ---- |
| `g:textools_surround_prefix` | Prefix for the insert and visual mode vim-surround mappings. The default is `<C-s>`, which is intuitive but requires adding `bind -r '"\C-s"'` to your `~/.bashrc` or `~/.bash_profile`. |
| `g:textools_snippet_prefix` | Prefix for the citation label, figure filename, and snippet insert mappings. The default is `<C-d>`. |
| `g:textools_prevdelim_map` | Insert mode mapping for jumping to the previous bracket. The default is `<C-h>`. |
| `g:textools_nextdelim_map` | Insert mode mapping for jumping to the previous bracket. The default is `<C-l>`. |
| `g:textools_templates_path` | Location where templates are stored. These are optionally loaded when creating new files. |

Installation
============

Install with your favorite [plugin manager](https://vi.stackexchange.com/q/388/8084).
I highly recommend the [vim-plug](https://github.com/junegunn/vim-plug) manager.
To install with vim-plug, add
```
Plug 'lukelbd/vim-textools'
```
to your `~/.vimrc`.

See also
========

If you find this plugin useful, I also highly recommend the following:

* The [vim-scrollwrapped plugin](https://github.com/lukelbd/vim-scrollwrapped), which
  toggles "wrapped" lines automatically for non-code documents (like markdown, RST, and
  LaTeX files) and makes scrolling through vim windows with heavily wrapped lines much,
  much easier.
* The [idetools plugin](https://github.com/lukelbd/vim-idetools), which includes various
  refactoring commands and tools for jumping around documents based on ctags locations.
* This [ctags preference file](https://github.com/lukelbd/dotfiles/blob/master/.ctags),
  which contains a bunch of new definitions for marking section, figure, table, etc.
  locations with ctags.
