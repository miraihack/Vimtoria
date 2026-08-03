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
  call add(l:lines, printf(vimtoria#i18n#t('cs_title'),
        \ vimtoria#i18n#name(l:map.countries[a:st.country])))
  call add(l:lines, '')
  call add(l:lines, printf(vimtoria#i18n#t('cs_stats'),
        \ l:cap, l:unit, vimtoria#ui#fmt_num(float2nr(l:stats.spend))))
  let l:own = a:st.world.owner[a:st.selected] ==# a:st.country
  call add(l:lines, printf(vimtoria#i18n#t('cs_target'),
        \ vimtoria#i18n#name(l:target),
        \ l:own ? '' : vimtoria#i18n#t('cs_not_own')))
  if !empty(a:st.msg)
    call add(l:lines, '  » ' . a:st.msg)
  endif
  call add(l:lines, '')
  call add(l:lines, vimtoria#i18n#t('cs_menu'))
  let l:i = 0
  for l:bid in l:eco.buildings_order
    let l:bdef = l:eco.buildings[l:bid]
    let l:mark = l:i == a:st.menu_idx ? '>' : ' '
    let l:outs = []
    for [l:gid, l:q] in items(l:bdef.out)
      call add(l:outs, printf(vimtoria#i18n#t('cs_out'),
            \ vimtoria#i18n#name(l:eco.goods[l:gid]), l:q))
    endfor
    call add(l:lines, printf('  %s %s%3.0fpt ≈£%s  %s%s',
          \ l:mark, vimtoria#ui#pad(vimtoria#i18n#name(l:bdef), 20),
          \ l:eco.const.build_points,
          \ vimtoria#ui#fmt_num(float2nr(l:eco.const.build_points * l:unit)),
          \ vimtoria#i18n#t('cs_outputs'), join(l:outs, ' ')))
    let l:i += 1
  endfor
  call add(l:lines, '')
  call add(l:lines, printf(vimtoria#i18n#t('cs_queue'),
        \ len(l:queue), l:eco.const.build_queue_max))
  if empty(l:queue)
    call add(l:lines, vimtoria#i18n#t('cs_empty'))
  else
    let l:n = 1
    for l:item in l:queue
      let l:fill = float2nr(10.0 * l:item.done / l:item.total)
      call add(l:lines, printf('  %2d. %s %s %s %3.0f/%3.0fpt',
            \ l:n,
            \ vimtoria#ui#pad(vimtoria#i18n#name(l:map.states[l:item.sid]), 16),
            \ vimtoria#ui#pad(vimtoria#i18n#name(l:eco.buildings[l:item.bid]), 20),
            \ repeat('█', l:fill) . repeat('░', 10 - l:fill),
            \ l:item.done, l:item.total))
      let l:n += 1
    endfor
  endif
  return l:lines
endfunction
