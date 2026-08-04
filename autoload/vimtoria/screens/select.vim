scriptencoding utf-8
" screens/select.vim - ゲーム開始時の国選択画面
" j/k のメニュー選択に加え、カーソルを国の行に置いて Enter(または
" クリック)でもその国を選べる。国行の開始位置を描画時に記録する。

let s:row0 = -1   " 国リスト先頭のバッファ行番号(未描画なら -1)

function! vimtoria#screens#select#render(st) abort
  let l:map = vimtoria#data#map()
  let l:pol = vimtoria#data#politics()
  let l:world = a:st.world

  let l:lines = []
  call add(l:lines, vimtoria#i18n#t('sl_title'))
  call add(l:lines, '')
  call add(l:lines, vimtoria#i18n#t('sl_hint'))
  call add(l:lines, '')
  call add(l:lines, '    '
        \ . vimtoria#ui#pad(vimtoria#i18n#t('sl_col_country'), 28)
        \ . printf(vimtoria#i18n#t('sl_cols'),
        \          vimtoria#i18n#t('sl_col_states'),
        \          vimtoria#i18n#t('sl_col_pop'),
        \          vimtoria#i18n#t('sl_col_wf'),
        \          vimtoria#i18n#t('sl_col_army'),
        \          vimtoria#i18n#t('sl_col_econ')))
  call add(l:lines, '  ' . repeat('─', 78))
  " 国行の開始バッファ行を記録(ui がヘッダ等 3 行を前置するので +4)
  let s:row0 = len(l:lines) + 4
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
    call add(l:lines, printf('  %s %s%4d %10s %7.0f%s %6.0f  %s',
          \ l:i == a:st.menu_idx ? '>' : ' ',
          \ vimtoria#ui#pad(vimtoria#i18n#name(l:map.countries[l:cid]), 28),
          \ len(l:world.country_states[l:cid]),
          \ vimtoria#ui#fmt_num(l:pop),
          \ l:workforce, vimtoria#i18n#lang() ==# 'en' ? 'k' : '千',
          \ l:world.military[l:cid].regiments,
          \ vimtoria#i18n#name(l:pol.laws[l:econ_law])))
    let l:i += 1
  endfor
  call add(l:lines, '')
  call add(l:lines, vimtoria#i18n#t('sl_note'))
  return l:lines
endfunction

" バッファ行番号 → 国リストの添字(国の行でなければ -1)
function! vimtoria#screens#select#index_at(lnum) abort
  if s:row0 < 0
    return -1
  endif
  let l:idx = a:lnum - s:row0
  return l:idx >= 0 && l:idx < len(vimtoria#data#map().country_order)
        \ ? l:idx : -1
endfunction
