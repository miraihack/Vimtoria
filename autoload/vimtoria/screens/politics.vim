scriptencoding utf-8
" screens/politics.vim - 政治画面(利益集団・法律・急進性)

function! vimtoria#screens#politics#render(st) abort
  let l:data = vimtoria#data#politics()
  let l:map = vimtoria#data#map()
  let l:pol = a:st.world.politics[a:st.country]

  let l:lines = []
  call add(l:lines, printf(vimtoria#i18n#t('pl_title'),
        \ vimtoria#i18n#name(l:map.countries[a:st.country])))
  call add(l:lines, '')
  if empty(l:pol.enact.law)
    let l:enact = vimtoria#i18n#t('pl_none')
  else
    let l:def = l:data.laws[l:pol.enact.law]
    let l:sup = vimtoria#politics#support(a:st.world, a:st.country, l:pol.enact.law)
    let l:enact = printf(vimtoria#i18n#t('pl_enact'),
          \ vimtoria#i18n#name(l:def), l:pol.enact.progress,
          \ l:data.const.enact_points,
          \ l:sup, l:sup < 0.0 ? vimtoria#i18n#t('pl_forcing') : '')
  endif
  call add(l:lines, printf(vimtoria#i18n#t('pl_rad'),
        \ l:pol.rad,
        \ l:pol.rad > l:data.const.rad_uprising_threshold
        \   ? vimtoria#i18n#t('pl_danger') : '',
        \ l:enact))
  if !empty(a:st.msg)
    call add(l:lines, '  » ' . a:st.msg)
  endif
  call add(l:lines, '')
  call add(l:lines, vimtoria#i18n#t('pl_igs'))
  for l:ig in l:data.ig_order
    let l:att = vimtoria#politics#attitude(a:st.world, a:st.country, l:ig)
    call add(l:lines, printf(vimtoria#i18n#t('pl_ig_row'),
          \ vimtoria#ui#pad(vimtoria#i18n#name(l:data.igs[l:ig]), 14),
          \ l:pol.clout[l:ig] * 100.0, l:att,
          \ l:att >= 2 ? vimtoria#i18n#t('pl_happy')
          \            : (l:att <= -2 ? vimtoria#i18n#t('pl_angry') : '')))
  endfor
  call add(l:lines, '')
  call add(l:lines, vimtoria#i18n#t('pl_movs'))
  let l:any_mov = 0
  for l:mid in l:data.movement_order
    if has_key(l:pol.movements, l:mid)
      let l:mdef = l:data.movements[l:mid]
      call add(l:lines, printf(vimtoria#i18n#t('pl_mov_row'),
            \ vimtoria#ui#pad(vimtoria#i18n#name(l:mdef), 18),
            \ l:pol.movements[l:mid],
            \ vimtoria#i18n#name(l:data.laws[l:mdef.target])))
      let l:any_mov = 1
    endif
  endfor
  if !l:any_mov
    call add(l:lines, vimtoria#i18n#t('pl_mov_none'))
  endif
  call add(l:lines, '')
  call add(l:lines, vimtoria#i18n#t('pl_laws'))
  let l:i = 0
  for l:lid in l:data.law_order
    let l:def = l:data.laws[l:lid]
    if l:i == 0 || l:data.laws[l:data.law_order[l:i - 1]].group !=# l:def.group
      call add(l:lines, printf('  [%s]',
            \ vimtoria#i18n#name(l:data.groups[l:def.group])))
    endif
    let l:active = l:pol.laws[l:def.group] ==# l:lid
    if l:active
      let l:mark = '●'
      let l:note = ''
    elseif l:pol.enact.law ==# l:lid
      let l:mark = '▶'
      let l:note = vimtoria#i18n#t('pl_enacting')
    elseif !vimtoria#politics#law_unlocked(a:st.world, a:st.country, l:lid)
      " 思想(技術)が未研究で制定できない
      let l:mark = '×'
      let l:note = vimtoria#i18n#t('tc_req')
            \ . vimtoria#i18n#name(
            \     vimtoria#data#tech().techs[l:def.req_tech])
    else
      let l:mark = '○'
      let l:note = printf(vimtoria#i18n#t('pl_support'),
            \ vimtoria#politics#support(a:st.world, a:st.country, l:lid))
    endif
    call add(l:lines, printf('  %s %s %s %s%s',
          \ l:i == a:st.menu_idx ? '>' : ' ', l:mark,
          \ vimtoria#ui#pad(vimtoria#i18n#name(l:def), 18),
          \ vimtoria#i18n#desc(l:def), l:note))
    let l:i += 1
  endfor
  call add(l:lines, '')
  call add(l:lines, vimtoria#i18n#t('pl_note1'))
  call add(l:lines, vimtoria#i18n#t('pl_note2'))
  return l:lines
endfunction
