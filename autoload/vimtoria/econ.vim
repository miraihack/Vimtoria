scriptencoding utf-8
" econ.vim - 経済シミュレーション(市場・生産・雇用・賃金・財政)
"
" 週次サイクル(国=単一市場ごと):
"   1. 建物の売買注文と Pop の需要(前週の生活水準に応じた需要係数付き)、
"      鉄道の石炭消費、建設資材需要を集計
"   2. 需給から価格を更新(Victoria 3 と同型の式)
"   3. 新価格で建物の損益を計算 → 賃金・配当・雇用調整
"   4. 財政: 課税 → 政府維持費 → 利払い → 建設。研究を進め、AI 国は
"      研究と建設を自動決定
"   5. 州間の職業移動: 失業者が求人のある州へ毎週少しずつ移る
"
" 労働力は world.workforce[sid](千人)で動的に管理する(移動で変わる)。
" 国庫は信用限度(週間所得×credit_mult)まで負になれる(=国債)。

" 需給価格式: base * (1 + range * (buy - sell) / max(buy, sell))
function! vimtoria#econ#price_for(base, buy, sell) abort
  let l:range = vimtoria#data#economy().const.price_range
  if a:buy <= 0.0 && a:sell <= 0.0
    return a:base
  endif
  let l:hi = a:buy > a:sell ? a:buy : a:sell
  let l:delta = l:range * (a:buy - a:sell) / l:hi
  if l:delta > l:range
    let l:delta = l:range
  elseif l:delta < -l:range
    let l:delta = -l:range
  endif
  return a:base * (1.0 + l:delta)
endfunction

function! vimtoria#econ#init(state) abort
  let l:eco = vimtoria#data#economy()
  let l:map = vimtoria#data#map()
  let l:world = {'buildings': {}, 'markets': {}, 'stats': {},
        \ 'treasuries': {}, 'queues': {}, 'tax_rates': {}, 'workforce': {}}
  for [l:sid, l:stt] in items(l:map.states)
    let l:workforce = l:stt.pop * 10.0 * l:eco.const.workforce_rate
    let l:world.workforce[l:sid] = l:workforce
    let l:levels_total = l:workforce / l:eco.const.level_size
    let l:world.buildings[l:sid] = {}
    for [l:bid, l:bdef] in items(l:eco.buildings)
      let l:lv = l:levels_total * l:bdef.share
      if l:lv > 0.0
        let l:world.buildings[l:sid][l:bid] =
              \ {'levels': l:lv, 'f': l:eco.const.init_f, 'gross': 0.0}
      endif
    endfor
  endfor
  for l:cid in keys(l:map.countries)
    let l:world.markets[l:cid] = {}
    for l:gid in keys(l:eco.goods)
      let l:world.markets[l:cid][l:gid] =
            \ {'price': l:eco.goods[l:gid].base, 'buy': 0.0, 'sell': 0.0}
    endfor
    let l:world.treasuries[l:cid] = 10000.0
    let l:world.queues[l:cid] = []
    let l:world.tax_rates[l:cid] = l:eco.const.tax_rate
    let l:world.stats[l:cid] = {'gdp': 0.0, 'income': 0.0, 'sol': 1.0,
          \ 'workforce': 0.0, 'unemployed': 0.0,
          \ 'tax': 0.0, 'upkeep': 0.0, 'spend': 0.0,
          \ 'interest': 0.0, 'credit': 0.0}
  endfor
  call vimtoria#tech#init_world(l:world)
  call vimtoria#events#init_world(l:world)
  let a:state.world = l:world
endfunction

function! vimtoria#econ#tick(state) abort
  let l:map = vimtoria#data#map()
  for l:cid in keys(l:map.countries)
    call s:tick_country(a:state.world, l:cid, a:state.country, a:state.day)
  endfor
  let a:state.treasury = float2nr(a:state.world.treasuries[a:state.country])
endfunction

" 州の労働力・雇用の要約(UI からも使う)
function! vimtoria#econ#state_info(state, sid) abort
  let l:eco = vimtoria#data#economy()
  let l:workforce = a:state.world.workforce[a:sid]
  let l:employed = 0.0
  for [l:bid, l:b] in items(a:state.world.buildings[a:sid])
    let l:employed += l:b.levels * l:b.f * l:eco.const.level_size
  endfor
  let l:unemployed = l:workforce - l:employed
  return {'workforce': l:workforce, 'employed': l:employed,
        \ 'unemployed': l:unemployed > 0.0 ? l:unemployed : 0.0}
endfunction

