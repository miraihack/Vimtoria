scriptencoding utf-8
" screens/tech.vim - 技術画面(分野別の研究ツリー一覧と研究開始)
" 206 技術を分野ごとにまとめて表示する。リストは画面より長いため、
" ui.vim の描画が選択行(> 印)にカーソルを合わせてスクロールさせる。

function! vimtoria#screens#tech#render(st) abort
  let l:data = vimtoria#data#tech()
  let l:map = vimtoria#data#map()
  let l:t = a:st.world.techs[a:st.country]
  let l:stats = a:st.world.stats[a:st.country]
  let l:rate = vimtoria#tech#rate(a:st.world, a:st.country, l:stats.workforce)
  let l:menu = vimtoria#tech#menu_for(a:st.country)

  let l:lines = []
  call add(l:lines, printf(vimtoria#i18n#t('tc_title'),
        \ vimtoria#i18n#name(l:map.countries[a:st.country])))
  call add(l:lines, '')
  if empty(l:t.current)
    let l:cur = vimtoria#i18n#t('tc_none')
  else
    let l:def = l:data.techs[l:t.current]
    let l:done = get(l:t.progress, l:t.current, 0.0)
    let l:cur = printf('%s %.0f/%.0frp (%.0f%%)', vimtoria#i18n#name(l:def),
          \ l:done, l:def.cost, 100.0 * l:done / l:def.cost)
  endif
  call add(l:lines, printf(vimtoria#i18n#t('tc_cur'),
        \ len(l:t.done), len(l:menu), l:rate, l:cur))
  if !empty(a:st.msg)
    call add(l:lines, '  » ' . a:st.msg)
  endif
  let l:i = 0
  let l:branch = ''
  for l:tid in l:menu
    let l:def = l:data.techs[l:tid]
    if l:def.branch !=# l:branch
      let l:branch = l:def.branch
      call add(l:lines, '')
      call add(l:lines, printf('  ── %s ──',
            \ vimtoria#i18n#name(l:data.branches[l:branch])))
    endif
    if has_key(l:t.done, l:tid)
      let l:mark = '✓'
    elseif l:t.current ==# l:tid
      let l:mark = '▶'
    elseif vimtoria#tech#available(a:st.world, a:st.country, l:tid)
      let l:mark = '・'
    else
      let l:mark = '×'
    endif
    let l:req = ''
    if !empty(l:def.req) && !has_key(l:t.done, l:tid)
      let l:names = []
      for l:rid in l:def.req
        if !has_key(l:t.done, l:rid)
          call add(l:names, vimtoria#i18n#name(l:data.techs[l:rid]))
        endif
      endfor
      if !empty(l:names)
        let l:req = vimtoria#i18n#t('tc_req')
              \ . join(l:names, vimtoria#i18n#t('list_sep'))
      endif
    endif
    let l:prog = ''
    let l:p = get(l:t.progress, l:tid, 0.0)
    if l:p > 0.0 && !has_key(l:t.done, l:tid)
      let l:prog = printf(' (%.0f/%.0frp)', l:p, l:def.cost)
    endif
    call add(l:lines, printf('  %s %s %d %s%5.0frp  %s%s%s',
          \ l:i == a:st.menu_idx ? '>' : ' ', l:mark, l:def.era,
          \ vimtoria#ui#pad(vimtoria#i18n#name(l:def), 24), l:def.cost,
          \ vimtoria#i18n#desc(l:def), l:req, l:prog))
    let l:i += 1
  endfor
  call add(l:lines, '')
  call add(l:lines, vimtoria#i18n#t('tc_legend'))
  return l:lines
endfunction
