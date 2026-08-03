scriptencoding utf-8
" screens/select.vim - ゲーム開始時の国選択画面

function! vimtoria#screens#select#render(st) abort
  let l:map = vimtoria#data#map()
  let l:pol = vimtoria#data#politics()
  let l:world = a:st.world

  let l:lines = []
  call add(l:lines, '  ━━ プレイする国を選択 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
  call add(l:lines, '')
  call add(l:lines, '  j/k で選び、Enter で 1836年1月1日 からプレイ開始。')
  call add(l:lines, '')
  call add(l:lines, '    ' . vimtoria#ui#pad('国', 26)
        \ . printf('%4s %10s %8s %6s  %s', '州', '人口(万)', '労働力', '陸軍', '経済体制'))
  call add(l:lines, '  ' . repeat('─', 76))
  let l:i = 0
  for l:cid in l:map.country_order
    let l:pop = 0
    for l:sid in l:world.country_states[l:cid]
      let l:pop += l:map.states[l:sid].pop
    endfor
    let l:workforce = 0.0
    for l:sid in l:world.country_states[l:cid]
      let l:workforce += l:world.workforce[l:sid]
    endfor
    let l:econ_law = l:world.politics[l:cid].laws['econ_policy']
    call add(l:lines, printf('  %s %s%4d %10s %7.0f千 %6.0f  %s',
          \ l:i == a:st.menu_idx ? '>' : ' ',
          \ vimtoria#ui#pad(l:map.countries[l:cid].name, 26),
          \ len(l:world.country_states[l:cid]),
          \ vimtoria#ui#fmt_num(l:pop), l:workforce,
          \ l:world.military[l:cid].regiments,
          \ l:pol.laws[l:econ_law].name))
    let l:i += 1
  endfor
  call add(l:lines, '')
  call add(l:lines, '  大国は経済も軍も強いが研究は頭打ちしやすい。小国は身軽だが油断すると併合される。')
  return l:lines
endfunction
