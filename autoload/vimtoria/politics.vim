scriptencoding utf-8
" politics.vim - 政治(利益集団・法律・急進性)
"
" world.politics[cid] = {'clout': {ig: 0..1}, 'rad': 0..100,
"                        'laws': {group: law_id},
"                        'enact': {'law': law_id|'', 'progress': 0.0}}
" world.law_mods[cid] = 有効な法律から計算した効果(econ/build が参照)

let s:seeded = 0

function! s:roll(n) abort
  if !s:seeded
    call srand()
    let s:seeded = 1
  endif
  return rand() % a:n
endfunction

function! vimtoria#politics#init_world(world) abort
  let l:data = vimtoria#data#politics()
  let l:map = vimtoria#data#map()
  let a:world.politics = {}
  let a:world.law_mods = {}
  for l:cid in keys(l:map.countries)
    let l:laws = copy(l:data.default_laws)
    if has_key(l:data.country_laws, l:cid)
      call extend(l:laws, l:data.country_laws[l:cid])
    endif
    let l:clout = {}
    for l:ig in l:data.ig_order
      let l:clout[l:ig] = 1.0 / len(l:data.ig_order)
    endfor
    let a:world.politics[l:cid] = {'clout': l:clout, 'rad': 0.0,
          \ 'laws': l:laws, 'enact': {'law': '', 'progress': 0.0}}
    call vimtoria#politics#recompute_law_mods(a:world, l:cid)
  endfor
endfunction

function! vimtoria#politics#recompute_law_mods(world, cid) abort
  let l:data = vimtoria#data#politics()
  let l:mods = {'out': {}, 'build_cap': 1.0, 'wage_share': 0.7, 'tax_max': 0.30}
  for l:lid in values(a:world.politics[a:cid].laws)
    let l:fx = l:data.laws[l:lid].effects
    if has_key(l:fx, 'out')
      for [l:bid, l:m] in items(l:fx.out)
        let l:mods.out[l:bid] = get(l:mods.out, l:bid, 1.0) * l:m
      endfor
    endif
    if has_key(l:fx, 'build_cap')
      let l:mods.build_cap = l:mods.build_cap * l:fx.build_cap
    endif
    if has_key(l:fx, 'wage_share')
      let l:mods.wage_share = l:fx.wage_share
    endif
    if has_key(l:fx, 'tax_max')
      let l:mods.tax_max = l:fx.tax_max
    endif
  endfor
  let a:world.law_mods[a:cid] = l:mods
endfunction

" 利益集団の、現行法全体への態度(approval の合計)
function! vimtoria#politics#attitude(world, cid, ig) abort
  let l:data = vimtoria#data#politics()
  let l:sum = 0
  for l:lid in values(a:world.politics[a:cid].laws)
    let l:sum += get(l:data.laws[l:lid].approval, a:ig, 0)
  endfor
  return l:sum
endfunction

" 法律案への勢力加重の支持(-2〜+2 程度)。現行法との態度差で決まる
function! vimtoria#politics#support(world, cid, lid) abort
  let l:data = vimtoria#data#politics()
  let l:def = l:data.laws[a:lid]
  let l:old = a:world.politics[a:cid].laws[l:def.group]
  let l:sum = 0.0
  for [l:ig, l:clout] in items(a:world.politics[a:cid].clout)
    let l:sum += l:clout * (get(l:def.approval, l:ig, 0)
          \ - get(l:data.laws[l:old].approval, l:ig, 0)) / 2.0
  endfor
  return l:sum
endfunction

" 制定開始。成功なら空文字、失敗なら理由を返す
function! vimtoria#politics#start_enact(world, cid, lid) abort
  let l:data = vimtoria#data#politics()
  let l:pol = a:world.politics[a:cid]
  let l:def = l:data.laws[a:lid]
  if l:pol.laws[l:def.group] ==# a:lid
    return l:def.name . ' は既に施行されています'
  endif
  if l:pol.enact.law ==# a:lid
    return l:def.name . ' は制定中です'
  endif
  let l:pol.enact = {'law': a:lid, 'progress': 0.0}
  return ''
endfunction

" 週次処理: 勢力更新 → 制定進行 → 急進性 → 反乱
function! vimtoria#politics#tick(world, cid, income_by_prof, sol, day, is_player) abort
  let l:data = vimtoria#data#politics()
  let l:pol = a:world.politics[a:cid]

  " 勢力 = 支持基盤の職業の所得シェア
  let l:totals = {}
  let l:grand = 0.0
  for l:ig in l:data.ig_order
    let l:t = 0.0
    for l:prof in l:data.igs[l:ig].professions
      let l:t += get(a:income_by_prof, l:prof, 0.0)
    endfor
    let l:totals[l:ig] = l:t
    let l:grand += l:t
  endfor
  if l:grand > 0.0
    for l:ig in l:data.ig_order
      let l:pol.clout[l:ig] = l:totals[l:ig] / l:grand
    endfor
  endif

  " 制定の進行
  if !empty(l:pol.enact.law)
    let l:sup = vimtoria#politics#support(a:world, a:cid, l:pol.enact.law)
    if l:sup > 0.0
      let l:pol.enact.progress += 1.0 + l:sup
    else
      let l:pol.enact.progress += 0.5
      let l:pol.rad += l:data.const.rad_forced_enact
    endif
    if l:pol.enact.progress >= l:data.const.enact_points
      call s:complete_enact(a:world, a:cid, a:day, a:is_player)
    endif
  endif

  " 急進性: 生活水準が低いと上がり、高いと下がる
  let l:sol = a:sol < 1.5 ? a:sol : 1.5
  let l:pol.rad += l:data.const.rad_sol_scale * (1.0 - l:sol)
  if l:pol.rad < 0.0
    let l:pol.rad = 0.0
  elseif l:pol.rad > 100.0
    let l:pol.rad = 100.0
  endif

  " 反乱
  if l:pol.rad > l:data.const.rad_uprising_threshold
        \ && s:roll(1000) < l:data.const.rad_uprising_chance
    call vimtoria#events#fire(a:world, a:cid, 'uprising', a:day, a:is_player)
    let l:pol.rad -= l:data.const.rad_uprising_relief
  endif
endfunction

function! s:complete_enact(world, cid, day, is_player) abort
  let l:data = vimtoria#data#politics()
  let l:pol = a:world.politics[a:cid]
  let l:lid = l:pol.enact.law
  let l:def = l:data.laws[l:lid]
  let l:old = l:pol.laws[l:def.group]
  " 反対派の勢力に応じて急進性が上がる
  for [l:ig, l:clout] in items(l:pol.clout)
    if get(l:def.approval, l:ig, 0) < get(l:data.laws[l:old].approval, l:ig, 0)
      let l:pol.rad += l:data.const.rad_enact_complete * l:clout * 2.0
    endif
  endfor
  let l:pol.laws[l:def.group] = l:lid
  let l:pol.enact = {'law': '', 'progress': 0.0}
  call vimtoria#politics#recompute_law_mods(a:world, a:cid)
  if a:is_player
    call add(a:world.eventlog, printf('%s 【法律制定】%s が施行された',
          \ vimtoria#core#date_str(a:day), l:def.name))
  endif
endfunction
