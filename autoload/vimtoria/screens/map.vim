scriptencoding utf-8
" screens/map.vim - 世界地図画面

function! vimtoria#screens#map#render(st) abort
  let l:data = vimtoria#data#map()
  let l:sel = a:st.selected
  let l:lines = []
  for l:tmpl in l:data.template
    call add(l:lines, substitute(l:tmpl, '{\(\u\{3}\)}',
          \ '\=s:tag(submatch(1), l:sel)', 'g'))
  endfor
  call add(l:lines, '')
  let l:stt = l:data.states[l:sel]
  let l:country = l:data.countries[l:stt.country]
  let l:own = l:stt.country ==# a:st.country ? '(自国)' : ''
  call add(l:lines, printf('  選択: [%s] %s — %s%s / 人口 %d万人',
        \ l:sel, l:stt.name, l:country.name, l:own, l:stt.pop))
  let l:tags = []
  for [l:sid, l:s] in items(l:data.states)
    if l:s.country ==# l:stt.country
      call add(l:tags, l:sid)
    endif
  endfor
  call sort(l:tags)
  call add(l:lines, printf('  %s の州: %s', l:country.name, join(l:tags, ' ')))
  if !empty(a:st.msg)
    call add(l:lines, '  » ' . a:st.msg)
  endif
  " 最近の出来事(直近3件)
  if !empty(a:st.world.eventlog)
    call add(l:lines, '')
    call add(l:lines, '  ── 最近の出来事 ──')
    for l:e in a:st.world.eventlog[-3:]
      call add(l:lines, '  ' . l:e)
    endfor
  endif
  call add(l:lines, '')
  call add(l:lines, printf('  1836年の世界 — %dカ国 %d州',
        \ len(l:data.countries), len(l:data.states)))
  return l:lines
endfunction

function! s:tag(tag, selected) abort
  return a:tag ==# a:selected ? '[' . a:tag . ']' : ' ' . a:tag . ' '
endfunction
