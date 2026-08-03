scriptencoding utf-8
" politics.vim - 政治(利益集団・法律・政体・急進性・社会運動)
"
" world.politics[cid] = {'clout': {ig: 0..1}, 'rad': 0..100,
"                        'laws': {group: law_id},
"                        'movements': {mov_id: 支持 0..100},
"                        'enact': {'law': law_id|'', 'progress': 0.0}}
" world.law_mods[cid] = 有効な法律から計算した効果(econ/build/war が参照)
"   結合規則: 倍率(out_all/build_cap/research/mil/trade/tax_eff)は乗算、
"             wage_share は最大値、tax_max は最小値、rad は加算

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
          \ 'laws': l:laws, 'movements': {},
          \ 'enact': {'law': '', 'progress': 0.0}}
    call vimtoria#politics#recompute_law_mods(a:world, l:cid)
  endfor
endfunction

function! vimtoria#politics#recompute_law_mods(world, cid) abort
  let l:data = vimtoria#data#politics()
  let l:mods = {'out': {}, 'out_all': 1.0, 'build_cap': 1.0, 'research': 1.0,
        \ 'mil': 1.0, 'trade': 1.0, 'tax_eff': 1.0, 'rad': 0.0,
        \ 'wage_share': -1.0, 'tax_max': 9.9}
  for l:lid in values(a:world.politics[a:cid].laws)
    let l:fx = l:data.laws[l:lid].effects
    if has_key(l:fx, 'out')
      for [l:bid, l:m] in items(l:fx.out)
        let l:mods.out[l:bid] = get(l:mods.out, l:bid, 1.0) * l:m
      endfor
    endif
    for l:key in ['out_all', 'build_cap', 'research', 'mil', 'trade', 'tax_eff']
      if has_key(l:fx, l:key)
        let l:mods[l:key] = l:mods[l:key] * l:fx[l:key]
      endif
    endfor
    if has_key(l:fx, 'rad')
      let l:mods.rad += l:fx.rad
    endif
    " 賃金分配は最も労働者寄りの法(最大値)、税率上限は最も厳しい法(最小値)
    if has_key(l:fx, 'wage_share') && l:fx.wage_share > l:mods.wage_share
      let l:mods.wage_share = l:fx.wage_share
    endif
    if has_key(l:fx, 'tax_max') && l:fx.tax_max < l:mods.tax_max
      let l:mods.tax_max = l:fx.tax_max
    endif
  endfor
  if l:mods.wage_share < 0.0
    let l:mods.wage_share = 0.7
  endif
  if l:mods.tax_max > 1.0
    let l:mods.tax_max = 0.30
  endif
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

" 法律案への勢力加重の支持(-2〜+2 程度)。現行法との態度差で決まり、
" 対応する社会運動が活動中なら支持が上乗せされる
function! vimtoria#politics#support(world, cid, lid) abort
  let l:data = vimtoria#data#politics()
  let l:def = l:data.laws[a:lid]
  let l:old = a:world.politics[a:cid].laws[l:def.group]
  let l:sum = 0.0
  for [l:ig, l:clout] in items(a:world.politics[a:cid].clout)
    let l:sum += l:clout * (get(l:def.approval, l:ig, 0)
          \ - get(l:data.laws[l:old].approval, l:ig, 0)) / 2.0
  endfor
  for [l:mid, l:sup] in items(a:world.politics[a:cid].movements)
    if l:data.movements[l:mid].target ==# a:lid
      let l:sum += l:sup / 100.0 * l:data.const.mov_support_boost
    endif
  endfor
  return l:sum
endfunction

" 制定に必要な技術(思想)が未研究なら 0
function! vimtoria#politics#law_unlocked(world, cid, lid) abort
  let l:def = vimtoria#data#politics().laws[a:lid]
  return !has_key(l:def, 'req_tech')
        \ || has_key(a:world.techs[a:cid].done, l:def.req_tech)
endfunction

