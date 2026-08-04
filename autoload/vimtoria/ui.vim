scriptencoding utf-8
" ui.vim - バッファ/ウィンドウ管理と描画フレームワーク
" 描画は「状態 → 行リスト」の純関数(build_lines)と、その結果を
" setbufline で反映する render に分かれる。

let s:bufnr = -1
let s:match_sig = ''
let s:saved_mouse = v:null
let s:last_screen = ''
let s:map_view = {}
let s:normalizing = 0
let s:in_render = 0
" 地図画面のヘッダ・フッタの字下げ量(= 現在の水平スクロール位置)。
" 右へスクロールしても自国の情勢や歴史イベントが読めるように、
" 固定行を常に見えている位置へ描き直す
let s:cur_leftcol = 0
let s:win_lc = 0
" 地図 1 周分の表示幅(200 桁)。バッファには 2 周分描かれている
let s:MAP_W = 200

" 地図画面の固定行(ヘッダ・フッタ)の字下げ量
function! vimtoria#ui#map_leftcol() abort
  return s:cur_leftcol
endfunction

function! vimtoria#ui#_capture_lc() abort
  let s:win_lc = winsaveview().leftcol
endfunction

function! s:win_leftcol() abort
  let l:winid = s:bufnr == -1 ? -1 : bufwinid(s:bufnr)
  if l:winid == -1
    return 0
  endif
  let s:win_lc = 0
  call win_execute(l:winid, 'call vimtoria#ui#_capture_lc()')
  return s:win_lc
endfunction

function! vimtoria#ui#screen_name(screen) abort
  return vimtoria#i18n#t('scr_' . a:screen)
endfunction

function! vimtoria#ui#bufnr() abort
  return s:bufnr
endfunction

function! vimtoria#ui#focus_existing() abort
  if s:bufnr == -1 || !bufexists(s:bufnr)
    return 0
  endif
  let l:win = bufwinnr(s:bufnr)
  if l:win != -1
    execute l:win . 'wincmd w'
  else
    execute 'buffer' s:bufnr
  endif
  return 1
endfunction

