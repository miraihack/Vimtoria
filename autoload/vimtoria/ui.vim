scriptencoding utf-8
" ui.vim - バッファ/ウィンドウ管理と描画フレームワーク
" 描画は「状態 → 行リスト」の純関数(build_lines)と、その結果を
" setbufline で反映する render に分かれる。

let s:bufnr = -1

let s:SCREEN_NAMES = {
      \ 'map': '世界地図',
      \ 'state': '州情報',
      \ 'market': '市場',
      \ 'budget': '予算',
      \ 'construction': '建設',
      \ 'tech': '技術',
      \ 'pops': 'Pop',
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
  call s:set_matches()
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
  let l:lines = vimtoria#ui#build_lines(vimtoria#core#state())
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
    return ' Space:停止/再開 1-4:速度 hjkl:州を選択 Enter:州情報'
          \ . ' gm:市場 gb:予算 gc:建設 gt:技術 gp:Pop q:終了'
  elseif a:st.screen ==# 'construction'
    return ' j/k:建物を選択 Enter:キューへ追加 x:末尾を取消 Space:停止/再開 q:マップへ戻る'
  elseif a:st.screen ==# 'budget'
    return ' +/-:税率を変更 Space:停止/再開 1-4:速度 q:マップへ戻る'
  elseif a:st.screen ==# 'tech'
    return ' j/k:技術を選択 Enter:研究開始 Space:停止/再開 q:マップへ戻る'
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
        \ 'gp': 'screen_pops',
        \ 'x': 'cancel',
        \ '+': 'tax_up', '=': 'tax_up', '-': 'tax_down',
        \ 'q': 'back',
        \ }
  for [l:key, l:act] in items(l:maps)
    execute printf('nnoremap <buffer> <silent> <nowait> %s :<C-u>call vimtoria#core#action(%s)<CR>',
          \ l:key, string(l:act))
  endfor
  " 編集系キーは誤爆防止のため無効化
  for l:key in ['i', 'I', 'a', 'A', 'o', 'O', 'R', 'c', 'C', 's', 'S']
    execute 'nnoremap <buffer> <nowait> ' . l:key . ' <Nop>'
  endfor
endfunction

" 国ごとの州タグ色はデータ駆動なので、syntax ではなく matchadd で付ける
function! s:set_matches() abort
  let l:data = vimtoria#data#map()
  for [l:cid, l:country] in items(l:data.countries)
    let l:tags = []
    for [l:sid, l:stt] in items(l:data.states)
      if l:stt.country ==# l:cid
        call add(l:tags, l:sid)
      endif
    endfor
    if !empty(l:tags)
      call matchadd(l:country.hl, '\v<(' . join(l:tags, '|') . ')>', 10)
    endif
  endfor
  call matchadd('VimtoriaSelected', '\[\u\{3}\]', 20)
endfunction
