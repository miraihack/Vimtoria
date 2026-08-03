scriptencoding utf-8
" screens/diplo.vim - 外交画面(各国との関係・同盟・戦争)

function! vimtoria#screens#diplo#render(st) abort
  let l:map = vimtoria#data#map()
  let l:world = a:st.world

  let l:lines = []
  call add(l:lines, printf('  ━━ 外交: %s ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
        \ l:map.countries[a:st.country].name))
  call add(l:lines, '')
  call add(l:lines, '  宣戦の奪取目標はマップで選択中の州(相手領の場合)になる')
  if !empty(a:st.msg)
    call add(l:lines, '  » ' . a:st.msg)
  endif
  call add(l:lines, '')
  call add(l:lines, '    ' . vimtoria#ui#pad('国', 24)
        \ . printf('%6s  %-8s %8s', '関係', '状態', '戦力'))
  call add(l:lines, '  ' . repeat('─', 56))
  let l:i = 0
  for l:cid in vimtoria#core#diplo_targets(a:st)
    let l:rel = vimtoria#diplo#relation(l:world, a:st.country, l:cid)
    if empty(l:world.country_states[l:cid])
      let l:status = '滅亡'
    elseif !empty(vimtoria#diplo#war_between(l:world, a:st.country, l:cid))
      let l:status = '交戦中'
    elseif vimtoria#diplo#allied(l:world, a:st.country, l:cid)
      let l:status = '同盟'
    else
      let l:status = '─'
    endif
    call add(l:lines, printf('  %s %s%+6.0f  %-8s %8.0f',
          \ l:i == a:st.menu_idx ? '>' : ' ',
          \ vimtoria#ui#pad(l:map.countries[l:cid].name, 24),
          \ l:rel, vimtoria#ui#pad(l:status, 8),
          \ vimtoria#war#strength(l:world, l:cid)))
    let l:i += 1
  endfor
  call add(l:lines, '')
  call add(l:lines, '  ── 世界の戦争 ──')
  if empty(l:world.wars)
    call add(l:lines, '  (なし)')
  else
    for l:w in l:world.wars
      let l:names = l:map.countries[l:w.attacker].name . ' → '
            \ . l:map.countries[l:w.defender].name
      if !empty(l:w.allies_d)
        let l:allies = []
        for l:ally in l:w.allies_d
          call add(l:allies, l:map.countries[l:ally].name)
        endfor
        let l:names .= '(+' . join(l:allies, '・') . ')'
      endif
      call add(l:lines, printf('  %s ┃ 戦況 %+.0f(+100で攻撃側勝利)┃ 目標: %s',
            \ l:names, l:w.score, l:map.states[l:w.goal].name))
    endfor
  endif
  return l:lines
endfunction
