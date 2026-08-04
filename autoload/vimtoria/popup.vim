scriptencoding utf-8
" popup.vim - 各国概況・自国ステータス・開始時ブリーフィングのポップアップ
"
" 3 つのスロットを管理する:
"   'sel'   選択中の州の所有国の概況(州名ラベルの脇に追従)
"   'own'   自国の概況(ハワイ南方の海域に常設)
"   'brief' 国選択直後の情勢解説(何かキーを押すと閉じる)
" Vim は popup_create()、Neovim はフローティングウィンドウを使い、
" 枠線は両対応のため自前で描く。v キーで sel/own の表示を切り替えられる。

let s:enabled = -1        " -1: 未初期化(g:vimtoria_popup から読む)
let s:slots = {}          " key -> {'vim': popup id, 'win': nvim win, 'buf': nvim buf}
let s:view = {'leftcol': 0, 'width': 200}

" ゲームウィンドウのスクロール位置と幅を取り込む(win_execute 経由)
function! vimtoria#popup#_capture() abort
  let s:view = {'leftcol': winsaveview().leftcol, 'width': winwidth(0)}
endfunction

" ラベル位置(地図 1 周目)を、いま見えている側の世界コピーへ写す。
" 地図バッファには世界が 2 周分描かれているため、左端より西のラベルは
" 2 周目のコピー上に見えている
function! s:eff_anchor(pos) abort
  if a:pos[3] < s:view.leftcol
    let l:rb = vimtoria#screens#map#row_bytes(a:pos[0])
    return [a:pos[0], a:pos[1] + l:rb, a:pos[2] + l:rb,
          \ a:pos[3] + 200, a:pos[4] + 200]
  endif
  return a:pos
endfunction

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
    call s:hide('sel')
    call s:hide('own')
  endif
endfunction

function! vimtoria#popup#hide() abort
  for l:key in keys(s:slots)
    call s:hide(l:key)
  endfor
endfunction

function! s:hide(key) abort
  if !has_key(s:slots, a:key)
    return
  endif
  let l:s = s:slots[a:key]
  if has('nvim')
    if l:s.win != -1
      silent! call nvim_win_close(l:s.win, v:true)
      let l:s.win = -1
    endif
  elseif l:s.vim != 0
    silent! call popup_close(l:s.vim)
    let l:s.vim = 0
  endif
endfunction

