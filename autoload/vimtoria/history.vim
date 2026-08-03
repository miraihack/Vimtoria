scriptencoding utf-8
" history.vim - 歴史イベント(1836〜1945年の実史イベントの週次発火)
"
" data/history.vim の定義を日付順に発火させる。対象国が既に消滅している
" 場合は「歴史が分岐した」ものとしてスキップする。発火済みは
" world.history_fired に記録し、時限効果は events.vim に 'h:' 接頭辞で
" 登録する。日本と清は鎖国(world.isolated)で始まり、ペリー来航・
" 南京条約などの open 効果で開国する。
" g:vimtoria_disable_history = 1 で止められる(テスト用)。

function! vimtoria#history#init_world(world) abort
  " 1836年時点の鎖国国(交易・外交不可。歴史イベントで開国)
  let a:world.isolated = {'JAP': 1, 'QIN': 1}
  let a:world.history_fired = {}
endfunction

function! vimtoria#history#tick(world, day, player) abort
  if get(g:, 'vimtoria_disable_history', 0)
    return
  endif
  let l:data = vimtoria#data#history()
  for l:hid in l:data.order
    if l:data.events[l:hid].day > a:day
      break
    endif
    if has_key(a:world.history_fired, l:hid)
      continue
    endif
    let a:world.history_fired[l:hid] = 1
    call s:fire(a:world, l:hid, a:day)
  endfor
endfunction

function! s:fire(world, hid, day) abort
  let l:def = vimtoria#data#history().events[a:hid]
  let l:cid = l:def.country
  " 対象国が消滅していれば歴史は分岐した — 何も起きない
  if !empty(l:cid) && empty(a:world.country_states[l:cid])
    return
  endif
  let l:fx = l:def.effects
  if !empty(l:cid)
    " 開国
    if get(l:fx, 'open', 0) && has_key(a:world.isolated, l:cid)
      call remove(a:world.isolated, l:cid)
    endif
    " 国庫(週間所得×係数で国の規模に自動対応)
    if has_key(l:fx, 'treasury_weeks')
      let a:world.treasuries[l:cid] +=
            \ a:world.stats[l:cid].income * l:fx.treasury_weeks
    endif
    " 全州の労働力増減(飢饉・移民・戦禍)
    if has_key(l:fx, 'workforce_pct')
      for l:sid in a:world.country_states[l:cid]
        let a:world.workforce[l:sid] =
              \ a:world.workforce[l:sid] * (1.0 + l:fx.workforce_pct)
      endfor
    endif
    " 急進性の即時増減
    if has_key(l:fx, 'rad')
      let l:pol = a:world.politics[l:cid]
      let l:pol.rad += l:fx.rad
      if l:pol.rad < 0.0
        let l:pol.rad = 0.0
      elseif l:pol.rad > 100.0
        let l:pol.rad = 100.0
      endif
    endif
    " 軍備の増減(動員・敗戦)
    if has_key(l:fx, 'regiments_pct')
      let a:world.military[l:cid].regiments =
            \ a:world.military[l:cid].regiments * (1.0 + l:fx.regiments_pct)
    endif
    if has_key(l:fx, 'ships_pct')
      let a:world.military[l:cid].ships =
            \ a:world.military[l:cid].ships * (1.0 + l:fx.ships_pct)
    endif
    " 時限効果(out/out_all/research/build_cap/trade × duration 週)
    if get(l:fx, 'duration', 0) > 0
      call vimtoria#events#add_timed(a:world, l:cid, 'h:' . a:hid, l:fx.duration)
    endif
  endif
  " 二国間関係の変化(当事国が両方生きている場合のみ)
  if has_key(l:fx, 'rel')
    for l:r in l:fx.rel
      if !empty(a:world.country_states[l:r[0]])
            \ && !empty(a:world.country_states[l:r[1]])
        call vimtoria#diplo#add_relation(a:world, l:r[0], l:r[1], l:r[2])
      endif
    endfor
  endif
  " 州の割譲(アラスカ売却など。現所有者が当事国の場合のみ)
  if has_key(l:fx, 'cede')
    let l:sid = l:fx.cede[0]
    let l:to = l:fx.cede[1]
    if a:world.owner[l:sid] ==# l:cid && !empty(a:world.country_states[l:to])
      call vimtoria#war#annex(a:world, l:sid, l:to)
    endif
  endif
  " 世界ニュースとして全プレイヤーのログに載せる
  call vimtoria#war#log(a:world, a:day, printf(vimtoria#i18n#t('log_history'),
        \ vimtoria#i18n#name(l:def), vimtoria#i18n#desc(l:def)))
endfunction
