scriptencoding utf-8
" data.vim - data/ 配下のゲームデータのローダ
" データ本体はコードから分離した data/*.vim の辞書定義(Mod しやすくするため)。

let s:root = expand('<sfile>:p:h:h:h')
let s:map_cache = {}
let s:economy_cache = {}
let s:tech_cache = {}

function! vimtoria#data#tech() abort
  if empty(s:tech_cache)
    execute 'source' fnameescape(s:root . '/data/tech.vim')
    let s:tech_cache = g:vimtoria_data_tech
  endif
  return s:tech_cache
endfunction

let s:events_cache = {}

function! vimtoria#data#events() abort
  if empty(s:events_cache)
    execute 'source' fnameescape(s:root . '/data/events.vim')
    let s:events_cache = g:vimtoria_data_events
  endif
  return s:events_cache
endfunction

let s:politics_cache = {}

function! vimtoria#data#politics() abort
  if empty(s:politics_cache)
    execute 'source' fnameescape(s:root . '/data/politics.vim')
    let s:politics_cache = g:vimtoria_data_politics
  endif
  return s:politics_cache
endfunction

let s:diplomacy_cache = {}

function! vimtoria#data#diplomacy() abort
  if empty(s:diplomacy_cache)
    execute 'source' fnameescape(s:root . '/data/diplomacy.vim')
    let s:diplomacy_cache = g:vimtoria_data_diplomacy
  endif
  return s:diplomacy_cache
endfunction

function! vimtoria#data#map() abort
  if !empty(s:map_cache)
    return s:map_cache
  endif
  execute 'source' fnameescape(s:root . '/data/map.vim')
  let s:map_cache = g:vimtoria_data_map
  call s:locate_states(s:map_cache)
  " 国 → 州リストの逆引きを前計算
  let s:map_cache.country_states = {}
  for l:cid in keys(s:map_cache.countries)
    let s:map_cache.country_states[l:cid] = []
  endfor
  for [l:sid, l:stt] in items(s:map_cache.states)
    call add(s:map_cache.country_states[l:stt.country], l:sid)
  endfor
  for l:cid in keys(s:map_cache.country_states)
    call sort(s:map_cache.country_states[l:cid])
  endfor
  return s:map_cache
endfunction

function! vimtoria#data#economy() abort
  if !empty(s:economy_cache)
    return s:economy_cache
  endif
  execute 'source' fnameescape(s:root . '/data/economy.vim')
  let s:economy_cache = g:vimtoria_data_economy
  " 1 レベルあたりの労働者/オーナー数と、ホットループ用の items() を前計算
  " (items() は呼ぶたびにリストを確保するので、静的データは一度だけ展開する)
  for l:bdef in values(s:economy_cache.buildings)
    let l:bdef.workers_pl = 0.0
    let l:bdef.owners_pl = 0.0
    for [l:prof, l:n] in items(l:bdef.jobs)
      if s:economy_cache.professions[l:prof].owner
        let l:bdef.owners_pl += l:n
      else
        let l:bdef.workers_pl += l:n
      endif
    endfor
    let l:bdef.out_items = items(l:bdef.out)
    let l:bdef.in_items = items(l:bdef['in'])
    let l:bdef.jobs_items = items(l:bdef.jobs)
    let l:bdef.owner_flags = {}
    for l:prof in keys(l:bdef.jobs)
      let l:bdef.owner_flags[l:prof] = s:economy_cache.professions[l:prof].owner
    endfor
  endfor
  let s:economy_cache.needs_base_items = items(s:economy_cache.needs_base)
  let s:economy_cache.needs_owner_items = items(s:economy_cache.needs_owner)
  let s:economy_cache.mil_goods_items = items(s:economy_cache.mil_goods)
  let s:economy_cache.goods_ids = keys(s:economy_cache.goods)
  let s:economy_cache.goods_base = {}
  for [l:gid, l:g] in items(s:economy_cache.goods)
    let s:economy_cache.goods_base[l:gid] = l:g.base
  endfor
  return s:economy_cache
endfunction

" マップテンプレート中の {TAG} プレースホルダを走査し、
" 各州の座標 (row, col) をデータに書き込む
function! s:locate_states(data) abort
  for l:stt in values(a:data.states)
    let l:stt.row = -1
    let l:stt.col = -1
  endfor
  let l:row = 0
  for l:line in a:data.template
    let l:pos = 0
    while 1
      let l:m = matchstrpos(l:line, '{\u\{3}}', l:pos)
      if l:m[1] == -1
        break
      endif
      let l:tag = l:m[0][1:3]
      if has_key(a:data.states, l:tag)
        let a:data.states[l:tag].row = l:row
        let a:data.states[l:tag].col = l:m[1]
      endif
      let l:pos = l:m[2]
    endwhile
    let l:row += 1
  endfor
endfunction
