scriptencoding utf-8
" screens/military.vim - 軍事画面(連隊・維持費・戦争・戦力比較)

function! vimtoria#screens#military#render(st) abort
  let l:eco = vimtoria#data#economy()
  let l:map = vimtoria#data#map()
  let l:world = a:st.world
  let l:mil = l:world.military[a:st.country]

  let l:lines = []
  call add(l:lines, printf('  ━━ 軍事: %s ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
        \ l:map.countries[a:st.country].name))
  call add(l:lines, '')
  let l:goods = []
  for [l:gid, l:q] in items(l:eco.mil_goods)
    call add(l:goods, printf('%s %.0f', l:eco.goods[l:gid].name,
          \ l:q * l:mil.regiments))
  endfor
  call add(l:lines, printf('  連隊 %.0f / 上限 %.0f ┃ 総戦力 %.0f(技術ボーナス込み)',
        \ l:mil.regiments, vimtoria#war#cap(l:world, a:st.country),
        \ vimtoria#war#strength(l:world, a:st.country)))
  call add(l:lines, printf('  週間維持費 £%s + 物資: %s',
        \ vimtoria#ui#fmt_num(float2nr(l:mil.regiments * l:eco.const.mil_upkeep_money)),
        \ join(l:goods, ' ')))
  call add(l:lines, printf('  徴募: %.0f個連隊あたり £%s と労働力 %.0f千人(最大州から)',
        \ l:eco.const.mil_recruit_batch,
        \ vimtoria#ui#fmt_num(float2nr(l:eco.const.mil_recruit_batch
        \                              * l:eco.const.mil_recruit_cost)),
        \ l:eco.const.mil_recruit_batch))
  if !empty(a:st.msg)
    call add(l:lines, '  » ' . a:st.msg)
  endif
  call add(l:lines, '')
  call add(l:lines, '  ── 交戦中の戦争 ──')
  let l:any = 0
  for l:w in l:world.wars
    if l:w.attacker ==# a:st.country || l:w.defender ==# a:st.country
          \ || index(l:w.allies_d, a:st.country) >= 0
      let l:side = l:w.attacker ==# a:st.country ? '攻撃側' : '防御側'
      call add(l:lines, printf('  vs %s(%s)┃ 戦況 %+.0f ┃ 目標: %s',
            \ l:map.countries[l:w.attacker ==# a:st.country
            \                 ? l:w.defender : l:w.attacker].name,
            \ l:side, l:w.score, l:map.states[l:w.goal].name))
      let l:any = 1
    endif
  endfor
  if !l:any
    call add(l:lines, '  (なし — 宣戦は外交画面 gd から)')
  endif
  call add(l:lines, '')
  call add(l:lines, '  ── 陸軍力トップ10 ──')
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
          \ l:rank, vimtoria#ui#pad(l:map.countries[l:row[0]].name, 24),
          \ l:row[1], l:row[0] ==# a:st.country ? ' ←自国' : ''))
    let l:rank += 1
  endfor
  return l:lines
endfunction
