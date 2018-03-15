"=============================================================================
" File:         autoload/lh/c/fold.vim                                {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"               <URL:http://github.com/LucHermitte/VimFold4C>
" Version:      3.1.0
let s:k_version = 310
" Created:      06th Jan 2002
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
" # Version {{{2
function! lh#c#fold#version()
  return s:k_version
endfunction

" # Debug   {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#c#fold#verbose(...) "{{{3
  if a:0 > 0 | let s:verbose = a:1 | endif
  if s:verbose
    sign define Fold0   text=0  texthl=Identifier
    for i in range(1, 9)
      exe 'sign define Fold'.i.'   text=|'.i.' texthl=Identifier'
      exe 'sign define Fold'.i.'gt text=>'.i.' texthl=Identifier'
      exe 'sign define Fold'.i.'lt text=<'.i.' texthl=Identifier'
    endfor
  endif
  exe 'sign unplace * buffer='.bufnr('%')
  return s:verbose
endfunction

function! s:Log(expr, ...) "{{{3
  call call('lh#log#this',[a:expr]+a:000)
endfunction

function! s:Verbose(expr, ...) "{{{3
  if s:verbose >= 2
    call call('s:Log',[a:expr]+a:000)
  endif
endfunction

function! lh#c#fold#debug(expr) abort "{{{3
  return eval(a:expr)
endfunction

" Function: lh#c#fold#toggle_balloons() {{{3
function! lh#c#fold#toggle_balloons() abort
  if &bexpr == 'lh#c#fold#_balloon_expr()'
    call s:balloon_reset.finalize()
    call lh#common#WarningMsg('Stop balloon debugging for VimFold4C')
  else
    let s:balloon_reset = lh#on#exit()
          \.restore('&beval')
          \.restore('&bexpr')
    setlocal beval bexpr=lh#c#fold#_balloon_expr()
    call lh#common#WarningMsg('Start balloon debugging for VimFold4C')
  endif
endfunction

" Function: lh#c#fold#_balloon_expr() {{{3
function! lh#c#fold#_balloon_expr() abort
  if !exists('b:fold_data')
    " This may happen when splitting a window where bexpr is set
    " `:sp` copy all local option values, even if the filetype of the
    " buffer on't be compatible...
    setlocal bexpr<
    return
  endif
  let l = v:beval_lnum
  let expr = printf("Debug VimFold4C\nline: %d\nlevel: %d\ndata: [%d, %d]\ninstr: [%d, %d]\ncontext: %s",
        \ l, b:fold_data.levels[l],
        \ b:fold_data.begin[l], b:fold_data.end[l],
        \ b:fold_data.instr_begin[l], b:fold_data.instr_end[l],
        \ b:fold_data.context[l]
        \ )
  return expr
endfunction

" # Options {{{2
" let b/g:fold_options = {
      " \ 'fold_blank': 1,
      " \ 'fold_includes': 1,
      " \ 'ignored_doxygen_fields' : ['class', 'ingroup', 'function', 'def', 'defgroup', 'exception', 'headerfile', 'namespace', 'property', 'fn', 'var']
      " \ 'max_foldline_length': 'win'/'tw'/42,
      " \ 'merge_comments' : 1
      " \ 'show_if_and_else': 1,
      " \ 'strip_namespaces': 1,
      " \ 'strip_template_arguments': 1,
      " \ }
function! s:opt_show_if_and_else() abort
  return lh#option#get('fold_options.show_if_and_else', 1)
endfunction
function! s:opt_strip_template_arguments() abort
  return lh#option#get('fold_options.strip_template_arguments', 1)
endfunction
function! s:opt_strip_namespaces() abort
  return lh#option#get('fold_options.strip_namespaces', 1)
endfunction
function! s:opt_fold_blank() abort
  return lh#option#get('fold_options.fold_blank', 1)
endfunction
function! s:opt_fold_includes() abort
  return lh#option#get('fold_options.fold_includes', 1)
endfunction
function! s:opt_max_foldline_length() abort
  " TODO: optimize this function call
  let how = lh#option#get('fold_options.max_foldline_length', 'win')
  if type(how) == type(42)
    return how - &foldcolumn
  elseif how =~ '\ctw\|textwidth'
    return &tw - &foldcolumn
  else " if how =~ '\cwin\%[dow]'
    " I don't check for errors as it could mess vim
    return winwidth(winnr()) - &foldcolumn
  endif
endfunction
function! s:opt_merge_comments() abort
  return lh#option#get('fold_options.merge_comments', 1)
endfunction
let s:k_ignored_doxygen_fields = ['class', 'ingroup', 'function', 'def', 'defgroup', 'exception', 'headerfile', 'namespace', 'property', 'fn', 'var']
function! s:opt_ignored_doxygen_fields() abort
  return lh#option#get('fold_options.ignored_doxygen_fields', s:k_ignored_doxygen_fields)
endfunction

function! s:line_doesnt_matches_an_ignored_doxygen_field(line) abort
  let fields = s:opt_ignored_doxygen_fields()
  let matches = map(copy(fields), 'match(a:line, "[@\\\\]".v:val)')
  return empty(filter(matches, 'v:val >= 0'))
endfunction

"------------------------------------------------------------------------
" ## Exported functions {{{1
" Function: lh#c#fold#expr()               {{{2
" Expectation: with i < j, lh#c#fold#expr(i) is called before lh#c#fold#expr(j)
" This way instead of having something recursive to the extreme, we cache fold
" levels from one call to the other.
" It means sometimes we have to refresh everything with zx/zX
function! lh#c#fold#expr(lnum) abort
  let opt_merge_comments = s:opt_merge_comments()

  " 0- Resize b:fold_* arrays to have as many lines as the buffer {{{4
  call s:ResizeCache()

  " 1- First obtain the current fold boundaries {{{4
  let where_it_starts = b:fold_data.begin[a:lnum]
  if where_it_starts == 0
    " it's possible the boundaries was never known => compute thems
    let where_it_ends   = s:WhereInstructionEnds(a:lnum, opt_merge_comments)
    let where_it_starts = b:fold_data.begin[a:lnum]
  else
    " Actually, we can't know when text is changed, the where it starts may
    " change
    let where_it_ends = b:fold_data.end[a:lnum]
  endif


  " 2- Then return what must be {{{4
  let instr_start = b:fold_data.instr_begin[a:lnum]
  let instr_lines = s:getline(instr_start, where_it_ends)

  " Case: "} catch|else|... {" & "#elif" & "#else" {{{5
  " TODO: use the s:opt_show_if_and_else() option
  " -> We check the next line to see whether it closes something before opening
  "  something new
  if a:lnum < line('$')
    let instr_line = join(instr_lines, '')
    let next_line = getline(a:lnum+1)
    if next_line =~ '}.*{'
      " assert(where_it_ends < a:lnum+1)
      let decr = len(substitute(matchstr(next_line, '^[^{]*'), '[^}]', '', 'g'))
            \ + len(substitute(instr_line, '[^}]', '', 'g'))
      let b:fold_data.context[a:lnum] = ''
      return s:DecrFoldLevel(a:lnum, decr)
    elseif next_line =~ '^\s*#\s*\(elif\|else\)'
      let decr = 1
            \ + len(substitute(instr_line, '[^}]', '', 'g'))
      return s:DecrFoldLevel(a:lnum, decr)
    endif
  endif

  " The lines to analyze {{{5
  let lines = getline(where_it_starts, where_it_ends)
  let line  = getline(where_it_ends)

  " Case: #include {{{5
  let fold_includes = s:opt_fold_includes()
  if fold_includes && line =~ '^\s*#\s*include'
    let b:fold_data.context[a:lnum] = 'include'
    if     b:fold_data.context[a:lnum-1] == '#if'
      " Override #include context with #if
      let b:fold_data.context[a:lnum] = b:fold_data.context[a:lnum-1]
      return s:KeepFoldLevel(a:lnum)
    elseif b:fold_data.context[a:lnum-1] != 'include'
      " Start a new #include block
      let b:fold_data.context[where_it_starts : where_it_ends]
            \ = repeat(['include'], 1 + where_it_ends - where_it_starts)
      " And update the include context for the next elements...
      if getline(where_it_ends+1) =~ '^\s*#\s*include'
        let where_next_ends = s:WhereInstructionEnds(a:lnum+1, opt_merge_comments)
        let b:fold_data.context[where_it_starts : where_next_ends]
              \ = repeat(['include'], 1 + where_next_ends - where_it_starts)
      endif
      return s:IncrFoldLevel(a:lnum, 1)
    endif

    let where_next_ends = s:WhereInstructionEnds(a:lnum+1, opt_merge_comments)
    let next_lines = getline(a:lnum+1, where_next_ends)
    if match(next_lines, '^\s*#\s*include') == -1
      return s:DecrFoldLevel(a:lnum, 1)
    else
      let b:fold_data.context[where_it_starts : where_next_ends]
            \ = repeat(['include'], 1 + where_next_ends - where_it_starts)
      return s:KeepFoldLevel(a:lnum)
    endif
  elseif b:fold_data.context[a:lnum] == 'include'
    if a:lnum == where_it_ends && match(getline(a:lnum+1), '^\s*#\s*include') == -1
      " line is the last in the "#include" context, and the next line
      " doesn't match "#include" either => end of the fold
      return s:DecrFoldLevel(a:lnum, 1)
    else
      return s:KeepFoldLevel(a:lnum)
    endif
  endif

  " Clear include context {{{5
  " But maintain #if context and ignore #endif context
  if     b:fold_data.context[a:lnum-1] == '#if' && b:fold_data.context[a:lnum] != '#endif'
    let b:fold_data.context[a:lnum] = b:fold_data.context[a:lnum-1]
  elseif b:fold_data.context[a:lnum] != '#endif'
    let b:fold_data.context[a:lnum] = ''
  endif

  " Case: Opening things ? {{{5
  " The foldlevel increase can be done only at the start of the instruction
  if a:lnum == where_it_starts
    if     line =~ '^\s*#\s*ifndef'
      let symbol = matchstr(line, '^\s*#\s*ifndef\s\+\zs\S\+')
      if (s:getline(a:lnum+1) !~ '^\s*#\s*define\s\+'.symbol.'\s*$') || !empty(filter(b:fold_data.context[:a:lnum], 'v:val == "#if"'))
        let b:fold_data.context[a:lnum] = '#if'
        return s:IncrFoldLevel(a:lnum, 1)
        " else: we ignore the first which is likelly an anti-reinclusion
        " guard
      endif
    elseif line =~ '^\s*#\s*if'
      let b:fold_data.context[a:lnum] = '#if'
      return s:IncrFoldLevel(a:lnum, 1)
    endif
  elseif line =~ '{[^}]*$'
    " Case: opening, but started earlier
    " -> already opened -> keep fold level
    return s:KeepFoldLevel(a:lnum)
  endif

  " Case: "#else", "#elif", "#endif" {{{5
  if line =~ '^\s*#\s*\(else\|elif\)'
    return s:IncrFoldLevel(a:lnum, 1)
  elseif  match(lines, '^\s*#\s*endif') >= 0
    if a:lnum == where_it_ends
      let b:fold_data.context[a:lnum] = '#endif'
      return s:DecrFoldLevel(a:lnum, 1)
    else
      " Register where the #endif ends
      let b:fold_data.context[where_it_starts : where_it_ends]
            \ = repeat(['#endif'], 1 + where_it_ends - where_it_starts)
    endif
  endif
  if b:fold_data.context[a:lnum] == '#endif' && a:lnum == where_it_ends
      return s:DecrFoldLevel(a:lnum, 1)
  endif

  " Case: "} ... {" -> "{"  // the return of the s:opt_show_if_and_else() {{{5
  " TODO: support multiline comments
  call map(instr_lines, "substitute(v:val, '^[^{]*}\\ze.*{', '', '')")

  let line = join(instr_lines, '')
  let incr = count(line, '{') " len(substitute(line, '[^{]', '', 'g'))
  let decr = count(line, '}') " len(substitute(line, '[^}]', '', 'g'))

  if incr > decr  && a:lnum == where_it_starts
    return s:IncrFoldLevel(a:lnum, incr-decr)
  elseif decr > incr
    if a:lnum != where_it_ends
      " Wait till the last moment!
      return s:KeepFoldLevel(a:lnum)
    else
      return s:DecrFoldLevel(a:lnum, decr-incr)
    endif
  else
    " This is where we can detect instructions, or comments, spanning on several lines
    " Note: ";" case permits to merge comments with single-line function
    " declarations, but also to fold multi-line instructions. At this
    " point, I don't see how to distinguish the two cases: functions
    " calls and function declarations are quite alike.
    " Should it be an option?
    if line =~ '\v\{.*\}|;\s*$'
          \ || (!opt_merge_comments && join(getline(instr_start, where_it_ends), '') =~ '\v^\s*(/\*.*\*/|//)')
      " first case: oneliner that cannot be folded => we left it as it is
      if     a:lnum == instr_start && a:lnum == where_it_ends | return s:KeepFoldLevel(a:lnum)
      elseif a:lnum == instr_start                            | return s:IncrFoldLevel(a:lnum, 1)
      elseif a:lnum == where_it_ends                          | return s:DecrFoldLevel(a:lnum, 1) " Note: this case cannot happen
      endif
    endif
    return s:KeepFoldLevel(a:lnum)
  endif
endfunction

" Function: lh#c#fold#text()               {{{2
function! lh#c#fold#text_(lnum) abort
  " options cached
  let shall_fold_blank = s:opt_fold_blank()
  let ts = s:Build_ts()

  let lnum = s:NextNonCommentNonBlank(a:lnum, shall_fold_blank)

  " Case: Don't merge comment                         {{{3
  if (lnum > a:lnum) && ! s:opt_merge_comments()
    " => Extract something like the brief line...
    let lines = getline(b:fold_data.begin[a:lnum], b:fold_data.end[a:lnum])

    let leading_spaces = matchstr(lines[0], '^\s*')
    let leading_spaces = substitute(leading_spaces, "\t", ts, 'g')

    let [lead, lead_start, lead_end] = matchstrpos(lines[0], '\v/.[*!]?\ze(\_s|$)')
    " Trim line of repeated characters, if any
    let lines[0] = substitute(lines[0][lead_end:], '\v(.)\1+\s*$', '', '')
    let tail = matchstr(lines[-1], './\ze\s*$')
    " Remove leading characters like '*', '///', and so on
    call map(lines, 'substitute(v:val, "\\v^\\s*(/\\*[*!]|//!|///|[*])", "", "")')
    " Remove leading spaces
    call map(lines, 'substitute(v:val, "^\\s*", "", "")')
    " * Ignore stuff like \class, @ingroup, ...
    let ignored_doxygen_fields = s:opt_ignored_doxygen_fields()
    call filter(lines, 's:line_doesnt_matches_an_ignored_doxygen_field(v:val)')
    " * Extract brief line
    " -> Search the first empty line after the first that is not empty...
    let first = match(lines, '.')
    let end = index(lines, '', first+1)
    " -> Ignore what follows
    let lines = lines[first : end]
    let line = join(lines, ' ')
    let line = substitute(line, '\v\.\zs(\_s|$).*', '', '')
    let line = substitute(line, '[\\@]brief ', '', '')

    return leading_spaces . lead.' '.line.' '.tail
  endif

  " Case: #include                                    {{{3
  if b:fold_data.context[a:lnum] == 'include'
    let includes = []
    let lastline = line('$')
    while lnum <= lastline && b:fold_data.context[lnum] == 'include'
      let includes += [matchstr(getline(lnum), '["<]\zs.*\ze[">]')]
      let lnum = s:NextNonCommentNonBlank(lnum+1, shall_fold_blank)
    endwhile
    return '#include '.join(includes, ' ')
  endif

  " Case: #if & co                                    {{{3
  " No need: What follows does the work

  " Loop for all the lines in the fold                {{{3
  let line = ''
  let in_macro_ctx = 0

  let lastline = b:fold_data.end[a:lnum]
  while lnum <= lastline
    let current = getline(lnum)
    " Foldmarks will get ignored
    let current = substitute(current, '{\{3}\d\=.*$', '', 'g')
    " Get rid of C comments
    let current = substitute(current, '/\*.*\*/', '', 'g')

    if current =~ '^#\s*\(if\|elif\).*\\$'
      let in_macro_ctx = 1
      let current = substitute(current, '\s*\\$', '', '')
      let break = 0
      let lastline = line('$')
    elseif in_macro_ctx
      let in_macro_ctx = !empty(current) && current[-1] == '\\'
      let current = substitute(current, '\s*\\$', '', '')
      let break = ! in_macro_ctx

    elseif current =~ '[^:]:[^:]' && current !~ 'for\s*('
      " class XXX : ancestor
      " Ignore C++11 for range loops
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
    let lnum = s:NextNonCommentNonBlank(lnum + 1, shall_fold_blank)
  endwhile
  let leading_spaces = get(l:, 'leading_spaces', '')

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
  if s:IsLineTooLong(line)
        \ && s:opt_strip_template_arguments() && line =~ '\s*template\s*<'
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

  " Replace tabs                                      {{{3
  let line = substitute(line, "\t", ' ', 'g')

  " Trim line if too long                             {{{3
  if s:IsLineTooLong(line)
    " TODO: factorise option fetching
    let max_length = s:opt_max_foldline_length() - &foldcolumn
    call s:Verbose('Trimming #%1: %2', a:lnum, line)
    let line = s:TrimLongLine(line, max_length)
  endif

  " Return the result                                 {{{3
  return line
  " let lines = v:folddashes . '[' . (v:foldend - v:foldstart + 1) . ']'
  " let lines .= repeat(' ', 10 - strlen(lines))
  " return lines . line
endfunction

function! lh#c#fold#text() abort
  " return getline(v:foldstart) " When there is a bug, use this one
  return lh#c#fold#text_(v:foldstart)
endfunction

" Function: lh#c#fold#clear(cmd)           {{{2
" b:fold_data.begin: Block of non empty lines before the instruction
"                    New line => new block
"                    TODO: merge several comment blocks ?
" b:fold_data.end:   Will contain all empty lines  that follow
"                    TODO: special case: do {...} while ();
"
" + special case: #includes
function! lh#c#fold#clear(cmd) abort
  call lh#c#fold#verbose(s:verbose) " clear signs
  let b:fold_data.begin       = repeat([0], 1+line('$'))
  let b:fold_data.end         = copy(b:fold_data.begin)
  let b:fold_data.instr_begin = copy(b:fold_data.begin)
  let b:fold_data.instr_end   = copy(b:fold_data.begin)
  let b:fold_data.levels           = copy(b:fold_data.begin)
  let b:fold_data.context          = repeat([''], 1+line('$'))
  let b:fold_data.last_updated = 0
  exe 'normal! '.a:cmd
endfunction

"------------------------------------------------------------------------
" ## Internal functions {{{1
" Function: s:ResizeCache()                  {{{2
function! s:ResizeCache() abort
  let missing = line('$') - len(b:fold_data.levels) + 1
  if missing > 0
    let to_be_appended = repeat([0], missing)
    let b:fold_data.levels           += to_be_appended
    let b:fold_data.begin       += to_be_appended
    let b:fold_data.end         += to_be_appended
    let b:fold_data.instr_begin += to_be_appended
    let b:fold_data.instr_end   += to_be_appended
    let b:fold_data.context          += repeat([''], missing)
  endif
  " @post len(*) == line('$') + 1
endfunction

" Function: s:CleanLine(line)                {{{2
" clean from comments
" TODO: merge with similar functions in lh-cpp and lh-dev
function! s:CleanLine(line) abort
  " 1- remove strings
  let line = substitute(a:line, '".\{-}[^\\]"', '', 'g')
  " 2- remove C Comments
  let line = substitute(line, '/\*.\{-}\*/', '', 'g')
  " 3- remove C++ Comments
  let line = substitute(line, '//.*', '', 'g')
  return line
endfunction

function! s:CleanLineCtx(line, ctx) abort
  let line = a:line
  if a:ctx.is_in_a_continuing_comment
    let p = matchend(line, '\*/')
    if p >= 0
      let line = line[p:]
      let a:ctx.is_in_a_continuing_comment = 0
    else
      return ''
    endif
  endif
  " 1- remove strings
  let line = substitute(line, '".\{-}[^\\]"', '', 'g')
  " 2- remove C Comments
  let line = substitute(line, '/\*.\{-}\*/', '', 'g')
  " 3- remove C++ Comments
  let line = substitute(line, '//.*', '', 'g')
  " 4- multilines C comments
  let p = match(line, '/\*')
  if p >= 0
    let line = p > 0 ? line[: (p-1)] : ''
    let a:ctx.is_in_a_continuing_comment = 1
  endif
  return line
endfunction

" Function: s:WhereInstructionEnds()         {{{2
" Given a line number, search for something that indicates the end of a
" instruction => ; , {, }
" TODO: Handle special case: "do { ... }\nwhile()\n;"
let s:g_syn_filter_comments = lh#syntax#line_filter('\v\ccomment|doxygen')

function! s:WhereInstructionEnds(lnum, opt_merge_comments) abort
  let last_line = line('$')
  let lnum = a:lnum
  " let last = lnum
  if ! a:opt_merge_comments
    " whithin a comment line => search end of the comment line
    " else => as usual
    let line = s:g_syn_filter_comments.getline_not_matching(lnum)
    if line =~ '^\s*$'
      " let lnum += 1
      " => only whitespaces & comments in the line
      " => let's merge with comments
      while lnum <= last_line
        let line = s:g_syn_filter_comments.getline_not_matching(lnum+1)
        if line !~ '^\s*$'
          break
        endif
        let lnum += 1
      endwhile
      let as_usual = 0
    else
      " in the other case, let search as usual
      let as_usual = 1
    endif
  else
    let as_usual = 1
  endif

  while (lnum <= last_line) && as_usual
    "" Where the instruction started
    " let b:fold_data.begin[lnum] = a:lnum
    let line = getline(lnum)
    if line =~ '^\s*$'
      break
    else
      let line = s:getline(lnum) " remove comments & strings
      if line =~ '[{}]\|^\s*#\|^\s*\(public\|private\|protected\):\|;\s*$'
        " let last = lnum
        " Search next non empty line -- why don't I use nextnonblank(lnum)?
        while lnum < last_line && getline(lnum+1) =~ '^\s*$'
          let lnum += 1
        endwhile
        " TODO: if there is no error => use this new value
        " call lh#assert#value(lnum).equal(max(nextnonblank(last+1)-1, last))
        break
      endif
    endif
    let lnum += 1
  endwhile

  " assert(lnum <= last_line)
  let b:fold_data.instr_begin[(a:lnum):lnum] = map(b:fold_data.instr_begin[(a:lnum):lnum], 'min([v:val==0 ? (a:lnum) : v:val, a:lnum])')
  " let b:fold_data.instr_end[(a:lnum):last]   = repeat([last], last-a:lnum+1)
  let nb = lnum-a:lnum+1
  let b:fold_data.begin[(a:lnum):lnum]       = repeat([a:lnum], nb)
  let b:fold_data.end[(a:lnum):lnum]         = repeat([lnum], nb)

  return lnum
endfunction

" Function: s:IsACommentLine(lnum)           {{{2
function! s:IsACommentLine(lnum, or_blank) abort
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

" Function: s:NextNonCommentNonBlank(lnum)   {{{2
" Comments => ignore them:
" the fold level is determined by the code that follows
function! s:NextNonCommentNonBlank(lnum, or_blank) abort
  let lnum = a:lnum
  let lastline = line('$')
  while (lnum <= lastline) && s:IsACommentLine(lnum, a:or_blank)
    let lnum += 1
  endwhile
  return lnum
endfunction

" Function: s:Build_ts()                     {{{2
function! s:Build_ts() abort
  if !exists('s:ts_d') || (s:ts_d != &ts)
    let s:ts = repeat(' ', &ts)
    let s:ts_d = &ts
  endif
  return s:ts
endfunction

" Function: s:ShowInstrBegin()               {{{2
function! s:ShowInstrBegin() abort
  silent sign define Fold   text=~~ texthl=Identifier

  let bufnr = bufnr('%')
  silent! exe 'sign unplace * buffer='.bufnr
  let boi = lh#list#unique_sort(values(b:fold_data.begin))
  for l in boi
    silent exe 'sign place '.l.' line='.l.' name=Fold buffer='.bufnr
  endfor
endfunction

" Function: s:IncrFoldLevel(lnum)            {{{2
" @pre lnum > 0
" @pre len(b:fold_data.levels) == line('$')+1
function! s:IncrFoldLevel(lnum, nb) abort
  let b:fold_data.levels[a:lnum] = b:fold_data.levels[a:lnum-1] + a:nb
  if s:verbose
    silent exe 'sign place '.a:lnum.' line='.a:lnum.' name=Fold'.b:fold_data.levels[a:lnum].'gt buffer='.bufnr('%')
  endif
  return '>'.b:fold_data.levels[a:lnum]
endfunction

" Function: s:DecrFoldLevel(lnum)            {{{2
" @pre lnum > 0
" @pre len(b:fold_data.levels) == line('$')+1
function! s:DecrFoldLevel(lnum, nb) abort
  let b:fold_data.levels[a:lnum] =  max([b:fold_data.levels[a:lnum-1]- a:nb, 0])
  if s:verbose
    silent exe 'sign place '.a:lnum.' line='.a:lnum.' name=Fold'.(b:fold_data.levels[a:lnum]+1).'lt buffer='.bufnr('%')
  endif
  return '<'.(b:fold_data.levels[a:lnum]+1)
endfunction

" Function: s:KeepFoldLevel(lnum)            {{{2
" @pre lnum > 0
" @pre len(b:fold_data.levels) == line('$')+1
function! s:KeepFoldLevel(lnum) abort
  let b:fold_data.levels[a:lnum] = b:fold_data.levels[a:lnum-1]
  if s:verbose
    silent exe 'sign place '.a:lnum.' line='.a:lnum.' name=Fold'.b:fold_data.levels[a:lnum].' buffer='.bufnr('%')
  endif
  return b:fold_data.levels[a:lnum]
endfunction


" Function: s:IsLineTooLong(text)            {{{2
function! s:IsLineTooLong(text) abort
  return lh#encoding#strlen(a:text) > s:opt_max_foldline_length()
endfunction

" Function: s:TrimLongLine(line, max_length) {{{2
" @pre lh#encoding#strlen(a:line) > max_length -- unchecked
" TODO: implement a better heuristics that could recognize:
" -[X] initialization lists
" -[X] function declarations
" -[ ] function calls
let s:k_annotations = {
      \ 'const'    : ' const',
      \ 'volatile' : ' volatile',
      \ 'overriden': ' override',
      \ 'final'    : ' final'
      \ }
let s:k_proto_pattern = '(.*)\(\s*\(\<noexcept\>\|\<volatile\>\|\<const\>\|\<final\>\|\<override\>\|=\s*0\)\)*'
let s:k_has_lhcpp = !empty(globpath(&rtp, 'autoload/lh/cpp/AnalysisLib_Function.vim'))
function! s:TrimLongLine(line, max_length) abort
  call s:Verbose('TrimLongLine(%1, %2)', a:line, a:max_length)
  let line = a:line
  " 1- detect initialization-list (top priority)
  let p = match(line, ')\s*:[^:]')
  if p > 0
    let line = line[:p]
    let len = lh#encoding#strlen(line)
    call s:Verbose('Initialisation list found; p=%1, strlen(:p)=%2', p, len)
    if len > a:max_length - 7
      let line = s:TrimLongLine(line, a:max_length-7)
    endif
    let line .= ' : ....'
    return line
  endif

  " 2- detect functions signatures (and calls...)
  " -- if and only if lh-cpp is detected
  if s:k_has_lhcpp && line =~ s:k_proto_pattern
    call s:Verbose('Function found')
    let indent = matchstr(line, '^\s*')
    let proto = lh#cpp#AnalysisLib_Function#AnalysePrototype(a:line)
    let elements = []
    if !empty(get(proto, 'return', ''))
      let elements += [proto.return]
    endif
    let elements += [join(proto.name, '::')]
    let line = indent . join(elements, ' ')
    let line .= '(' . join(map(proto.parameters, 'v:val.type'), ', ') . ')'
    let annotations = ['const', 'volatile', 'overriden', 'final']
    call map(annotations, 'get(s:k_annotations, get(proto, v:val, 0) ? v:val : "", "")')
    let line = join([line]+annotations, '')
    let len = lh#encoding#strlen(line)
    if len > a:max_length
      let p = stridx(line, ')')
      let line = s:TrimLongLine(line[:p-1], a:max_length-(len-p)) . line[p:]
    endif
    return line
  endif

  " n- Default case: trim!
  call s:Verbose('Default case')
  let line = substitute(line, '\v^(.){'.(a:max_length-4).'}\zs.*', '....', '')
  return line
endfunction

" Function: s:getline(first [, last]) abort  {{{2
" This function caches calls to s:CleanLine() as long as the file hasn't been
" modified.
" TODO: support multiline comments
if exists('*undotree')
  function! s:getline(...) abort
    let ut = undotree()
    let time = get(ut.entries, -1, {'time': localtime()}).time
    if b:fold_data.last_updated < time
      "" s:CleanLine() doesn't handle multi line comments well
      " let b:fold_data.lines = [''] + getline(1, '$')
      " " TODO: -> s:getSNR
      " call map(b:fold_data.lines, 's:CleanLine(v:val)')
      "" getline_not_matching is too slow...
      " let b:fold_data.lines = [''] + map(range(1, line('$')), 's:g_syn_filter_comments.getline_not_matching(v:val)')
      let b:fold_data.lines = [''] + getline(1, '$')
      let ctx = {'is_in_a_continuing_comment': 0}
      " TODO: -> s:getSNR
      call map(b:fold_data.lines, 's:CleanLineCtx(v:val, ctx)')
      let b:fold_data.last_updated = time
    endif
    return a:0 == 1
          \ ? b:fold_data.lines[(a:1)]
          \ : b:fold_data.lines[(a:1) : (a:2)]
  endfunction
else
  function! s:getline(...) abort
    let res = call('getline', a:000)
    if a:0 == 1
      return s:CleanLine(res)
    else
      call map(res, 's:CleanLine(v:val)')
      return res
    endif
  endfunction
endif

"------------------------------------------------------------------------
" }}}1
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
