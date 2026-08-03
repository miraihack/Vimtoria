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
  call add(l:lines, printf(vimtoria#i18n#t('pp_title'),
        \ vimtoria#i18n#name(l:map.countries[a:st.country])))
  call add(l:lines, '')
  call add(l:lines, printf(vimtoria#i18n#t('pp_stats'),
        \ l:stats.workforce, l:stats.workforce - l:stats.unemployed,
        \ l:stats.unemployed, l:stats.sol))
  call add(l:lines, '')
  call add(l:lines, vimtoria#i18n#t('pp_byprof'))
  for l:prof in ['farmers', 'laborers', 'machinists', 'shopkeepers',
        \ 'capitalists', 'aristocrats']
    call add(l:lines, printf(vimtoria#i18n#t('pp_prof_row'),
          \ vimtoria#ui#pad(vimtoria#i18n#name(l:eco.professions[l:prof]), 12),
          \ l:by_prof[l:prof]))
  endfor
  call add(l:lines, '')
  call add(l:lines, vimtoria#i18n#t('pp_bystate'))
  call add(l:lines, '    '
        \ . vimtoria#ui#pad(vimtoria#i18n#t('pp_col_state'), 16)
        \ . printf(vimtoria#i18n#t('pp_cols'),
        \          vimtoria#i18n#t('pp_col_wf'),
        \          vimtoria#i18n#t('pp_col_emp'),
        \          vimtoria#i18n#t('pp_col_sub')))
  for l:sid in a:st.world.country_states[a:st.country]
    let l:info = vimtoria#econ#state_info(a:st, l:sid)
    call add(l:lines, printf(vimtoria#i18n#t('pp_row'),
          \ vimtoria#ui#pad(vimtoria#i18n#name(l:map.states[l:sid]), 16),
          \ l:info.workforce, l:info.employed, l:info.unemployed))
  endfor
  return l:lines
endfunction
