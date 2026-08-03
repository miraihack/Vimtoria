scriptencoding utf-8
" screens/budget.vim - 予算画面(国庫・税率・先週の収支)

function! vimtoria#screens#budget#render(st) abort
  let l:eco = vimtoria#data#economy()
  let l:map = vimtoria#data#map()
  let l:stats = a:st.world.stats[a:st.country]
  let l:rate = a:st.world.tax_rates[a:st.country]
  let l:net = l:stats.tax - l:stats.upkeep - l:stats.spend

  let l:lines = []
  call add(l:lines, printf('  ━━ 予算: %s ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
        \ l:map.countries[a:st.country].name))
  call add(l:lines, '')
  call add(l:lines, printf('  国庫: £%s', vimtoria#ui#fmt_num(a:st.treasury)))
  call add(l:lines, printf('  所得税率: %.1f%%  (+/- で %.1f%% ずつ変更、%.0f%%〜%.0f%%)',
        \ l:rate * 100.0, l:eco.const.tax_step * 100.0,
        \ l:eco.const.tax_min * 100.0, l:eco.const.tax_max * 100.0))
  call add(l:lines, '')
  call add(l:lines, '  ── 先週の収支 ──')
  call add(l:lines, printf('    税収          +£%s',
        \ vimtoria#ui#fmt_num(float2nr(l:stats.tax))))
  call add(l:lines, printf('    政府維持費    -£%s',
        \ vimtoria#ui#fmt_num(float2nr(l:stats.upkeep))))
  call add(l:lines, printf('    建設支出      -£%s',
        \ vimtoria#ui#fmt_num(float2nr(l:stats.spend))))
  call add(l:lines, '    ' . repeat('─', 24))
  call add(l:lines, printf('    収支          %s£%s',
        \ l:net >= 0.0 ? '+' : '-',
        \ vimtoria#ui#fmt_num(float2nr(abs(l:net)))))
  call add(l:lines, '')
  call add(l:lines, printf('  参考: 週間所得 £%s ┃ 生活水準 %.2f(増税すると低下)',
        \ vimtoria#ui#fmt_num(float2nr(l:stats.income)), l:stats.sol))
  call add(l:lines, '')
  call add(l:lines, '  ※国庫が尽きると建設が停止する。国債は M3 で実装予定。')
  return l:lines
endfunction
