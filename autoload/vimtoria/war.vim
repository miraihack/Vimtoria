scriptencoding utf-8
" war.vim - 軍事(連隊・戦闘・併合)
"
" world.military[cid] = {'regiments': float}
" 戦争は週次で戦況(score)が動き、±100 で決着する。
" 攻撃側が勝てば目標州を併合し、州の所有権(world.owner)が書き換わる。

let s:seeded = 0

function! s:roll(n) abort
  if !s:seeded
    call srand()
    let s:seeded = 1
  endif
  return rand() % a:n
endfunction

function! vimtoria#war#init_world(world) abort
  let l:eco = vimtoria#data#economy()
  let l:map = vimtoria#data#map()
  let a:world.military = {}
  for l:cid in keys(l:map.countries)
    let l:workforce = 0.0
    for l:sid in a:world.country_states[l:cid]
      let l:workforce += a:world.workforce[l:sid]
    endfor
    let a:world.military[l:cid] =
          \ {'regiments': l:workforce / l:eco.const.mil_init_div}
  endfor
endfunction

" 総戦力 = 連隊数 × (1 + 技術ボーナス)
function! vimtoria#war#strength(world, cid) abort
  let l:eco = vimtoria#data#economy()
  return a:world.military[a:cid].regiments
        \ * (1.0 + l:eco.const.mil_tech_bonus
        \        * len(a:world.techs[a:cid].done))
endfunction

" 連隊の上限(労働力に比例)
function! vimtoria#war#cap(world, cid) abort
  let l:eco = vimtoria#data#economy()
  let l:workforce = 0.0
  for l:sid in a:world.country_states[a:cid]
    let l:workforce += a:world.workforce[l:sid]
  endfor
  return l:workforce / l:eco.const.mil_cap_div
endfunction

" 徴募: 費用と労働力(最大州から)を消費する。成功なら空文字
function! vimtoria#war#recruit(world, cid) abort
  let l:eco = vimtoria#data#economy()
  let l:n = l:eco.const.mil_recruit_batch
  let l:mil = a:world.military[a:cid]
  if l:mil.regiments + l:n > vimtoria#war#cap(a:world, a:cid)
    return '連隊が上限に達しています(労働力を増やすと上限も増える)'
  endif
  let l:cost = l:n * l:eco.const.mil_recruit_cost
  if a:world.treasuries[a:cid] < l:cost
    return printf('資金不足です(£%.0f 必要)', l:cost)
  endif
  let l:sid = s:largest_state(a:world, a:cid)
  if empty(l:sid) || a:world.workforce[l:sid] < l:n + 1.0
    return '徴募できる労働力がありません'
  endif
  let a:world.treasuries[a:cid] -= l:cost
  let a:world.workforce[l:sid] -= l:n
  let l:mil.regiments += l:n
  return ''
endfunction

" 解散: 兵士は最大州の労働力に戻る
function! vimtoria#war#disband(world, cid) abort
  let l:eco = vimtoria#data#economy()
  let l:n = l:eco.const.mil_recruit_batch
  let l:mil = a:world.military[a:cid]
  if l:mil.regiments < l:n
    return '解散できる連隊がありません'
  endif
  let l:mil.regiments -= l:n
  let l:sid = s:largest_state(a:world, a:cid)
  if !empty(l:sid)
    let a:world.workforce[l:sid] += l:n
  endif
  return ''
endfunction

" 週次の戦争処理(全戦争、経済ティックの後に1回)
function! vimtoria#war#tick(world, day) abort
  let l:eco = vimtoria#data#economy()
  for l:w in copy(a:world.wars)
    " 消滅した国の戦争は消える
    if empty(a:world.country_states[l:w.attacker])
          \ || empty(a:world.country_states[l:w.defender])
      call filter(a:world.wars, 'v:val isnot l:w')
      continue
    endif
    let l:pow_a = vimtoria#war#strength(a:world, l:w.attacker)
    let l:pow_d = vimtoria#war#strength(a:world, l:w.defender)
    for l:ally in l:w.allies_d
      let l:pow_d += vimtoria#war#strength(a:world, l:ally)
    endfor
    if l:pow_a + l:pow_d <= 0.01
      continue
    endif
    " 戦況: 戦力比 + 戦場の霧(乱数)
    let l:w.score += 8.0 * (l:pow_a - l:pow_d) / (l:pow_a + l:pow_d)
          \ + (s:roll(401) - 200) / 100.0
    " 損耗(劣勢側ほど大きい)
    let l:rate_a = l:eco.const.mil_casualty * 2.0 * l:pow_d / (l:pow_a + l:pow_d)
    let l:rate_d = l:eco.const.mil_casualty * 2.0 * l:pow_a / (l:pow_a + l:pow_d)
    let a:world.military[l:w.attacker].regiments *= (1.0 - l:rate_a)
    let a:world.military[l:w.defender].regiments *= (1.0 - l:rate_d)
    for l:ally in l:w.allies_d
      let a:world.military[l:ally].regiments *= (1.0 - l:rate_d)
    endfor
    " 決着
    let l:map = vimtoria#data#map()
    if l:w.score >= 100.0
      call vimtoria#war#annex(a:world, l:w.goal, l:w.attacker)
      call filter(a:world.wars, 'v:val isnot l:w')
      call vimtoria#war#log(a:world, a:day, printf('【講和】%s が勝利し %s を併合',
            \ l:map.countries[l:w.attacker].name, l:map.states[l:w.goal].name))
      let a:world.relations[vimtoria#diplo#key(l:w.attacker, l:w.defender)] = -60.0
    elseif l:w.score <= -100.0
      call filter(a:world.wars, 'v:val isnot l:w')
      call vimtoria#war#log(a:world, a:day, printf('【講和】%s の侵攻は撃退された',
            \ l:map.countries[l:w.attacker].name))
      let a:world.relations[vimtoria#diplo#key(l:w.attacker, l:w.defender)] = -60.0
      " 敗戦国は動揺する
      let a:world.politics[l:w.attacker].rad += 10.0
    endif
  endfor
endfunction

" 州の併合: 所有権を書き換え、建物・労働力はそのまま引き継ぐ
function! vimtoria#war#annex(world, sid, winner) abort
  let l:old = a:world.owner[a:sid]
  let a:world.owner[a:sid] = a:winner
  call vimtoria#econ#rebuild_country_states(a:world)
  " 旧所有国の建設キューから失った州の項目を除去
  call filter(a:world.queues[l:old], 'v:val.sid !=# a:sid')
  let a:world.map_version += 1
endfunction

" 世界ニュース(戦争関連はすべての国のものを記録する)
function! vimtoria#war#log(world, day, text) abort
  call add(a:world.eventlog, vimtoria#core#date_str(a:day) . ' ' . a:text)
  if len(a:world.eventlog) > 20
    call remove(a:world.eventlog, 0, len(a:world.eventlog) - 21)
  endif
endfunction

function! s:largest_state(world, cid) abort
  let l:best = ''
  let l:max = -1.0
  for l:sid in a:world.country_states[a:cid]
    if a:world.workforce[l:sid] > l:max
      let l:max = a:world.workforce[l:sid]
      let l:best = l:sid
    endif
  endfor
  return l:best
endfunction
