function! IndentLevel(lnum)
  return indent(a:lnum) / &shiftwidth
endfunction

function! NextNonBlankLine(lnum)
  let numlines = line('$')
  let current = a:lnum + 1

  while current <= numlines
    if getline(current) =~? '\v\S'
      return current
    endif
    let current += 1
  endwhile

  return -2
endfunction

function! FoamFolds()
  if getline(v:lnum) =~? '\v^\s*$'
    return '='
  endif

  let this_indent = IndentLevel(v:lnum)
  let next_nonblank = NextNonBlankLine(v:lnum)
  let next_indent = IndentLevel(next_nonblank)

  if this_indent >= 3 || next_indent >= 4
    return 3
  elseif getline(v:lnum) =~? '\v\s*(}|])'
    return this_indent + 1    " Include closing }s with their parents
  elseif next_indent == this_indent
    return this_indent
  elseif next_indent < this_indent
    return this_indent
  elseif next_indent > this_indent
    return '>' . next_indent
  endif
endfunction

function! FoamReadName(lnum)
  return substitute(getline(a:lnum), '\v\s*name:\s*([' . "'" . '"])(.*)\1.*', '\2', '')
endfunction

function! FoamFindName(start, end)
  let current = a:start + 1
  while current <= a:end
    if getline(current) =~? '\v\s*name:'
      return FoamReadName(current)
    endif

    let current += 1
  endwhile

  return "NAME NOT FOUND"
endfunction

function! FoamIndents(indents)
  let i = a:indents * &shiftwidth
  let s = ''
  while i > 0
    let s = s . ' '
    let i -= 1
  endwhile
  return s
endfunction

function! FoamFoldTextInner(start, end)
  " There are several types of fold starters in FOAM:
  " * MODEL, CLASS and INTERFACE lines (fetch the name:)
  " * properties:, models: etc.
  " * methodName: function() {... lines
  " * { lines that begin a new block
  let thisline = getline(a:start)
  if thisline =~? '\v^\s*MODEL'
    return 'MODEL: ' . FoamFindName(a:start, a:end)
  elseif thisline =~? '\v^\s*CLASS'
    return 'CLASS: ' . FoamFindName(a:start, a:end)
  elseif thisline =~? '\v^\s*INTERFACE'
    return 'INTERFACE: ' . FoamFindName(a:start, a:end)
  elseif thisline =~? '\v:\s*function'
    " Grab either the function foobar() name or the foobar: function() name
    if thisline =~? '\vfunction\s+\S+\s*\('
      return FoamIndents(2) . substitute(thisline, '\v\s*function\s+(\S+)\s*\(.*', '\1', '')
    else
      return FoamIndents(2) . substitute(thisline, '\v\s*(\S+)\s*:.*', '\1', '')
    endif
  elseif thisline =~? '\v\s*function\s+\S+\s*\('
    return FoamIndents(2) . substitute(thisline, '\v\s*function\s+(\S+)\s*\(', '\1', '')
  elseif thisline =~? '\v\s*\S+\s*:'
    return FoamIndents(1) . substitute(thisline, '\v\s*(\S+)\s*:.*', '\1', '')
  elseif thisline =~? '\v\s*(\}\s*,\s*){,1}\{'
    return FoamIndents(2) . FoamFindName(a:start, a:end)
  endif

  return "UNKNOWN STRUCTURE"
endfunction

function! FoamFoldText()
  return FoamFoldTextInner(v:foldstart, v:foldend) . ' (' . (v:foldend - v:foldstart + 1) . ' lines)'
endfunction

setlocal foldnestmax=3
setlocal foldmethod=expr
setlocal foldexpr=FoamFolds()
setlocal foldtext=FoamFoldText()

