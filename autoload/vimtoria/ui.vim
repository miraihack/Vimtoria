scriptencoding utf-8
" ui.vim - バッファ/ウィンドウ管理と描画フレームワーク
" 描画は「状態 → 行リスト」の純関数(build_lines)と、その結果を
" setbufline で反映する render に分かれる。

let s:bufnr = -1
let s:match_sig = ''
let s:saved_mouse = v:null

function! vimtoria#ui#screen_name(screen) abort
  return vimtoria#i18n#t('scr_' . a:screen)
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
  call s:set_keymaps()
  call vimtoria#ui#apply_matches()
  let s:match_sig = s:matches_sig(vimtoria#core#state())
  augroup vimtoria_ui
    autocmd! * <buffer>
    autocmd BufWipeout <buffer> call vimtoria#ui#restore_mouse()
          \ | call vimtoria#popup#hide()
          \ | call vimtoria#core#shutdown()
  augroup END
  call vimtoria#ui#render()
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
  if s:bufnr == -1 || !bufexists(s:bufnr) || bufwinnr(s:bufnr) == -1
    return
  endif
  let l:st = vimtoria#core#state()
  let l:sig = s:matches_sig(l:st)
  if l:sig !=# s:match_sig
    call win_execute(bufwinid(s:bufnr), 'call vimtoria#ui#apply_matches()')
    let s:match_sig = l:sig
  endif
  let l:lines = vimtoria#ui#build_lines(l:st)
  call setbufvar(s:bufnr, '&modifiable', 1)
  call setbufline(s:bufnr, 1, l:lines)
  silent! call deletebufline(s:bufnr, len(l:lines) + 1, '$')
  call setbufvar(s:bufnr, '&modifiable', 0)
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
  " 世界地図では選択中の州の所有国の概況をポップアップ表示する
  if l:st.screen ==# 'map'
    call vimtoria#popup#update(s:bufnr, l:st)
  else
    call vimtoria#popup#hide()
  endif
  redraw
endfunction

function! vimtoria#ui#build_lines(st) abort
  let l:lines = [s:header_line(a:st), s:hint_line(a:st), '']
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
        \ vimtoria#core#date_str(a:st.day),
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
  " 編集系キーは誤爆防止のため無効化
  for l:key in ['I', 'A', 'o', 'O', 'R', 'c', 'C', 's']
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
