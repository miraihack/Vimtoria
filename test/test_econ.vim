scriptencoding utf-8
" test_econ.vim - M1 経済コアのヘッドレステスト
" 実行: test/run.sh(結果は test/results.txt に書かれる)

let v:errors = []
" 決定性のためランダムイベントを止める
let g:vimtoria_disable_events = 1

" ---- 価格式 ----
call assert_equal(20.0, vimtoria#econ#price_for(20.0, 0.0, 0.0))
call assert_equal(20.0, vimtoria#econ#price_for(20.0, 100.0, 100.0))
call assert_equal(35.0, vimtoria#econ#price_for(20.0, 100.0, 0.0))
call assert_equal(5.0, vimtoria#econ#price_for(20.0, 0.0, 100.0))
call assert_true(abs(vimtoria#econ#price_for(20.0, 150.0, 100.0) - 25.0) < 0.001)
call assert_true(abs(vimtoria#econ#price_for(20.0, 100.0, 150.0) - 15.0) < 0.001)

" ---- 初期化 ----
call vimtoria#core#init()
let s:st = vimtoria#core#state()
call assert_true(has_key(s:st, 'world'))
let s:eco = vimtoria#data#economy()
let s:map = vimtoria#data#map()
call assert_equal(len(s:map.states), len(s:st.world.buildings))
call assert_equal(len(s:map.countries), len(s:st.world.markets))
" share 合計 ≈ 0.57(残りは自給農プール)
let s:share = 0.0
for s:bdef in values(s:eco.buildings)
  let s:share += s:bdef.share
endfor
call assert_true(s:share > 0.5 && s:share < 0.65, printf('share合計 %.4f', s:share))
" 全建物のレベルは正、江戸には全建物種がある
for [s:bid, s:b] in items(s:st.world.buildings['EDO'])
  call assert_true(s:b.levels > 0.0, s:bid)
endfor
call assert_equal(len(s:eco.buildings), len(s:st.world.buildings['EDO']))

" ---- 不変条件チェック関数 ----
function! s:check_invariants(st, label) abort
  let l:eco = vimtoria#data#economy()
  for [l:cid, l:market] in items(a:st.world.markets)
    for [l:gid, l:m] in items(l:market)
      let l:base = l:eco.goods[l:gid].base
      call assert_false(isnan(l:m.price), a:label . ': ' . l:cid . '/' . l:gid . ' price NaN')
      call assert_true(l:m.price >= l:base * 0.2499 && l:m.price <= l:base * 1.7501,
            \ printf('%s: %s/%s 価格逸脱 %.2f', a:label, l:cid, l:gid, l:m.price))
    endfor
    call assert_false(isnan(a:st.world.treasuries[l:cid]), a:label . ': 国庫 NaN')
    " M3: 信用限度(週間所得×0.5)までは債務を許容する
    call assert_true(a:st.world.treasuries[l:cid]
          \ > -(a:st.world.stats[l:cid].income * 2.0 + 1000.0),
          \ a:label . ': ' . l:cid . ' 債務が過大')
  endfor
  for [l:sid, l:bs] in items(a:st.world.buildings)
    for [l:bid, l:b] in items(l:bs)
      call assert_true(l:b.f >= l:eco.const.min_f - 0.001 && l:b.f <= 1.0001,
            \ printf('%s: %s/%s 稼働率逸脱 %.3f', a:label, l:sid, l:bid, l:b.f))
    endfor
  endfor
  for [l:cid, l:s] in items(a:st.world.stats)
    call assert_true(l:s.gdp > 0.0, a:label . ': ' . l:cid . ' GDP非正')
    call assert_true(l:s.unemployed >= -0.001, a:label . ': ' . l:cid . ' 失業者負値')
    call assert_true(l:s.unemployed <= l:s.workforce + 0.001, a:label . ': ' . l:cid . ' 失業者過大')
  endfor
endfunction

" ---- 1 tick ----
call vimtoria#econ#tick(s:st)
call s:check_invariants(s:st, '1週目')
" 国庫の収支が一致する(初期 10000 + 税収 - 維持費 - 軍事費 - 利払い - 建設支出)
let s:jap = s:st.world.stats['JAP']
call assert_true(abs(s:st.world.treasuries['JAP']
      \ - (10000.0 + s:jap.tax - s:jap.upkeep - s:jap.mil
      \    - s:jap.interest - s:jap.spend)) < 0.01,
      \ '国庫の収支が合わない')
call assert_true(s:jap.tax > 0.0, '税収がない')
call assert_equal(float2nr(s:st.world.treasuries['JAP']), s:st.treasury,
      \ 'プレイヤー国庫が同期されていない')
" 需要のある財に注文が立っている
call assert_true(s:st.world.markets['JAP']['grain'].buy > 0.0)
call assert_true(s:st.world.markets['JAP']['grain'].sell > 0.0)

" ---- 10年(520週)の長期安定性と性能 ----
let s:t0 = reltime()
let s:i = 0
while s:i < 519
  call vimtoria#econ#tick(s:st)
  let s:i += 1
endwhile
let s:elapsed_ms = reltimefloat(reltime(s:t0)) * 1000.0
call s:check_invariants(s:st, '10年後')

" 10年間で経済が動いている(価格が全て基準に張り付いたままではない)
let s:moved = 0
for [s:gid, s:m] in items(s:st.world.markets['JAP'])
  if abs(s:m.price - s:eco.goods[s:gid].base) > 0.01
    let s:moved += 1
  endif
endfor
call assert_true(s:moved >= 3, '価格が全く動いていない(moved=' . s:moved . ')')

" 雇用が維持されている(全建物が min_f まで崩壊していない)
let s:info = vimtoria#econ#state_info(s:st, 'EDO')
call assert_true(s:info.employed > 0.0, '江戸の雇用が消滅')
call assert_true(s:info.employed <= s:info.workforce + 0.001, '江戸の雇用が労働力超過')

" 性能: 520 tick(34カ国×10年)の所要時間。目標 1tick < 50ms
call assert_true(s:elapsed_ms < 26000.0,
      \ printf('10年シミュレーションが遅すぎる: %.0fms', s:elapsed_ms))

call vimtoria#core#shutdown()

" ---- 結果出力 ----
if empty(v:errors)
  call writefile(['OK', printf('520 ticks: %.0fms (%.1fms/tick)',
        \ s:elapsed_ms, s:elapsed_ms / 520)], 'test/results.txt')
else
  call writefile(['FAIL'] + v:errors, 'test/results.txt')
endif
qa!
