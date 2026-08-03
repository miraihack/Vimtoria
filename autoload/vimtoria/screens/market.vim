scriptencoding utf-8
" screens/market.vim - 市場画面(自国市場の価格・需給の台帳)

function! vimtoria#screens#market#render(st) abort
  let l:eco = vimtoria#data#economy()
  let l:map = vimtoria#data#map()
  let l:market = a:st.world.markets[a:st.country]
  let l:stats = a:st.world.stats[a:st.country]
  let l:country = l:map.countries[a:st.country]

  let l:lines = []
  call add(l:lines, printf(vimtoria#i18n#t('mk_title'),
        \ vimtoria#i18n#name(l:country)))
  call add(l:lines, '')
  let l:unemp_pct = l:stats.workforce > 0.0
        \ ? 100.0 * l:stats.unemployed / l:stats.workforce : 0.0
  call add(l:lines, printf(vimtoria#i18n#t('mk_stats'),
        \ vimtoria#ui#fmt_num(float2nr(l:stats.gdp)),
        \ vimtoria#ui#fmt_num(float2nr(l:stats.income)),
        \ l:unemp_pct, l:stats.sol))
  call add(l:lines, '')
  call add(l:lines, '  '
        \ . vimtoria#ui#pad(vimtoria#i18n#t('mk_col_goods'), 10)
        \ . printf(vimtoria#i18n#t('mk_cols'),
        \          vimtoria#i18n#t('mk_col_price'),
        \          vimtoria#i18n#t('mk_col_base'),
        \          vimtoria#i18n#t('mk_col_world'),
        \          vimtoria#i18n#t('mk_col_buy'),
        \          vimtoria#i18n#t('mk_col_sell'),
        \          vimtoria#i18n#t('mk_col_bal')))
  call add(l:lines, '  ' . repeat('─', 78))
  let l:flows = get(a:st.world.trade_flows, a:st.country, {})
  for l:gid in l:eco.goods_order
    let l:m = l:market[l:gid]
    let l:g = l:eco.goods[l:gid]
    if l:m.buy > l:m.sell * 1.05
      let l:mark = vimtoria#i18n#t('mk_short')
    elseif l:m.sell > l:m.buy * 1.05
      let l:mark = vimtoria#i18n#t('mk_over')
    else
      let l:mark = vimtoria#i18n#t('mk_even')
    endif
    let l:flow = get(l:flows, l:gid, 0.0)
    if l:flow > 0.05
      let l:trade = printf(vimtoria#i18n#t('mk_exp'), l:flow)
    elseif l:flow < -0.05
      let l:trade = printf(vimtoria#i18n#t('mk_imp'), -l:flow)
    else
      let l:trade = ''
    endif
    call add(l:lines, '  ' . vimtoria#ui#pad(vimtoria#i18n#name(l:g), 10)
          \ . printf('%8.1f£ %8.1f£ %8.1f£ %9.0f %9.0f  %s %s',
          \          l:m.price, l:g.base,
          \          get(a:st.world.world_prices, l:gid, l:g.base),
          \          l:m.buy, l:m.sell,
          \          vimtoria#ui#pad(l:mark, 10), l:trade))
  endfor
  call add(l:lines, '')
  call add(l:lines, printf(vimtoria#i18n#t('mk_tariff'),
        \ vimtoria#ui#fmt_num(float2nr(l:stats.tariff))))
  call add(l:lines, vimtoria#i18n#t('mk_note'))
  return l:lines
endfunction
