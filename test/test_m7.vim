scriptencoding utf-8
" test_m7.vim - M7(海軍・鎖国・歴史イベント・ブリーフィング)のヘッドレステスト
" 実行: test/run.sh(結果は test/results.txt に書かれる)

let v:errors = []
" 決定性のためランダムイベントを止める(歴史イベントは決定的なので回す)
let g:vimtoria_disable_events = 1

" ---- 歴史イベントデータの整合性(200件規模) ----
let s:hd = vimtoria#data#history()
let s:md = vimtoria#data#map()
let s:pd2 = vimtoria#data#politics()
call assert_true(len(s:hd.events) >= 180,
      \ printf('歴史イベントが少なすぎる: %d', len(s:hd.events)))
call assert_equal(len(s:hd.events), len(s:hd.order))
let s:n_cond = 0
for [s:hid, s:def] in items(s:hd.events)
  call assert_true(empty(s:def.country) || has_key(s:md.countries, s:def.country),
        \ s:hid . ': 対象国が未定義')
  " 1936年以降のイベントは存在しない
  call assert_true(s:def.year >= 1836 && s:def.year <= 1935, s:hid . ': 年が範囲外')
  call assert_true(!empty(s:def.name) && !empty(s:def.name_en), s:hid . ': 名前欠落')
  if has_key(s:def.effects, 'rel')
    for s:r in s:def.effects.rel
      call assert_true(has_key(s:md.countries, s:r[0])
            \ && has_key(s:md.countries, s:r[1]), s:hid . ': rel の国が未定義')
    endfor
  endif
  " 発生条件の整合性(参照先が実在すること)
  if has_key(s:def, 'cond')
    let s:n_cond += 1
    for s:rid in get(s:def.cond, 'req_event', [])
      call assert_true(has_key(s:hd.events, s:rid), s:hid . ': req_event 未定義 ' . s:rid)
      call assert_true(s:hd.events[s:rid].day <= s:def.day,
            \ s:hid . ': req_event が自分より後の日付 ' . s:rid)
    endfor
    for s:lid in get(s:def.cond, 'req_law', [])
      call assert_true(has_key(s:pd2.laws, s:lid), s:hid . ': req_law 未定義 ' . s:lid)
    endfor
  endif
endfor
call assert_true(s:n_cond >= 50, printf('発生条件付きイベントが少ない: %d', s:n_cond))
" order は日付昇順
let s:prev = -1
for s:hid in s:hd.order
  call assert_true(s:hd.events[s:hid].day >= s:prev, s:hid . ': 日付順でない')
  let s:prev = s:hd.events[s:hid].day
endfor

" ---- 鎖国: 日清は交易も外交も不可 ----
call vimtoria#core#init()
let s:st = vimtoria#core#state()
let s:world = s:st.world
call assert_true(get(s:world.isolated, 'JAP', 0), '日本が鎖国していない')
call assert_true(get(s:world.isolated, 'QIN', 0), '清が鎖国していない')
call assert_notequal('', vimtoria#diplo#improve(s:world, 'JAP', 'KOR', 0),
      \ '鎖国中に関係改善できた')
call assert_notequal('', vimtoria#diplo#improve(s:world, 'GBR', 'QIN', 0),
      \ '鎖国国を相手に関係改善できた')
call vimtoria#econ#tick(s:st)
call assert_true(empty(s:world.trade_flows['JAP']), '鎖国中に交易が発生した')
call assert_equal(0.0, s:world.stats['JAP'].tariff, '鎖国中に関税収入がある')
call assert_true(!empty(s:world.trade_flows['GBR'])
      \ || s:world.stats['GBR'].tariff >= 0.0, '開国済み国の交易情報がない')

