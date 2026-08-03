scriptencoding utf-8
" tech.vim - 技術ツリー(研究の進行と国別モディファイア)
"
" world.techs[cid] = {'done': {tid:1}, 'current': tid|'', 'progress': {tid: rp}}
" world.mods[cid]  = 研究済み技術から計算した効果(econ/build が毎週参照)
" 研究対象は切り替えても進捗が per-tech に保存される。

function! vimtoria#tech#init_world(world) abort
  let l:map = vimtoria#data#map()
  let a:world.techs = {}
  let a:world.mods = {}
  for l:cid in keys(l:map.countries)
    let a:world.techs[l:cid] = {'done': {}, 'current': '', 'progress': {}}
    call vimtoria#tech#recompute_mods(a:world, l:cid)
  endfor
endfunction

function! vimtoria#tech#recompute_mods(world, cid) abort
  let l:data = vimtoria#data#tech()
  let l:mods = {'out': {}, 'out_all': 1.0, 'build_cap': 1.0, 'research': 1.0,
        \ 'trade': 1.0, 'mil': 1.0, 'mil_cap': 1.0, 'tariff': 1.0,
        \ 'tax_eff': 1.0, 'upkeep': 1.0, 'rad': 0.0,
        \ 'interest': 0.05, 'rail': 0}
  for l:tid in keys(a:world.techs[a:cid].done)
    let l:fx = l:data.techs[l:tid].effects
    if has_key(l:fx, 'out')
      for [l:bid, l:m] in items(l:fx.out)
        let l:mods.out[l:bid] = get(l:mods.out, l:bid, 1.0) * l:m
      endfor
    endif
    " 乗算で積み上がる倍率
    for l:key in ['out_all', 'build_cap', 'research', 'trade', 'mil',
          \       'mil_cap', 'tariff', 'tax_eff', 'upkeep']
      if has_key(l:fx, l:key)
        let l:mods[l:key] = l:mods[l:key] * l:fx[l:key]
      endif
    endfor
    if has_key(l:fx, 'rad')
      let l:mods.rad += l:fx.rad
    endif
    if has_key(l:fx, 'interest') && l:fx.interest < l:mods.interest
      let l:mods.interest = l:fx.interest
    endif
    if get(l:fx, 'rail', 0)
      let l:mods.rail = 1
    endif
  endfor
  let a:world.mods[a:cid] = l:mods
endfunction

let s:list_cache = {}
let s:menu_cache = {}

" その国が研究しうる技術 ID のリスト(固有技術は対象国のみ)
function! vimtoria#tech#list_for(cid) abort
  if !has_key(s:list_cache, a:cid)
    let l:data = vimtoria#data#tech()
    let l:list = []
    for l:tid in l:data.order
      let l:def = l:data.techs[l:tid]
      if !has_key(l:def, 'country') || index(l:def.country, a:cid) >= 0
        call add(l:list, l:tid)
      endif
    endfor
    let s:list_cache[a:cid] = l:list
  endif
  return s:list_cache[a:cid]
endfunction

" 技術画面のメニュー順(分野ごとにまとめた表示順)
function! vimtoria#tech#menu_for(cid) abort
  if !has_key(s:menu_cache, a:cid)
    let l:data = vimtoria#data#tech()
    let l:menu = []
    for l:branch in l:data.branch_order
      for l:tid in vimtoria#tech#list_for(a:cid)
        if l:data.techs[l:tid].branch ==# l:branch
          call add(l:menu, l:tid)
        endif
      endfor
    endfor
    let s:menu_cache[a:cid] = l:menu
  endif
  return s:menu_cache[a:cid]
endfunction

" 建物の産出倍率
function! vimtoria#tech#out_mult(world, cid, bid) abort
  return get(a:world.mods[a:cid].out, a:bid, 1.0)
endfunction

" 研究可能か(未研究・前提充足・固有技術は対象国のみ)
function! vimtoria#tech#available(world, cid, tid) abort
  let l:data = vimtoria#data#tech()
  let l:def = l:data.techs[a:tid]
  if has_key(l:def, 'country') && index(l:def.country, a:cid) < 0
    return 0
  endif
  let l:t = a:world.techs[a:cid]
  if has_key(l:t.done, a:tid)
    return 0
  endif
  for l:req in l:def.req
    if !has_key(l:t.done, l:req)
      return 0
    endif
  endfor
  return 1
endfunction

" 研究開始。成功なら空文字、失敗なら理由を返す
function! vimtoria#tech#start(world, cid, tid) abort
  let l:data = vimtoria#data#tech()
  let l:t = a:world.techs[a:cid]
  if has_key(l:t.done, a:tid)
    return printf(vimtoria#i18n#t('err_tech_done'),
          \ vimtoria#i18n#name(l:data.techs[a:tid]))
  endif
  if !vimtoria#tech#available(a:world, a:cid, a:tid)
    let l:missing = []
    for l:req in l:data.techs[a:tid].req
      if !has_key(l:t.done, l:req)
        call add(l:missing, vimtoria#i18n#name(l:data.techs[l:req]))
      endif
    endfor
    return printf(vimtoria#i18n#t('err_tech_req'),
          \ join(l:missing, vimtoria#i18n#t('list_sep')))
  endif
  let l:t.current = a:tid
  return ''
endfunction

" 週次の研究力(rp/週)。労働力の平方根でスケールし、
" 技術と法律(政体・参政権)の研究倍率がかかる
function! vimtoria#tech#rate(world, cid, workforce) abort
  let l:c = vimtoria#data#tech().const
  let l:wf = a:workforce > 0.0 ? a:workforce : 0.0
  return (l:c.rp_base + sqrt(l:wf) / l:c.rp_div)
        \ * a:world.mods[a:cid].research
        \ * a:world.law_mods[a:cid].research
endfunction

" 週次進行。完了したら効果を再計算する
function! vimtoria#tech#tick(world, cid, rp) abort
  let l:data = vimtoria#data#tech()
  let l:t = a:world.techs[a:cid]
  if empty(l:t.current)
    return
  endif
  let l:tid = l:t.current
  let l:t.progress[l:tid] = get(l:t.progress, l:tid, 0.0) + a:rp
  if l:t.progress[l:tid] >= l:data.techs[l:tid].cost
    let l:t.done[l:tid] = 1
    let l:t.current = ''
    call vimtoria#tech#recompute_mods(a:world, a:cid)
  endif
endfunction
