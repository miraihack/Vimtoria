scriptencoding utf-8
" screens/ranking.vim - 列強ランキング(週間GDP順のスコアボード)

function! vimtoria#screens#ranking#render(st) abort
  let l:map = vimtoria#data#map()
  let l:rows = []
  for [l:cid, l:s] in items(a:st.world.stats)
    if empty(a:st.world.country_states[l:cid])
      continue
    endif
    call add(l:rows, [l:cid, l:s.gdp, l:s.sol,
          \ len(a:st.world.techs[l:cid].done),
          \ a:st.world.military[l:cid].regiments,
          \ a:st.world.treasuries[l:cid]])
  endfor
  call sort(l:rows, {a, b -> a[1] < b[1] ? 1 : a[1] > b[1] ? -1 : 0})

  let l:lines = []
  call add(l:lines, '  ━━ 列強ランキング(週間GDP順) ━━━━━━━━━━━━━━━━━━━━')
  call add(l:lines, '')
  call add(l:lines, '   順位 ' . vimtoria#ui#pad('国', 24)
        \ . printf('%12s %8s %6s %6s %14s', '週間GDP', '生活水準', '技術', '陸軍', '国庫'))
  call add(l:lines, '  ' . repeat('─', 80))
  let l:rank = 1
  for l:row in l:rows
    let [l:cid, l:gdp, l:sol, l:ntech, l:reg, l:gold] = l:row
    let l:me = l:cid ==# a:st.country
    if l:rank <= 20 || l:me
      call add(l:lines, printf('  %s%3d. %s%11s£ %8.2f %5d %6.0f %13s£',
            \ l:me ? '→' : ' ', l:rank,
            \ vimtoria#ui#pad(l:map.countries[l:cid].name . (l:me ? '(自国)' : ''), 24),
            \ vimtoria#ui#fmt_num(float2nr(l:gdp)), l:sol, l:ntech, l:reg,
            \ vimtoria#ui#fmt_num(float2nr(l:gold))))
    endif
    let l:rank += 1
  endfor
  call add(l:lines, '')
  call add(l:lines, '  スコアの目安: GDP は経済規模、生活水準は豊かさ、技術は先進性。')
  return l:lines
endfunction
