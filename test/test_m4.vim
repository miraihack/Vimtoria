scriptencoding utf-8
" test_m4.vim - M4 セーブ/ロード・イベント・ランキングのヘッドレステスト
" 実行: test/run.sh(結果は test/results.txt に書かれる)

let v:errors = []
" 抽選は止め、イベントは fire で直接検証する
let g:vimtoria_disable_events = 1
let g:vimtoria_save_file = 'test/tmp_save.json'

" ---- イベントデータの整合性 ----
let s:data = vimtoria#data#events()
call assert_equal(len(s:data.events), len(s:data.order))
call assert_equal(sort(keys(s:data.events)), sort(copy(s:data.order)))
for [s:eid, s:def] in items(s:data.events)
  call assert_true(has_key(s:def.effects, 'duration'), s:eid)
endfor

" ---- セーブ / ロード ----
call vimtoria#core#init()
let s:st = vimtoria#core#state()
call vimtoria#build#enqueue(s:st, 'EDO', 'textile_mill')
let s:i = 0
while s:i < 10
  call vimtoria#econ#tick(s:st)
  let s:st.day += 7
  let s:i += 1
endwhile
let s:day_saved = s:st.day
let s:gold_saved = s:st.world.treasuries['JAP']
let s:done_saved = s:st.world.queues['JAP'][0].done
call assert_true(vimtoria#core#save(), 'セーブに失敗')
call assert_true(filereadable('test/tmp_save.json'), 'セーブファイルが無い')
" 進めてからロード → 巻き戻る
let s:i = 0
while s:i < 20
  call vimtoria#econ#tick(s:st)
  let s:st.day += 7
  let s:i += 1
endwhile
call assert_notequal(s:day_saved, vimtoria#core#state().day)
call assert_true(vimtoria#core#load(), 'ロードに失敗')
let s:st = vimtoria#core#state()
call assert_equal(s:day_saved, s:st.day, '日付が復元されていない')
call assert_true(abs(s:st.world.treasuries['JAP'] - s:gold_saved) < 0.01,
      \ '国庫が復元されていない')
call assert_true(abs(s:st.world.queues['JAP'][0].done - s:done_saved) < 0.01,
      \ '建設キューが復元されていない')
call assert_equal(1, s:st.paused, 'ロード後に停止していない')
call assert_equal('map', s:st.screen)
" ロード後もシミュレーションが回る
call vimtoria#econ#tick(s:st)
call assert_true(s:st.world.stats['JAP'].gdp > 0.0, 'ロード後に経済が回らない')
call delete('test/tmp_save.json')
" セーブデータが無いときはエラーメッセージ
call assert_equal(0, vimtoria#core#load())
call assert_match('セーブデータがありません', s:st.msg)

" ---- イベント: 即時効果(国庫・労働力) ----
call vimtoria#core#init()
let s:st = vimtoria#core#state()
call vimtoria#econ#tick(s:st)
let s:income = s:st.world.stats['JAP'].income
let s:gold0 = s:st.world.treasuries['JAP']
call vimtoria#events#fire(s:st.world, 'JAP', 'trade_windfall', s:st.day, 1)
call assert_true(abs(s:st.world.treasuries['JAP'] - (s:gold0 + s:income * 0.75)) < 1.0,
      \ '交易の追い風の国庫効果が違う')
call assert_equal(1, len(s:st.world.eventlog), 'イベントログに記録されていない')
call assert_match('交易の追い風', s:st.world.eventlog[0])
" 労働力イベントは総量を変える
let s:wf0 = 0.0
for s:sid in vimtoria#data#map().country_states['JAP']
  let s:wf0 += s:st.world.workforce[s:sid]
endfor
call vimtoria#events#fire(s:st.world, 'JAP', 'immigration', s:st.day, 1)
let s:wf1 = 0.0
for s:sid in vimtoria#data#map().country_states['JAP']
  let s:wf1 += s:st.world.workforce[s:sid]
endfor
call assert_true(s:wf1 > s:wf0, '移民で労働力が増えていない')

" ---- イベント: 時限効果と期限切れ ----
call vimtoria#core#init()
let s:st = vimtoria#core#state()
call vimtoria#econ#tick(s:st)
call vimtoria#events#fire(s:st.world, 'JAP', 'strikes', s:st.day, 1)
call assert_true(abs(s:st.world.event_mods['JAP'].out_all - 0.9) < 0.001,
      \ '労働争議の倍率が効いていない')
" 産出(売り注文)が下がる
let s:sell0 = s:st.world.markets['JAP']['grain'].sell
call vimtoria#econ#tick(s:st)
call assert_true(s:st.world.markets['JAP']['grain'].sell < s:sell0 * 0.95,
      \ 'ストの産出減が売り注文に出ていない')
" 8週で期限切れ → 倍率が戻る
let s:i = 0
while s:i < 9
  call vimtoria#econ#tick(s:st)
  let s:i += 1
endwhile
call assert_true(empty(s:st.world.events['JAP']), 'イベントが期限切れにならない')
call assert_true(abs(s:st.world.event_mods['JAP'].out_all - 1.0) < 0.001,
      \ '期限切れ後も倍率が残っている')
" AI 国のイベントはログに載らない
call vimtoria#events#fire(s:st.world, 'GBR', 'strikes', s:st.day, 0)
for s:line in s:st.world.eventlog
  call assert_false(s:line =~# 'イギリス', 'AI 国のイベントがログに載った')
endfor

" ---- 抽選を有効にすると実際にイベントが起きる(34カ国×2年で確率的にほぼ確実) ----
unlet g:vimtoria_disable_events
call vimtoria#core#init()
let s:st = vimtoria#core#state()
let s:i = 0
while s:i < 104
  call vimtoria#econ#tick(s:st)
  let s:i += 1
endwhile
let s:total_events = 0
for s:cid in keys(s:st.world.events)
  let s:total_events += len(s:st.world.events[s:cid])
endfor
call assert_true(s:total_events > 0 || !empty(s:st.world.eventlog),
      \ '2年間イベントが一度も起きていない')
let g:vimtoria_disable_events = 1

" ---- 列強ランキング画面 ----
let s:st.screen = 'ranking'
let s:lines = vimtoria#ui#build_lines(s:st)
call assert_true(len(s:lines) > 10, 'ランキングの描画行が少なすぎる')
let s:found_me = 0
for s:line in s:lines
  if s:line =~# '(自国)'
    let s:found_me = 1
  endif
endfor
call assert_true(s:found_me, '自国がランキングに出ていない')

" ---- ヘルプが存在する ----
call assert_true(filereadable('doc/vimtoria.txt'), 'ヘルプファイルが無い')

call vimtoria#core#shutdown()

" ---- 結果出力 ----
if empty(v:errors)
  call writefile(['OK'], 'test/results.txt')
else
  call writefile(['FAIL'] + v:errors, 'test/results.txt')
endif
qa!
