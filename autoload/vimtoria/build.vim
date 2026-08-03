scriptencoding utf-8
" build.vim - 建設システム
"
" 国ごとに建設キューを持ち、毎週「建設力」ポイント分だけ先頭から進める。
" 進捗 1 ポイントごとに資材(build_goods)を市場価格で国庫から購入する。
" 国庫が尽きるとその週の建設は停止する。完成で対象州の建物が +1 レベル。

" 建設力 = (base + 国の労働力(千人) / div) × 技術倍率 × 法律 × イベント
function! vimtoria#build#capacity(world, cid) abort
  let l:eco = vimtoria#data#economy()
  let l:workforce = 0.0
  for l:sid in a:world.country_states[a:cid]
    let l:workforce += a:world.workforce[l:sid]
  endfor
  return (l:eco.const.build_capacity_base
        \ + l:workforce / l:eco.const.build_capacity_div)
        \ * a:world.mods[a:cid].build_cap
        \ * a:world.law_mods[a:cid].build_cap
        \ * a:world.event_mods[a:cid].build_cap
endfunction

" 現在の市場価格での 1 ポイントあたりの費用(£)
function! vimtoria#build#point_cost(market) abort
  let l:eco = vimtoria#data#economy()
  let l:cost = 0.0
  for [l:gid, l:q] in items(l:eco.build_goods)
    let l:cost += l:q * a:market[l:gid].price
  endfor
  return l:cost
endfunction

" キューに追加。成功なら空文字、失敗なら理由を返す
function! vimtoria#build#enqueue(state, sid, bid) abort
  let l:eco = vimtoria#data#economy()
  let l:map = vimtoria#data#map()
  if a:state.world.owner[a:sid] !=# a:state.country
    return l:map.states[a:sid].name . ' は自国領ではありません'
  endif
  let l:queue = a:state.world.queues[a:state.country]
  if len(l:queue) >= l:eco.const.build_queue_max
    return 'キューが一杯です(最大' . l:eco.const.build_queue_max . '件)'
  endif
  call add(l:queue, {'sid': a:sid, 'bid': a:bid,
        \ 'done': 0.0, 'total': l:eco.const.build_points})
  return ''
endfunction

" 末尾のキュー項目を取り消す(進捗は返金されない)
function! vimtoria#build#cancel_last(state) abort
  let l:queue = a:state.world.queues[a:state.country]
  if empty(l:queue)
    return 'キューは空です'
  endif
  call remove(l:queue, -1)
  return ''
endfunction

" 今週進める予定のポイント分の資材需要を買い注文に載せる(価格決定前に呼ぶ)
function! vimtoria#build#demand(world, cid, buy) abort
  let l:eco = vimtoria#data#economy()
  let l:remaining = 0.0
  for l:item in a:world.queues[a:cid]
    let l:remaining += l:item.total - l:item.done
  endfor
  if l:remaining <= 0.0
    return
  endif
  let l:cap = vimtoria#build#capacity(a:world, a:cid)
  let l:pts = l:remaining < l:cap ? l:remaining : l:cap
  for [l:gid, l:q] in items(l:eco.build_goods)
    let a:buy[l:gid] += l:q * l:pts
  endfor
endfunction

" キューを進める(価格決定後に呼ぶ)。支出£を返す。
" credit(信用限度)の分まで国庫を負にしながら進められる
function! vimtoria#build#progress(world, cid, credit) abort
  let l:eco = vimtoria#data#economy()
  let l:queue = a:world.queues[a:cid]
  if empty(l:queue)
    return 0.0
  endif
  let l:market = a:world.markets[a:cid]
  let l:unit = vimtoria#build#point_cost(l:market)
  let l:cap = vimtoria#build#capacity(a:world, a:cid)
  let l:avail = a:world.treasuries[a:cid] + a:credit
  let l:spent = 0.0
  while l:cap > 0.001 && !empty(l:queue)
    let l:item = l:queue[0]
    let l:step = l:item.total - l:item.done
    if l:step > l:cap
      let l:step = l:cap
    endif
    " 信用限度内で支払える分まで縮める
    if l:unit > 0.0 && l:step * l:unit > l:avail
      let l:step = l:avail / l:unit
    endif
    if l:step <= 0.001
      break
    endif
    let l:cost = l:step * l:unit
    let a:world.treasuries[a:cid] -= l:cost
    let l:avail -= l:cost
    let l:spent += l:cost
    let l:item.done += l:step
    let l:cap -= l:step
    if l:item.done >= l:item.total - 0.001
      call s:complete(a:world, l:item)
      call remove(l:queue, 0)
    endif
  endwhile
  return l:spent
endfunction

" 完成: 対象州の建物を +1 レベル。雇用人数を保存するよう稼働率を薄める
function! s:complete(world, item) abort
  let l:eco = vimtoria#data#economy()
  let l:bs = a:world.buildings[a:item.sid]
  if !has_key(l:bs, a:item.bid)
    let l:bs[a:item.bid] = {'levels': 1.0, 'f': l:eco.const.build_new_f, 'gross': 0.0}
    return
  endif
  let l:b = l:bs[a:item.bid]
  let l:b.f = l:b.f * l:b.levels / (l:b.levels + 1.0)
  if l:b.f < l:eco.const.min_f
    let l:b.f = l:eco.const.min_f
  endif
  let l:b.levels += 1.0
endfunction
