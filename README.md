VimFold4C
=========

Vim fold plugin for C &amp; C++ (and similar langages)

Unlike folding on syntax or or indent, this script tries to correctly detect
the fold boundaries.

The foldtext displayed will also try to be as pertinent as possible:
- Correctly indented
- Template parameters may be discarded if they make the line too long
- Strip spaces in parenthesis, and eventually parameters when lines are too
  longs)
- Strip scopes:: (optional)


## Options

### How to set them

You can set local or global options to tune the behaviour of this fold-plugin.
```vim
let g:fold_options = {
   \ 'show_if_and_else': 1,
   \ 'strip_template_argurments': 1,
   \ 'strip_namespaces': 1,
   \ }
```
or from a [local_vimrc plugin](https://github.com/LucHermitte/local_vimrc):
```vim
let b:fold_options = {
   \ 'show_if_and_else': 1,
   \ 'strip_template_argurments': 1,
   \ 'strip_namespaces': 1,
   \ }
```

### Available options
The options are:
- `show_if_and_else` (which is currently hard-coded to _true_) requires to have
  two folds on 
```c
if (foo) {
    foo_action();
} else {
    bar_action();
}
```
instead of the single fold we have when using `indent` _foldmethod_ (or was it
the `syntax` one ?).

- `strip_template_argurments` (default: _true_) strips template arguments from
  the fold text generated if the text would be too long for the current window
  width

- `strip_namespaces` (default: _true_) tells to strip scopes like `std::` or
  `boost::filesystem::` from the fold text generated.

## Requirements / Installation

This fold-plugin requires vim 7+ and 
[lh-vim-lib](http://code.google.com/p/lh-vim/wiki/lhVimLib).

The easiest way to install this plugin is with
[vim-addon-manager](https://github.com/MarcWeber/vim-addon-manager), or other
plugin managers based on [vim-pi](https://bitbucket.org/vimcommunity/vim-pi),
that support vim-addon-files -- as this script specifies its
[dependencies](https://github.com/LucHermitte/VimFold4C/blob/master/VimFold4C-addon-info.txt)
in vim-addon-file format.

When installing [lh-cpp](http://code.google.com/p/lh-vim/wiki/lhCpp) with
[vim-addon-manager](https://github.com/MarcWeber/vim-addon-manager), or other
plugin managers based on [vim-pi](https://bitbucket.org/vimcommunity/vim-pi),
this fold-plugin will get automatically installed.
```vim
ActivateAddons lh-cpp
" Or just this one (and soon as I register it in vim-pi):
ActivateAddons VimFold4C
```

If you really want to stick with dependencies unware plugins that cannot
support subversion repositories like Vundle, you can install vim-script mirror
of lh-vim-lib on github.
```vim
Bundle 'vim-scripts/lh-vim-lib'                                          
Bundle 'LucHermitte/VimFold4C'
```

So far, it is only triggered for C and C++. It should be easy to use it from
C#, Java, and other languages with C like syntax: a

```vim
runtime ftplugin/c/c-fold.vim
```

from a C#/Java/... ftplugin should do the trick.

However, I'm unlikelly to handle specials cases in those languages.

## TO DO
There is still a lot to be done:

- Correctly handle comments for fold boundaries detection
- Test, Test, and re-test!
- Possibly fold a logging line spanning of several lines (cout, printf,
  log(stuff << stuff)
- Fold visibilities
- Fold Includes
- Fold #if
- Test with C++11 lambdas

## History
- A long time ago (~2001), Johannes Zellner published a first folding plugin
  for C & C++.
- Then, I did some changes (2002-2004), but the result was very slow at the
  time. (the last version is still archived in
  <http://hermitte.free.fr/vim/ressources/lh-cpp.tar.gz>)
- Eventually I got tired of the slow execution times and moved back to
  foldmethod=indent.

- Here is a new (2014) version almost entirelly rewritten, that I hope will
  be fast enough to be usable.
