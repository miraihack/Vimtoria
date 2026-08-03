scriptencoding utf-8
" screens/market.vim - 市場画面(自国市場の価格・需給の台帳)

function! vimtoria#screens#market#render(st) abort
  let l:eco = vimtoria#data#economy()
  let l:map = vimtoria#data#map()
  let l:market = a:st.world.markets[a:st.country]
  let l:stats = a:st.world.stats[a:st.country]
  let l:country = l:map.countries[a:st.country]

  let l:lines = []
  call add(l:lines, printf('  ━━ 市場: %s ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', l:country.name))
  call add(l:lines, '')
  let l:unemp_pct = l:stats.workforce > 0.0
        \ ? 100.0 * l:stats.unemployed / l:stats.workforce : 0.0
  call add(l:lines, printf('  週間GDP £%s ┃ 週間所得 £%s ┃ 失業率(自給農含む) %.1f%% ┃ 生活水準 %.2f',
        \ vimtoria#ui#fmt_num(float2nr(l:stats.gdp)),
        \ vimtoria#ui#fmt_num(float2nr(l:stats.income)),
        \ l:unemp_pct, l:stats.sol))
  call add(l:lines, '')
  call add(l:lines, '  ' . vimtoria#ui#pad('財', 10)
        \ . printf('%9s %9s %10s %10s  %s', '価格', '基準', '買い注文', '売り注文', '需給'))
  call add(l:lines, '  ' . repeat('─', 60))
  for l:gid in l:eco.goods_order
    let l:m = l:market[l:gid]
    let l:g = l:eco.goods[l:gid]
    if l:m.buy > l:m.sell * 1.05
      let l:mark = '▲不足'
    elseif l:m.sell > l:m.buy * 1.05
      let l:mark = '▼過剰'
    else
      let l:mark = '─均衡'
    endif
    call add(l:lines, '  ' . vimtoria#ui#pad(l:g.name, 10)
          \ . printf('%8.1f£ %8.1f£ %10.0f %10.0f  %s',
          \          l:m.price, l:g.base, l:m.buy, l:m.sell, l:mark))
  endfor
  call add(l:lines, '')
  call add(l:lines, '  ※価格は需給で毎週変動(基準価格の ±75% でクランプ)。建設(gc)は M2 で実装。')
  return l:lines
endfunction
