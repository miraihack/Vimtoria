scriptencoding utf-8
" diplo.vim - 外交(関係値・同盟・宣戦・和平)
"
" world.relations {pairkey: -100..100}, world.alliances {pairkey: 1},
" world.diplo_cd {pairkey: 最後に関係改善した day},
" world.wars = [{'attacker', 'defender', 'allies_d': [], 'score', 'goal', 'started'}]
" pairkey は国タグをソートして 'A:B'。

let s:seeded = 0

function! s:roll(n) abort
  if !s:seeded
    call srand()
    let s:seeded = 1
  endif
  return rand() % a:n
endfunction

function! vimtoria#diplo#key(a, b) abort
  return a:a <# a:b ? a:a . ':' . a:b : a:b . ':' . a:a
endfunction

function! vimtoria#diplo#init_world(world) abort
  let a:world.relations = {}
  let a:world.alliances = {}
  let a:world.diplo_cd = {}
  let a:world.wars = []
  for l:p in vimtoria#data#diplomacy().presets
    let a:world.relations[vimtoria#diplo#key(l:p[0], l:p[1])] = l:p[2]
  endfor
endfunction

function! vimtoria#diplo#relation(world, a, b) abort
  return get(a:world.relations, vimtoria#diplo#key(a:a, a:b), 0.0)
endfunction

function! s:add_relation(world, a, b, delta) abort
  let l:k = vimtoria#diplo#key(a:a, a:b)
  let l:v = get(a:world.relations, l:k, 0.0) + a:delta
  let a:world.relations[l:k] = l:v > 100.0 ? 100.0 : (l:v < -100.0 ? -100.0 : l:v)
endfunction

function! vimtoria#diplo#allied(world, a, b) abort
  return has_key(a:world.alliances, vimtoria#diplo#key(a:a, a:b))
endfunction

" その国がいずれかの戦争に参加しているか(交易の封鎖判定などに使う)
function! vimtoria#diplo#in_war(world, cid) abort
  for l:w in a:world.wars
    if l:w.attacker ==# a:cid || l:w.defender ==# a:cid
          \ || index(l:w.allies_d, a:cid) >= 0
      return 1
    endif
  endfor
  return 0
endfunction

" a と b の間の戦争(どちらの陣営でも)を返す。無ければ {}
function! vimtoria#diplo#war_between(world, a, b) abort
  for l:w in a:world.wars
    let l:side_a = [l:w.attacker]
    let l:side_d = [l:w.defender] + l:w.allies_d
    if (index(l:side_a, a:a) >= 0 && index(l:side_d, a:b) >= 0)
          \ || (index(l:side_a, a:b) >= 0 && index(l:side_d, a:a) >= 0)
      return l:w
    endif
  endfor
  return {}
endfunction

" ---- プレイヤー/AI 共通のアクション(成功なら空文字を返す) ----

function! vimtoria#diplo#improve(world, cid, other, day) abort
  let l:c = vimtoria#data#diplomacy().const
  let l:k = vimtoria#diplo#key(a:cid, a:other)
  if has_key(a:world.diplo_cd, l:k)
        \ && a:day - a:world.diplo_cd[l:k] < l:c.improve_cd_weeks * 7
    return vimtoria#i18n#t('err_dip_cd')
  endif
  if a:world.treasuries[a:cid] < l:c.improve_cost
    return printf(vimtoria#i18n#t('err_no_funds'), l:c.improve_cost)
  endif
  let a:world.treasuries[a:cid] -= l:c.improve_cost
  call s:add_relation(a:world, a:cid, a:other, l:c.improve_gain)
  let a:world.diplo_cd[l:k] = a:day
  return ''
endfunction

function! vimtoria#diplo#toggle_alliance(world, cid, other) abort
  let l:c = vimtoria#data#diplomacy().const
  let l:k = vimtoria#diplo#key(a:cid, a:other)
  if has_key(a:world.alliances, l:k)
    call remove(a:world.alliances, l:k)
    call s:add_relation(a:world, a:cid, a:other, -30.0)
    return ''
  endif
  if !empty(vimtoria#diplo#war_between(a:world, a:cid, a:other))
    return vimtoria#i18n#t('err_ally_war')
  endif
  if vimtoria#diplo#relation(a:world, a:cid, a:other) < l:c.ally_threshold
    return printf(vimtoria#i18n#t('err_ally_rel'), l:c.ally_threshold)
  endif
  let a:world.alliances[l:k] = 1
  return ''
endfunction

" 宣戦布告。goal_sid は奪取目標の州
function! vimtoria#diplo#declare_war(world, cid, other, goal_sid, day, player) abort
  if a:cid ==# a:other
    return vimtoria#i18n#t('err_war_self')
  endif
  if vimtoria#diplo#allied(a:world, a:cid, a:other)
    return vimtoria#i18n#t('err_war_ally')
  endif
  if !empty(vimtoria#diplo#war_between(a:world, a:cid, a:other))
    return vimtoria#i18n#t('err_war_already')
  endif
  if empty(a:world.country_states[a:other])
    return vimtoria#i18n#t('err_war_dead')
  endif
  " 防御側の同盟国が参戦する
  let l:allies = []
  for l:third in keys(vimtoria#data#map().countries)
    if l:third !=# a:cid && l:third !=# a:other
          \ && vimtoria#diplo#allied(a:world, a:other, l:third)
      call add(l:allies, l:third)
    endif
  endfor
  call add(a:world.wars, {'attacker': a:cid, 'defender': a:other,
        \ 'allies_d': l:allies, 'score': 0.0, 'goal': a:goal_sid,
        \ 'started': a:day})
  let a:world.relations[vimtoria#diplo#key(a:cid, a:other)] = -100.0
  let l:map = vimtoria#data#map()
  call vimtoria#war#log(a:world, a:day, printf(vimtoria#i18n#t('log_war_declared'),
        \ vimtoria#i18n#name(l:map.countries[a:cid]),
        \ vimtoria#i18n#name(l:map.countries[a:other]),
        \ vimtoria#i18n#name(l:map.states[a:goal_sid])))
  return ''
endfunction

" 白紙和平(常に受諾される)
function! vimtoria#diplo#white_peace(world, cid, other, day) abort
  let l:w = vimtoria#diplo#war_between(a:world, a:cid, a:other)
  if empty(l:w)
    return vimtoria#i18n#t('err_no_war')
  endif
  call filter(a:world.wars, 'v:val isnot l:w')
  let l:map = vimtoria#data#map()
  call vimtoria#war#log(a:world, a:day, printf(vimtoria#i18n#t('log_white_peace'),
        \ vimtoria#i18n#name(l:map.countries[l:w.attacker]),
        \ vimtoria#i18n#name(l:map.countries[l:w.defender])))
  return ''
endfunction

" ---- 週次処理 ----

" 関係値のドリフト(正は速く、負はゆっくり 0 へ)
function! vimtoria#diplo#tick(world) abort
  let l:c = vimtoria#data#diplomacy().const
  for [l:k, l:v] in items(a:world.relations)
    if l:v > 0.0
      let a:world.relations[l:k] = l:v > l:c.drift_pos ? l:v - l:c.drift_pos : 0.0
    elseif l:v < 0.0
      let a:world.relations[l:k] = l:v < -l:c.drift_neg ? l:v + l:c.drift_neg : 0.0
    endif
  endfor
endfunction

" AI の外交(毎週、各 AI 国について呼ばれる)
function! vimtoria#diplo#ai(world, cid, day, player) abort
  let l:c = vimtoria#data#diplomacy().const
  let l:map = vimtoria#data#map()
  for l:other in l:map.country_order
    if l:other ==# a:cid || empty(a:world.country_states[l:other])
      continue
    endif
    let l:rel = vimtoria#diplo#relation(a:world, a:cid, l:other)
    " 同盟(AI 同士のみ。プレイヤーへの提案は自動成立させない)
    if l:other !=# a:player && l:rel >= l:c.ally_threshold
          \ && !vimtoria#diplo#allied(a:world, a:cid, l:other)
          \ && s:roll(1000) < l:c.ai_ally_chance
      call vimtoria#diplo#toggle_alliance(a:world, a:cid, l:other)
    endif
    " 宣戦(強い相手には仕掛けない)
    if l:rel <= l:c.ai_war_relation
          \ && empty(vimtoria#diplo#war_between(a:world, a:cid, l:other))
          \ && !vimtoria#diplo#allied(a:world, a:cid, l:other)
          \ && s:roll(1000) < l:c.ai_war_chance
          \ && vimtoria#war#strength(a:world, a:cid)
          \    > l:c.ai_war_advantage * vimtoria#war#strength(a:world, l:other)
      call vimtoria#diplo#declare_war(a:world, a:cid, l:other,
            \ s:weakest_state(a:world, l:other), a:day, a:player)
    endif
  endfor
  " 負けが込んだ戦争は放棄する
  for l:w in copy(a:world.wars)
    if l:w.attacker ==# a:cid && l:w.score <= l:c.ai_giveup_score
          \ && s:roll(1000) < l:c.ai_giveup_chance
      call vimtoria#diplo#white_peace(a:world, a:cid, l:w.defender, a:day)
    endif
  endfor
endfunction

function! s:weakest_state(world, cid) abort
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
