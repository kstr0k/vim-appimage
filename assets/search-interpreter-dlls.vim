function! s:ProcessLdconfig(lines) abort
  let ms = matchstrlist(a:lines, '\s*\(\S*\).* => \(\S*\)', { 'submatches': v:true })
  return reduce(ms, { acc, v -> acc->extend({ v.submatches[0]: v.submatches[1] }) }, {})
endfunction

let s:libs = systemlist('PATH="$PATH":/sbin:/usr/sbin ldconfig -p')
let s:soname_to_path = s:ProcessLdconfig(s:libs)

function! s:ResolveInterp(dllopt, libpat = '')
  let dllval = eval('&' .. a:dllopt)
  if s:soname_to_path->has_key(dllval)
    return
  endif
  let dlls = filter(copy(s:soname_to_path), 'v:key =~# a:libpat')
  if len(dlls)
    call execute('set ' .. a:dllopt .. '=' .. reverse(sort(dlls->keys()))[0])
    return
  endif
endfunction

let s:interps = #{ pythonthree: '^libpython3\.\(\d\+\)\.so$' }
call map(s:interps->items(), { _, kv -> s:ResolveInterp(kv[0] .. 'dll', kv[1]) })


" vim: set et sw=2 :
