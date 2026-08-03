scriptencoding utf-8
" screens/budget.vim - 予算画面(国庫・税率・先週の収支)

function! vimtoria#screens#budget#render(st) abort
  let l:eco = vimtoria#data#economy()
  let l:map = vimtoria#data#map()
  let l:stats = a:st.world.stats[a:st.country]
  let l:rate = a:st.world.tax_rates[a:st.country]
  let l:net = l:stats.tax + l:stats.tariff - l:stats.upkeep - l:stats.mil
        \ - l:stats.interest - l:stats.spend

  let l:mods = a:st.world.mods[a:st.country]

  let l:lines = []
  call add(l:lines, printf(vimtoria#i18n#t('bg_title'),
        \ vimtoria#i18n#name(l:map.countries[a:st.country])))
  call add(l:lines, '')
  if a:st.treasury >= 0
    call add(l:lines, printf(vimtoria#i18n#t('bg_treasury'),
          \ vimtoria#ui#fmt_num(a:st.treasury)))
  else
    call add(l:lines, printf(vimtoria#i18n#t('bg_debt'),
          \ vimtoria#ui#fmt_num(-a:st.treasury)))
  endif
  call add(l:lines, printf(vimtoria#i18n#t('bg_credit'),
        \ vimtoria#ui#fmt_num(float2nr(l:stats.credit)),
        \ l:eco.const.credit_mult * 100.0, l:mods.interest * 100.0))
  call add(l:lines, printf(vimtoria#i18n#t('bg_tax'),
        \ l:rate * 100.0, l:eco.const.tax_step * 100.0,
        \ l:eco.const.tax_min * 100.0, l:eco.const.tax_max * 100.0))
  call add(l:lines, '')
  call add(l:lines, vimtoria#i18n#t('bg_lastweek'))
  call add(l:lines, printf(vimtoria#i18n#t('bg_row_tax'),
        \ vimtoria#ui#fmt_num(float2nr(l:stats.tax))))
  call add(l:lines, printf(vimtoria#i18n#t('bg_row_tariff'),
        \ vimtoria#ui#fmt_num(float2nr(l:stats.tariff))))
  call add(l:lines, printf(vimtoria#i18n#t('bg_row_upkeep'),
        \ vimtoria#ui#fmt_num(float2nr(l:stats.upkeep))))
  call add(l:lines, printf(vimtoria#i18n#t('bg_row_mil'),
        \ vimtoria#ui#fmt_num(float2nr(l:stats.mil))))
  call add(l:lines, printf(vimtoria#i18n#t('bg_row_interest'),
        \ vimtoria#ui#fmt_num(float2nr(l:stats.interest))))
  call add(l:lines, printf(vimtoria#i18n#t('bg_row_spend'),
        \ vimtoria#ui#fmt_num(float2nr(l:stats.spend))))
  call add(l:lines, '    ' . repeat('─', 24))
  call add(l:lines, printf(vimtoria#i18n#t('bg_row_net'),
        \ l:net >= 0.0 ? '+' : '-',
        \ vimtoria#ui#fmt_num(float2nr(abs(l:net)))))
  call add(l:lines, '')
  call add(l:lines, printf(vimtoria#i18n#t('bg_ref'),
        \ vimtoria#ui#fmt_num(float2nr(l:stats.income)), l:stats.sol))
  call add(l:lines, '')
  call add(l:lines, vimtoria#i18n#t('bg_note'))
  return l:lines
endfunction