" ---- 海軍: 初期艦隊・建造・退役 ----
call assert_true(s:world.military['JAP'].ships > 10.0, '日本の初期艦隊が小さすぎる')
call assert_true(vimtoria#war#navy_strength(s:world, 'GBR')
      \ > vimtoria#war#navy_strength(s:world, 'HAW'), '海軍力の序列がおかしい')
let s:world.treasuries['JAP'] = 100000.0
let s:ships0 = s:world.military['JAP'].ships
call assert_equal('', vimtoria#war#recruit_ships(s:world, 'JAP'))
call assert_true(abs(s:world.military['JAP'].ships - s:ships0 - 2.0) < 0.001,
      \ '建造で艦艇が増えない')
call assert_equal('', vimtoria#war#disband_ships(s:world, 'JAP'))
call assert_true(abs(s:world.military['JAP'].ships - s:ships0) < 0.001)

" ---- 渡航上陸: 陸続きは自由、海外は海軍力が要る ----
" 朝鮮→満洲は陸続き
call assert_equal('', vimtoria#war#invasion_check(s:world, 'KOR', 'MAN'))
" 島国日本→大陸は海外だが、日本の海軍なら足りる
call assert_equal('', vimtoria#war#invasion_check(s:world, 'JAP', 'MAN'))
" ハワイ→日本は海軍不足で不可(宣戦も弾かれる)
call assert_notequal('', vimtoria#war#invasion_check(s:world, 'HAW', 'EDO'))
call assert_notequal('', vimtoria#diplo#declare_war(s:world, 'HAW', 'JAP', 'EDO', 0, 'JAP'))
call assert_true(empty(s:world.wars), '海軍不足でも宣戦できてしまった')
" 海軍需(木材・石炭・鋼鉄)が市場に乗っている
call assert_true(s:world.markets['GBR']['coal'].buy > 0.0)

" ---- 歴史イベント: 発火・ログ・開国・割譲 ----
call vimtoria#core#init()
let s:st = vimtoria#core#state()
let s:world = s:st.world
let s:i = 0
while s:i < 70
  let s:st.day += 7
  call vimtoria#econ#tick(s:st)
  let s:i += 1
endwhile
call assert_true(has_key(s:world.history_fired, 'panic_1837'), '1837年恐慌が発火しない')
let s:found = 0
for s:line in s:world.eventlog
  if s:line =~# '歴史'
    let s:found = 1
  endif
endfor
call assert_true(s:found, '歴史イベントがログに載らない')
" ペリー来航(1853)と南京条約(1842)で日清が開国する
let s:st.day = (1853 - 1836) * 365 + 250
call vimtoria#econ#tick(s:st)
call assert_equal(1, get(s:world.history_fired, 'perry', -1), 'ペリー来航が発火しない')
call assert_equal(1, get(s:world.history_fired, 'opium_war', -1),
      \ 'アヘン戦争が発火しない(林則徐→開戦の連鎖)')
call assert_false(has_key(s:world.isolated, 'JAP'), 'ペリー来航後も日本が鎖国中')
call assert_false(has_key(s:world.isolated, 'QIN'), '南京条約後も清が鎖国中')
" 開国後は交易が始まる
call vimtoria#econ#tick(s:st)
call vimtoria#econ#tick(s:st)
call assert_true(s:world.stats['JAP'].tariff > 0.0
      \ || !empty(s:world.trade_flows['JAP']), '開国後も交易が始まらない')
" アラスカ売却(1867)で州が割譲される
let s:st.day = (1868 - 1836) * 365
call vimtoria#econ#tick(s:st)
call assert_equal('USA', s:world.owner['ALA'], 'アラスカが合衆国に渡っていない')
" 発火済みイベントは繰り返さない
let s:fired = len(s:world.history_fired)
call vimtoria#econ#tick(s:st)
call assert_equal(s:fired, len(s:world.history_fired) , '同じイベントが再発火した')

" ---- 対象国が消滅していれば歴史は分岐する ----
call vimtoria#core#init()
let s:st = vimtoria#core#state()
let s:world = s:st.world
" テキサスを併合してから 1837 年へ → テキサス関連イベントは起きない(値 0)
call vimtoria#war#annex(s:world, 'TEX', 'MEX')
let s:st.day = 500
call vimtoria#econ#tick(s:st)
call assert_equal(0, get(s:world.history_fired, 'texas_republic', -1),
      \ '消滅国のイベントが分岐しない')

" ---- 発生条件: 政治体制が革命の分かれ目になる ----
call vimtoria#core#init()
let s:st = vimtoria#core#state()
let s:world = s:st.world
" 墺(絶対王政)は急進化していれば三月革命が起き、
" 仏(立憲君主制)は同じ急進性でも二月革命が起きない
let s:world.politics['AUS'].rad = 30.0
let s:world.politics['FRA'].rad = 30.0
let s:st.day = (1849 - 1836) * 365
call vimtoria#econ#tick(s:st)
call assert_equal(1, get(s:world.history_fired, 'mar_revolution_aus', -1),
      \ '絶対王政の墺で三月革命が起きない')
call assert_equal(0, get(s:world.history_fired, 'feb_revolution_fra', -1),
      \ '立憲君主制の仏で二月革命が起きてしまった')

" ---- 発生条件: 既に開国していればペリー来航は起きない ----
call vimtoria#core#init()
let s:st = vimtoria#core#state()
let s:world = s:st.world
let s:world.isolated = {}
let s:st.day = (1855 - 1836) * 365
call vimtoria#econ#tick(s:st)
call assert_equal(0, get(s:world.history_fired, 'perry', -1),
      \ '開国済みなのにペリー来航が起きた')
call assert_equal(0, get(s:world.history_fired, 'kanagawa', -1),
      \ '先行イベント無しで日米和親条約が起きた(連鎖切断の検証)')

" ---- 国庫: 初期国庫は規模比例で、1年間 AI 任せでも枯渇しない ----
call vimtoria#core#init()
let s:st = vimtoria#core#state()
let s:world = s:st.world
call assert_true(s:world.treasuries['QIN'] > s:world.treasuries['HAW'],
      \ '初期国庫が規模に比例していない')
let s:i = 0
let s:min_t = {}
while s:i < 52
  let s:st.day += 7
  call vimtoria#econ#tick(s:st)
  for [s:cid, s:t] in items(s:world.treasuries)
    if s:t < get(s:min_t, s:cid, 1.0e18)
      let s:min_t[s:cid] = s:t
    endif
  endfor
  let s:i += 1
endwhile
for [s:cid, s:t] in items(s:min_t)
  call assert_true(s:t > -1000.0,
        \ printf('%s の国庫が1年以内に枯渇: 最低 %.0f', s:cid, s:t))
endfor

" ---- ブリーフィング(純関数)----
call vimtoria#core#init()
let s:st = vimtoria#core#state()
let s:box = vimtoria#popup#brief_lines(s:st, 'JAP')
call assert_true(len(s:box) > 8, 'ブリーフィングが短すぎる')
call assert_match('日本', s:box[0])
call assert_match('黒船', join(s:box, "\n"), '日本の情勢解説がない')
call assert_match('鎖国中', join(s:box, "\n"), '鎖国の注記がない')
" 枠幅が揃っている
let s:w = strdisplaywidth(s:box[0])
for s:line in s:box
  call assert_equal(s:w, strdisplaywidth(s:line), 'ブリーフィングの枠幅が不揃い')
endfor
" 全37カ国に両言語の解説がある
let s:map2 = vimtoria#data#map()
for s:cid in s:map2.country_order
  call assert_true(has_key(s:map2.briefs, s:cid), s:cid . ': ブリーフィング未定義')
  call assert_true(!empty(s:map2.briefs[s:cid].ja) && !empty(s:map2.briefs[s:cid].en),
        \ s:cid . ': 言語が欠けている')
  " どの国でも枠付きで生成できる
  call assert_true(len(vimtoria#popup#brief_lines(s:st, s:cid)) > 6, s:cid)
endfor
" 英語でも生成できる
call vimtoria#i18n#set('en')
call assert_match('Qing', vimtoria#popup#brief_lines(s:st, 'QIN')[0])
call vimtoria#i18n#set('ja')

" ---- 概況ポップアップに海軍と鎖国が載る ----
let s:box = vimtoria#popup#country(s:st, 'JAP')
call assert_match('海軍', join(s:box, "\n"), '概況に海軍がない')
call assert_match('鎖国中', join(s:box, "\n"), '概況に鎖国がない')

call vimtoria#core#shutdown()

" ---- 結果出力 ----
if empty(v:errors)
  call writefile(['OK'], 'test/results.txt')
else
  call writefile(['FAIL'] + v:errors, 'test/results.txt')
endif
qa!
