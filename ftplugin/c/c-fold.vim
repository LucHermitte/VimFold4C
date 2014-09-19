"=============================================================================
" $Id$
" File:         ftplugin/c-fold.vim                                   {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://github.com/LucHermitte/VimFold4C>
" License:      GPLv3 with exceptions
"               <URL:http://code.google.com/p/lh-vim/wiki/License>
" Version:	3.0.0
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
" - Correctly handle comments for fold boundaries detection
" - Test, Test, and re-test!
" - Possibly fold a logging line spanning of several lines (cout, printf,
"   log(stuff << stuff)
" - Fold visibilities
" - Fold Includes
" - Fold #if
" - Test with C++11 lambdas
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
let b:fold_data_begin = {}
let b:fold_data_end   = {}
let b:fold_levels     = []


"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
