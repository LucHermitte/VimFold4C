"=============================================================================
" File:         ftplugin/c-fold.vim                                   {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://github.com/LucHermitte/VimFold4C>
" License:      GPLv3 with exceptions
"               <URL:http://code.google.com/p/lh-vim/wiki/License>
" Version:	3.1.0
let s:k_version = 310
" Created:	06th Jan 2002
"------------------------------------------------------------------------
" Description:
"       Folding for C and C++
"
" Unlike folding on syntax or on indent, this script tries to correctly detect
" the fold boundaries, and to display comprehensible foldtext.
"
" See README.md for more information
"
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
command! -b -nargs=0 ShowInstrBegin call lh#c#fold#debug(s:ShowInstrBegin())

" Script Data                                    {{{2
let b:fold_data              = {}
let b:fold_data.begin        = repeat([0], 1+line('$'))
let b:fold_data.instr_begin  = deepcopy(b:fold_data.begin)
let b:fold_data.instr_end    = deepcopy(b:fold_data.begin)
let b:fold_data.end          = deepcopy(b:fold_data.begin)
let b:fold_data.levels       = deepcopy(b:fold_data.begin)
let b:fold_data.context      = repeat([''], 1+line('$'))
let b:fold_data.last_updated = 0

" Mappings {{{1
nnoremap <silent> <buffer> zx :call lh#c#fold#clear('zx')<cr>
nnoremap <silent> <buffer> zX :call lh#c#fold#clear('zX')<cr>

" To help debug
" nnoremap <silent> µ :echo lh#c#fold#expr(line('.')).' -- foldlevels:'.string(b:fold_data.levels[(line('.')-1):line('.')]).' -- @'.line('.').' -- [beg,end;instr_beg,instr_end]:['.b:fold_data.begin[line('.')].','.b:fold_data.end[line('.')].','.b:fold_data.instr_begin[line('.')].','.b:fold_data.instr_end[line('.')].'] --> ctx:'.b:fold_data.context[line('.')]<CR>


"------------------------------------------------------------------------
" }}}1
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
