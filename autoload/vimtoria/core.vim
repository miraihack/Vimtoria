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
        \ 'menu_idx': 0,
        \ 'msg': '',
        \ }
  call vimtoria#econ#init(s:state)
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
  call vimtoria#econ#tick(s:state)
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
  let l:st.msg = ''
  if a:name ==# 'pause'
    let l:st.paused = !l:st.paused
    call s:timer_restart()
  elseif a:name =~# '^speed_[1-4]$'
    let l:st.speed = str2nr(a:name[6:])
    call s:timer_restart()
  elseif a:name =~# '^nav_[hjkl]$'
    if l:st.screen ==# 'map'
      let l:st.selected = vimtoria#map#neighbor(l:st.selected, a:name[4:])
    elseif s:menu_len(l:st) > 0
      " メニュー画面では j/k が項目選択
      let l:n = s:menu_len(l:st)
      if a:name ==# 'nav_j' && l:st.menu_idx < l:n - 1
        let l:st.menu_idx += 1
      elseif a:name ==# 'nav_k' && l:st.menu_idx > 0
        let l:st.menu_idx -= 1
      endif
    endif
  elseif a:name ==# 'open_state'
    if l:st.screen ==# 'map'
      let l:st.screen = 'state'
      let l:st.screen_arg = l:st.selected
    elseif l:st.screen ==# 'construction'
      let l:bid = vimtoria#data#economy().buildings_order[l:st.menu_idx]
      let l:err = vimtoria#build#enqueue(l:st, l:st.selected, l:bid)
      let l:st.msg = empty(l:err)
            \ ? vimtoria#data#economy().buildings[l:bid].name . ' をキューに追加しました'
            \ : l:err
    elseif l:st.screen ==# 'tech'
      let l:data = vimtoria#data#tech()
      let l:tid = l:data.order[l:st.menu_idx]
      let l:err = vimtoria#tech#start(l:st.world, l:st.country, l:tid)
      let l:st.msg = empty(l:err)
            \ ? l:data.techs[l:tid].name . ' の研究を開始しました'
            \ : l:err
    elseif l:st.screen ==# 'politics'
      let l:data = vimtoria#data#politics()
      let l:lid = l:data.law_order[l:st.menu_idx]
      let l:err = vimtoria#politics#start_enact(l:st.world, l:st.country, l:lid)
      let l:st.msg = empty(l:err)
            \ ? l:data.laws[l:lid].name . ' の制定を開始しました'
            \ : l:err
    endif
  elseif a:name =~# '^dip_'
    if l:st.screen ==# 'diplo'
      call s:diplo_action(l:st, a:name)
    endif
  elseif a:name ==# 'mil_recruit' || a:name ==# 'mil_disband'
    if l:st.screen ==# 'military'
      let l:err = a:name ==# 'mil_recruit'
            \ ? vimtoria#war#recruit(l:st.world, l:st.country)
            \ : vimtoria#war#disband(l:st.world, l:st.country)
      let l:st.msg = empty(l:err)
            \ ? (a:name ==# 'mil_recruit' ? '5個連隊を徴募しました' : '5個連隊を解散しました')
            \ : l:err
    endif
  elseif a:name ==# 'cancel'
    if l:st.screen ==# 'construction'
      let l:err = vimtoria#build#cancel_last(l:st)
      let l:st.msg = empty(l:err) ? '末尾のキュー項目を取り消しました' : l:err
    endif
  elseif a:name ==# 'tax_up' || a:name ==# 'tax_down'
    if l:st.screen ==# 'budget'
      let l:eco = vimtoria#data#economy()
      let l:rate = l:st.world.tax_rates[l:st.country]
      let l:rate += a:name ==# 'tax_up' ? l:eco.const.tax_step : -l:eco.const.tax_step
      " 上限は税制の法律で決まる(地租 15% / 所得税 30%)
      let l:max = l:st.world.law_mods[l:st.country].tax_max
      if l:rate > l:max
        let l:rate = l:max
        let l:st.msg = printf('現行の税制では %.0f%% が上限です(gv で税制を変更)',
              \ l:max * 100.0)
      elseif l:rate < l:eco.const.tax_min
        let l:rate = l:eco.const.tax_min
      endif
      let l:st.world.tax_rates[l:st.country] = l:rate
    endif
  elseif a:name ==# 'save'
    call vimtoria#core#save()
  elseif a:name ==# 'load'
    if confirm('セーブデータをロードしますか?(現在の進行は失われます)',
          \ "&Yes\n&No", 2) == 1
      call vimtoria#core#load()
    endif
  elseif a:name =~# '^screen_'
    let l:st.screen = a:name[7:]
    let l:st.screen_arg = ''
    let l:st.menu_idx = 0
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

function! s:save_file() abort
  return expand(get(g:, 'vimtoria_save_file', '~/.vimtoria_save.json'))
endfunction

" JSON でセーブ(ゲーム状態はすべて JSON 安全な型でできている)
function! vimtoria#core#save() abort
  let l:st = vimtoria#core#state()
  try
    call writefile([json_encode({'version': 1, 'state': l:st})], s:save_file())
    let l:st.msg = 'セーブしました: ' . s:save_file()
    return 1
  catch
    let l:st.msg = 'セーブに失敗しました: ' . v:exception
    return 0
  endtry
endfunction

function! vimtoria#core#load() abort
  let l:file = s:save_file()
  let l:st = vimtoria#core#state()
  if !filereadable(l:file)
    let l:st.msg = 'セーブデータがありません: ' . l:file
    return 0
  endif
  try
    let l:data = json_decode(join(readfile(l:file), ''))
  catch
    let l:st.msg = 'セーブデータを読み込めません: ' . v:exception
    return 0
  endtry
  if type(l:data) != v:t_dict || get(l:data, 'version', 0) != 1
        \ || !has_key(l:data, 'state')
    let l:st.msg = 'セーブデータの形式が不正です'
    return 0
  endif
  let s:state = l:data.state
  let s:state.paused = 1
  let s:state.screen = 'map'
  let s:state.msg = 'ロードしました(停止中): ' . vimtoria#core#date_str(s:state.day)
  call s:timer_restart()
  return 1
endfunction

" 画面ごとのメニュー項目数(0 ならメニュー無し)
function! s:menu_len(st) abort
  if a:st.screen ==# 'construction'
    return len(vimtoria#data#economy().buildings_order)
  elseif a:st.screen ==# 'tech'
    return len(vimtoria#data#tech().order)
  elseif a:st.screen ==# 'politics'
    return len(vimtoria#data#politics().law_order)
  elseif a:st.screen ==# 'diplo'
    return len(vimtoria#core#diplo_targets(a:st))
  endif
  return 0
endfunction

" 外交画面の相手国リスト(自国を除いた固定順)
function! vimtoria#core#diplo_targets(st) abort
  return filter(copy(vimtoria#data#map().country_order),
        \ 'v:val !=# a:st.country')
endfunction

function! s:diplo_action(st, name) abort
  let l:targets = vimtoria#core#diplo_targets(a:st)
  let l:other = l:targets[a:st.menu_idx]
  let l:map = vimtoria#data#map()
  let l:world = a:st.world
  if a:name ==# 'dip_improve'
    let l:err = vimtoria#diplo#improve(l:world, a:st.country, l:other, a:st.day)
    let a:st.msg = empty(l:err)
          \ ? l:map.countries[l:other].name . ' との関係を改善しました'
          \ : l:err
  elseif a:name ==# 'dip_alliance'
    let l:was = vimtoria#diplo#allied(l:world, a:st.country, l:other)
    let l:err = vimtoria#diplo#toggle_alliance(l:world, a:st.country, l:other)
    let a:st.msg = empty(l:err)
          \ ? l:map.countries[l:other].name
          \   . (l:was ? ' との同盟を破棄しました' : ' と同盟を結びました')
          \ : l:err
  elseif a:name ==# 'dip_war'
    " 奪取目標: マップで選択中の州が相手領ならそこ、でなければ相手の最弱州
    let l:goal = l:world.owner[a:st.selected] ==# l:other
          \ ? a:st.selected : s:weakest_of(l:world, l:other)
    if empty(l:goal)
      let a:st.msg = '相手国に州がありません'
      return
    endif
    let l:err = vimtoria#diplo#declare_war(l:world, a:st.country, l:other,
          \ l:goal, a:st.day, a:st.country)
    let a:st.msg = empty(l:err)
          \ ? printf('%s に宣戦布告(目標: %s)',
          \          l:map.countries[l:other].name, l:map.states[l:goal].name)
          \ : l:err
  elseif a:name ==# 'dip_peace'
    let l:err = vimtoria#diplo#white_peace(l:world, a:st.country, l:other, a:st.day)
    let a:st.msg = empty(l:err) ? '白紙和平が成立しました' : l:err
  endif
endfunction

function! s:weakest_of(world, cid) abort
  let l:best = ''
  let l:min = 1.0e18
  for l:sid in a:world.country_states[a:cid]
    if a:world.workforce[l:sid] < l:min
      let l:min = a:world.workforce[l:sid]
      let l:best = l:sid
    endif
  endfor
  return l:best
endfunction

function! vimtoria#core#quit() abort
  if confirm('Vimtoria を終了しますか?(S でセーブできます)', "&Yes\n&No", 2) != 1
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