function! s:tick_country(world, cid, player, day) abort
  let l:eco = vimtoria#data#economy()
  let l:map = vimtoria#data#map()
  let l:market = a:world.markets[a:cid]
  let l:mods = a:world.mods[a:cid]

  " ランダムイベント(期限処理・抽選・倍率再計算)
  call vimtoria#events#tick(a:world, a:cid, a:day, a:cid ==# a:player)
  let l:evm = a:world.event_mods[a:cid]

  " 需要係数: 前週の生活水準が高いほど消費が増える
  let l:dm = 0.5 + 0.5 * a:world.stats[a:cid].sol
  if l:dm < l:eco.const.dm_min
    let l:dm = l:eco.const.dm_min
  elseif l:dm > l:eco.const.dm_max
    let l:dm = l:eco.const.dm_max
  endif

  " --- 1. 注文集計 ---
  let l:buy = {}
  let l:sell = {}
  for l:gid in keys(l:eco.goods)
    let l:buy[l:gid] = 0.0
    let l:sell[l:gid] = 0.0
  endfor
  let l:workers = 0.0
  let l:owners = 0.0
  let l:subsist = 0.0
  let l:workforce_total = 0.0
  for l:sid in l:map.country_states[a:cid]
    let l:workforce_total += a:world.workforce[l:sid]
    let l:employed = 0.0
    for [l:bid, l:b] in items(a:world.buildings[l:sid])
      let l:bdef = l:eco.buildings[l:bid]
      let l:eff = l:b.levels * l:b.f
      let l:om = get(l:mods.out, l:bid, 1.0) * l:evm.out_all
            \ * get(l:evm.out, l:bid, 1.0)
      for [l:gid, l:q] in items(l:bdef.out)
        let l:sell[l:gid] += l:q * l:om * l:eff
      endfor
      for [l:gid, l:q] in items(l:bdef['in'])
        let l:buy[l:gid] += l:q * l:eff
      endfor
      let l:workers += l:bdef.workers_pl * l:eff
      let l:owners += l:bdef.owners_pl * l:eff
      let l:employed += l:eff * l:eco.const.level_size
    endfor
    let l:unemp = a:world.workforce[l:sid] - l:employed
    if l:unemp > 0.0
      let l:subsist += l:unemp
    endif
  endfor
  " Pop 需要(自給農は必需品の一部だけ市場で購う)
  for [l:gid, l:q] in items(l:eco.needs_base)
    let l:buy[l:gid] += l:q * l:dm * (l:workers + l:owners
          \ + l:subsist * l:eco.const.subsist_needs)
  endfor
  for [l:gid, l:q] in items(l:eco.needs_owner)
    let l:buy[l:gid] += l:q * l:dm * l:owners
  endfor
  " 鉄道網の石炭消費(研究済みの場合)
  if l:mods.rail
    let l:buy['coal'] += l:workforce_total * l:eco.const.rail_coal_per_k
  endif
  " 建設キューの資材需要
  call vimtoria#build#demand(a:world, a:cid, l:buy)

  " --- 2. 価格更新 ---
  for l:gid in keys(l:eco.goods)
    let l:m = l:market[l:gid]
    let l:m.buy = l:buy[l:gid]
    let l:m.sell = l:sell[l:gid]
    let l:m.price = vimtoria#econ#price_for(
          \ l:eco.goods[l:gid].base, l:m.buy, l:m.sell)
  endfor

  " --- 3. 建物損益・賃金・雇用調整 ---
  let l:gdp = 0.0
  let l:wages_total = 0.0
  let l:div_total = 0.0
  let l:subsist_total = 0.0
  let l:unemployed_total = 0.0
  let l:state_unemp = {}
  let l:state_unfilled = {}
  for l:sid in l:map.country_states[a:cid]
    let l:workforce = a:world.workforce[l:sid]
    let l:employed = 0.0
    for [l:bid, l:b] in items(a:world.buildings[l:sid])
      let l:employed += l:b.levels * l:b.f * l:eco.const.level_size
    endfor
    let l:unemployed = l:workforce - l:employed
    if l:unemployed < 0.0
      let l:unemployed = 0.0
    endif
    for [l:bid, l:b] in items(a:world.buildings[l:sid])
      let l:bdef = l:eco.buildings[l:bid]
      let l:eff = l:b.levels * l:b.f
      let l:om = get(l:mods.out, l:bid, 1.0) * l:evm.out_all
            \ * get(l:evm.out, l:bid, 1.0)
      let l:rev = 0.0
      for [l:gid, l:q] in items(l:bdef.out)
        let l:rev += l:q * l:om * l:eff * l:market[l:gid].price
      endfor
      let l:cost = 0.0
      for [l:gid, l:q] in items(l:bdef['in'])
        let l:cost += l:q * l:eff * l:market[l:gid].price
      endfor
      let l:gross = l:rev - l:cost
      let l:b.gross = l:gross
      let l:gdp += l:rev
      if l:gross > 0.0
        let l:wages_total += l:gross * l:eco.const.wage_share
        let l:div_total += l:gross * (1.0 - l:eco.const.wage_share)
      endif
      " 黒字なら雇用を増やし(失業者がいれば)、赤字なら減らす
      if l:gross > 0.0 && l:unemployed > 0.5 && l:b.f < 1.0
        let l:hired = l:b.levels * l:eco.const.hire_step * l:eco.const.level_size
        if l:hired > l:unemployed
          let l:hired = l:unemployed
        endif
        let l:b.f += l:hired / (l:b.levels * l:eco.const.level_size)
        if l:b.f > 1.0
          let l:b.f = 1.0
        endif
        let l:unemployed -= l:hired
      elseif l:gross < 0.0
        let l:b.f -= l:eco.const.hire_step
        if l:b.f < l:eco.const.min_f
          let l:b.f = l:eco.const.min_f
        endif
      endif
    endfor
    " 移動用: 州ごとの失業者と欠員(調整後の f で計算)
    let l:unfilled = 0.0
    for [l:bid, l:b] in items(a:world.buildings[l:sid])
      let l:unfilled += l:b.levels * (1.0 - l:b.f) * l:eco.const.level_size
    endfor
    let l:state_unemp[l:sid] = l:unemployed
    let l:state_unfilled[l:sid] = l:unfilled
    let l:unemployed_total += l:unemployed
    let l:subsist_total += l:unemployed * l:eco.const.subsist_income
  endfor

  " --- 4. 財政(課税 → 維持費 → 利払い → 建設)・研究・AI ---
  let l:tax_rate = a:world.tax_rates[a:cid]
  let l:income = l:wages_total + l:div_total + l:subsist_total
  let l:tax = l:income * l:tax_rate
  let a:world.treasuries[a:cid] += l:tax
  let l:upkeep = l:workforce_total * l:eco.const.upkeep_per_k
  let a:world.treasuries[a:cid] -= l:upkeep
  " 国債: 負の国庫には週割り金利がかかる
  let l:interest = 0.0
  if a:world.treasuries[a:cid] < 0.0
    let l:interest = -a:world.treasuries[a:cid] * l:mods.interest / 52.0
    let a:world.treasuries[a:cid] -= l:interest
  endif
  " 建設は信用限度(週間所得 × credit_mult)まで借金しながら進められる
  let l:credit = l:income * l:eco.const.credit_mult
  let l:spend = vimtoria#build#progress(a:world, a:cid, l:credit)
  " 研究(イベントの研究力倍率込み)
  call vimtoria#tech#tick(a:world, a:cid,
        \ vimtoria#tech#rate(a:world, a:cid, l:workforce_total)
        \ * l:evm.research)
  " AI 国の意思決定
  if a:cid !=# a:player
    call vimtoria#ai#decide(a:world, a:cid)
  endif

  " --- 5. 州間の職業移動(失業者 → 欠員のある州) ---
  let l:unfilled_total = 0.0
  for l:v in values(l:state_unfilled)
    let l:unfilled_total += l:v
  endfor
  if l:unemployed_total > 0.5 && l:unfilled_total > 0.5
        \ && len(l:state_unemp) > 1
    let l:move = l:unemployed_total * l:eco.const.migration_rate
    if l:move > l:unfilled_total
      let l:move = l:unfilled_total
    endif
    for l:sid in keys(l:state_unemp)
      let a:world.workforce[l:sid] +=
            \ l:move * (l:state_unfilled[l:sid] / l:unfilled_total
            \          - l:state_unemp[l:sid] / l:unemployed_total)
    endfor
  endif

  " --- 統計 ---
  let l:basket = 0.0
  for [l:gid, l:q] in items(l:eco.needs_base)
    let l:basket += l:q * l:market[l:gid].price
  endfor
  let l:sol = 0.0
  if l:workforce_total > 0.0 && l:basket > 0.0
    let l:sol = l:income * (1.0 - l:tax_rate) / l:workforce_total / l:basket
  endif
  let a:world.stats[a:cid] = {
        \ 'gdp': l:gdp,
        \ 'income': l:income,
        \ 'sol': l:sol,
        \ 'workforce': l:workforce_total,
        \ 'unemployed': l:unemployed_total,
        \ 'tax': l:tax,
        \ 'upkeep': l:upkeep,
        \ 'spend': l:spend,
        \ 'interest': l:interest,
        \ 'credit': l:credit,
        \ }
endfunction
