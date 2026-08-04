scriptencoding utf-8
" core.vim - ゲームループ・時間・状態ストア
" ゲーム状態はこのスクリプトの s:state 一箇所で管理し、他モジュールは
" vimtoria#core#state() 経由で読む。書き換えは action() を通す。

let s:MONTH_DAYS = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
let s:MONTH_EN = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      \ 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
let s:START_YEAR = 1836
" 速度 → 1ティック(=ゲーム内1週間)のミリ秒
let s:SPEED_MS = {1: 2000, 2: 1000, 3: 500, 4: 250}

" 選択系画面(時間停止・操作制限)と、そこで許可するアクション
let s:PICKER_SCREENS = ['select', 'lang']
let s:PICKER_ACTIONS = ['nav_j', 'nav_k', 'open_state', 'back', 'load']

let s:state = {}
let s:timer = -1

function! vimtoria#core#init() abort
  call vimtoria#i18n#init()
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
        \ 'treasury': 0,
        \ 'menu_idx': 0,
        \ 'msg': '',
        \ }
  call vimtoria#econ#init(s:state)
  let s:state.treasury = float2nr(s:state.world.treasuries[l:player])
endfunction

function! vimtoria#core#state() abort
  if empty(s:state)
    call vimtoria#core#init()
  endif
  return s:state
endfunction

" ゲーム状態が存在するか(autocmd からの再初期化を防ぐガード)
function! vimtoria#core#running() abort
  return !empty(s:state)
endfunction

function! vimtoria#core#start() abort
  if !empty(s:state) && vimtoria#ui#focus_existing()
    call vimtoria#ui#render()
    return
  endif
  call vimtoria#core#init()
  " g:vimtoria_lang 未指定なら言語選択、g:vimtoria_player_country 未指定なら
  " 国選択から始める(言語 → 国 → マップの順)
  if !exists('g:vimtoria_lang')
    let s:state.screen = 'lang'
  elseif !exists('g:vimtoria_player_country')
    let s:state.screen = 'select'
  endif
  call vimtoria#ui#open()
  " 国が既に決まっている場合は、首都を中央にしてブリーフィングを表示する
  if s:state.screen ==# 'map'
    call vimtoria#ui#center_map()
    call vimtoria#ui#render()
    call vimtoria#popup#briefing(vimtoria#ui#bufnr(), s:state)
  endif
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
  if vimtoria#i18n#lang() ==# 'en'
    return printf('%s %d, %d', s:MONTH_EN[l:d.month - 1], l:d.day, l:d.year)
  endif
  return printf('%d年%2d月%2d日', l:d.year, l:d.month, l:d.day)
endfunction

function! vimtoria#core#speed_ms(speed) abort
  return s:SPEED_MS[a:speed]
endfunction

