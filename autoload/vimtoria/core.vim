scriptencoding utf-8
" core.vim - ゲームループ・時間・状態ストア
" ゲーム状態はこのスクリプトの s:state 一箇所で管理し、他モジュールは
" vimtoria#core#state() 経由で読む。書き換えは action() を通す。

let s:MONTH_DAYS = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
let s:START_YEAR = 1836
" 速度 → 1ティック(=ゲーム内1週間)のミリ秒
let s:SPEED_MS = {1: 2000, 2: 1000, 3: 500, 4: 250}

let s:state = {}
let s:timer = -1

function! vimtoria#core#init() abort
  let l:data = vimtoria#data#map()
  let l:player = get(g:, 'vimtoria_player_country', 'JAP')
  if !has_key(l:data.countries, l:player)
    let l:player = 'JAP'
  endif
  let s:state = {
        \ 'day': 0,
        \ 'paused': 1,
        \ 'speed': 2,
        \ 'screen': 'map',
        \ 'screen_arg': '',
        \ 'selected': l:data.countries[l:player].capital,
        \ 'country': l:player,
        \ 'treasury': 10000,
        \ }
endfunction

function! vimtoria#core#state() abort
  if empty(s:state)
    call vimtoria#core#init()
  endif
  return s:state
endfunction

function! vimtoria#core#start() abort
  if !empty(s:state) && vimtoria#ui#focus_existing()
    call vimtoria#ui#render()
    return
  endif
  call vimtoria#core#init()
  call vimtoria#ui#open()
endfunction

" 1ティック = ゲーム内1週間
function! vimtoria#core#tick() abort
  let s:state.day += 7
  " M1: ここに週次の経済更新フックが入る
  call vimtoria#ui#render()
endfunction

" 経過日数 → {year, month, day}(うるう年なしの365日暦)
function! vimtoria#core#date(day) abort
  let l:year = s:START_YEAR + a:day / 365
  let l:rest = a:day % 365
  let l:month = 0
  while l:rest >= s:MONTH_DAYS[l:month]
    let l:rest -= s:MONTH_DAYS[l:month]
    let l:month += 1
  endwhile
  return {'year': l:year, 'month': l:month + 1, 'day': l:rest + 1}
endfunction

function! vimtoria#core#date_str(day) abort
  let l:d = vimtoria#core#date(a:day)
  return printf('%d年%2d月%2d日', l:d.year, l:d.month, l:d.day)
endfunction

function! vimtoria#core#speed_ms(speed) abort
  return s:SPEED_MS[a:speed]
endfunction

" キー入力はすべてここに集約される
function! vimtoria#core#action(name) abort
  let l:st = vimtoria#core#state()
  if a:name ==# 'pause'
    let l:st.paused = !l:st.paused
    call s:timer_restart()
  elseif a:name =~# '^speed_[1-4]$'
    let l:st.speed = str2nr(a:name[6:])
    call s:timer_restart()
  elseif a:name =~# '^nav_[hjkl]$'
    if l:st.screen ==# 'map'
      let l:st.selected = vimtoria#map#neighbor(l:st.selected, a:name[4:])
    endif
  elseif a:name ==# 'open_state'
    if l:st.screen ==# 'map'
      let l:st.screen = 'state'
      let l:st.screen_arg = l:st.selected
    endif
  elseif a:name =~# '^screen_'
    let l:st.screen = a:name[7:]
    let l:st.screen_arg = ''
  elseif a:name ==# 'back'
    if l:st.screen ==# 'map'
      call vimtoria#core#quit()
      return
    endif
    let l:st.screen = 'map'
    let l:st.screen_arg = ''
  endif
  call vimtoria#ui#render()
endfunction

function! vimtoria#core#quit() abort
  if confirm('Vimtoria を終了しますか?(M0 ではセーブされません)', "&Yes\n&No", 2) != 1
    return
  endif
  call vimtoria#ui#close()
endfunction

" バッファ破棄時にも呼ばれる後始末(冪等)
function! vimtoria#core#shutdown() abort
  call s:timer_stop()
  let s:state = {}
endfunction

function! s:timer_stop() abort
  if s:timer != -1
    call timer_stop(s:timer)
    let s:timer = -1
  endif
endfunction

function! s:timer_restart() abort
  call s:timer_stop()
  if !empty(s:state) && !s:state.paused
    let s:timer = timer_start(s:SPEED_MS[s:state.speed],
          \ function('s:on_timer'), {'repeat': -1})
  endif
endfunction

function! s:on_timer(timer) abort
  call vimtoria#core#tick()
endfunction
