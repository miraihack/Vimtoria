scriptencoding utf-8
" test_build.vim - M2 建設・予算のヘッドレステスト
" 実行: test/run.sh(結果は test/results.txt に書かれる)

let v:errors = []
" 決定性のためランダムイベントを止める
let g:vimtoria_disable_events = 1

call vimtoria#core#init()
let s:st = vimtoria#core#state()
let s:eco = vimtoria#data#economy()

" ---- 建設力と資材費 ----
let s:cap = vimtoria#build#capacity(s:st.world, 'JAP')
call assert_true(s:cap > 3.0, printf('日本の建設力が小さすぎる: %.1f', s:cap))
call assert_true(vimtoria#build#capacity(s:st.world, 'ZUL') < s:cap, '小国の建設力が大国以上')
let s:unit = vimtoria#build#point_cost(s:st.world.markets['JAP'])
call assert_true(s:unit > 0.0)

" ---- キュー投入の検証 ----
" 他国領には建てられない
call assert_notequal('', vimtoria#build#enqueue(s:st, 'GBR', 'grain_farm'))
call assert_equal(0, len(s:st.world.queues['JAP']))
" 自国領は OK
call assert_equal('', vimtoria#build#enqueue(s:st, 'EDO', 'textile_mill'))
call assert_equal(1, len(s:st.world.queues['JAP']))
" キュー上限
let s:i = 0
while s:i < 30
  call vimtoria#build#enqueue(s:st, 'KIN', 'grain_farm')
  let s:i += 1
endwhile
call assert_equal(s:eco.const.build_queue_max, len(s:st.world.queues['JAP']))
" 取消
call assert_equal('', vimtoria#build#cancel_last(s:st))
call assert_equal(s:eco.const.build_queue_max - 1, len(s:st.world.queues['JAP']))
" 全部取り消して 1 件だけ残す
while len(s:st.world.queues['JAP']) > 1
  call vimtoria#build#cancel_last(s:st)
endwhile
call assert_equal('textile_mill', s:st.world.queues['JAP'][0].bid)

" ---- 進捗・資材需要・支出 ----
" 建設中は資材需要が上乗せされる(木材の買い注文で確認)
call vimtoria#econ#tick(s:st)
let s:buy_with = s:st.world.markets['JAP']['wood'].buy
call assert_true(s:st.world.queues['JAP'][0].done > 0.0, '建設が進んでいない')
call assert_true(s:st.world.stats['JAP'].spend > 0.0, '建設支出が計上されていない')
call assert_true(s:st.world.stats['JAP'].tax > 0.0, '税収が計上されていない')
call assert_true(s:st.world.stats['JAP'].upkeep > 0.0, '維持費が計上されていない')

" ---- 完成: レベル +1、稼働率は雇用保存で希釈 ----
let s:before = s:st.world.buildings['EDO']['textile_mill']
let s:lv0 = s:before.levels
let s:emp0 = s:before.levels * s:before.f
let s:i = 0
while !empty(s:st.world.queues['JAP']) && s:i < 60
  call vimtoria#econ#tick(s:st)
  let s:i += 1
endwhile
call assert_true(empty(s:st.world.queues['JAP']), '60週で完成しない')
let s:after = s:st.world.buildings['EDO']['textile_mill']
call assert_true(abs(s:after.levels - (s:lv0 + 1.0)) < 0.001,
      \ printf('レベルが+1されていない: %.2f → %.2f', s:lv0, s:after.levels))

" ---- 建物が無い州への新設 ----
" 蝦夷地は小さく製鉄所が無い(share×levels が極小でも存在はし得るので確認してから)
let s:target = 'EZO'
if !has_key(s:st.world.buildings[s:target], 'steel_mill')
  call assert_equal('', vimtoria#build#enqueue(s:st, s:target, 'steel_mill'))
  let s:i = 0
  while !empty(s:st.world.queues['JAP']) && s:i < 60
    call vimtoria#econ#tick(s:st)
    let s:i += 1
  endwhile
  call assert_true(has_key(s:st.world.buildings[s:target], 'steel_mill'),
        \ '新設建物が作られていない')
  call assert_true(abs(s:st.world.buildings[s:target]['steel_mill'].levels - 1.0) < 0.001)
endif

" ---- 国債: 無一文でも信用限度まで借金して建設が進む(M3) ----
call vimtoria#core#init()
let s:st = vimtoria#core#state()
let s:st.world.tax_rates['JAP'] = 0.0
let s:st.world.treasuries['JAP'] = 0.0
call assert_equal('', vimtoria#build#enqueue(s:st, 'EDO', 'grain_farm'))
call vimtoria#econ#tick(s:st)
call assert_true(s:st.world.queues['JAP'][0].done > 0.0,
      \ '信用があるのに建設が進まない')
call assert_true(s:st.world.treasuries['JAP'] < 0.0, '債務になっていない')
let s:credit = s:st.world.stats['JAP'].credit
call assert_true(s:st.world.treasuries['JAP']
      \ >= -(s:credit + s:st.world.stats['JAP'].upkeep + 100.0),
      \ '信用限度を大きく超えて借金した')
" 債務には利払いが発生する
call vimtoria#econ#tick(s:st)
call assert_true(s:st.world.stats['JAP'].interest > 0.0, '利払いが計上されていない')

" ---- 税率アクション(予算画面のみ有効) ----
call vimtoria#core#init()
let s:st = vimtoria#core#state()
call vimtoria#core#action('tax_up')
call assert_equal(0.075, s:st.world.tax_rates['JAP'], 'マップ画面で税率が変わった')
call vimtoria#core#action('screen_budget')
call vimtoria#core#action('tax_up')
call assert_true(abs(s:st.world.tax_rates['JAP'] - 0.10) < 0.0001)
call vimtoria#core#action('tax_down')
call vimtoria#core#action('tax_down')
call assert_true(abs(s:st.world.tax_rates['JAP'] - 0.05) < 0.0001)
" 上限は税制の法律で決まる(日本の初期は地租 = 15%)
let s:i = 0
while s:i < 20
  call vimtoria#core#action('tax_up')
  let s:i += 1
endwhile
call assert_true(abs(s:st.world.tax_rates['JAP']
      \ - s:st.world.law_mods['JAP'].tax_max) < 0.0001)
call vimtoria#core#action('back')

" ---- 建設メニュー操作と投入アクション ----
call vimtoria#core#action('screen_construction')
call assert_equal(0, vimtoria#core#state().menu_idx)
call vimtoria#core#action('nav_j')
call vimtoria#core#action('nav_j')
call assert_equal(2, vimtoria#core#state().menu_idx)
call vimtoria#core#action('nav_k')
call assert_equal(1, vimtoria#core#state().menu_idx)
" 選択中の州(既定=江戸)に Enter で投入
call vimtoria#core#action('open_state')
call assert_equal(1, len(s:st.world.queues['JAP']))
call assert_equal('EDO', s:st.world.queues['JAP'][0].sid)
call vimtoria#core#action('cancel')
call assert_equal(0, len(s:st.world.queues['JAP']))

" ---- 建設画面・予算画面の描画 ----
call vimtoria#build#enqueue(s:st, 'EDO', 'grain_farm')
call vimtoria#econ#tick(s:st)
for s:screen in ['construction', 'budget']
  let s:st.screen = s:screen
  let s:lines = vimtoria#ui#build_lines(s:st)
  call assert_true(len(s:lines) > 5, s:screen . ': 描画行が少なすぎる')
endfor

" ---- 20年の長期安定性(建設キューを回しながら) ----
call vimtoria#core#init()
let s:st = vimtoria#core#state()
let s:i = 0
while s:i < 1040
  if len(s:st.world.queues['JAP']) < 3
    call vimtoria#build#enqueue(s:st, 'EDO', 'textile_mill')
  endif
  call vimtoria#econ#tick(s:st)
  let s:i += 1
endwhile
call assert_true(s:st.world.treasuries['JAP'] >= -s:st.world.stats['JAP'].credit * 2.0,
      \ '20年後に信用限度を大きく超える債務')
call assert_true(s:st.world.buildings['EDO']['textile_mill'].levels > 11.0,
      \ printf('20年で織物工場が増えていない: %.1f',
      \        s:st.world.buildings['EDO']['textile_mill'].levels))
for [s:gid, s:m] in items(s:st.world.markets['JAP'])
  let s:base = s:eco.goods[s:gid].base
  call assert_true(s:m.price >= s:base * 0.2499 && s:m.price <= s:base * 1.7501,
        \ printf('20年後の価格逸脱: %s %.2f', s:gid, s:m.price))
endfor

call vimtoria#core#shutdown()

" ---- 結果出力 ----
if empty(v:errors)
  call writefile(['OK'], 'test/results.txt')
else
  call writefile(['FAIL'] + v:errors, 'test/results.txt')
endif
qa!
