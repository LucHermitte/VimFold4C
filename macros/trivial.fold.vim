"=============================================================================
" $Id$
" File:         macros/trivial.fold.vim                           {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://code.google.com/p/lh-vim/>
" Version:      001
" Created:      19th Sep 2014
" Last Update:  $Date$
"------------------------------------------------------------------------
" Description:
"       Script to test foldexpressions
"
"       Just source it on a file with foldexpressions  to see how vim handles
"       them.
" 
"------------------------------------------------------------------------
" Installation:
"       Drop this file into {rtp}/macros
"       Requires Vim7+
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------

setlocal foldexpr=TrivialFold(v:lnum)
setlocal foldmethod=expr

function! TrivialFold(lnum)
  return getline(a:lnum)
endfunction

let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
