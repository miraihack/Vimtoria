scriptencoding utf-8
" popup.vim - 世界地図上の各国概況ポップアップ
"
" 地図で州を選択すると、その州を領有する国の概況(政体・GDP・国庫・
" 技術・軍事・対自国関係・交戦状況)を州名ラベルの近くに表示する。
" Vim は popup_create()、Neovim はフローティングウィンドウを使い、
" 枠線は両対応のため自前で描く。v キーで表示/非表示を切り替えられる。

let s:enabled = -1        " -1: 未初期化(g:vimtoria_popup から読む)
let s:vim_id = 0          " Vim の popup ID
let s:nvim_win = -1       " Neovim のフロート window
let s:nvim_buf = -1

function! s:init_enabled() abort
  if s:enabled == -1
    let s:enabled = get(g:, 'vimtoria_popup', 1) ? 1 : 0
  endif
endfunction

function! vimtoria#popup#supported() abort
  return has('nvim') ? exists('*nvim_open_win') : has('popupwin')
endfunction

function! vimtoria#popup#toggle() abort
  call s:init_enabled()
  let s:enabled = !s:enabled
  if !s:enabled
    call vimtoria#popup#hide()
  endif
endfunction

function! vimtoria#popup#hide() abort
  if has('nvim')
    if s:nvim_win != -1
      silent! call nvim_win_close(s:nvim_win, v:true)
      let s:nvim_win = -1
    endif
  elseif s:vim_id != 0
    silent! call popup_close(s:vim_id)
    let s:vim_id = 0
  endif
endfunction

" 地図の描画後に ui.vim から呼ばれる。選択中の州の所有国を表示する
function! vimtoria#popup#update(bufnr, st) abort
  call s:init_enabled()
  if !s:enabled || !vimtoria#popup#supported()
    call vimtoria#popup#hide()
    return
  endif
  let l:winid = bufwinid(a:bufnr)
  if l:winid == -1
    call vimtoria#popup#hide()
    return
  endif
  let l:pos = vimtoria#screens#map#label_pos(a:st.selected)
  if empty(l:pos)
    call vimtoria#popup#hide()
    return
  endif
  let l:lines = vimtoria#popup#country(a:st, a:st.world.owner[a:st.selected])
  " ラベルの右下に出す。右端に近いラベルは左下へ
  let l:lnum = l:pos[0] + 4
  let l:left = l:pos[4] <= 150
  let l:bcol = l:left ? l:pos[2] : l:pos[1]
  call s:show(l:winid, l:lnum, l:bcol, l:left, l:lines)
endfunction

function! s:show(winid, lnum, bcol, left, lines) abort
  let l:w = 0
  for l:line in a:lines
    let l:dw = strdisplaywidth(l:line)
    if l:dw > l:w
      let l:w = l:dw
    endif
  endfor
  if has('nvim')
    if s:nvim_buf == -1 || !bufexists(s:nvim_buf)
      let s:nvim_buf = nvim_create_buf(v:false, v:true)
    endif
    call nvim_buf_set_lines(s:nvim_buf, 0, -1, v:false, a:lines)
    let l:conf = {'relative': 'win', 'win': a:winid,
          \ 'bufpos': [a:lnum - 1, a:bcol],
          \ 'row': 1, 'col': a:left ? 1 : -1,
          \ 'anchor': a:left ? 'NW' : 'NE',
          \ 'width': l:w, 'height': len(a:lines),
          \ 'style': 'minimal', 'focusable': v:false, 'zindex': 50}
    if s:nvim_win != -1 && nvim_win_is_valid(s:nvim_win)
      call nvim_win_set_config(s:nvim_win, l:conf)
    else
      let s:nvim_win = nvim_open_win(s:nvim_buf, v:false, l:conf)
    endif
  else
    " Vim: スクリーン座標に変換して popup を置く(画面外なら消す)
    let l:sp = screenpos(a:winid, a:lnum, a:bcol + 1)
    if l:sp.row == 0
      call vimtoria#popup#hide()
      return
    endif
    let l:opts = {'line': l:sp.row + 1,
          \ 'col': a:left ? l:sp.col + 1 : l:sp.col - 1,
          \ 'pos': a:left ? 'topleft' : 'topright',
          \ 'zindex': 50, 'wrap': 0}
    if s:vim_id != 0 && !empty(popup_getpos(s:vim_id))
      call popup_settext(s:vim_id, a:lines)
      call popup_move(s:vim_id, l:opts)
    else
      let s:vim_id = popup_create(a:lines, l:opts)
    endif
  endif
