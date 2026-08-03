scriptencoding utf-8
" ai.vim - AI 国の簡易運営(毎週呼ばれる)
"
" 研究: 何も研究していなければデータ順で最初に研究可能なものを選ぶ。
" 建設: キューに余裕があり国庫が潤っていれば、市場で最も割高な財
"       (価格/基準比が最大)を産出する建物を、失業者の最も多い自国州に建てる。

function! vimtoria#ai#decide(world, cid, day, player) abort
  call s:decide_research(a:world, a:cid)
  call s:decide_budget(a:world, a:cid)
  call s:decide_build(a:world, a:cid)
  " 外交判断は重い(全ペア走査)ので 4 週間隔・国ごとに位相をずらして分散
  if (a:day / 7 + char2nr(a:cid[0]) + char2nr(a:cid[2])) % 4 == 0
    call vimtoria#diplo#ai(a:world, a:cid, a:day, a:player)
  endif
endfunction

" 財政: 国庫が細れば増税(法律の上限まで、最大15%)、潤えば減税
function! s:decide_budget(world, cid) abort
  let l:eco = vimtoria#data#economy()
  let l:t = a:world.treasuries[a:cid]
  let l:rate = a:world.tax_rates[a:cid]
  let l:cap = a:world.law_mods[a:cid].tax_max
  if l:cap > 0.15
    let l:cap = 0.15
  endif
  if l:t < l:eco.const.ai_build_reserve && l:rate + l:eco.const.tax_step <= l:cap
    let a:world.tax_rates[a:cid] = l:rate + l:eco.const.tax_step
  elseif l:t > l:eco.const.ai_build_reserve * 5.0
        \ && l:rate > l:eco.const.tax_rate
    let a:world.tax_rates[a:cid] = l:rate - l:eco.const.tax_step
  endif
endfunction

function! s:decide_research(world, cid) abort
  let l:t = a:world.techs[a:cid]
  if !empty(l:t.current)
    return
  endif
  for l:tid in vimtoria#data#tech().order
    if vimtoria#tech#available(a:world, a:cid, l:tid)
      let l:t.current = l:tid
      return
    endif
  endfor
endfunction

function! s:decide_build(world, cid) abort
  let l:eco = vimtoria#data#economy()
  let l:queue = a:world.queues[a:cid]
  if len(l:queue) >= l:eco.const.ai_queue_max
        \ || a:world.treasuries[a:cid] < l:eco.const.ai_build_reserve
    return
  endif
  let l:market = a:world.markets[a:cid]
  " 価格/基準比が最大の財 → それを産出する建物
  let l:best_bid = ''
  let l:best_ratio = 0.0
  for [l:bid, l:bdef] in items(l:eco.buildings)
    for l:gid in keys(l:bdef.out)
      let l:ratio = l:market[l:gid].price / l:eco.goods[l:gid].base
      if l:ratio > l:best_ratio
        let l:best_ratio = l:ratio
        let l:best_bid = l:bid
      endif
    endfor
  endfor
  if empty(l:best_bid)
    return
  endif
  " 失業者が最も多い自国州へ
  let l:best_sid = ''
  let l:best_unemp = -1.0
  for l:sid in a:world.country_states[a:cid]
    let l:employed = 0.0
    for [l:bid, l:b] in items(a:world.buildings[l:sid])
      let l:employed += l:b.levels * l:b.f * l:eco.const.level_size
    endfor
    let l:unemp = a:world.workforce[l:sid] - l:employed
    if l:unemp > l:best_unemp
      let l:best_unemp = l:unemp
      let l:best_sid = l:sid
    endif
  endfor
  if empty(l:best_sid)
    return
  endif
  call add(l:queue, {'sid': l:best_sid, 'bid': l:best_bid,
        \ 'done': 0.0, 'total': l:eco.const.build_points})
endfunction
