"=============================================================================
" $Id$
" File:         addons/VimFold4C/mkVba/mk-vimfold4c.vim           {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://code.google.com/p/lh-vim/>
let s:version = '3.0.5'
" Version:      3.0.5
" Created:      18th Sep 2014
" Last Update:  $Date$
"------------------------------------------------------------------------
" Description:
"       «description»
" 
"------------------------------------------------------------------------
" Installation:
"       Drop this file into {rtp}/addons/VimFold4C/mkVba
"       Requires Vim7+
"       «install details»
" History:      «history»
" TODO:         «missing features»
" }}}1
"=============================================================================

let s:project = 'vimfold4c'
cd <sfile>:p:h
try 
  let save_rtp = &rtp
  let &rtp = expand('<sfile>:p:h:h').','.&rtp
  exe '36,$MkVimball! '.s:project.'-'.s:version
  set modifiable
  set buftype=
finally
  let &rtp = save_rtp
endtry
finish
README.md
VimFold4C-addon-info.txt
autoload/lh/c/fold.vim
ftplugin/c/c-fold.vim
