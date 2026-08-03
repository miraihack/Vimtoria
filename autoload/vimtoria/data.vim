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
    call s:tech_gen_descs(s:tech_cache)
  endif
  return s:tech_cache
endfunction

" 技術の説明文(desc/desc_en)を効果辞書から自動生成する。
" 政体・法律の解禁(politics の req_tech)も逆引きして表記する
function! s:tech_gen_descs(data) abort
  let l:eco = vimtoria#data#economy()
  let l:pol = vimtoria#data#politics()
  " 技術 → 解禁される法律のリスト
  let l:unlocks = {}
  for l:lid in l:pol.law_order
    let l:ldef = l:pol.laws[l:lid]
    if has_key(l:ldef, 'req_tech')
      if !has_key(l:unlocks, l:ldef.req_tech)
        let l:unlocks[l:ldef.req_tech] = []
      endif
      call add(l:unlocks[l:ldef.req_tech], l:lid)
    endif
  endfor
  for [l:tid, l:def] in items(a:data.techs)
    let l:def.desc = s:fx_desc(l:def.effects, 0, l:eco, l:pol,
          \ get(l:unlocks, l:tid, []))
    let l:def.desc_en = s:fx_desc(l:def.effects, 1, l:eco, l:pol,
          \ get(l:unlocks, l:tid, []))
  endfor
endfunction

function! s:pct(mult) abort
  return printf('%+d%%', float2nr(round((a:mult - 1.0) * 100.0)))
endfunction

function! s:fx_desc(fx, en, eco, pol, unlocks) abort
  let l:p = []
  for l:lid in a:unlocks
    let l:lname = a:en ? get(a:pol.laws[l:lid], 'name_en', a:pol.laws[l:lid].name)
          \           : a:pol.laws[l:lid].name
    call add(l:p, a:en ? 'unlocks "' . l:lname . '"' : '「' . l:lname . '」を解禁')
  endfor
  if has_key(a:fx, 'out')
    for [l:bid, l:m] in items(a:fx.out)
      let l:bname = a:en ? get(a:eco.buildings[l:bid], 'name_en', a:eco.buildings[l:bid].name)
            \           : a:eco.buildings[l:bid].name
      call add(l:p, a:en ? l:bname . ' output ' . s:pct(l:m)
            \           : l:bname . 'の産出 ' . s:pct(l:m))
    endfor
  endif
  let l:simple = [
        \ ['out_all',   '全産出 ',       'all output '],
        \ ['build_cap', '建設力 ',       'construction '],
        \ ['research',  '研究力 ',       'research '],
        \ ['trade',     '交易量 ',       'trade '],
        \ ['mil',       '軍事力 ',       'military '],
        \ ['mil_cap',   '連隊上限 ',     'regiment cap '],
        \ ['tariff',    '関税収入 ',     'tariff income '],
        \ ['tax_eff',   '徴税効率 ',     'tax efficiency '],
        \ ['upkeep',    '政府維持費 ',   'gov. upkeep '],
        \ ]
  for [l:key, l:ja, l:enl] in l:simple
    if has_key(a:fx, l:key)
      call add(l:p, (a:en ? l:enl : l:ja) . s:pct(a:fx[l:key]))
    endif
  endfor
  if has_key(a:fx, 'interest')
    call add(l:p, a:en
          \ ? printf('debt interest → %g%%/yr', a:fx.interest * 100.0)
          \ : printf('国債年利 → %g%%', a:fx.interest * 100.0))
  endif
  if has_key(a:fx, 'rad')
    call add(l:p, a:en ? printf('radicalism %+.2f/wk', a:fx.rad)
          \           : printf('急進性 %+.2f/週', a:fx.rad))
  endif
  if get(a:fx, 'rail', 0)
    call add(l:p, a:en ? 'rail network consumes coal weekly'
          \           : '鉄道網が石炭を毎週消費')
  endif
  return join(l:p, a:en ? ', ' : '、')
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
" 各州の座標 (row, col) と、行ごとのタグ一覧 row_tags を書き込む。
" row_tags[row] = [[col, sid], ...](col 昇順)で、マップ描画が
" 州名ラベルを左から順に配置するのに使う。
function! s:locate_states(data) abort
  for l:stt in values(a:data.states)
    let l:stt.row = -1
    let l:stt.col = -1
  endfor
  let a:data.row_tags = {}
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
        if !has_key(a:data.row_tags, l:row)
          let a:data.row_tags[l:row] = []
        endif
        call add(a:data.row_tags[l:row], [l:m[1], l:tag])
      endif
      let l:pos = l:m[2]
    endwhile
    let l:row += 1
  endfor
endfunction
