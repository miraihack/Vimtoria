scriptencoding utf-8
" screens/construction.vim - 建設画面(建物メニュー+建設キュー)

function! vimtoria#screens#construction#render(st) abort
  let l:eco = vimtoria#data#economy()
  let l:map = vimtoria#data#map()
  let l:market = a:st.world.markets[a:st.country]
  let l:stats = a:st.world.stats[a:st.country]
  let l:queue = a:st.world.queues[a:st.country]
  let l:target = l:map.states[a:st.selected]
  let l:cap = vimtoria#build#capacity(a:st.world, a:st.country)
  let l:unit = vimtoria#build#point_cost(l:market)

  let l:lines = []
  call add(l:lines, printf('  ━━ 建設: %s ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
        \ l:map.countries[a:st.country].name))
  call add(l:lines, '')
  call add(l:lines, printf('  建設力 %.1fpt/週 ┃ 資材費 £%.0f/pt ┃ 先週の建設支出 £%s',
        \ l:cap, l:unit, vimtoria#ui#fmt_num(float2nr(l:stats.spend))))
  let l:own = l:target.country ==# a:st.country
  call add(l:lines, printf('  建設先: [%s] %s%s', a:st.selected, l:target.name,
        \ l:own ? '' : ' ※自国領ではありません(マップで自国州を選択してから gc)'))
  if !empty(a:st.msg)
    call add(l:lines, '  » ' . a:st.msg)
  endif
  call add(l:lines, '')
  call add(l:lines, '  ── 建物メニュー ──')
  let l:i = 0
  for l:bid in l:eco.buildings_order
    let l:bdef = l:eco.buildings[l:bid]
    let l:mark = l:i == a:st.menu_idx ? '>' : ' '
    let l:outs = []
    for [l:gid, l:q] in items(l:bdef.out)
      call add(l:outs, printf('%s %.0f/週', l:eco.goods[l:gid].name, l:q))
    endfor
    call add(l:lines, printf('  %s %s%3.0fpt ≈£%s  産出: %s',
          \ l:mark, vimtoria#ui#pad(l:bdef.name, 12),
          \ l:eco.const.build_points,
          \ vimtoria#ui#fmt_num(float2nr(l:eco.const.build_points * l:unit)),
          \ join(l:outs, ' ')))
    let l:i += 1
  endfor
  call add(l:lines, '')
  call add(l:lines, printf('  ── 建設キュー (%d/%d) ──',
        \ len(l:queue), l:eco.const.build_queue_max))
  if empty(l:queue)
    call add(l:lines, '  (空 — Enter で追加)')
  else
    let l:n = 1
    for l:item in l:queue
      let l:fill = float2nr(10.0 * l:item.done / l:item.total)
      call add(l:lines, printf('  %2d. %s %s %s %3.0f/%3.0fpt',
            \ l:n,
            \ vimtoria#ui#pad(l:map.states[l:item.sid].name, 10),
            \ vimtoria#ui#pad(l:eco.buildings[l:item.bid].name, 12),
            \ repeat('█', l:fill) . repeat('░', 10 - l:fill),
            \ l:item.done, l:item.total))
      let l:n += 1
    endfor
  endif
  return l:lines
endfunction
