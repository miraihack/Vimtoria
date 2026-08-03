scriptencoding utf-8
" test_core.vim - M0 のヘッドレステスト
" 実行: test/run.sh(結果は test/results.txt に書かれる)

let v:errors = []

" ---- 日付変換(365日暦) ----
call assert_equal({'year': 1836, 'month': 1, 'day': 1}, vimtoria#core#date(0))
call assert_equal({'year': 1836, 'month': 1, 'day': 31}, vimtoria#core#date(30))
call assert_equal({'year': 1836, 'month': 2, 'day': 1}, vimtoria#core#date(31))
call assert_equal({'year': 1836, 'month': 12, 'day': 31}, vimtoria#core#date(364))
call assert_equal({'year': 1837, 'month': 1, 'day': 1}, vimtoria#core#date(365))
call assert_equal({'year': 1936, 'month': 1, 'day': 1}, vimtoria#core#date(36500))

" ---- tick で 1 週間進む ----
call vimtoria#core#init()
call assert_equal(0, vimtoria#core#state().day)
call vimtoria#core#tick()
call assert_equal(7, vimtoria#core#state().day)
call vimtoria#core#tick()
call assert_equal(14, vimtoria#core#state().day)

" ---- マップデータの整合性 ----
let s:data = vimtoria#data#map()
call assert_equal(78, len(s:data.states))
call assert_equal(37, len(s:data.countries))
call assert_equal(sort(keys(s:data.countries)), sort(copy(s:data.country_order)))
" 全行が同じ幅({TAG} は置換後も 5 文字なので生の strlen で検証できる)
for s:line in s:data.template
  call assert_equal(strlen(s:data.template[0]), strlen(s:line),
        \ 'マップの行幅が不揃い: ' . s:line)
endfor
" 精緻化後のグリッドサイズ(tools/gen_map.py の設定と一致)
call assert_equal(200, strlen(s:data.template[0]))
call assert_equal(37, len(s:data.template))
" 各国の capital が実在し、その国に属する
for [s:cid, s:country] in items(s:data.countries)
  call assert_true(has_key(s:data.states, s:country.capital), s:cid . ': capital が未定義')
  call assert_equal(s:cid, s:data.states[s:country.capital].country, s:cid . ': capital が他国領')
endfor
let s:joined = join(s:data.template, "\n")
for [s:id, s:stt] in items(s:data.states)
  " 所属国が実在する
  call assert_true(has_key(s:data.countries, s:stt.country), s:id . ': 国が未定義')
  " マップ上に一度だけ配置されている
  let s:cnt = 0
  let s:idx = 0
  while 1
    let s:idx = stridx(s:joined, '{' . s:id . '}', s:idx)
    if s:idx == -1 | break | endif
    let s:cnt += 1
    let s:idx += 1
  endwhile
  call assert_equal(1, s:cnt, s:id . ': マップ上の配置数が 1 でない')
  " 座標が計算済み
  call assert_true(s:stt.row >= 0 && s:stt.col >= 0, s:id . ': 座標が未計算')
endfor

" ---- ナビゲーション: 全州・全方向で結果が有効な州 ID ----
for s:id in keys(s:data.states)
  let s:moved = 0
  for s:dir in ['h', 'j', 'k', 'l']
    let s:to = vimtoria#map#neighbor(s:id, s:dir)
    call assert_true(has_key(s:data.states, s:to), s:id . '/' . s:dir . ': 不正な移動先 ' . s:to)
    if s:to !=# s:id
      let s:moved = 1
    endif
  endfor
  " 孤立州がない(どれかの方向には動ける)
  call assert_true(s:moved, s:id . ': どの方向にも動けない')
endfor

" ---- マウスクリック/カーソル位置の州解決(州名ラベル) ----
call vimtoria#core#init()
" マップ描画で州名ラベルの位置テーブルができる
call vimtoria#screens#map#render(vimtoria#core#state())
let s:labels = vimtoria#screens#map#labels()
" 全ラベルの直上(先頭と末尾のバイト)でその州に解決される
let s:seen = {}
for [s:row, s:entries] in items(s:labels)
  for s:e in s:entries
    call assert_equal(s:e[0],
          \ vimtoria#core#click_resolve(str2nr(s:row), s:e[1]),
          \ s:e[0] . ': ラベル先頭のクリックが解決できない')
    call assert_equal(s:e[0],
          \ vimtoria#core#click_resolve(str2nr(s:row), s:e[2] - 1),
          \ s:e[0] . ': ラベル末尾のクリックが解決できない')
    let s:seen[s:e[0]] = 1
  endfor
endfor
call assert_equal(len(s:data.states), len(s:seen), '全州のラベルが配置されていない')
" 孤立州(ハワイ)の近傍クリックは最寄りとして解決される
let s:haw_e = filter(copy(s:labels[s:data.states['HAW'].row]),
      \ 'v:val[0] ==# ''HAW''')[0]
call assert_equal('HAW',
      \ vimtoria#core#click_resolve(s:data.states['HAW'].row + 1, s:haw_e[1]))
call assert_equal('HAW',
      \ vimtoria#core#click_resolve(s:data.states['HAW'].row, s:haw_e[2] + 2))
" 遠洋のクリックは何も選択しない
call assert_equal('', vimtoria#core#click_resolve(35, 20))
call assert_equal('', vimtoria#core#click_resolve(-3, 0))
" hit() はラベル直上のみ(近傍では空 = Enter は選択中の州へフォールバック)
call assert_equal('', vimtoria#screens#map#hit(35, 20))
call assert_equal('HAW', vimtoria#screens#map#hit(s:data.states['HAW'].row, s:haw_e[1]))

" ---- クリックアクション: 選択 → 再クリックで詳細 ----
let s:st = vimtoria#core#state()
" click() は getmousepos() 依存なので resolve+選択ロジックを直接検証
let s:st.selected = 'KIN'
call vimtoria#screens#map#render(s:st)
let s:edo_row = s:data.states['EDO'].row
let s:edo_e = filter(copy(vimtoria#screens#map#labels()[s:edo_row]),
      \ 'v:val[0] ==# ''EDO''')[0]
call assert_equal('EDO', vimtoria#core#click_resolve(s:edo_row, s:edo_e[1]))

" ---- アクション: 画面遷移・選択・速度 ----
call vimtoria#core#init()
" 既定プレイヤーは日本、初期選択は首都の江戸
call assert_equal('JAP', vimtoria#core#state().country)
call assert_equal('EDO', vimtoria#core#state().selected)
call vimtoria#core#action('speed_3')
call assert_equal(3, vimtoria#core#state().speed)
call assert_equal(500, vimtoria#core#speed_ms(3))

call vimtoria#core#action('nav_l')
call assert_notequal('', vimtoria#core#state().selected)

call vimtoria#core#action('open_state')
call assert_equal('state', vimtoria#core#state().screen)
call vimtoria#core#action('back')
call assert_equal('map', vimtoria#core#state().screen)

call vimtoria#core#action('screen_market')
call assert_equal('market', vimtoria#core#state().screen)
" 別画面ではマップ操作は無効
let s:before = vimtoria#core#state().selected
call vimtoria#core#action('nav_h')
call assert_equal(s:before, vimtoria#core#state().selected)
call vimtoria#core#action('back')
call assert_equal('map', vimtoria#core#state().screen)

" ---- 全画面の描画関数が非空の行リストを返す ----
for s:screen in ['map', 'state', 'market', 'budget', 'construction', 'tech', 'pops']
  let s:st = vimtoria#core#state()
  let s:st.screen = s:screen
  let s:st.screen_arg = s:screen ==# 'state' ? 'EDO' : ''
  let s:lines = vimtoria#ui#build_lines(s:st)
  call assert_true(len(s:lines) > 3, s:screen . ': 描画行が少なすぎる')
  for s:line in s:lines
    call assert_equal(v:t_string, type(s:line), s:screen . ': 文字列でない行がある')
  endfor
  " ヘッダに日付が入っている
  call assert_match('1836年', s:lines[0], s:screen)
endfor

" ---- 国選択画面: 選択操作以外を受け付けず、Enter で国が決まる ----
call vimtoria#core#init()
let s:st = vimtoria#core#state()
let s:st.screen = 'select'
" 時間・画面遷移はブロックされる
call vimtoria#core#action('pause')
call assert_equal(1, s:st.paused, '国選択中に時間が動いた')
call vimtoria#core#action('screen_market')
call assert_equal('select', s:st.screen, '国選択中に画面が遷移した')
" 2番目の国(イギリス)を選択
call vimtoria#core#action('nav_j')
call vimtoria#core#action('open_state')
call assert_equal('GBR', s:st.country, '選択した国になっていない')
call assert_equal('GBR', s:st.selected, '首都が選択されていない')
call assert_equal('map', s:st.screen)
" 国選択画面の描画
let s:st2 = vimtoria#core#state()
let s:st2.screen = 'select'
let s:lines = vimtoria#ui#build_lines(s:st2)
call assert_true(len(s:lines) > 37, '国選択画面に全国が並んでいない')
let s:st2.screen = 'map'

" ---- ESC(to_map): サブ画面から地図へ戻る。地図上では何もしない ----
call vimtoria#core#init()
let s:st = vimtoria#core#state()
call vimtoria#core#action('screen_market')
call vimtoria#core#action('to_map')
call assert_equal('map', s:st.screen, 'ESCで地図に戻らない')
call vimtoria#core#action('to_map')
call assert_equal('map', s:st.screen, '地図上のESCで画面が変わった')

" ---- 言語: 英語表示と言語選択画面 ----
call vimtoria#i18n#set('en')
call vimtoria#core#init()
let s:st = vimtoria#core#state()
call assert_equal('Jan 1, 1836', vimtoria#core#date_str(0))
let s:lines = vimtoria#ui#build_lines(s:st)
call assert_match('Treasury', s:lines[0], '英語ヘッダになっていない')
call assert_match('World Map', s:lines[0])
let s:joined = join(s:lines, "\n")
call assert_match('\[Edo\]', s:joined, '地図に英語の州名がない')
call assert_match('British Isles', s:joined)
" 言語選択画面: 選択操作以外を受け付けず、Enter で言語が決まる
let s:st.screen = 'lang'
let s:st.menu_idx = 0
call vimtoria#core#action('pause')
call assert_equal(1, s:st.paused, '言語選択中に時間が動いた')
call vimtoria#core#action('screen_market')
call assert_equal('lang', s:st.screen, '言語選択中に画面が遷移した')
call vimtoria#core#action('nav_j')
call vimtoria#core#action('open_state')
call assert_equal('en', vimtoria#i18n#lang(), '選択した言語になっていない')
call assert_equal('select', s:st.screen, '言語選択後に国選択へ進まない')
" 日本語に戻すと同じデータが日本語名で描画される
call vimtoria#i18n#set('ja')
let s:st.screen = 'map'
call assert_match('江戸', join(vimtoria#ui#build_lines(s:st), "\n"))
call vimtoria#core#init()

" ---- ポーズ切り替え(タイマー起動→即停止) ----
call vimtoria#core#init()
call assert_equal(1, vimtoria#core#state().paused)
call vimtoria#core#action('pause')
call assert_equal(0, vimtoria#core#state().paused)
call vimtoria#core#action('pause')
call assert_equal(1, vimtoria#core#state().paused)

call vimtoria#core#shutdown()

" ---- 結果出力 ----
if empty(v:errors)
  call writefile(['OK'], 'test/results.txt')
else
  call writefile(['FAIL'] + v:errors, 'test/results.txt')
endif
qa!
