scriptencoding utf-8
" screens/budget.vim - 予算画面(国庫・税率・先週の収支)

function! vimtoria#screens#budget#render(st) abort
  let l:eco = vimtoria#data#economy()
  let l:map = vimtoria#data#map()
  let l:stats = a:st.world.stats[a:st.country]
  let l:rate = a:st.world.tax_rates[a:st.country]
  let l:net = l:stats.tax - l:stats.upkeep - l:stats.interest - l:stats.spend

  let l:mods = a:st.world.mods[a:st.country]

  let l:lines = []
  call add(l:lines, printf('  ━━ 予算: %s ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
        \ l:map.countries[a:st.country].name))
  call add(l:lines, '')
  if a:st.treasury >= 0
    call add(l:lines, printf('  国庫: £%s', vimtoria#ui#fmt_num(a:st.treasury)))
  else
    call add(l:lines, printf('  国庫: -£%s(債務)',
          \ vimtoria#ui#fmt_num(-a:st.treasury)))
  endif
  call add(l:lines, printf('  信用限度: £%s(週間所得の%.0f%%)┃ 年利 %.0f%%',
        \ vimtoria#ui#fmt_num(float2nr(l:stats.credit)),
        \ l:eco.const.credit_mult * 100.0, l:mods.interest * 100.0))
  call add(l:lines, printf('  所得税率: %.1f%%  (+/- で %.1f%% ずつ変更、%.0f%%〜%.0f%%)',
        \ l:rate * 100.0, l:eco.const.tax_step * 100.0,
        \ l:eco.const.tax_min * 100.0, l:eco.const.tax_max * 100.0))
  call add(l:lines, '')
  call add(l:lines, '  ── 先週の収支 ──')
  call add(l:lines, printf('    税収          +£%s',
        \ vimtoria#ui#fmt_num(float2nr(l:stats.tax))))
  call add(l:lines, printf('    政府維持費    -£%s',
        \ vimtoria#ui#fmt_num(float2nr(l:stats.upkeep))))
  call add(l:lines, printf('    利払い        -£%s',
        \ vimtoria#ui#fmt_num(float2nr(l:stats.interest))))
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
  call add(l:lines, '  ※建設は信用限度まで借金しながら進む。中央銀行の研究で年利が下がる。')
  return l:lines
endfunction
