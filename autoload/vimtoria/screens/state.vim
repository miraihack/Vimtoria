scriptencoding utf-8
" screens/state.vim - 州の詳細画面(基本情報+建物・雇用)

function! vimtoria#screens#state#render(st) abort
  let l:data = vimtoria#data#map()
  let l:eco = vimtoria#data#economy()
  let l:id = empty(a:st.screen_arg) ? a:st.selected : a:st.screen_arg
  let l:stt = l:data.states[l:id]
  let l:ocid = a:st.world.owner[l:id]
  let l:country = l:data.countries[l:ocid]
  let l:own = l:ocid ==# a:st.country ? vimtoria#i18n#t('map_own') : ''
  let l:info = vimtoria#econ#state_info(a:st, l:id)

  let l:lines = []
  call add(l:lines, printf(vimtoria#i18n#t('st_title'),
        \ vimtoria#i18n#name(l:stt), l:id))
  call add(l:lines, '')
  call add(l:lines, printf(vimtoria#i18n#t('st_owner'),
        \ vimtoria#i18n#name(l:country), l:own))
  call add(l:lines, printf(vimtoria#i18n#t('st_pop'),
        \ vimtoria#i18n#pop(l:stt.pop),
        \ l:info.workforce, l:info.employed, l:info.unemployed))
  call add(l:lines, '')
  call add(l:lines, '    '
        \ . vimtoria#ui#pad(vimtoria#i18n#t('st_col_building'), 20)
        \ . printf(vimtoria#i18n#t('st_cols'),
        \          vimtoria#i18n#t('st_col_levels'),
        \          vimtoria#i18n#t('st_col_f'),
        \          vimtoria#i18n#t('st_col_gross')))
  call add(l:lines, '    ' . repeat('─', 52))
  for l:bid in l:eco.buildings_order
    if !has_key(a:st.world.buildings[l:id], l:bid)
      continue
    endif
    let l:b = a:st.world.buildings[l:id][l:bid]
    call add(l:lines, '    '
          \ . vimtoria#ui#pad(vimtoria#i18n#name(l:eco.buildings[l:bid]), 20)
          \ . printf('%8.1f %7.0f%% %11s£',
          \          l:b.levels, l:b.f * 100.0,
          \          vimtoria#ui#fmt_num(float2nr(l:b.gross))))
  endfor
  return l:lines
endfunction
