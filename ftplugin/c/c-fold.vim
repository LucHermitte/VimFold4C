"=============================================================================
" $Id$
" File:         ftplugin/c-fold.vim                                   {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://github.com/LucHermitte/VimFold4C>
" License:      GPLv3 with exceptions
"               <URL:http://code.google.com/p/lh-vim/wiki/License>
" Version:	3.0.2
" Created:	06th Jan 2002
"------------------------------------------------------------------------
" Description:
"       Folding for C and C++
"
"       Unlike folding on syntax or or indent, this script tries to correctly
"       detect the fold boundaries.
"
"       The foldtext displayed will also try to be as pertinent as possible:
"       - Correctly indented
"       - Template parameters may be discarded if they make the line too long
"       - Strip spaces in parenthesis, and eventually parameters when lines are
"       too longs)
"       - Strip scopes:: (optional)
"
" Todo:
" There is still a lot to be done
" - [optional] fold a logging line spanning of several lines (cout, printf,
"   log(stuff << stuff)
" - [optional] Fold visibilities
" - Fold #includes
" - Fold #if
" - Comments
"   - Correctly handle comments for fold boundaries detection
"   - [optional] when there is a leading comment, add a summary at the end of the
"     fold text
"   - [optional] support a policy for comments handling (integrated to the
"     following fold, independent fold, not folded)
"   - use @doxygen tags to build comments foldtext
"   - File headers shall have a special treatment -> detect
"     copyrights/licence/... to build the foldtext
" - Tests
"   - Test, Test, and re-test!
"   - Test with C++11 lambdas
" - Control statements
"   - switch/case
"     - increment foldlevel for every case (switch)
"     - [optional] merge cases that aren't separated by a "break;"
"   - "do { } while();" requires a specific handling
"------------------------------------------------------------------------
" History:
" - A long time ago (~2001), Johannes Zellner published a first folding plugin
"   for C & C++.
" - Then, I did some changes (2002-2004), but the result was very slow at the
"   time. (the last version is still archived in
"   <http://hermitte.free.fr/vim/ressources/lh-cpp.tar.gz>)
" - Eventually I got tired of the slow execution times and moved back to
"   foldmethod=indent.
"
" - Here is a new (2014) version almost entirelly rewritten, that I hope will
"   be fast enough to be usable.
"------------------------------------------------------------------------
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------

" Avoid global reinclusion {{{1
let s:k_version = 1
if &cp || (exists("g:loaded_c_fold")
      \ && (g:loaded_c_fold >= s:k_version)
      \ && !exists('g:force_reload_c_fold'))
  " finish
endif
let g:loaded_c_fold = s:k_version
let s:cpo_save=&cpo
set cpo&vim
" Avoid global reinclusion }}}1
"------------------------------------------------------------------------
" Settings {{{1

" Settings                                       {{{2
setlocal foldexpr=lh#c#fold#expr(v:lnum)
setlocal foldmethod=expr
setlocal foldtext=lh#c#fold#text()

" Script Debugging                               {{{2
command! -b -nargs=0 ShowInstrBegin call s:ShowInstrBegin()

" Script Data                                    {{{2
let b:fold_data_begin = repeat([0], 1+line('$'))
let b:fold_data_end   = deepcopy(b:fold_data_begin)
let b:fold_levels     = deepcopy(b:fold_data_begin)

" Mappings {{{1
nnoremap <silent> <buffer> zx :call lh#c#fold#clear('zx')<cr>
nnoremap <silent> <buffer> zX :call lh#c#fold#clear('zX')<cr>

" To help debug
nnoremap <silent> µ :echo lh#c#fold#expr(line('.')).' -- foldlevels:'.string(b:fold_levels[(line('.')-1):line('.')]).' -- @'.line('.').' -- [beg,end]:['.b:fold_data_begin[line('.')].','.b:fold_data_end[line('.')].']'<CR>


"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
