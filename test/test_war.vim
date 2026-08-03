scriptencoding utf-8
" test_war.vim - 外交・軍事・併合のヘッドレステスト
" 実行: test/run.sh(結果は test/results.txt に書かれる)

let v:errors = []
" 決定性のためランダムイベントを止める
let g:vimtoria_disable_events = 1

call vimtoria#core#init()
let s:st = vimtoria#core#state()
let s:world = s:st.world
" このテストは開国後の外交を検証する(鎖国は test_m7 で検証)
let s:world.isolated = {}

" ---- 外交の初期状態 ----
call assert_equal(-60.0, vimtoria#diplo#relation(s:world, 'MEX', 'TEX'))
call assert_equal(-60.0, vimtoria#diplo#relation(s:world, 'TEX', 'MEX'), '対称でない')
call assert_equal(0.0, vimtoria#diplo#relation(s:world, 'JAP', 'HAW'))

" ---- 関係改善: 費用・効果・クールダウン ----
let s:gold0 = s:world.treasuries['JAP']
call assert_equal('', vimtoria#diplo#improve(s:world, 'JAP', 'KOR', s:st.day))
call assert_equal(15.0, vimtoria#diplo#relation(s:world, 'JAP', 'KOR'))
call assert_true(s:world.treasuries['JAP'] < s:gold0, '費用が引かれていない')
call assert_notequal('', vimtoria#diplo#improve(s:world, 'JAP', 'KOR', s:st.day + 7),
      \ 'クールダウンが効いていない')

" ---- 同盟: 閾値・成立・破棄 ----
call assert_notequal('', vimtoria#diplo#toggle_alliance(s:world, 'JAP', 'KOR'))
let s:world.relations[vimtoria#diplo#key('JAP', 'KOR')] = 70.0
call assert_equal('', vimtoria#diplo#toggle_alliance(s:world, 'JAP', 'KOR'))
call assert_true(vimtoria#diplo#allied(s:world, 'JAP', 'KOR'))
call assert_equal('', vimtoria#diplo#toggle_alliance(s:world, 'JAP', 'KOR'))
call assert_false(vimtoria#diplo#allied(s:world, 'JAP', 'KOR'))
call assert_equal(40.0, vimtoria#diplo#relation(s:world, 'JAP', 'KOR'), '破棄ペナルティ')

" ---- 関係ドリフト: 正負とも 0 へ ----
call vimtoria#diplo#tick(s:world)
call assert_true(vimtoria#diplo#relation(s:world, 'JAP', 'KOR') < 40.0)
call assert_true(vimtoria#diplo#relation(s:world, 'MEX', 'TEX') > -60.0)

" ---- 軍事: 徴募と解散 ----
let s:world.treasuries['JAP'] = 100000.0
let s:reg0 = s:world.military['JAP'].regiments
let s:largest = ''
let s:max = -1.0
for s:sid in s:world.country_states['JAP']
  if s:world.workforce[s:sid] > s:max
    let s:max = s:world.workforce[s:sid]
    let s:largest = s:sid
  endif
endfor
let s:wf0 = s:world.workforce[s:largest]
call assert_equal('', vimtoria#war#recruit(s:world, 'JAP'))
call assert_true(abs(s:world.military['JAP'].regiments - (s:reg0 + 5.0)) < 0.001)
call assert_true(abs(s:world.workforce[s:largest] - (s:wf0 - 5.0)) < 0.001,
      \ '徴募で労働力が減っていない')
call assert_equal('', vimtoria#war#disband(s:world, 'JAP'))
call assert_true(abs(s:world.military['JAP'].regiments - s:reg0) < 0.001)

" ---- 軍需が市場に乗る ----
call vimtoria#econ#tick(s:st)
let s:buy_with_army = s:world.markets['JAP']['grain'].buy
let s:save_reg = s:world.military['JAP'].regiments
let s:world.military['JAP'].regiments = 0.0
call vimtoria#econ#tick(s:st)
call assert_true(s:world.markets['JAP']['grain'].buy < s:buy_with_army,
      \ '軍の穀物需要が市場に乗っていない')
let s:world.military['JAP'].regiments = s:save_reg

" ---- 宣戦と戦争解決: 圧倒的戦力差で州を併合 ----
call vimtoria#core#init()
let s:st = vimtoria#core#state()
let s:world = s:st.world
call assert_notequal('', vimtoria#diplo#declare_war(s:world, 'JAP', 'JAP', 'EDO', 0, 'JAP'))
let s:world.military['JAP'].regiments = 500.0
let s:world.military['KOR'].regiments = 5.0
call assert_equal('', vimtoria#diplo#declare_war(s:world, 'JAP', 'KOR', 'KOR', s:st.day, 'JAP'))
call assert_equal(1, len(s:world.wars))
call assert_equal(-100.0, vimtoria#diplo#relation(s:world, 'JAP', 'KOR'))
" 二重宣戦は不可
call assert_notequal('', vimtoria#diplo#declare_war(s:world, 'JAP', 'KOR', 'KOR', s:st.day, 'JAP'))
" 決着まで回す(戦力比ほぼ 100:1 → 毎週 +8 前後)
let s:i = 0
while !empty(s:world.wars) && s:i < 60
  call vimtoria#econ#tick(s:st)
  let s:i += 1
endwhile
call assert_true(empty(s:world.wars), '60週で戦争が決着しない')
call assert_equal('JAP', s:world.owner['KOR'], '朝鮮が併合されていない')
call assert_true(index(s:world.country_states['JAP'], 'KOR') >= 0)
call assert_true(empty(s:world.country_states['KOR']), '旧所有国に州が残っている')
call assert_true(s:world.map_version > 0, 'map_version が上がっていない')
" 併合ニュースがログに載る
let s:found = 0
for s:line in s:world.eventlog
  if s:line =~# '併合'
    let s:found = 1
  endif
endfor
call assert_true(s:found, '併合がログに載っていない')
" 併合後も経済が回る(消滅国はスキップされる)
call vimtoria#econ#tick(s:st)
call assert_true(s:world.stats['JAP'].gdp > 0.0)
" 併合した州に建設できる
call assert_equal('', vimtoria#build#enqueue(s:st, 'KOR', 'grain_farm'))

" ---- 白紙和平 ----
call vimtoria#core#init()
let s:st = vimtoria#core#state()
let s:world = s:st.world
call assert_equal('', vimtoria#diplo#declare_war(s:world, 'JAP', 'HAW', 'HAW', s:st.day, 'JAP'))
call assert_equal('', vimtoria#diplo#white_peace(s:world, 'JAP', 'HAW', s:st.day))
call assert_true(empty(s:world.wars))
call assert_equal('HAW', s:world.owner['HAW'], '白紙和平で州が動いた')

" ---- 同盟国の参戦 ----
let s:world.alliances[vimtoria#diplo#key('HAW', 'USA')] = 1
call assert_equal('', vimtoria#diplo#declare_war(s:world, 'JAP', 'HAW', 'HAW', s:st.day, 'JAP'))
call assert_equal(['USA'], s:world.wars[0].allies_d, '防御同盟が参戦していない')
call vimtoria#diplo#white_peace(s:world, 'JAP', 'HAW', s:st.day)

" ---- 戦闘での損耗 ----
call vimtoria#core#init()
let s:st = vimtoria#core#state()
let s:world = s:st.world
call vimtoria#diplo#declare_war(s:world, 'JAP', 'QIN', 'MAN', s:st.day, 'JAP')
let s:reg_jap = s:world.military['JAP'].regiments
let s:reg_qin = s:world.military['QIN'].regiments
call vimtoria#war#tick(s:world, s:st.day)
call assert_true(s:world.military['JAP'].regiments < s:reg_jap, '攻撃側に損耗がない')
call assert_true(s:world.military['QIN'].regiments < s:reg_qin, '防御側に損耗がない')

" ---- 外交画面・軍事画面の描画 ----
for s:screen in ['diplo', 'military']
  let s:st.screen = s:screen
  let s:st.menu_idx = 0
  let s:lines = vimtoria#ui#build_lines(s:st)
  call assert_true(len(s:lines) > 10, s:screen . ': 描画行が少なすぎる')
endfor

" ---- AI 外交がクラッシュしない(2年) ----
call vimtoria#core#init()
let s:st = vimtoria#core#state()
let s:i = 0
while s:i < 104
  call vimtoria#econ#tick(s:st)
  let s:i += 1
endwhile
call assert_true(s:st.world.stats['JAP'].gdp > 0.0)

call vimtoria#core#shutdown()

" ---- 結果出力 ----
if empty(v:errors)
  call writefile(['OK'], 'test/results.txt')
else
  call writefile(['FAIL'] + v:errors, 'test/results.txt')
endif
qa!
