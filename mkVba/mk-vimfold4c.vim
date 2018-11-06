"=============================================================================
" File:         mkVba/mk-vimfold4c.vim                                {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"               <URL:http://github.com/LucHermitte/VimFold4C>
let s:version = '320'
" Version:      3.2.0
" Created:      18th Sep 2014
" Last Update:  06th Nov 2018
"------------------------------------------------------------------------
" Description:
"       Helper script to build vimfold4c tarball archive
" }}}1
"=============================================================================

let s:project = 'vimfold4c'
cd <sfile>:p:h
try
  let save_rtp = &rtp
  let &rtp = expand('<sfile>:p:h:h').','.&rtp
  exe '27,$MkVimball! '.s:project.'-'.s:version
  set modifiable
  set buftype=
finally
  let &rtp = save_rtp
endtry
finish
README.md
addon-info.json
autoload/lh/c/fold.vim
ftplugin/c/c-fold.vim
VimFlavor
