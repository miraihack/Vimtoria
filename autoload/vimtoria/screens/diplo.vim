scriptencoding utf-8
" screens/diplo.vim - 外交画面(各国との関係・同盟・戦争)

function! vimtoria#screens#diplo#render(st) abort
  let l:map = vimtoria#data#map()
  let l:world = a:st.world

  let l:lines = []
  call add(l:lines, printf(vimtoria#i18n#t('dp_title'),
        \ vimtoria#i18n#name(l:map.countries[a:st.country])))
  call add(l:lines, '')
  call add(l:lines, vimtoria#i18n#t('dp_hint'))
  if !empty(a:st.msg)
    call add(l:lines, '  » ' . a:st.msg)
  endif
  call add(l:lines, '')
  call add(l:lines, '    '
        \ . vimtoria#ui#pad(vimtoria#i18n#t('dp_col_country'), 28)
        \ . printf(vimtoria#i18n#t('dp_cols'),
        \          vimtoria#i18n#t('dp_col_rel'),
        \          vimtoria#i18n#t('dp_col_status'),
        \          vimtoria#i18n#t('dp_col_power')))
  call add(l:lines, '  ' . repeat('─', 60))
  let l:i = 0
  for l:cid in vimtoria#core#diplo_targets(a:st)
    let l:rel = vimtoria#diplo#relation(l:world, a:st.country, l:cid)
    if empty(l:world.country_states[l:cid])
      let l:status = vimtoria#i18n#t('dp_gone')
    elseif !empty(vimtoria#diplo#war_between(l:world, a:st.country, l:cid))
      let l:status = vimtoria#i18n#t('dp_atwar')
    elseif vimtoria#diplo#allied(l:world, a:st.country, l:cid)
      let l:status = vimtoria#i18n#t('dp_ally')
    else
      let l:status = '─'
    endif
    call add(l:lines, printf('  %s %s%+6.0f  %-8s %8.0f',
          \ l:i == a:st.menu_idx ? '>' : ' ',
          \ vimtoria#ui#pad(vimtoria#i18n#name(l:map.countries[l:cid]), 28),
          \ l:rel, vimtoria#ui#pad(l:status, 8),
          \ vimtoria#war#strength(l:world, l:cid)))
    let l:i += 1
  endfor
  call add(l:lines, '')
  call add(l:lines, vimtoria#i18n#t('dp_wars'))
  if empty(l:world.wars)
    call add(l:lines, vimtoria#i18n#t('dp_none'))
  else
    for l:w in l:world.wars
      let l:names = vimtoria#i18n#name(l:map.countries[l:w.attacker]) . ' → '
            \ . vimtoria#i18n#name(l:map.countries[l:w.defender])
      if !empty(l:w.allies_d)
        let l:allies = []
        for l:ally in l:w.allies_d
          call add(l:allies, vimtoria#i18n#name(l:map.countries[l:ally]))
        endfor
        let l:names .= '(+' . join(l:allies, vimtoria#i18n#t('list_sep')) . ')'
      endif
      call add(l:lines, printf(vimtoria#i18n#t('dp_war_row'),
            \ l:names, l:w.score, vimtoria#i18n#name(l:map.states[l:w.goal])))
    endfor
  endif
  return l:lines
endfunction
