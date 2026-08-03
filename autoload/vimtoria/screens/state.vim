scriptencoding utf-8
" screens/state.vim - 州の詳細画面(M0 では基本情報のみ)

function! vimtoria#screens#state#render(st) abort
  let l:data = vimtoria#data#map()
  let l:id = empty(a:st.screen_arg) ? a:st.selected : a:st.screen_arg
  let l:stt = l:data.states[l:id]
  let l:country = l:data.countries[l:stt.country]
  let l:own = l:stt.country ==# a:st.country ? '(自国)' : ''
  return [
        \ printf('  ━━ 州情報: %s (%s) ━━━━━━━━━━━━━━━━━━━━', l:stt.name, l:id),
        \ '',
        \ printf('    所属国: %s%s', l:country.name, l:own),
        \ printf('    人口:   %d万人', l:stt.pop),
        \ '',
        \ '    (建物・雇用・市場のデータは M1/M2 で実装予定)',
        \ ]
endfunction