" 地図の描画後に ui.vim から呼ばれる
function! vimtoria#popup#update(bufnr, st) abort
  call s:init_enabled()
  if !s:enabled || !vimtoria#popup#supported()
    call s:hide('sel')
    call s:hide('own')
    return
  endif
  let l:winid = bufwinid(a:bufnr)
  if l:winid == -1
    call vimtoria#popup#hide()
    return
  endif
  call win_execute(l:winid, 'call vimtoria#popup#_capture()')
  " 選択中の州の所有国(ラベルの脇。右端寄りなら左側へ出す)
  let l:pos = vimtoria#screens#map#label_pos(a:st.selected)
  if empty(l:pos)
    call s:hide('sel')
  else
    let l:pos = s:eff_anchor(l:pos)
    let l:left = l:pos[4] - s:view.leftcol <= s:view.width - 45
    call s:show('sel', l:winid, l:pos[0] + 4,
          \ l:left ? l:pos[2] : l:pos[1], l:left,
          \ vimtoria#popup#country(a:st, a:st.world.owner[a:st.selected]))
  endif
  " 自国の概況(ハワイ南方の太平洋海域に常設)
  let l:haw = vimtoria#screens#map#label_pos('HAW')
  if empty(l:haw)
    call s:hide('own')
  else
    let l:haw = s:eff_anchor(l:haw)
    call s:show('own', l:winid, l:haw[0] + 4 + 2,
          \ l:haw[1] > 4 ? l:haw[1] - 4 : l:haw[1], 1,
          \ vimtoria#popup#country(a:st, a:st.country))
  endif
endfunction

" 国選択直後の情勢解説をウィンドウ中央に出す(次のキー入力で閉じる)。
" バッファ位置でなくウィンドウ位置に置くので、地図のスクロールと無関係
function! vimtoria#popup#briefing(bufnr, st) abort
  if !vimtoria#popup#supported()
    return
  endif
  let l:winid = bufwinid(a:bufnr)
  if l:winid == -1
    return
  endif
  call s:show_win_centered('brief', l:winid, 4,
        \ vimtoria#popup#brief_lines(a:st, a:st.country))
endfunction

" ウィンドウ相対で水平中央に表示する(ブリーフィング用)
function! s:show_win_centered(key, winid, row, lines) abort
  if !has_key(s:slots, a:key)
    let s:slots[a:key] = {'vim': 0, 'win': -1, 'buf': -1}
  endif
  let l:s = s:slots[a:key]
  let l:w = 0
  for l:line in a:lines
    let l:dw = strdisplaywidth(l:line)
    if l:dw > l:w
      let l:w = l:dw
    endif
  endfor
  let l:col = (winwidth(a:winid) - l:w) / 2
  if l:col < 0
    let l:col = 0
  endif
  if has('nvim')
    if l:s.buf == -1 || !bufexists(l:s.buf)
      let l:s.buf = nvim_create_buf(v:false, v:true)
    endif
    call nvim_buf_set_lines(l:s.buf, 0, -1, v:false, a:lines)
    let l:conf = {'relative': 'win', 'win': a:winid,
          \ 'row': a:row, 'col': l:col, 'anchor': 'NW',
          \ 'width': l:w, 'height': len(a:lines),
          \ 'style': 'minimal', 'focusable': v:false, 'zindex': 60}
    if l:s.win != -1 && nvim_win_is_valid(l:s.win)
      call nvim_win_set_config(l:s.win, l:conf)
    else
      let l:s.win = nvim_open_win(l:s.buf, v:false, l:conf)
    endif
  else
    let l:wp = win_screenpos(a:winid)
    let l:opts = {'line': l:wp[0] + a:row, 'col': l:wp[1] + l:col,
          \ 'pos': 'topleft', 'zindex': 60, 'wrap': 0}
    if l:s.vim != 0 && !empty(popup_getpos(l:s.vim))
      call popup_settext(l:s.vim, a:lines)
      call popup_move(l:s.vim, l:opts)
    else
      let l:s.vim = popup_create(a:lines, l:opts)
    endif
  endif
endfunction

function! vimtoria#popup#dismiss_brief() abort
  call s:hide('brief')
endfunction

function! s:show(key, winid, lnum, bcol, left, lines) abort
  if !has_key(s:slots, a:key)
    let s:slots[a:key] = {'vim': 0, 'win': -1, 'buf': -1}
  endif
  let l:s = s:slots[a:key]
  let l:w = 0
  for l:line in a:lines
    let l:dw = strdisplaywidth(l:line)
    if l:dw > l:w
      let l:w = l:dw
    endif
  endfor
  if has('nvim')
    if l:s.buf == -1 || !bufexists(l:s.buf)
      let l:s.buf = nvim_create_buf(v:false, v:true)
    endif
    call nvim_buf_set_lines(l:s.buf, 0, -1, v:false, a:lines)
    let l:conf = {'relative': 'win', 'win': a:winid,
          \ 'bufpos': [a:lnum - 1, a:bcol],
          \ 'row': 1, 'col': a:left ? 1 : -1,
          \ 'anchor': a:left ? 'NW' : 'NE',
          \ 'width': l:w, 'height': len(a:lines),
          \ 'style': 'minimal', 'focusable': v:false,
          \ 'zindex': a:key ==# 'brief' ? 60 : 50}
    if l:s.win != -1 && nvim_win_is_valid(l:s.win)
      call nvim_win_set_config(l:s.win, l:conf)
    else
      let l:s.win = nvim_open_win(l:s.buf, v:false, l:conf)
    endif
  else
    " Vim: スクリーン座標に変換して popup を置く(画面外なら消す)
    let l:sp = screenpos(a:winid, a:lnum, a:bcol + 1)
    if l:sp.row == 0
      call s:hide(a:key)
      return
    endif
    let l:opts = {'line': l:sp.row + 1,
          \ 'col': a:left ? l:sp.col + 1 : l:sp.col - 1,
          \ 'pos': a:left ? 'topleft' : 'topright',
          \ 'zindex': a:key ==# 'brief' ? 60 : 50, 'wrap': 0}
    if l:s.vim != 0 && !empty(popup_getpos(l:s.vim))
      call popup_settext(l:s.vim, a:lines)
      call popup_move(l:s.vim, l:opts)
    else
      let l:s.vim = popup_create(a:lines, l:opts)
    endif
  endif
endfunction

" ---- 内容の生成(純関数。テストからも呼ばれる) ----

" 行リストに枠を付ける
function! s:frame(title, body) abort
  let l:title = ' ' . a:title . ' '
  let l:w = strdisplaywidth(l:title)
  for l:line in a:body
    let l:dw = strdisplaywidth(l:line)
    if l:dw > l:w
      let l:w = l:dw
    endif
  endfor
  let l:out = ['┌' . l:title
        \ . repeat('─', l:w - strdisplaywidth(l:title) + 1) . '┐']
  for l:line in a:body
    call add(l:out, '│' . vimtoria#ui#pad(l:line, l:w + 1) . '│')
  endfor
  call add(l:out, '└' . repeat('─', l:w + 1) . '┘')
  return l:out
endfunction

" 国の概況ボックス
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
  " 軍事(陸軍+海軍)
  call add(l:body, printf(vimtoria#i18n#t('pu_army'),
        \ l:world.military[a:cid].regiments,
        \ vimtoria#war#strength(l:world, a:cid),
        \ l:world.military[a:cid].ships,
        \ vimtoria#war#navy_strength(l:world, a:cid)))
  " 鎖国中の表示
  if get(get(l:world, 'isolated', {}), a:cid, 0)
    call add(l:body, vimtoria#i18n#t('pu_isolated'))
  endif
  " 対自国関係(自国は「あなたの国」表示)
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
  return s:frame(vimtoria#i18n#name(l:country), l:body)
endfunction

" 国選択直後のブリーフィングボックス(1836年の情勢解説+基礎データ)
function! vimtoria#popup#brief_lines(st, cid) abort
  let l:map = vimtoria#data#map()
  let l:world = a:st.world
  let l:pd = vimtoria#data#politics()
  let l:country = l:map.countries[a:cid]
  let l:lang = vimtoria#i18n#lang()

  let l:body = ['']
  " 情勢解説(data/map.vim の briefs)
  for l:line in get(get(l:map.briefs, a:cid, {}), l:lang, [])
    call add(l:body, l:line)
  endfor
  call add(l:body, '')
  " 基礎データ
  let l:pop = 0
  let l:workforce = 0.0
  for l:sid in l:world.country_states[a:cid]
    let l:pop += l:map.states[l:sid].pop
    let l:workforce += l:world.workforce[l:sid]
  endfor
  call add(l:body, printf(vimtoria#i18n#t('bf_gov'),
        \ vimtoria#i18n#name(l:pd.laws[l:world.politics[a:cid].laws['government']]),
        \ vimtoria#i18n#name(l:pd.laws[l:world.politics[a:cid].laws['suffrage']])))
  call add(l:body, printf(vimtoria#i18n#t('bf_pop'),
        \ len(l:world.country_states[a:cid]),
        \ vimtoria#i18n#pop(l:pop), l:workforce))
  call add(l:body, printf(vimtoria#i18n#t('bf_mil'),
        \ l:world.military[a:cid].regiments,
        \ l:world.military[a:cid].ships))
  if get(get(l:world, 'isolated', {}), a:cid, 0)
    call add(l:body, vimtoria#i18n#t('bf_isolated'))
  endif
  call add(l:body, '')
  call add(l:body, vimtoria#i18n#t('bf_dismiss'))
  return s:frame(printf(vimtoria#i18n#t('bf_title'),
        \ vimtoria#i18n#name(l:country)), l:body)
endfunction
