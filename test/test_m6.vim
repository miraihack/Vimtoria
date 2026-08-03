scriptencoding utf-8
" test_m6.vim - M6(拡張技術ツリー・政体・社会運動・交易)のヘッドレステスト
" 実行: test/run.sh(結果は test/results.txt に書かれる)

let v:errors = []
" 決定性のためランダムイベントを止める
let g:vimtoria_disable_events = 1

" ---- 技術データの整合性(206件規模) ----
let s:td = vimtoria#data#tech()
let s:map = vimtoria#data#map()
call assert_true(len(s:td.techs) >= 200,
      \ printf('技術が200個未満: %d', len(s:td.techs)))
call assert_equal(len(s:td.techs), len(s:td.order))
let s:nat = 0
for [s:tid, s:def] in items(s:td.techs)
  call assert_true(s:def.cost > 0.0, s:tid)
  call assert_true(has_key(s:td.branches, s:def.branch), s:tid . ': 分野が未定義')
  call assert_true(s:def.era >= 1836 && s:def.era <= 1945, s:tid . ': 年代が範囲外')
  call assert_true(!empty(s:def.desc) && !empty(s:def.desc_en),
        \ s:tid . ': 説明が生成されていない')
  for s:req in s:def.req
    call assert_true(has_key(s:td.techs, s:req), s:tid . ': 前提が未定義 ' . s:req)
  endfor
  if has_key(s:def, 'country')
    let s:nat += 1
    for s:cid in s:def.country
      call assert_true(has_key(s:map.countries, s:cid), s:tid . ': 対象国が未定義')
    endfor
  endif
endfor
call assert_true(s:nat >= 15, printf('固有技術が少なすぎる: %d', s:nat))

" ---- 政治データの整合性(政体・参政権・運動) ----
let s:pd = vimtoria#data#politics()
for s:g in ['government', 'suffrage']
  call assert_true(has_key(s:pd.groups, s:g), s:g)
endfor
for [s:lid, s:def] in items(s:pd.laws)
  if has_key(s:def, 'req_tech')
    call assert_true(has_key(s:td.techs, s:def.req_tech), s:lid . ': req_tech 未定義')
  endif
endfor
for [s:mid, s:mdef] in items(s:pd.movements)
  call assert_true(has_key(s:pd.laws, s:mdef.target), s:mid . ': target 未定義')
  call assert_true(has_key(s:td.techs, s:mdef.req_tech), s:mid . ': req_tech 未定義')
endfor
" 政体は5種
let s:govs = filter(copy(s:pd.law_order), 's:pd.laws[v:val].group ==# "government"')
call assert_equal(5, len(s:govs), '政体が5種でない')

" ---- 初期政体と law_mods ----
call vimtoria#core#init()
let s:st = vimtoria#core#state()
let s:world = s:st.world
call assert_equal('despotism', s:world.politics['JAP'].laws['government'])
call assert_equal('liberal_democracy', s:world.politics['GBR'].laws['government'])
call assert_true(abs(s:world.law_mods['JAP'].research - 0.9) < 0.001, '専制の研究-10%')
call assert_true(abs(s:world.law_mods['GBR'].trade - 1.25) < 0.001, '自由主義の交易+25%')
call assert_true(s:world.law_mods['JAP'].rad > 0.0, '専制の急進性ドリフト')
call assert_true(s:world.law_mods['GBR'].rad < 0.0, '自由主義の急進性ドリフト')

