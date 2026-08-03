scriptencoding utf-8
" events.vim - ランダムイベント(週次抽選と時限モディファイア)
"
" world.events[cid]     = [{'id': eid, 'weeks': 残り週}, ...]
" world.event_mods[cid] = 有効なイベントから計算した倍率(econ/build が参照)
" world.eventlog        = プレイヤー国のイベント履歴(表示用、最大20件)
" g:vimtoria_disable_events = 1 で自動抽選を止められる(テスト用)。

let s:seeded = 0

function! s:roll(n) abort
  if !s:seeded
    call srand()
    let s:seeded = 1
  endif
  return rand() % a:n
endfunction

function! vimtoria#events#init_world(world) abort
  let l:map = vimtoria#data#map()
  let a:world.events = {}
  let a:world.event_mods = {}
  let a:world.eventlog = []
  for l:cid in keys(l:map.countries)
    let a:world.events[l:cid] = []
    call s:recompute(a:world, l:cid)
  endfor
endfunction

" 週次処理: 期限切れの除去 → 新規抽選 → モディファイア再計算
function! vimtoria#events#tick(world, cid, day, is_player) abort
  let l:active = a:world.events[a:cid]
  let l:changed = 0
  if !empty(l:active)
    let l:changed = 1
    let l:i = len(l:active) - 1
    while l:i >= 0
      let l:active[l:i].weeks -= 1
      if l:active[l:i].weeks <= 0
        call remove(l:active, l:i)
      endif
      let l:i -= 1
    endwhile
  endif
  if !get(g:, 'vimtoria_disable_events', 0)
    let l:data = vimtoria#data#events()
    if s:roll(1000) < l:data.chance
      let l:eid = l:data.order[s:roll(len(l:data.order))]
      call vimtoria#events#fire(a:world, a:cid, l:eid, a:day, a:is_player)
      let l:changed = 1
    endif
  endif
  if l:changed
    call s:recompute(a:world, a:cid)
  endif
endfunction

" イベントを即時発火させる(抽選とテストの両方から使う)
function! vimtoria#events#fire(world, cid, eid, day, is_player) abort
  let l:def = vimtoria#data#events().events[a:eid]
  let l:fx = l:def.effects
  " 即時効果
  if has_key(l:fx, 'treasury_weeks')
    let a:world.treasuries[a:cid] +=
          \ a:world.stats[a:cid].income * l:fx.treasury_weeks
  endif
  let l:where = ''
  if has_key(l:fx, 'workforce_pct') && !empty(a:world.country_states[a:cid])
    let l:sids = a:world.country_states[a:cid]
    let l:sid = l:sids[s:roll(len(l:sids))]
    let a:world.workforce[l:sid] =
          \ a:world.workforce[l:sid] * (1.0 + l:fx.workforce_pct)
    let l:where = vimtoria#i18n#name(vimtoria#data#map().states[l:sid]) . ': '
  endif
  " 時限効果
  if l:fx.duration > 0
    call add(a:world.events[a:cid], {'id': a:eid, 'weeks': l:fx.duration})
  endif
  call s:recompute(a:world, a:cid)
  if a:is_player
    call add(a:world.eventlog, vimtoria#core#date_str(a:day) . ' '
          \ . printf(vimtoria#i18n#t('evt_fmt'), vimtoria#i18n#name(l:def),
          \          l:where, vimtoria#i18n#desc(l:def)))
    if len(a:world.eventlog) > 20
      call remove(a:world.eventlog, 0, len(a:world.eventlog) - 21)
    endif
  endif
endfunction

" 歴史イベントの時限効果を登録する(id は 'h:' 接頭辞で区別する)
function! vimtoria#events#add_timed(world, cid, id, weeks) abort
  call add(a:world.events[a:cid], {'id': a:id, 'weeks': a:weeks})
  call s:recompute(a:world, a:cid)
endfunction

function! s:recompute(world, cid) abort
  let l:data = vimtoria#data#events()
  let l:mods = {'out': {}, 'out_all': 1.0, 'research': 1.0,
        \ 'build_cap': 1.0, 'trade': 1.0}
  for l:e in a:world.events[a:cid]
    " 'h:' 接頭辞は歴史イベント(data/history.vim)の時限効果
    let l:fx = l:e.id =~# '^h:'
          \ ? vimtoria#data#history().events[l:e.id[2:]].effects
          \ : l:data.events[l:e.id].effects
    if has_key(l:fx, 'out')
      for [l:bid, l:m] in items(l:fx.out)
        let l:mods.out[l:bid] = get(l:mods.out, l:bid, 1.0) * l:m
      endfor
    endif
    for l:key in ['out_all', 'research', 'build_cap', 'trade']
      if has_key(l:fx, l:key)
        let l:mods[l:key] = l:mods[l:key] * l:fx[l:key]
      endif
    endfor
  endfor
  let a:world.event_mods[a:cid] = l:mods
endfunction
