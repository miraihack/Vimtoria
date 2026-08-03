scriptencoding utf-8
" ui.vim - バッファ/ウィンドウ管理と描画フレームワーク
" 描画は「状態 → 行リスト」の純関数(build_lines)と、その結果を
" setbufline で反映する render に分かれる。

let s:bufnr = -1
let s:match_version = -1

let s:SCREEN_NAMES = {
      \ 'map': '世界地図',
      \ 'state': '州情報',
      \ 'market': '市場',
      \ 'budget': '予算',
      \ 'construction': '建設',
      \ 'tech': '技術',
      \ 'pops': 'Pop',
      \ 'ranking': '列強ランキング',
      \ 'politics': '政治',
      \ 'diplo': '外交',
      \ 'military': '軍事',
      \ }

function! vimtoria#ui#screen_name(screen) abort
  return get(s:SCREEN_NAMES, a:screen, a:screen)
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
  call s:set_keymaps()
  call vimtoria#ui#apply_matches()
  let s:match_version = vimtoria#core#state().world.map_version
  augroup vimtoria_ui
    autocmd! * <buffer>
    autocmd BufWipeout <buffer> call vimtoria#core#shutdown()
  augroup END
  call vimtoria#ui#render()
endfunction

function! vimtoria#ui#close() abort
  if s:bufnr != -1 && bufexists(s:bufnr)
    execute 'bwipeout!' s:bufnr
  endif
  let s:bufnr = -1
endfunction

function! vimtoria#ui#render() abort
  if s:bufnr == -1 || !bufexists(s:bufnr) || bufwinnr(s:bufnr) == -1
    return
  endif
  let l:st = vimtoria#core#state()
  " 併合などで所有権が変わっていたら国色を再適用
  if l:st.world.map_version != s:match_version
    call win_execute(bufwinid(s:bufnr), 'call vimtoria#ui#apply_matches()')
    let s:match_version = l:st.world.map_version
  endif
  let l:lines = vimtoria#ui#build_lines(l:st)
  call setbufvar(s:bufnr, '&modifiable', 1)
  call setbufline(s:bufnr, 1, l:lines)
  silent! call deletebufline(s:bufnr, len(l:lines) + 1, '$')
  call setbufvar(s:bufnr, '&modifiable', 0)
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
    let l:speed = '❚❚ 停止中'
  else
    let l:speed = repeat('▶', a:st.speed) . printf(' 速度%d', a:st.speed)
  endif
  return printf(' VIMTORIA ┃ %s ┃ %s ┃ 国庫 £%s ┃ %s',
        \ vimtoria#core#date_str(a:st.day),
        \ l:speed,
        \ s:fmt_num(a:st.treasury),
        \ vimtoria#ui#screen_name(a:st.screen))
endfunction

function! s:hint_line(st) abort
  if a:st.screen ==# 'map'
    return ' Space:停止 1-4:速度 hjkl/Enter:州 gm:市場 gb:予算 gc:建設 gt:技術'
          \ . ' gv:政治 gd:外交 ga:軍事 gp:Pop gr:列強 S:セーブ L:ロード q:終了'
  elseif a:st.screen ==# 'construction'
    return ' j/k:建物を選択 Enter:キューへ追加 x:末尾を取消 Space:停止/再開 q:マップへ戻る'
  elseif a:st.screen ==# 'budget'
    return ' +/-:税率を変更 Space:停止/再開 1-4:速度 q:マップへ戻る'
  elseif a:st.screen ==# 'tech'
    return ' j/k:技術を選択 Enter:研究開始 Space:停止/再開 q:マップへ戻る'
  elseif a:st.screen ==# 'politics'
    return ' j/k:法律を選択 Enter:制定開始 Space:停止/再開 q:マップへ戻る'
  elseif a:st.screen ==# 'diplo'
    return ' j/k:国を選択 i:関係改善 a:同盟/破棄 w:宣戦布告 p:白紙和平 q:マップへ戻る'
  elseif a:st.screen ==# 'military'
    return ' r:徴募(+5連隊) d:解散(-5連隊) Space:停止/再開 q:マップへ戻る'
  endif
  return ' Space:停止/再開 1-4:速度 q:マップへ戻る'
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
        \ 'S': 'save', 'L': 'load',
        \ 'q': 'back',
        \ }
  for [l:key, l:act] in items(l:maps)
    execute printf('nnoremap <buffer> <silent> <nowait> %s :<C-u>call vimtoria#core#action(%s)<CR>',
          \ l:key, string(l:act))
  endfor
  " 編集系キーは誤爆防止のため無効化
  for l:key in ['I', 'A', 'o', 'O', 'R', 'c', 'C', 's']
    execute 'nnoremap <buffer> <nowait> ' . l:key . ' <Nop>'
  endfor
endfunction

" 国ごとの州タグ色は現在の所有権(world.owner)から付ける。
" 併合で所有権が変わると map_version が上がり、render が再適用する
function! vimtoria#ui#apply_matches() abort
  call clearmatches()
  let l:data = vimtoria#data#map()
  let l:world = vimtoria#core#state().world
  for [l:cid, l:country] in items(l:data.countries)
    let l:tags = l:world.country_states[l:cid]
    if !empty(l:tags)
      call matchadd(l:country.hl, '\v<(' . join(l:tags, '|') . ')>', 10)
    endif
  endfor
  call matchadd('VimtoriaSelected', '\[\u\{3}\]', 20)
endfunction
