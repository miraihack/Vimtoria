scriptencoding utf-8
" screens/politics.vim - 政治画面(利益集団・法律・急進性)

function! vimtoria#screens#politics#render(st) abort
  let l:data = vimtoria#data#politics()
  let l:map = vimtoria#data#map()
  let l:pol = a:st.world.politics[a:st.country]

  let l:lines = []
  call add(l:lines, printf('  ━━ 政治: %s ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
        \ l:map.countries[a:st.country].name))
  call add(l:lines, '')
  if empty(l:pol.enact.law)
    let l:enact = '(なし — j/k で法律を選び Enter で制定開始)'
  else
    let l:def = l:data.laws[l:pol.enact.law]
    let l:sup = vimtoria#politics#support(a:st.world, a:st.country, l:pol.enact.law)
    let l:enact = printf('%s %.0f/%.0f(支持 %+.2f%s)',
          \ l:def.name, l:pol.enact.progress, l:data.const.enact_points,
          \ l:sup, l:sup < 0.0 ? ' — 強行中、急進性が上がる' : '')
  endif
  call add(l:lines, printf('  急進性 %.1f/100%s ┃ 制定中: %s',
        \ l:pol.rad,
        \ l:pol.rad > l:data.const.rad_uprising_threshold ? '(反乱の危険!)' : '',
        \ l:enact))
  if !empty(a:st.msg)
    call add(l:lines, '  » ' . a:st.msg)
  endif
  call add(l:lines, '')
  call add(l:lines, '  ── 利益集団 ──')
  for l:ig in l:data.ig_order
    let l:att = vimtoria#politics#attitude(a:st.world, a:st.country, l:ig)
    call add(l:lines, printf('    %s 勢力 %4.0f%%  現行法への態度 %+d %s',
          \ vimtoria#ui#pad(l:data.igs[l:ig].name, 10),
          \ l:pol.clout[l:ig] * 100.0, l:att,
          \ l:att >= 2 ? '(満足)' : (l:att <= -2 ? '(不満)' : '')))
  endfor
  call add(l:lines, '')
  call add(l:lines, '  ── 法律 ──')
  let l:i = 0
  for l:lid in l:data.law_order
    let l:def = l:data.laws[l:lid]
    if l:i == 0 || l:data.laws[l:data.law_order[l:i - 1]].group !=# l:def.group
      call add(l:lines, printf('  [%s]', l:data.groups[l:def.group].name))
    endif
    let l:active = l:pol.laws[l:def.group] ==# l:lid
    if l:active
      let l:mark = '●'
      let l:note = ''
    elseif l:pol.enact.law ==# l:lid
      let l:mark = '▶'
      let l:note = ' 制定中'
    else
      let l:mark = '○'
      let l:note = printf(' 支持 %+.2f',
            \ vimtoria#politics#support(a:st.world, a:st.country, l:lid))
    endif
    call add(l:lines, printf('  %s %s %s %s%s',
          \ l:i == a:st.menu_idx ? '>' : ' ', l:mark,
          \ vimtoria#ui#pad(l:def.name, 10), l:def.desc, l:note))
    let l:i += 1
  endfor
  call add(l:lines, '')
  call add(l:lines, '  支持が正なら制定が速い。負のまま強行すると急進性が上がり、')
  call add(l:lines, '  急進性 60 超で反乱(全産出 -20%)の危険がある。')
  return l:lines
endfunction
