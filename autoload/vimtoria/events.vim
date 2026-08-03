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
  let l:changed = 0
  for l:e in a:world.events[a:cid]
    let l:e.weeks -= 1
    let l:changed = 1
  endfor
  call filter(a:world.events[a:cid], 'v:val.weeks > 0')
  let l:data = vimtoria#data#events()
  if !get(g:, 'vimtoria_disable_events', 0)
        \ && s:roll(1000) < l:data.chance
    let l:eid = l:data.order[s:roll(len(l:data.order))]
    call vimtoria#events#fire(a:world, a:cid, l:eid, a:day, a:is_player)
    let l:changed = 1
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
    let l:where = vimtoria#data#map().states[l:sid].name . ': '
  endif
  " 時限効果
  if l:fx.duration > 0
    call add(a:world.events[a:cid], {'id': a:eid, 'weeks': l:fx.duration})
  endif
  call s:recompute(a:world, a:cid)
  if a:is_player
    call add(a:world.eventlog, printf('%s 【%s】%s%s',
          \ vimtoria#core#date_str(a:day), l:def.name, l:where, l:def.desc))
    if len(a:world.eventlog) > 20
      call remove(a:world.eventlog, 0, len(a:world.eventlog) - 21)
    endif
  endif
endfunction

function! s:recompute(world, cid) abort
  let l:data = vimtoria#data#events()
  let l:mods = {'out': {}, 'out_all': 1.0, 'research': 1.0, 'build_cap': 1.0}
  for l:e in a:world.events[a:cid]
    let l:fx = l:data.events[l:e.id].effects
    if has_key(l:fx, 'out')
      for [l:bid, l:m] in items(l:fx.out)
        let l:mods.out[l:bid] = get(l:mods.out, l:bid, 1.0) * l:m
      endfor
    endif
    if has_key(l:fx, 'out_all')
      let l:mods.out_all = l:mods.out_all * l:fx.out_all
    endif
    if has_key(l:fx, 'research')
      let l:mods.research = l:mods.research * l:fx.research
    endif
    if has_key(l:fx, 'build_cap')
      let l:mods.build_cap = l:mods.build_cap * l:fx.build_cap
    endif
  endfor
  let a:world.event_mods[a:cid] = l:mods
endfunction
