scriptencoding utf-8
" screens/pops.vim - Pop 画面(職業別雇用と州別の労働力・移動の様子)

function! vimtoria#screens#pops#render(st) abort
  let l:eco = vimtoria#data#economy()
  let l:map = vimtoria#data#map()
  let l:stats = a:st.world.stats[a:st.country]

  " 職業別雇用を集計
  let l:by_prof = {}
  for l:prof in keys(l:eco.professions)
    let l:by_prof[l:prof] = 0.0
  endfor
  for l:sid in a:st.world.country_states[a:st.country]
    for [l:bid, l:b] in items(a:st.world.buildings[l:sid])
      for [l:prof, l:n] in items(l:eco.buildings[l:bid].jobs)
        let l:by_prof[l:prof] += l:n * l:b.levels * l:b.f
      endfor
    endfor
  endfor

  let l:lines = []
  call add(l:lines, printf('  ━━ Pop: %s ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
        \ l:map.countries[a:st.country].name))
  call add(l:lines, '')
  call add(l:lines, printf('  労働力 %.0f千人 ┃ 雇用 %.0f千人 ┃ 自給農 %.0f千人 ┃ 生活水準 %.2f',
        \ l:stats.workforce, l:stats.workforce - l:stats.unemployed,
        \ l:stats.unemployed, l:stats.sol))
  call add(l:lines, '')
  call add(l:lines, '  ── 職業別雇用 ──')
  for l:prof in ['farmers', 'laborers', 'machinists', 'shopkeepers',
        \ 'capitalists', 'aristocrats']
    call add(l:lines, printf('    %s %8.0f千人',
          \ vimtoria#ui#pad(l:eco.professions[l:prof].name, 8),
          \ l:by_prof[l:prof]))
  endfor
  call add(l:lines, '')
  call add(l:lines, '  ── 州別(失業者は毎週、求人のある州へ少しずつ移動する) ──')
  call add(l:lines, '    ' . vimtoria#ui#pad('州', 12)
        \ . printf('%10s %10s %10s', '労働力', '雇用', '自給農'))
  for l:sid in a:st.world.country_states[a:st.country]
    let l:info = vimtoria#econ#state_info(a:st, l:sid)
    call add(l:lines, printf('    %s%9.0f千 %9.0f千 %9.0f千',
          \ vimtoria#ui#pad(l:map.states[l:sid].name, 12),
          \ l:info.workforce, l:info.employed, l:info.unemployed))
  endfor
  return l:lines
endfunction