function! vimtoria#ui#open() abort
  enew
  let s:bufnr = bufnr('%')
  setlocal buftype=nofile bufhidden=hide noswapfile nobuflisted
  setlocal nonumber norelativenumber nolist nowrap nomodifiable
  setlocal signcolumn=no filetype=vimtoria
  silent! execute 'file vimtoria://game'
  " マップのクリック選択のためにマウスを有効化(終了時に復元する)
  let s:saved_mouse = &mouse
  set mouse=a
  let s:last_screen = ''
  let s:map_view = {}
  call s:set_keymaps()
  call vimtoria#ui#apply_matches()
  let s:match_sig = s:matches_sig(vimtoria#core#state())
  augroup vimtoria_ui
    autocmd! * <buffer>
    autocmd BufWipeout <buffer> call vimtoria#ui#restore_mouse()
          \ | call vimtoria#popup#hide()
          \ | call vimtoria#core#shutdown()
    " 地図の横スクロールが端に達したら反対側の世界コピーへ巻き戻す
    if exists('##WinScrolled')
      autocmd WinScrolled <buffer> call vimtoria#ui#on_scroll()
    endif
  augroup END
  call vimtoria#ui#render()
endfunction

function! vimtoria#ui#save_map_view() abort
  let s:map_view = winsaveview()
endfunction

function! vimtoria#ui#restore_map_view() abort
  if !empty(s:map_view)
    call winrestview(s:map_view)
  endif
endfunction

" 地図のループスクロール: バッファには世界が 2 周分描かれている。
" leftcol が 1 周目の左端(0)や右端(200 超)に達したら、見た目が同一の
" 反対側のコピーへ leftcol とカーソルを 1 周分ずらす。ユーザーには
" 継ぎ目が見えず、右(左)へスクロールし続けると地球を一周して戻る
function! vimtoria#ui#on_scroll() abort
  if s:in_render || s:normalizing || s:bufnr == -1 || bufwinid(s:bufnr) == -1
        \ || !vimtoria#core#running()
    return
  endif
  if vimtoria#core#state().screen !=# 'map'
    return
  endif
  " 巻き戻しと固定行(ヘッダ・フッタ)の字下げ調整のため描き直す
  call vimtoria#ui#render()
endfunction

function! s:normalize_scroll() abort
  if s:normalizing || bufwinid(s:bufnr) == -1
    return
  endif
  let s:normalizing = 1
  call win_execute(bufwinid(s:bufnr), 'call vimtoria#ui#_normalize_in_win()')
  let s:normalizing = 0
endfunction

function! vimtoria#ui#_normalize_in_win() abort
  let l:v = winsaveview()
  let l:shift = l:v.leftcol > s:MAP_W ? -1 : (l:v.leftcol < 1 ? 1 : 0)
  if l:shift == 0
    return
  endif
  " カーソルも同じ見た目の位置(もう一方のコピー)へ移す。
  " 地図の行の上にいないときは巻き戻せないので何もしない
  let l:rb = vimtoria#screens#map#row_bytes(l:v.lnum - 4)
  if l:rb <= 0
    return
  endif
  let l:col = l:v.col + l:shift * l:rb
  if l:col < 0 || l:col >= 2 * l:rb
    return
  endif
  call winrestview({'lnum': l:v.lnum, 'col': l:col, 'topline': l:v.topline,
        \ 'leftcol': l:v.leftcol + l:shift * s:MAP_W})
endfunction

" プレイヤーの首都が画面中央に来るように地図をスクロールする
" (ゲーム開始時・国選択時に呼ばれる)
function! vimtoria#ui#center_map() abort
  if s:bufnr == -1 || bufwinid(s:bufnr) == -1
    return
  endif
  let l:st = vimtoria#core#state()
  if l:st.screen !=# 'map'
    return
  endif
  let l:cap = vimtoria#data#map().countries[l:st.country].capital
  let l:pos = vimtoria#screens#map#label_pos(l:cap)
  if empty(l:pos)
    return
  endif
  let l:winid = bufwinid(s:bufnr)
  let l:center = (l:pos[3] + l:pos[4]) / 2
  let l:lc = l:center - winwidth(l:winid) / 2
  while l:lc < 1
    let l:lc += s:MAP_W
  endwhile
  if l:lc > s:MAP_W
    let l:lc -= s:MAP_W
  endif
  " 首都ラベルが見える側の世界コピーにカーソルを置く
  let l:col = l:pos[1]
  if l:center < l:lc
    let l:col += vimtoria#screens#map#row_bytes(l:pos[0])
  endif
  call win_execute(l:winid, printf(
        \ 'call winrestview({"lnum": %d, "col": %d, "leftcol": %d, "topline": 1})',
        \ l:pos[0] + 4, l:col, l:lc))
  call win_execute(l:winid, 'call vimtoria#ui#save_map_view()')
endfunction

function! vimtoria#ui#restore_mouse() abort
  if s:saved_mouse isnot v:null
    let &mouse = s:saved_mouse
    let s:saved_mouse = v:null
  endif
endfunction

function! vimtoria#ui#close() abort
  call vimtoria#popup#hide()
  if s:bufnr != -1 && bufexists(s:bufnr)
    execute 'bwipeout!' s:bufnr
  endif
  let s:bufnr = -1
endfunction

" 州名ハイライトの再適用が必要になる状態のシグネチャ
" (併合で所有権が変わる、言語が変わる、選択州が変わる)
function! s:matches_sig(st) abort
  return printf('%d:%s:%s',
        \ a:st.world.map_version, vimtoria#i18n#lang(), a:st.selected)
endfunction

function! vimtoria#ui#render() abort
  if s:in_render
    return
  endif
  let s:in_render = 1
  try
    call s:render_impl()
  finally
    let s:in_render = 0
  endtry
endfunction

function! s:render_impl() abort
  if s:bufnr == -1 || !bufexists(s:bufnr) || bufwinnr(s:bufnr) == -1
    return
  endif
  let l:st = vimtoria#core#state()
  let l:sig = s:matches_sig(l:st)
  if l:sig !=# s:match_sig
    call win_execute(bufwinid(s:bufnr), 'call vimtoria#ui#apply_matches()')
    let s:match_sig = l:sig
  endif
  " 画面の切り替え時にスクロール位置を整える。地図は横 200 桁あるので、
  " 右へスクロールしたままサブ画面を開くと画面が見切れてしまう。
  " 地図 → サブ画面: 地図の表示位置を保存して左上へリセット
  " サブ画面 → 地図: 保存しておいた表示位置に戻す
  " (保存はバッファを書き換える前に行う。書き換えで leftcol が失われるため)
  let l:screen_changed = l:st.screen !=# s:last_screen
  if l:screen_changed && s:last_screen ==# 'map'
    call win_execute(bufwinid(s:bufnr), 'call vimtoria#ui#save_map_view()')
  endif
  " 地図の固定行の字下げに使う現在の水平スクロール位置
  if l:st.screen ==# 'map' && !l:screen_changed
    let s:cur_leftcol = s:win_leftcol()
  endif
  let l:lines = vimtoria#ui#build_lines(l:st)
  call setbufvar(s:bufnr, '&modifiable', 1)
  call setbufline(s:bufnr, 1, l:lines)
  silent! call deletebufline(s:bufnr, len(l:lines) + 1, '$')
  call setbufvar(s:bufnr, '&modifiable', 0)
  if l:screen_changed
    let l:winid = bufwinid(s:bufnr)
    if l:st.screen ==# 'map'
      call win_execute(l:winid, 'call vimtoria#ui#restore_map_view()')
    else
      call win_execute(l:winid,
            \ 'call winrestview({"lnum": 1, "col": 0, "leftcol": 0, "topline": 1})')
    endif
    let s:last_screen = l:st.screen
  endif
  " メニュー画面ではカーソルを選択行(> 印)へ移す。技術ツリーのような
  " 画面より長いリストでも、Vim のスクロールで選択行が常に見える
  if l:st.screen !=# 'map'
    let l:i = 0
    for l:line in l:lines
      let l:i += 1
      if l:line =~# '^  > '
        call win_execute(bufwinid(s:bufnr), 'call cursor(' . l:i . ', 1)')
        break
      endif
    endfor
  endif
  " 世界地図では、端に達したスクロールを巻き戻し、フッタの字下げが
  " ビュー確定後の位置とずれていれば組み直してから、概況を表示する
  if l:st.screen ==# 'map'
    call s:normalize_scroll()
    let l:lc = s:win_leftcol()
    if l:lc != s:cur_leftcol
      let s:cur_leftcol = l:lc
      let l:lines = vimtoria#ui#build_lines(l:st)
      call setbufvar(s:bufnr, '&modifiable', 1)
      call setbufline(s:bufnr, 1, l:lines)
      silent! call deletebufline(s:bufnr, len(l:lines) + 1, '$')
      call setbufvar(s:bufnr, '&modifiable', 0)
    endif
    call vimtoria#popup#update(s:bufnr, l:st)
  else
    call vimtoria#popup#hide()
  endif
  redraw
endfunction

function! vimtoria#ui#build_lines(st) abort
  " 地図画面では、右へスクロールしていてもヘッダ・ヒントが読めるよう
  " 現在の水平スクロール位置まで字下げする(フッタは screens/map が行う)
  let l:ind = a:st.screen ==# 'map' ? repeat(' ', s:cur_leftcol) : ''
  let l:lines = [l:ind . s:header_line(a:st), l:ind . s:hint_line(a:st), '']
  if a:st.screen ==# 'map'
    call extend(l:lines, vimtoria#screens#map#render(a:st))
  elseif a:st.screen ==# 'state'
    call extend(l:lines, vimtoria#screens#state#render(a:st))
  elseif a:st.screen ==# 'market'
    call extend(l:lines, vimtoria#screens#market#render(a:st))
  elseif a:st.screen ==# 'construction'
    call extend(l:lines, vimtoria#screens#construction#render(a:st))
  elseif a:st.screen ==# 'budget'
    call extend(l:lines, vimtoria#screens#budget#render(a:st))
  elseif a:st.screen ==# 'tech'
    call extend(l:lines, vimtoria#screens#tech#render(a:st))
  elseif a:st.screen ==# 'pops'
    call extend(l:lines, vimtoria#screens#pops#render(a:st))
  elseif a:st.screen ==# 'ranking'
    call extend(l:lines, vimtoria#screens#ranking#render(a:st))
  elseif a:st.screen ==# 'politics'
    call extend(l:lines, vimtoria#screens#politics#render(a:st))
  elseif a:st.screen ==# 'diplo'
    call extend(l:lines, vimtoria#screens#diplo#render(a:st))
  elseif a:st.screen ==# 'military'
    call extend(l:lines, vimtoria#screens#military#render(a:st))
  elseif a:st.screen ==# 'select'
    call extend(l:lines, vimtoria#screens#select#render(a:st))
  elseif a:st.screen ==# 'lang'
    call extend(l:lines, vimtoria#screens#lang#render(a:st))
  else
    call extend(l:lines, vimtoria#screens#todo#render(a:st))
  endif
  return l:lines
endfunction

" 表示幅(全角=2)で右パディング
function! vimtoria#ui#pad(str, width) abort
  let l:fill = a:width - strdisplaywidth(a:str)
  return l:fill > 0 ? a:str . repeat(' ', l:fill) : a:str
endfunction

function! vimtoria#ui#fmt_num(n) abort
  return s:fmt_num(a:n)
endfunction

function! s:header_line(st) abort
  if a:st.paused
    let l:speed = vimtoria#i18n#t('hdr_paused')
  else
    let l:speed = repeat('▶', a:st.speed)
          \ . printf(vimtoria#i18n#t('hdr_speed'), a:st.speed)
  endif
  return printf(vimtoria#i18n#t('hdr_fmt'),
        \ vimtoria#core#date_str(a:st.day)
        \   . printf(vimtoria#i18n#t('hdr_hour'), get(a:st, 'hour', 0)),
        \ l:speed,
        \ s:fmt_num(a:st.treasury),
        \ vimtoria#ui#screen_name(a:st.screen))
endfunction

function! s:hint_line(st) abort
  if index(['map', 'construction', 'budget', 'tech', 'politics',
        \   'diplo', 'military', 'select', 'lang'], a:st.screen) >= 0
    return vimtoria#i18n#t('hint_' . a:st.screen)
  endif
  return vimtoria#i18n#t('hint_default')
endfunction

function! s:fmt_num(n) abort
  let l:out = printf('%d', a:n)
  while 1
    let l:new = substitute(l:out, '^\(-\?\d\+\)\(\d\{3}\)', '\1,\2', '')
    if l:new ==# l:out
      break
    endif
    let l:out = l:new
  endwhile
  return l:out
endfunction

function! s:set_keymaps() abort
  let l:maps = {
        \ '<Space>': 'pause',
        \ '1': 'speed_1', '2': 'speed_2', '3': 'speed_3', '4': 'speed_4',
        \ 'h': 'nav_h', 'j': 'nav_j', 'k': 'nav_k', 'l': 'nav_l',
        \ '<CR>': 'open_state',
        \ 'gm': 'screen_market', 'gb': 'screen_budget',
        \ 'gc': 'screen_construction', 'gt': 'screen_tech',
        \ 'gp': 'screen_pops', 'gr': 'screen_ranking',
        \ 'gv': 'screen_politics', 'gd': 'screen_diplo', 'ga': 'screen_military',
        \ 'x': 'cancel',
        \ '+': 'tax_up', '=': 'tax_up', '-': 'tax_down',
        \ 'i': 'dip_improve', 'a': 'dip_alliance',
        \ 'w': 'dip_war', 'p': 'dip_peace',
        \ 'r': 'mil_recruit', 'd': 'mil_disband',
        \ 'R': 'navy_recruit', 'D': 'navy_disband',
        \ 'v': 'popup_toggle',
        \ 'S': 'save', 'L': 'load',
        \ 'q': 'back',
        \ '<Esc>': 'to_map',
        \ }
  for [l:key, l:act] in items(l:maps)
    execute printf('nnoremap <buffer> <silent> <nowait> %s :<C-u>call vimtoria#core#action(%s)<CR>',
          \ l:key, string(l:act))
  endfor
  " マウス: マップ上のクリックで州を選択
  nnoremap <buffer> <silent> <LeftMouse> :<C-u>call vimtoria#core#click()<CR>
  nnoremap <buffer> <silent> <2-LeftMouse> :<C-u>call vimtoria#core#click()<CR>
  nnoremap <buffer> <silent> <LeftDrag> <Nop>
  nnoremap <buffer> <silent> <LeftRelease> <Nop>
  " 編集系キーは誤爆防止のため無効化(R は海軍徴募に使う)
  for l:key in ['I', 'A', 'o', 'O', 'c', 'C', 's']
    execute 'nnoremap <buffer> <nowait> ' . l:key . ' <Nop>'
  endfor
endfunction

" 州名ラベルの国別カラーリング。パターンは現在の言語の州名で、
" 所有権(world.owner)に従って張り直す(併合・言語切替・選択変更で再適用)
function! vimtoria#ui#apply_matches() abort
  call clearmatches()
  let l:data = vimtoria#data#map()
  let l:st = vimtoria#core#state()
  let l:world = l:st.world
  for [l:cid, l:country] in items(l:data.countries)
    let l:names = []
    for l:sid in l:world.country_states[l:cid]
      call add(l:names, escape(vimtoria#i18n#name(l:data.states[l:sid]), '\'))
    endfor
    if !empty(l:names)
      call matchadd(l:country.hl,
            \ '\V\<\(' . join(l:names, '\|') . '\)\>', 10)
    endif
  endfor
  " 選択中の州([州名] と表示される)の強調
  call matchadd('VimtoriaSelected',
        \ '\V[' . escape(vimtoria#i18n#name(l:data.states[l:st.selected]), '\') . ']',
        \ 20)
endfunction