" ---- 政体の解禁: 思想の研究が必要 ----
call assert_notequal('', vimtoria#politics#start_enact(s:world, 'JAP', 'liberal_democracy'))
call assert_notequal('', vimtoria#politics#start_enact(s:world, 'JAP', 'socialist_state'))
call assert_notequal('', vimtoria#politics#start_enact(s:world, 'JAP', 'anarchist_commune'))
let s:world.techs['JAP'].done['utopian_socialism'] = 1
let s:world.techs['JAP'].done['communist_manifesto'] = 1
let s:world.techs['JAP'].done['scientific_socialism'] = 1
call vimtoria#tech#recompute_mods(s:world, 'JAP')
call assert_equal('', vimtoria#politics#start_enact(s:world, 'JAP', 'socialist_state'))

" ---- 社会運動: 支持が法律への支持を押し上げ、制定で解散する ----
let s:sup0 = vimtoria#politics#support(s:world, 'JAP', 'socialist_state')
let s:world.politics['JAP'].movements['socialist'] = 80.0
let s:sup1 = vimtoria#politics#support(s:world, 'JAP', 'socialist_state')
call assert_true(s:sup1 > s:sup0 + 1.0,
      \ printf('運動の支持ブーストがない: %.2f → %.2f', s:sup0, s:sup1))
" 運動は毎週成長し、急進性を押し上げる
let s:rad0 = s:world.politics['JAP'].rad
call vimtoria#politics#tick(s:world, 'JAP', {}, 1.4, 0, 0)
call assert_true(s:world.politics['JAP'].movements['socialist'] > 80.0, '運動が成長しない')
" 制定完了で運動は解散する
let s:world.politics['JAP'].enact = {'law': 'socialist_state', 'progress': 999.0}
call vimtoria#politics#tick(s:world, 'JAP', {}, 1.0, 0, 0)
call assert_equal('socialist_state', s:world.politics['JAP'].laws['government'])
call assert_false(has_key(s:world.politics['JAP'].movements, 'socialist'),
      \ '制定後も運動が残っている')
" 社会主義: 賃金分配は最大値結合で 0.85
call assert_true(abs(s:world.law_mods['JAP'].wage_share - 0.85) < 0.001)

" ---- 無政府主義: 徴税効率が半減する ----
let s:world.politics['JAP'].laws['government'] = 'anarchist_commune'
call vimtoria#politics#recompute_law_mods(s:world, 'JAP')
call assert_true(abs(s:world.law_mods['JAP'].tax_eff - 0.5) < 0.001)
call vimtoria#econ#tick(s:st)
let s:jap = s:world.stats['JAP']
call assert_true(abs(s:jap.tax
      \ - s:jap.income * s:world.tax_rates['JAP']
      \   * s:world.mods['JAP'].tax_eff * 0.5) < 0.01,
      \ '無政府主義で税収が半減していない')

" ---- 軍事力は技術と政体の倍率で決まる ----
call vimtoria#core#init()
let s:st = vimtoria#core#state()
let s:world = s:st.world
let s:reg = s:world.military['JAP'].regiments
let s:base = vimtoria#war#strength(s:world, 'JAP')
call assert_true(abs(s:base - s:reg * 1.05) < 0.01, '専制の軍事+5%が効いていない')
let s:world.techs['JAP'].done['percussion_caps'] = 1
let s:world.techs['JAP'].done['rifled_muskets'] = 1
call vimtoria#tech#recompute_mods(s:world, 'JAP')
call assert_true(abs(vimtoria#war#strength(s:world, 'JAP')
      \ - s:reg * 1.05 * 1.05 * 1.1) < 0.01, '軍事技術の倍率が効いていない')
" 国民皆兵で連隊上限が増える
let s:cap0 = vimtoria#war#cap(s:world, 'JAP')
let s:world.techs['JAP'].done['conscription'] = 1
call vimtoria#tech#recompute_mods(s:world, 'JAP')
call assert_true(vimtoria#war#cap(s:world, 'JAP') > s:cap0 * 1.15, '連隊上限+20%')

" ---- 固有技術: 対象国だけが研究できる ----
call assert_true(vimtoria#tech#available(s:world, 'JAP', 'meiji_restoration'))
call assert_false(vimtoria#tech#available(s:world, 'GBR', 'meiji_restoration'))
call assert_true(index(vimtoria#tech#menu_for('GBR'), 'pax_britannica') >= 0)
call assert_true(index(vimtoria#tech#menu_for('JAP'), 'pax_britannica') < 0)

" ---- 交易: 割安な財は輸出され、関税収入が入る ----
call vimtoria#core#init()
let s:st = vimtoria#core#state()
let s:world = s:st.world
" 日本の穀物を人為的に割安にする → 輸出が立つ
let s:world.markets['JAP']['grain'].price = 8.0
call vimtoria#econ#tick(s:st)
call assert_true(get(s:world.world_prices, 'grain', 0.0) > 10.0, '世界価格が計算されていない')
call assert_true(get(s:world.trade_flows['JAP'], 'grain', 0.0) > 0.0,
      \ '割安な穀物が輸出されていない')
call assert_true(s:world.stats['JAP'].tariff > 0.0, '関税収入がない')
" 割高な財は輸入される
let s:world.markets['JAP']['tools'].price = 70.0
call vimtoria#econ#tick(s:st)
call assert_true(get(s:world.trade_flows['JAP'], 'tools', 0.0) < 0.0,
      \ '割高な工具が輸入されていない')
" 戦争中は交易が細る
call assert_false(vimtoria#diplo#in_war(s:world, 'JAP'))
call vimtoria#diplo#declare_war(s:world, 'JAP', 'HAW', 'HAW', 0, 'JAP')
call assert_true(vimtoria#diplo#in_war(s:world, 'JAP'))
call assert_true(vimtoria#diplo#in_war(s:world, 'HAW'))
call assert_false(vimtoria#diplo#in_war(s:world, 'KOR'))

" ---- 3年回して安定性を確認(AI・運動・交易が全て動く) ----
call vimtoria#core#init()
let s:st = vimtoria#core#state()
let s:i = 0
while s:i < 156
  call vimtoria#econ#tick(s:st)
  let s:i += 1
endwhile
call assert_true(s:st.world.stats['JAP'].gdp > 0.0)
for [s:cid, s:s] in items(s:st.world.stats)
  call assert_false(isnan(s:st.world.treasuries[s:cid]), s:cid . ': 国庫 NaN')
endfor
" AI は新ツリーでも研究を進めている
call assert_true(len(s:st.world.techs['GBR'].done) >= 2, 'AI の研究が進んでいない')

" ---- 画面描画(技術・政治・市場、両言語) ----
for s:lang in ['ja', 'en']
  call vimtoria#i18n#set(s:lang)
  for s:screen in ['tech', 'politics', 'market', 'budget']
    let s:st.screen = s:screen
    let s:st.menu_idx = 0
    let s:lines = vimtoria#ui#build_lines(s:st)
    call assert_true(len(s:lines) > 10, s:lang . '/' . s:screen . ': 描画行が少ない')
  endfor
endfor
call vimtoria#i18n#set('ja')
" 技術画面のメニュー末尾まで nav できる(index 範囲の検証)
let s:st.screen = 'tech'
let s:st.menu_idx = 0
let s:n = len(vimtoria#tech#menu_for('JAP'))
let s:i = 0
while s:i < s:n + 5
  call vimtoria#core#action('nav_j')
  let s:i += 1
endwhile
call assert_equal(s:n - 1, s:st.menu_idx, 'メニュー末尾で止まらない')

" ---- 各国概況ポップアップの内容(純関数部分) ----
let s:box = vimtoria#popup#country(s:st, 'GBR')
call assert_true(len(s:box) >= 8, 'ポップアップの行数が少ない')
call assert_match('イギリス', s:box[0], 'タイトルに国名がない')
call assert_match('週間GDP', join(s:box, "\n"))
call assert_match('政体', join(s:box, "\n"))
" 枠の幅が揃っている
let s:w = strdisplaywidth(s:box[0])
for s:line in s:box
  call assert_equal(s:w, strdisplaywidth(s:line), 'ポップアップの枠幅が不揃い')
endfor
" 自国には関係値の代わりに「あなたの国」
call assert_match('あなたの国', join(vimtoria#popup#country(s:st, 'JAP'), "\n"))

call vimtoria#core#shutdown()

" ---- 結果出力 ----
if empty(v:errors)
  call writefile(['OK'], 'test/results.txt')
else
  call writefile(['FAIL'] + v:errors, 'test/results.txt')
endif
qa!