" キー入力はすべてここに集約される
function! vimtoria#core#action(name) abort
  let l:st = vimtoria#core#state()
  " 言語/国選択画面では選択操作以外を受け付けない(時間も進めない)
  if index(s:PICKER_SCREENS, l:st.screen) >= 0
        \ && index(s:PICKER_ACTIONS, a:name) < 0
    return
  endif
  " ブリーフィング表示中なら、どのキーでも閉じる
  call vimtoria#popup#dismiss_brief()
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
    if l:st.screen ==# 'lang'
      " 表示言語を決定して国選択へ
      call vimtoria#i18n#set(
            \ vimtoria#screens#lang#choices()[l:st.menu_idx][0])
      let l:st.screen = exists('g:vimtoria_player_country') ? 'map' : 'select'
      let l:st.menu_idx = 0
    elseif l:st.screen ==# 'select'
      " プレイする国を決定。カーソルが国の行にあればその国を優先する
      if bufname('%') ==# 'vimtoria://game'
        let l:ci = vimtoria#screens#select#index_at(line('.'))
        if l:ci >= 0
          let l:st.menu_idx = l:ci
        endif
      endif
      let l:map = vimtoria#data#map()
      let l:cid = l:map.country_order[l:st.menu_idx]
      let l:st.country = l:cid
      let l:st.selected = l:map.countries[l:cid].capital
      let l:st.treasury = float2nr(l:st.world.treasuries[l:cid])
      let l:st.screen = 'map'
      let l:st.menu_idx = 0
      let l:st.msg = printf(vimtoria#i18n#t('msg_play_start'),
            \ vimtoria#i18n#name(l:map.countries[l:cid]))
      " 首都を画面中央にし、その国の置かれている状況をブリーフィング表示する
      call vimtoria#ui#render()
      call vimtoria#ui#center_map()
      call vimtoria#ui#render()
      call vimtoria#popup#briefing(vimtoria#ui#bufnr(), l:st)
      return
    elseif l:st.screen ==# 'map'
      " カーソルが州名ラベルの上ならその州を選択して詳細を開く。
      " それ以外は従来どおり選択中の州の詳細
      let l:hit = ''
      if bufname('%') ==# 'vimtoria://game'
        let l:hit = vimtoria#screens#map#hit(line('.') - 4, col('.') - 1)
      endif
      if !empty(l:hit)
        let l:st.selected = l:hit
      endif
      let l:st.screen = 'state'
      let l:st.screen_arg = l:st.selected
    elseif l:st.screen ==# 'construction'
      let l:bid = vimtoria#data#economy().buildings_order[l:st.menu_idx]
      let l:err = vimtoria#build#enqueue(l:st, l:st.selected, l:bid)
      let l:st.msg = empty(l:err)
            \ ? printf(vimtoria#i18n#t('msg_enqueued'),
            \          vimtoria#i18n#name(vimtoria#data#economy().buildings[l:bid]))
            \ : l:err
    elseif l:st.screen ==# 'tech'
      let l:data = vimtoria#data#tech()
      let l:tid = vimtoria#tech#menu_for(l:st.country)[l:st.menu_idx]
      let l:err = vimtoria#tech#start(l:st.world, l:st.country, l:tid)
      let l:st.msg = empty(l:err)
            \ ? printf(vimtoria#i18n#t('msg_research_started'),
            \          vimtoria#i18n#name(l:data.techs[l:tid]))
            \ : l:err
    elseif l:st.screen ==# 'politics'
      let l:data = vimtoria#data#politics()
      let l:lid = l:data.law_order[l:st.menu_idx]
      let l:err = vimtoria#politics#start_enact(l:st.world, l:st.country, l:lid)
      let l:st.msg = empty(l:err)
            \ ? printf(vimtoria#i18n#t('msg_enact_started'),
            \          vimtoria#i18n#name(l:data.laws[l:lid]))
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
            \ ? vimtoria#i18n#t(a:name ==# 'mil_recruit'
            \                   ? 'msg_recruited' : 'msg_disbanded')
            \ : l:err
    endif
  elseif a:name ==# 'navy_recruit' || a:name ==# 'navy_disband'
    if l:st.screen ==# 'military'
      let l:err = a:name ==# 'navy_recruit'
            \ ? vimtoria#war#recruit_ships(l:st.world, l:st.country)
            \ : vimtoria#war#disband_ships(l:st.world, l:st.country)
      let l:st.msg = empty(l:err)
            \ ? vimtoria#i18n#t(a:name ==# 'navy_recruit'
            \                   ? 'msg_navy_built' : 'msg_navy_scrapped')
            \ : l:err
    endif
  elseif a:name ==# 'cancel'
    if l:st.screen ==# 'construction'
      let l:err = vimtoria#build#cancel_last(l:st)
      let l:st.msg = empty(l:err) ? vimtoria#i18n#t('msg_cancelled') : l:err
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
        let l:st.msg = printf(vimtoria#i18n#t('msg_tax_cap'), l:max * 100.0)
      elseif l:rate < l:eco.const.tax_min
        let l:rate = l:eco.const.tax_min
      endif
      let l:st.world.tax_rates[l:st.country] = l:rate
    endif
  elseif a:name ==# 'popup_toggle'
    call vimtoria#popup#toggle()
  elseif a:name ==# 'save'
    call vimtoria#core#save()
  elseif a:name ==# 'load'
    if confirm(vimtoria#i18n#t('confirm_load'), "&Yes\n&No", 2) == 1
      call vimtoria#core#load()
    endif
  elseif a:name =~# '^screen_'
    let l:st.screen = a:name[7:]
    let l:st.screen_arg = ''
    let l:st.menu_idx = 0
  elseif a:name ==# 'back'
    if l:st.screen ==# 'map' || index(s:PICKER_SCREENS, l:st.screen) >= 0
      call vimtoria#core#quit()
      return
    endif
    let l:st.screen = 'map'
    let l:st.screen_arg = ''
  elseif a:name ==# 'to_map'
    " ESC: どのサブ画面からでも世界地図へ(マップ上では何もしない)
    if l:st.screen !=# 'map'
      let l:st.screen = 'map'
      let l:st.screen_arg = ''
    endif
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
    call writefile([json_encode({'version': 3, 'state': l:st})], s:save_file())
    let l:st.msg = printf(vimtoria#i18n#t('msg_saved'), s:save_file())
    return 1
  catch
    let l:st.msg = printf(vimtoria#i18n#t('msg_save_fail'), v:exception)
    return 0
  endtry
endfunction

function! vimtoria#core#load() abort
  let l:file = s:save_file()
  let l:st = vimtoria#core#state()
  if !filereadable(l:file)
    let l:st.msg = printf(vimtoria#i18n#t('msg_no_save'), l:file)
    return 0
  endif
  try
    let l:data = json_decode(join(readfile(l:file), ''))
  catch
    let l:st.msg = printf(vimtoria#i18n#t('msg_load_fail'), v:exception)
    return 0
  endtry
  if type(l:data) != v:t_dict || get(l:data, 'version', 0) != 3
        \ || !has_key(l:data, 'state')
    let l:st.msg = vimtoria#i18n#t('msg_bad_save')
    return 0
  endif
  let s:state = l:data.state
  let s:state.paused = 1
  let s:state.screen = 'map'
  let s:state.msg = printf(vimtoria#i18n#t('msg_loaded'),
        \ vimtoria#core#date_str(s:state.day))
  call s:timer_restart()
  return 1
endfunction

" マウスクリック(マップ画面のみ)。クリック位置から州を選択し、
" 選択中の州をもう一度クリックすると詳細を開く
function! vimtoria#core#click() abort
  let l:st = vimtoria#core#state()
  let l:pos = getmousepos()
  if l:pos.winid == 0 || l:pos.line <= 0
    return
  endif
  " 国選択画面: クリックした行の国を選択(Enter で決定)
  if l:st.screen ==# 'select'
    let l:ci = vimtoria#screens#select#index_at(l:pos.line)
    if l:ci >= 0
      let l:st.menu_idx = l:ci
      call vimtoria#ui#render()
    endif
    return
  endif
  if l:st.screen !=# 'map'
    return
  endif
  " マップは ヘッダ・ヒント・空行 の 3 行の下(バッファ 4 行目)から始まる
  let l:sid = vimtoria#core#click_resolve(l:pos.line - 4, l:pos.column - 1)
  if empty(l:sid)
    return
  endif
  let l:st.msg = ''
  if l:st.selected ==# l:sid
    let l:st.screen = 'state'
    let l:st.screen_arg = l:sid
  else
    let l:st.selected = l:sid
  endif
  call vimtoria#ui#render()
endfunction

" マップ座標(テンプレートの行、行内のバイト位置)から州を解決する。
" ラベル直上ならその州、近傍なら最寄りのラベル、遠ければ空文字
function! vimtoria#core#click_resolve(row, col) abort
  return vimtoria#screens#map#resolve(a:row, a:col)
endfunction

" 画面ごとのメニュー項目数(0 ならメニュー無し)
function! s:menu_len(st) abort
  if a:st.screen ==# 'construction'
    return len(vimtoria#data#economy().buildings_order)
  elseif a:st.screen ==# 'tech'
    return len(vimtoria#tech#menu_for(a:st.country))
  elseif a:st.screen ==# 'politics'
    return len(vimtoria#data#politics().law_order)
  elseif a:st.screen ==# 'diplo'
    return len(vimtoria#core#diplo_targets(a:st))
  elseif a:st.screen ==# 'select'
    return len(vimtoria#data#map().country_order)
  elseif a:st.screen ==# 'lang'
    return len(vimtoria#screens#lang#choices())
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
          \ ? printf(vimtoria#i18n#t('msg_improved'),
          \          vimtoria#i18n#name(l:map.countries[l:other]))
          \ : l:err
  elseif a:name ==# 'dip_alliance'
    let l:was = vimtoria#diplo#allied(l:world, a:st.country, l:other)
    let l:err = vimtoria#diplo#toggle_alliance(l:world, a:st.country, l:other)
    let a:st.msg = empty(l:err)
          \ ? printf(vimtoria#i18n#t(l:was
          \            ? 'msg_alliance_broken' : 'msg_alliance_formed'),
          \          vimtoria#i18n#name(l:map.countries[l:other]))
          \ : l:err
  elseif a:name ==# 'dip_war'
    " 奪取目標: マップで選択中の州が相手領ならそこ、でなければ相手の最弱州
    let l:goal = l:world.owner[a:st.selected] ==# l:other
          \ ? a:st.selected : s:weakest_of(l:world, l:other)
    if empty(l:goal)
      let a:st.msg = vimtoria#i18n#t('msg_no_states')
      return
    endif
    let l:err = vimtoria#diplo#declare_war(l:world, a:st.country, l:other,
          \ l:goal, a:st.day, a:st.country)
    let a:st.msg = empty(l:err)
          \ ? printf(vimtoria#i18n#t('msg_war_declared'),
          \          vimtoria#i18n#name(l:map.countries[l:other]),
          \          vimtoria#i18n#name(l:map.states[l:goal]))
          \ : l:err
  elseif a:name ==# 'dip_peace'
    let l:err = vimtoria#diplo#white_peace(l:world, a:st.country, l:other, a:st.day)
    let a:st.msg = empty(l:err) ? vimtoria#i18n#t('msg_white_peace') : l:err
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
  if confirm(vimtoria#i18n#t('confirm_quit'), "&Yes\n&No", 2) != 1
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
