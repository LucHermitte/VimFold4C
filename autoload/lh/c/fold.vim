"=============================================================================
" $Id$
" File:         addons/VimFold4C/autoload/lh/c/fold.vim           {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://github.com/LucHermitte/VimFold4C>
" Version:	3.0.2
" Created:	06th Jan 2002
"------------------------------------------------------------------------
" Description:
"       Core functions for VimFold4C
" 
"------------------------------------------------------------------------
" Installation:
"       Drop this file into {rtp}/addons/VimFold4C/autoload/lh/c
"       Requires Vim7+
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version                                {{{2
let s:k_version = 1
function! lh#c#fold#version()
  return s:k_version
endfunction

" # Debug                                  {{{2
if !exists('s:verbose')
  let s:verbose = 0
endif
function! lh#c#fold#verbose(...)
  if a:0 > 0 | let s:verbose = a:1 | endif
  if s:verbose
    sign define Fold0   text=0  texthl=Identifier
    sign define Fold1   text=1  texthl=Identifier
    sign define Fold2   text=2  texthl=Identifier
    sign define Fold3   text=3  texthl=Identifier
    sign define Fold4   text=4  texthl=Identifier
    sign define Fold5   text=5  texthl=Identifier
    sign define Fold1gt text=>1 texthl=Identifier
    sign define Fold2gt text=>2 texthl=Identifier
    sign define Fold3gt text=>3 texthl=Identifier
    sign define Fold4gt text=>4 texthl=Identifier
    sign define Fold5gt text=>5 texthl=Identifier
    sign define Fold1lt text=<1 texthl=Identifier
    sign define Fold2lt text=<2 texthl=Identifier
    sign define Fold3lt text=<3 texthl=Identifier
    sign define Fold4lt text=<4 texthl=Identifier
    sign define Fold5lt text=<5 texthl=Identifier
  endif
  exe 'sign unplace * buffer='.bufnr('%')
  return s:verbose
endfunction

function! s:Verbose(expr)
  if s:verbose
    echomsg a:expr
  endif
endfunction

function! lh#c#fold#debug(expr)
  return eval(a:expr)
endfunction

" # Options                                {{{2
" let b/g:fold_options = {
      " \ 'show_if_and_else': 1,
      " \ 'strip_template_argurments': 1,
      " \ 'strip_namespaces': 1,
      " \ 'fold_blank': 1
      " \ }
function! s:opt_show_if_and_else()
  return lh#option#get('fold_options.show_if_and_else', 1)
endfunction
function! s:opt_strip_template_argurments()
  return lh#option#get('fold_options.strip_template_argurments', 1)
endfunction
function! s:opt_strip_namespaces()
  return lh#option#get('fold_options.strip_namespaces', 1)
endfunction
function! s:opt_fold_blank()
  return lh#option#get('fold_options.fold_blank', 1)
endfunction

"------------------------------------------------------------------------
" ## Exported functions {{{1
" Function: lh#c#fold#expr()               {{{2
" Expectation: with i < j, lh#c#fold#expr(i) is called before lh#c#fold#expr(j)
" This way instead of having something recursive to the extreme, we cache fold
" levels from one call to the other.
" It means sometimes we have to refresh everything with zx/zX
function! lh#c#fold#expr(lnum)
  " 0- Resize b:fold_* arrays to have as many lines as the buffer
  call s:ResizeCache()

  " 1- First obtain the current fold boundaries
  let where_it_starts = b:fold_data_begin[a:lnum]
  if where_it_starts == 0
    " it's possible the boundaries was never known => compute thems
    let where_it_ends   = s:WhereInstructionEnds(a:lnum)
    let where_it_starts = b:fold_data_begin[a:lnum]
  else
    " Actually, we can't know when text is changed, the where it starts may
    " change
    let where_it_ends = b:fold_data_end[a:lnum]
  endif



  " 2- Then return what must be
  "
  " Case: "} catch|else|... {"
  " TODO: use the s:opt_show_if_and_else() option
  " -> We check the next line to see whether it closes something before opening
  "  something new
  if a:lnum < line('$')
    let next_line = getline(a:lnum+1)
    if next_line =~ '}.*{'
      " assert(where_it_ends < a:lnum+1)
      let decr = len(substitute(matchstr(next_line, '^[^{]*'), '[^}]', '', 'g'))
            \ + len(substitute(getline(a:lnum), '[^}]', '', 'g'))
      return s:DecrFoldLevel(a:lnum, decr)
    endif
  endif

  let line = getline(where_it_ends)
  " Case: opening, but started earlier
  " -> already opened -> keep fold level
  if a:lnum != where_it_starts && line =~ '{[^}]*$'
    return s:KeepFoldLevel(a:lnum)
  endif


  " "} ... {" -> "{"  // the return of the s:opt_show_if_and_else()
  let line = substitute(line, '^[^{]*}\ze.*{', '', '')
  let incr = len(substitute(line, '[^{]', '', 'g'))
  let decr = len(substitute(line, '[^}]', '', 'g'))
  if incr > decr
    return s:IncrFoldLevel(a:lnum, incr-decr)
  elseif decr > incr
    if a:lnum != where_it_ends
      " Wait till the last moment!
      return s:KeepFoldLevel(a:lnum)
    else
      return s:DecrFoldLevel(a:lnum, decr-incr)
    endif
  else
    " This is where we can detect instructions spawning on several lines
    if line =~ '{.*}'
      " first case: oneliner that cannot be folded => we left it as it is
      if     a:lnum == where_it_starts && a:lnum == where_it_ends | return s:KeepFoldLevel(a:lnum)
      elseif a:lnum == where_it_starts                            | return s:IncrFoldLevel(a:lnum, 1)
      elseif a:lnum == where_it_ends                              | return s:DecrFoldLevel(a:lnum, 1) " Note: this case cannot happen
      endif
    endif
    return s:KeepFoldLevel(a:lnum)
  endif
endfunction

" Function: lh#c#fold#text()               {{{2
function! CFoldText_(lnum)
  let ts = s:Build_ts()
  let lnum = a:lnum
  let lastline = b:fold_data_end[a:lnum]
  let line = ''

  let lnum = s:NextNonCommentNonBlank(lnum, s:opt_fold_blank())

  " Loop for all the lines in the fold                {{{3
  while lnum <= lastline
    let current = getline(lnum)
    " Foldmarks will get ignored
    let current = substitute(current, '{\{3}\d\=.*$', '', 'g')
    " Get rid of C comments
    let current = substitute(current, '/\*.*\*/', '', 'g')

    if current =~ '[^:]:[^:]'
      " class XXX : ancestor
      let current = substitute(current, '\([^:]\):[^:].*$', '\1', 'g')
      let break = 1
    elseif current =~ '{\s*$'
      " '  } else {'
      let current = substitute(current, '^\(\s*\)}\s*', '\1', 'g')
      let current = substitute(current, '{\s*$', '', 'g')
      let break = 1
    else
      let break = 0
    endif
    if empty(line)
      " preserve indention: substitute leading tabs by spaces
      let leading_spaces = matchstr(current, '^\s*')
      let leading_spaces = substitute(leading_spaces, "\t", ts, 'g')
    endif

    " remove leading and trailing white spaces
    let current = matchstr(current, '^\s*\zs.\{-}\ze\s*$')
    " let current = substitute(current, '^\s*', '', 'g')
    " Manual join(), line by line
    if !empty(line) && current !~ '^\s*$' " add a separator
      let line .= ' '
    endif
    let line .= current
    if break
      break
    endif
    " Goto next line
    let lnum = s:NextNonCommentNonBlank(lnum + 1, s:opt_fold_blank())
  endwhile

  " Strip whatever follows "case xxx:" and "default:" {{{3
  let line = substitute(line, 
	\ '^\(\s*\%(case\s\+.\{-}[^:]:\_[^:]\|default\s*:\)\).*', '\1', 'g')

  " Strip spaces within parenthesis                   {{{3
  let line = substitute(line, '\s\{2,}', ' ', 'g')
  let line = substitute(line, '(\zs \| \ze)', '', 'g')

  " Strip namespaces
  if s:opt_strip_namespaces()
    let line = substitute(line, '\<\k\+::', '', 'g')
  endif

  " Add Indentation                                   {{{3
  let line = leading_spaces . line

  " Strip template parameters                         {{{3
  if strlen(line) > (winwidth(winnr()) - &foldcolumn)
	\ && s:opt_strip_template_argurments() && line =~ '\s*template\s*<'
    let c0 = stridx(line, '<') + 1 | let lvl = 1
    let c = c0
    while c > 0
      let c = match(line, '[<>]', c+1)
      if     line[c] == '<'
	let lvl += 1
      elseif line[c] == '>' 
	if lvl == 1 | break | endif
	let lvl -= 1
      endif
    endwhile 
    " TODO: doesn't work with template specialization
    let line = strpart(line, 0, c0) . '...' . strpart(line, c)
  endif

  " Return the result                                 {{{3
  return substitute(line, "\t", ' ', 'g')
  " let lines = v:folddashes . '[' . (v:foldend - v:foldstart + 1) . ']'
  " let lines .= repeat(' ', 10 - strlen(lines))
  " return lines . line
endfunction

function! lh#c#fold#text()
  " return getline(v:foldstart) " When there is a bug, use this one
  return CFoldText_(v:foldstart)
endfunction

" Function: lh#c#fold#clear(cmd)           {{{2
function! lh#c#fold#clear(cmd)
  call lh#c#fold#verbose( s:verbose) " clear signs
  let b:fold_data_begin = repeat([0], 1+line('$'))
  let b:fold_data_end   = copy(b:fold_data_begin)
  let b:fold_levels     = copy(b:fold_data_begin)
  exe 'normal! '.a:cmd
endfunction

"------------------------------------------------------------------------
" ## Internal functions {{{1
" Function: s:ResizeCache()                {{{2
function! s:ResizeCache()
  let missing = line('$') - len(b:fold_levels) + 1
  if missing > 0
    let to_be_appended = repeat([0], missing)
    let b:fold_levels     += to_be_appended
    let b:fold_data_begin += to_be_appended
    let b:fold_data_end   += to_be_appended
  endif
  " @post len(*) == line('$') + 1
endfunction

" Function: s:CleanLine(line)              {{{2
" clean from comments
" TODO: merge with similar functions in lh-cpp and lh-dev
function! s:CleanLine(line)
  " 1- remove strings
  let line = substitute(a:line, '".\{-}[^\\]"', '', 'g')
  " 2- remove C Comments
  let line = substitute(line, '/\*.\{-}\*/', '', 'g')
  " 3- remove C++ Comments
  let line = substitute(line, '//.*', '', 'g')
  return line
endfunction

" Function: s:WhereInstructionEnds()       {{{2
" Given a line number, search for something that indicates the end of a
" instruction => ; , {, }
" TODO: Handle special case: "do { ... }\nwhile()\n;"
function! s:WhereInstructionEnds(lnum)
  let last_line = line('$')
  let lnum = a:lnum
  while lnum <= last_line
    " Where the instruction started
    let b:fold_data_begin[lnum] = a:lnum
    let line = s:CleanLine(getline(lnum))
    if line =~ '[{}]\|^#\|^\s*\(public\|private\|protected\):\|;\s*$'
      break
    endif
    let lnum += 1
  endwhile

  " assert(lnum <= last_line)
  let l = a:lnum
  while l <= lnum
    let b:fold_data_end[l] = lnum
    let l += 1
  endwhile
  
  return lnum
endfunction

" Function: s:IsACommentLine(lnum)         {{{2
function! s:IsACommentLine(lnum, or_blank)
  let line = getline(a:lnum)
  if line =~ '^\s*//'. (a:or_blank ? '\|^\s*$' : '')
    " C++ comment line / empty line => continue
    return 1
  elseif line =~ '\S.*\(//\|/\*.\+\*/\)'
    " Not a comment line => break
    return 0
  else
    let id = synIDattr(synID(a:lnum, strlen(line)-1, 0), 'name')
    return id =~? 'comment\|doxygen'
  endif
endfunction

" Function: s:NextNonCommentNonBlank(lnum) {{{2
" Comments => ignore them:
" the fold level is determined by the code that follows
function! s:NextNonCommentNonBlank(lnum, or_blank)
  let lnum = a:lnum
  let lastline = line('$')
  while (lnum <= lastline) && s:IsACommentLine(lnum, a:or_blank)
    let lnum += 1
  endwhile
  return lnum
endfunction

" Function: s:NextNonCommentNonBlank(lnum) {{{2
" Comments => ignore them:
" the fold level is determined by the code that follows
function! s:NextNonCommentNonBlank(lnum, or_blank)
  let lnum = a:lnum
  let lastline = line('$')
  while (lnum <= lastline) && s:IsACommentLine(lnum, a:or_blank)
    let lnum += 1
  endwhile
  return lnum
endfunction
" Function: s:Build_ts()                   {{{2
function! s:Build_ts()
  if !exists('s:ts_d') || (s:ts_d != &ts)
    let s:ts = repeat(' ', &ts)
    let s:ts_d = &ts
  endif
  return s:ts
endfunction

" Function: s:ShowInstrBegin()             {{{2
function! s:ShowInstrBegin()
  sign define Fold   text=~~ texthl=Identifier
  
  let bufnr = bufnr('%')
  silent! exe 'sign unplace * buffer='.bufnr
  let boi = lh#list#unique_sort(values(b:fold_data_begin))
  for l in boi
    exe 'sign place '.l.' line='.l.' name=Fold buffer='.bufnr
  endfor
endfunction

" Function: s:IncrFoldLevel(lnum)          {{{2
" @pre lnum > 0
" @pre len(b:fold_levels) == line('$')+1
function! s:IncrFoldLevel(lnum, nb)
  let b:fold_levels[a:lnum] = b:fold_levels[a:lnum-1] + a:nb
  if s:verbose
    exe 'sign place '.a:lnum.' line='.a:lnum.' name=Fold'.b:fold_levels[a:lnum].'gt buffer='.bufnr('%')
  endif
  return '>'.b:fold_levels[a:lnum]
endfunction

" Function: s:DecrFoldLevel(lnum)          {{{2
" @pre lnum > 0
" @pre len(b:fold_levels) == line('$')+1
function! s:DecrFoldLevel(lnum, nb)
  let b:fold_levels[a:lnum] =  max([b:fold_levels[a:lnum-1]- a:nb, 0])
  if s:verbose
    exe 'sign place '.a:lnum.' line='.a:lnum.' name=Fold'.(b:fold_levels[a:lnum]+1).'lt buffer='.bufnr('%')
  endif
  return '<'.(b:fold_levels[a:lnum]+1)
endfunction

" Function: s:KeepFoldLevel(lnum)          {{{2
" @pre lnum > 0
" @pre len(b:fold_levels) == line('$')+1
function! s:KeepFoldLevel(lnum)
  let b:fold_levels[a:lnum] = b:fold_levels[a:lnum-1]
  if s:verbose
    exe 'sign place '.a:lnum.' line='.a:lnum.' name=Fold'.b:fold_levels[a:lnum].' buffer='.bufnr('%')
  endif
  return b:fold_levels[a:lnum]
endfunction

"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
"
