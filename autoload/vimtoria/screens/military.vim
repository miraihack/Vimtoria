scriptencoding utf-8
" screens/military.vim - 軍事画面(連隊・維持費・戦争・戦力比較)

function! vimtoria#screens#military#render(st) abort
  let l:eco = vimtoria#data#economy()
  let l:map = vimtoria#data#map()
  let l:world = a:st.world
  let l:mil = l:world.military[a:st.country]

  let l:lines = []
  call add(l:lines, printf(vimtoria#i18n#t('ml_title'),
        \ vimtoria#i18n#name(l:map.countries[a:st.country])))
  call add(l:lines, '')
  let l:goods = []
  for [l:gid, l:q] in items(l:eco.mil_goods)
    call add(l:goods, printf('%s %.0f',
          \ vimtoria#i18n#name(l:eco.goods[l:gid]), l:q * l:mil.regiments))
  endfor
  call add(l:lines, printf(vimtoria#i18n#t('ml_stats'),
        \ l:mil.regiments, vimtoria#war#cap(l:world, a:st.country),
        \ vimtoria#war#strength(l:world, a:st.country)))
  call add(l:lines, printf(vimtoria#i18n#t('ml_navy'),
        \ l:mil.ships, vimtoria#war#navy_cap(l:world, a:st.country),
        \ vimtoria#war#navy_strength(l:world, a:st.country)))
  call add(l:lines, printf(vimtoria#i18n#t('ml_upkeep'),
        \ vimtoria#ui#fmt_num(float2nr(
        \   l:mil.regiments * l:eco.const.mil_upkeep_money
        \   + l:mil.ships * l:eco.const.navy_upkeep_money)),
        \ join(l:goods, ' ')))
  call add(l:lines, printf(vimtoria#i18n#t('ml_recruit'),
        \ l:eco.const.mil_recruit_batch,
        \ vimtoria#ui#fmt_num(float2nr(l:eco.const.mil_recruit_batch
        \                              * l:eco.const.mil_recruit_cost)),
        \ l:eco.const.mil_recruit_batch))
  call add(l:lines, printf(vimtoria#i18n#t('ml_navy_recruit'),
        \ l:eco.const.navy_recruit_batch,
        \ vimtoria#ui#fmt_num(float2nr(l:eco.const.navy_recruit_batch
        \                              * l:eco.const.navy_recruit_cost))))
  call add(l:lines, vimtoria#i18n#t('ml_navy_note'))
  if !empty(a:st.msg)
    call add(l:lines, '  » ' . a:st.msg)
  endif
  call add(l:lines, '')
  call add(l:lines, vimtoria#i18n#t('ml_wars'))
  let l:any = 0
  for l:w in l:world.wars
    if l:w.attacker ==# a:st.country || l:w.defender ==# a:st.country
          \ || index(l:w.allies_d, a:st.country) >= 0
      let l:side = vimtoria#i18n#t(l:w.attacker ==# a:st.country
            \ ? 'ml_att' : 'ml_def')
      call add(l:lines, printf(vimtoria#i18n#t('ml_war_row'),
            \ vimtoria#i18n#name(l:map.countries[l:w.attacker ==# a:st.country
            \                    ? l:w.defender : l:w.attacker]),
            \ l:side, l:w.score, vimtoria#i18n#name(l:map.states[l:w.goal])))
      let l:any = 1
    endif
  endfor
  if !l:any
    call add(l:lines, vimtoria#i18n#t('ml_none'))
  endif
  call add(l:lines, '')
  call add(l:lines, vimtoria#i18n#t('ml_top'))
  let l:rows = []
  for l:cid in keys(l:map.countries)
    if !empty(l:world.country_states[l:cid])
      call add(l:rows, [l:cid, vimtoria#war#strength(l:world, l:cid)])
    endif
  endfor
  call sort(l:rows, {a, b -> a[1] < b[1] ? 1 : a[1] > b[1] ? -1 : 0})
  let l:rank = 1
  for l:row in l:rows[:9]
    call add(l:lines, printf('  %2d. %s %8.0f%s',
          \ l:rank,
          \ vimtoria#ui#pad(vimtoria#i18n#name(l:map.countries[l:row[0]]), 28),
          \ l:row[1],
          \ l:row[0] ==# a:st.country ? vimtoria#i18n#t('ml_me') : ''))
    let l:rank += 1
  endfor
  return l:lines
endfunction
