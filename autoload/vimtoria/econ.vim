scriptencoding utf-8
" econ.vim - 経済シミュレーション(市場・生産・雇用・賃金)
"
" 週次サイクル(国=単一市場ごと):
"   1. 建物の売買注文と Pop の需要を集計
"   2. 需給から価格を更新(Victoria 3 と同型の式)
"   3. 新価格で建物の損益を計算 → 賃金・配当・雇用調整
"   4. 所得に課税して国庫へ、統計(GDP・失業率・生活水準)を更新
"
" 雇用されない労働力は自給農として市場外で生計を立てる(M2 の建設労働の
" 供給源でもある)。

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
  let l:world = {'buildings': {}, 'markets': {}, 'stats': {}, 'treasuries': {}}
  for [l:sid, l:stt] in items(l:map.states)
    let l:levels_total = l:stt.pop * 10.0 * l:eco.const.workforce_rate
          \ / l:eco.const.level_size
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
    let l:world.stats[l:cid] = {'gdp': 0.0, 'income': 0.0, 'sol': 0.0,
          \ 'workforce': 0.0, 'unemployed': 0.0}
  endfor
  let a:state.world = l:world
endfunction

function! vimtoria#econ#tick(state) abort
  let l:map = vimtoria#data#map()
  for l:cid in keys(l:map.countries)
    call s:tick_country(a:state.world, l:cid)
  endfor
  let a:state.treasury = float2nr(a:state.world.treasuries[a:state.country])
endfunction

" 州の労働力・雇用の要約(UI からも使う)
function! vimtoria#econ#state_info(state, sid) abort
  let l:eco = vimtoria#data#economy()
  let l:map = vimtoria#data#map()
  let l:workforce = l:map.states[a:sid].pop * 10.0 * l:eco.const.workforce_rate
  let l:employed = 0.0
  for [l:bid, l:b] in items(a:state.world.buildings[a:sid])
    let l:employed += l:b.levels * l:b.f * l:eco.const.level_size
  endfor
  let l:unemployed = l:workforce - l:employed
  return {'workforce': l:workforce, 'employed': l:employed,
        \ 'unemployed': l:unemployed > 0.0 ? l:unemployed : 0.0}
endfunction

function! s:tick_country(world, cid) abort
  let l:eco = vimtoria#data#economy()
  let l:map = vimtoria#data#map()
  let l:market = a:world.markets[a:cid]

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
  for l:sid in l:map.country_states[a:cid]
    let l:employed = 0.0
    for [l:bid, l:b] in items(a:world.buildings[l:sid])
      let l:bdef = l:eco.buildings[l:bid]
      let l:eff = l:b.levels * l:b.f
      for [l:gid, l:q] in items(l:bdef.out)
        let l:sell[l:gid] += l:q * l:eff
      endfor
      for [l:gid, l:q] in items(l:bdef['in'])
        let l:buy[l:gid] += l:q * l:eff
      endfor
      let l:workers += l:bdef.workers_pl * l:eff
      let l:owners += l:bdef.owners_pl * l:eff
      let l:employed += l:eff * l:eco.const.level_size
    endfor
    let l:unemp = l:map.states[l:sid].pop * 10.0 * l:eco.const.workforce_rate
          \ - l:employed
    if l:unemp > 0.0
      let l:subsist += l:unemp
    endif
  endfor
  " 自給農は必需品の一部(subsist_needs)だけ市場で購う
  for [l:gid, l:q] in items(l:eco.needs_base)
    let l:buy[l:gid] += l:q * (l:workers + l:owners
          \ + l:subsist * l:eco.const.subsist_needs)
  endfor
  for [l:gid, l:q] in items(l:eco.needs_owner)
    let l:buy[l:gid] += l:q * l:owners
  endfor

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
  let l:workforce_total = 0.0
  let l:unemployed_total = 0.0
  for l:sid in l:map.country_states[a:cid]
    let l:workforce = l:map.states[l:sid].pop * 10.0 * l:eco.const.workforce_rate
    let l:workforce_total += l:workforce
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
      let l:rev = 0.0
      for [l:gid, l:q] in items(l:bdef.out)
        let l:rev += l:q * l:eff * l:market[l:gid].price
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
    let l:unemployed_total += l:unemployed
    let l:subsist_total += l:unemployed * l:eco.const.subsist_income
  endfor

  " --- 4. 課税と統計 ---
  let l:income = l:wages_total + l:div_total + l:subsist_total
  let a:world.treasuries[a:cid] += l:income * l:eco.const.tax_rate
  " 生活水準 = 手取り所得(千人あたり) / 基礎需要バスケット価格
  let l:basket = 0.0
  for [l:gid, l:q] in items(l:eco.needs_base)
    let l:basket += l:q * l:market[l:gid].price
  endfor
  let l:sol = 0.0
  if l:workforce_total > 0.0 && l:basket > 0.0
    let l:sol = l:income * (1.0 - l:eco.const.tax_rate)
          \ / l:workforce_total / l:basket
  endif
  let a:world.stats[a:cid] = {
        \ 'gdp': l:gdp,
        \ 'income': l:income,
        \ 'sol': l:sol,
        \ 'workforce': l:workforce_total,
        \ 'unemployed': l:unemployed_total,
        \ }
endfunction
