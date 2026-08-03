scriptencoding utf-8
" screens/state.vim - 州の詳細画面(基本情報+建物・雇用)

function! vimtoria#screens#state#render(st) abort
  let l:data = vimtoria#data#map()
  let l:eco = vimtoria#data#economy()
  let l:id = empty(a:st.screen_arg) ? a:st.selected : a:st.screen_arg
  let l:stt = l:data.states[l:id]
  let l:ocid = a:st.world.owner[l:id]
  let l:country = l:data.countries[l:ocid]
  let l:own = l:ocid ==# a:st.country ? '(自国)' : ''
  let l:info = vimtoria#econ#state_info(a:st, l:id)

  let l:lines = []
  call add(l:lines, printf('  ━━ 州情報: %s (%s) ━━━━━━━━━━━━━━━━━━━━━━━━━━━━', l:stt.name, l:id))
  call add(l:lines, '')
  call add(l:lines, printf('    所属国: %s%s', l:country.name, l:own))
  call add(l:lines, printf('    人口:   %d万人 ┃ 労働力 %.0f千人 ┃ 雇用 %.0f千人 ┃ 自給農 %.0f千人',
        \ l:stt.pop, l:info.workforce, l:info.employed, l:info.unemployed))
  call add(l:lines, '')
  call add(l:lines, '    ' . vimtoria#ui#pad('建物', 12)
        \ . printf('%8s %8s %12s', 'レベル', '稼働率', '週間粗利'))
  call add(l:lines, '    ' . repeat('─', 44))
  for l:bid in l:eco.buildings_order
    if !has_key(a:st.world.buildings[l:id], l:bid)
      continue
    endif
    let l:b = a:st.world.buildings[l:id][l:bid]
    call add(l:lines, '    ' . vimtoria#ui#pad(l:eco.buildings[l:bid].name, 12)
          \ . printf('%8.1f %7.0f%% %11s£',
          \          l:b.levels, l:b.f * 100.0,
          \          vimtoria#ui#fmt_num(float2nr(l:b.gross))))
  endfor
  call add(l:lines, '')
  call add(l:lines, '    (建設による拡張は M2、Pop 詳細・職業移動は M3 で実装予定)')
  return l:lines
endfunction