" 制定開始。成功なら空文字、失敗なら理由を返す
function! vimtoria#politics#start_enact(world, cid, lid) abort
  let l:data = vimtoria#data#politics()
  let l:pol = a:world.politics[a:cid]
  let l:def = l:data.laws[a:lid]
  if l:pol.laws[l:def.group] ==# a:lid
    return printf(vimtoria#i18n#t('err_law_active'), vimtoria#i18n#name(l:def))
  endif
  if l:pol.enact.law ==# a:lid
    return printf(vimtoria#i18n#t('err_law_enacting'), vimtoria#i18n#name(l:def))
  endif
  if !vimtoria#politics#law_unlocked(a:world, a:cid, a:lid)
    return printf(vimtoria#i18n#t('err_law_tech'),
          \ vimtoria#i18n#name(vimtoria#data#tech().techs[l:def.req_tech]))
  endif
  let l:pol.enact = {'law': a:lid, 'progress': 0.0}
  return ''
endfunction

" 週次処理: 勢力更新 → 社会運動 → 制定進行 → 急進性 → 反乱
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

  " 社会運動: 発生 → 成長 → 急進性への圧力
  let l:mov_rad = 0.0
  for l:mid in l:data.movement_order
    let l:mdef = l:data.movements[l:mid]
    let l:satisfied =
          \ l:pol.laws[l:data.laws[l:mdef.target].group] ==# l:mdef.target
    if has_key(l:pol.movements, l:mid)
      if l:satisfied
        call remove(l:pol.movements, l:mid)
        continue
      endif
      let l:g = l:data.const.mov_base_grow
      if l:mdef.grow ==# 'industrial'
        let l:g += 3.0 * l:pol.clout['industrialists']
      elseif l:mdef.grow ==# 'labor'
        let l:g += 3.0 * l:pol.clout['labor']
              \ + (a:sol < 1.0 ? 1.0 - a:sol : 0.0)
      else
        let l:g += 0.4
      endif
      let l:pol.movements[l:mid] = l:pol.movements[l:mid] + l:g
      if l:pol.movements[l:mid] > 100.0
        let l:pol.movements[l:mid] = 100.0
      endif
      let l:mov_rad += l:pol.movements[l:mid] / 100.0 * l:data.const.mov_rad
    elseif !l:satisfied
          \ && has_key(a:world.techs[a:cid].done, l:mdef.req_tech)
          \ && s:roll(1000) < l:data.const.mov_spawn_chance
      let l:pol.movements[l:mid] = 5.0
      if a:is_player
        call s:player_log(a:world, a:day,
              \ printf(vimtoria#i18n#t('log_movement'), vimtoria#i18n#name(l:mdef)))
      endif
    endif
  endfor

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

  " 急進性: 生活水準・政体(law_mods.rad)・技術(mods.rad)・運動の圧力
  let l:sol = a:sol < 1.5 ? a:sol : 1.5
  let l:pol.rad += l:data.const.rad_sol_scale * (1.0 - l:sol)
        \ + a:world.law_mods[a:cid].rad
        \ + a:world.mods[a:cid].rad
        \ + l:mov_rad
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
  " この法律を要求していた社会運動は解散し、急進性が和らぐ
  for [l:mid, l:sup] in items(l:pol.movements)
    if l:data.movements[l:mid].target ==# l:lid
      call remove(l:pol.movements, l:mid)
      let l:pol.rad -= l:data.const.mov_relief
      if l:pol.rad < 0.0
        let l:pol.rad = 0.0
      endif
    endif
  endfor
  call vimtoria#politics#recompute_law_mods(a:world, a:cid)
  if a:is_player
    call s:player_log(a:world, a:day,
          \ printf(vimtoria#i18n#t('log_law_enacted'), vimtoria#i18n#name(l:def)))
  endif
endfunction

function! s:player_log(world, day, text) abort
  call add(a:world.eventlog, vimtoria#core#date_str(a:day) . ' ' . a:text)
  if len(a:world.eventlog) > 20
    call remove(a:world.eventlog, 0, len(a:world.eventlog) - 21)
  endif
endfunction
