scriptencoding utf-8
" test_politics.vim - 政治(利益集団・法律・急進性)のヘッドレステスト
" 実行: test/run.sh(結果は test/results.txt に書かれる)

let v:errors = []
" 決定性のためランダムイベントを止める
let g:vimtoria_disable_events = 1

" ---- 政治データの整合性 ----
let s:data = vimtoria#data#politics()
call assert_equal(len(s:data.laws), len(s:data.law_order))
call assert_equal(sort(keys(s:data.laws)), sort(copy(s:data.law_order)))
for [s:lid, s:def] in items(s:data.laws)
  call assert_true(has_key(s:data.groups, s:def.group), s:lid)
  for s:ig in keys(s:def.approval)
    call assert_true(has_key(s:data.igs, s:ig), s:lid . ': 未定義の利益集団 ' . s:ig)
  endfor
endfor
" 各グループの既定法が存在する
for [s:g, s:lid] in items(s:data.default_laws)
  call assert_equal(s:g, s:data.laws[s:lid].group)
endfor

" ---- 初期化: 法律と law_mods ----
call vimtoria#core#init()
let s:st = vimtoria#core#state()
" 日本は農業国セット
call assert_equal('agrarianism', s:st.world.politics['JAP'].laws['econ_policy'])
call assert_equal(0.15, s:st.world.law_mods['JAP'].tax_max)
call assert_equal(0.65, s:st.world.law_mods['JAP'].wage_share)
" イギリスは工業国セット(産業奨励+所得税)
call assert_equal('industrialism', s:st.world.politics['GBR'].laws['econ_policy'])
call assert_equal(0.30, s:st.world.law_mods['GBR'].tax_max)
" 農本主義は農場産出 +10%
call assert_true(abs(get(s:st.world.law_mods['JAP'].out, 'grain_farm', 1.0) - 1.1) < 0.001)

" ---- 勢力: 1 tick 後、合計 ≈ 1 で農業国は地主が最大 ----
call vimtoria#econ#tick(s:st)
let s:clout = s:st.world.politics['JAP'].clout
let s:sum = 0.0
for s:v in values(s:clout)
  let s:sum += s:v
endfor
call assert_true(abs(s:sum - 1.0) < 0.001, printf('勢力合計 %.3f', s:sum))
call assert_true(s:clout.landowners > s:clout.industrialists,
      \ '農業国で地主が実業家より弱い')
call assert_true(s:clout.landowners > s:clout.labor, '農業国で地主が労働より弱い')

" ---- 税率上限は法律で決まる ----
call vimtoria#core#action('screen_budget')
let s:i = 0
while s:i < 20
  call vimtoria#core#action('tax_up')
  let s:i += 1
endwhile
call assert_true(abs(s:st.world.tax_rates['JAP'] - 0.15) < 0.0001,
      \ '地租の上限 15% でクランプされていない')
call vimtoria#core#action('back')

" ---- 制定: 検証と進行 ----
call assert_notequal('', vimtoria#politics#start_enact(s:st.world, 'JAP', 'agrarianism'))
call assert_equal('', vimtoria#politics#start_enact(s:st.world, 'JAP', 'income_tax'))
call vimtoria#econ#tick(s:st)
call assert_true(s:st.world.politics['JAP'].enact.progress > 0.0, '制定が進まない')
" 地主優勢での所得税は支持が負 → 急進性が上がる
call assert_true(vimtoria#politics#support(s:st.world, 'JAP', 'income_tax') < 0.0)
let s:rad0 = s:st.world.politics['JAP'].rad

" ---- 制定完了 → 効果適用 ----
let s:i = 0
while s:st.world.politics['JAP'].laws['taxation'] !=# 'income_tax' && s:i < 80
  call vimtoria#econ#tick(s:st)
  let s:i += 1
endwhile
call assert_equal('income_tax', s:st.world.politics['JAP'].laws['taxation'],
      \ '80週で所得税が成立しない')
call assert_equal(0.30, s:st.world.law_mods['JAP'].tax_max)
call assert_equal('', s:st.world.politics['JAP'].enact.law)
" プレイヤーのイベントログに載る
let s:found = 0
for s:line in s:st.world.eventlog
  if s:line =~# '法律制定'
    let s:found = 1
  endif
endfor
call assert_true(s:found, '法律制定がログに載っていない')

" ---- 労働保護で賃金分配が変わる ----
call vimtoria#core#init()
let s:st = vimtoria#core#state()
let s:st.world.politics['JAP'].laws['labor_law'] = 'worker_protection'
call vimtoria#politics#recompute_law_mods(s:st.world, 'JAP')
call assert_equal(0.75, s:st.world.law_mods['JAP'].wage_share)

" ---- 急進性: 低い生活水準で上がり、高いと下がる ----
call vimtoria#core#init()
let s:st = vimtoria#core#state()
let s:pol = s:st.world.politics['JAP']
let s:pol.rad = 50.0
call vimtoria#politics#tick(s:st.world, 'JAP', {}, 0.5, 0, 0)
call assert_true(s:pol.rad > 50.0, '低SoLで急進性が上がらない')
let s:pol.rad = 50.0
call vimtoria#politics#tick(s:st.world, 'JAP', {}, 1.4, 0, 0)
call assert_true(s:pol.rad < 50.0, '高SoLで急進性が下がらない')

" ---- 政治画面の描画とアクション ----
call vimtoria#core#action('screen_politics')
call assert_equal(0, s:st.menu_idx)
call vimtoria#core#action('nav_j')
call vimtoria#core#action('open_state')
call assert_equal('industrialism', s:st.world.politics['JAP'].enact.law)
let s:st.screen = 'politics'
let s:lines = vimtoria#ui#build_lines(s:st)
call assert_true(len(s:lines) > 10, '政治画面の描画行が少なすぎる')

call vimtoria#core#shutdown()

" ---- 結果出力 ----
if empty(v:errors)
  call writefile(['OK'], 'test/results.txt')
else
  call writefile(['FAIL'] + v:errors, 'test/results.txt')
endif
qa!