endfunction

" 国の概況を枠付きの行リストにする(純関数。テストからも呼ばれる)
function! vimtoria#popup#country(st, cid) abort
  let l:map = vimtoria#data#map()
  let l:world = a:st.world
  let l:pd = vimtoria#data#politics()
  let l:country = l:map.countries[a:cid]
  let l:stats = l:world.stats[a:cid]
  let l:pol = l:world.politics[a:cid]
  let l:t = l:world.techs[a:cid]

  let l:body = []
  " 政体と急進性
  call add(l:body, printf(vimtoria#i18n#t('pu_gov'),
        \ vimtoria#i18n#name(l:pd.laws[l:pol.laws['government']]), l:pol.rad))
  " GDP と世界順位
  let l:rank = 1
  for [l:ocid, l:s] in items(l:world.stats)
    if l:ocid !=# a:cid && !empty(l:world.country_states[l:ocid])
          \ && l:s.gdp > l:stats.gdp
      let l:rank += 1
    endif
  endfor
  call add(l:body, printf(vimtoria#i18n#t('pu_gdp'),
        \ vimtoria#ui#fmt_num(float2nr(l:stats.gdp)), l:rank))
  call add(l:body, printf(vimtoria#i18n#t('pu_treasury'),
        \ vimtoria#ui#fmt_num(float2nr(l:world.treasuries[a:cid])), l:stats.sol))
  let l:unemp = l:stats.workforce > 0.0
        \ ? 100.0 * l:stats.unemployed / l:stats.workforce : 0.0
  call add(l:body, printf(vimtoria#i18n#t('pu_workforce'),
        \ vimtoria#ui#fmt_num(float2nr(l:stats.workforce)), l:unemp))
  " 技術
  let l:cur = empty(l:t.current) ? '─'
        \ : vimtoria#i18n#name(vimtoria#data#tech().techs[l:t.current])
  call add(l:body, printf(vimtoria#i18n#t('pu_tech'),
        \ len(l:t.done), len(vimtoria#tech#list_for(a:cid)), l:cur))
  " 軍事
  call add(l:body, printf(vimtoria#i18n#t('pu_army'),
        \ l:world.military[a:cid].regiments,
        \ vimtoria#war#strength(l:world, a:cid)))
  " 対自国関係(自国は「自国」表示)
  if a:cid ==# a:st.country
    call add(l:body, vimtoria#i18n#t('pu_yours'))
  else
    let l:note = ''
    if !empty(vimtoria#diplo#war_between(l:world, a:st.country, a:cid))
      let l:note = vimtoria#i18n#t('pu_atwar_you')
    elseif vimtoria#diplo#allied(l:world, a:st.country, a:cid)
      let l:note = vimtoria#i18n#t('pu_ally')
    endif
    call add(l:body, printf(vimtoria#i18n#t('pu_rel'),
          \ vimtoria#diplo#relation(l:world, a:st.country, a:cid), l:note))
  endif
  " 交戦相手(最大2カ国+省略表示)
  let l:foes = []
  for l:w in l:world.wars
    let l:side_a = [l:w.attacker]
    let l:side_d = [l:w.defender] + l:w.allies_d
    if index(l:side_a, a:cid) >= 0
      call extend(l:foes, l:side_d)
    elseif index(l:side_d, a:cid) >= 0
      call extend(l:foes, l:side_a)
    endif
  endfor
  if !empty(l:foes)
    let l:names = []
    for l:foe in l:foes[:1]
      call add(l:names, vimtoria#i18n#name(l:map.countries[l:foe]))
    endfor
    if len(l:foes) > 2
      call add(l:names, printf('+%d', len(l:foes) - 2))
    endif
    call add(l:body, printf(vimtoria#i18n#t('pu_wars'),
          \ join(l:names, vimtoria#i18n#t('list_sep'))))
  endif

  " 枠を付ける(全角対応のため自前で描く)
  let l:title = ' ' . vimtoria#i18n#name(l:country) . ' '
  let l:w = strdisplaywidth(l:title)
  for l:line in l:body
    let l:dw = strdisplaywidth(l:line)
    if l:dw > l:w
      let l:w = l:dw
    endif
  endfor
  let l:out = ['┌' . l:title
        \ . repeat('─', l:w - strdisplaywidth(l:title) + 1) . '┐']
  for l:line in l:body
    call add(l:out, '│' . vimtoria#ui#pad(l:line, l:w + 1) . '│')
  endfor
  call add(l:out, '└' . repeat('─', l:w + 1) . '┘')
  return l:out
endfunction
