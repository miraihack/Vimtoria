scriptencoding utf-8
" test_tech.vim - M3 技術ツリー・AI 運営・職業移動のヘッドレステスト
" 実行: test/run.sh(結果は test/results.txt に書かれる)

let v:errors = []

" ---- 技術データの整合性 ----
let s:data = vimtoria#data#tech()
call assert_equal(len(s:data.techs), len(s:data.order))
call assert_equal(sort(keys(s:data.techs)), sort(copy(s:data.order)))
for [s:tid, s:def] in items(s:data.techs)
  call assert_true(s:def.cost > 0.0, s:tid)
  for s:req in s:def.req
    call assert_true(has_key(s:data.techs, s:req), s:tid . ': 前提が未定義 ' . s:req)
  endfor
endfor

" ---- 研究の開始条件と進行 ----
call vimtoria#core#init()
let s:st = vimtoria#core#state()
" 前提未達は開始できない
call assert_notequal('', vimtoria#tech#start(s:st.world, 'JAP', 'machine_tools'))
" 前提なしは開始できる
call assert_equal('', vimtoria#tech#start(s:st.world, 'JAP', 'steam_engine'))
call assert_equal('steam_engine', s:st.world.techs['JAP'].current)
call vimtoria#econ#tick(s:st)
call assert_true(s:st.world.techs['JAP'].progress['steam_engine'] > 0.0,
      \ '研究が進んでいない')
" 切り替えても進捗は保存される
call assert_equal('', vimtoria#tech#start(s:st.world, 'JAP', 'crop_rotation'))
call vimtoria#econ#tick(s:st)
call assert_true(s:st.world.techs['JAP'].progress['steam_engine'] > 0.0)
call assert_true(s:st.world.techs['JAP'].progress['crop_rotation'] > 0.0)

" ---- 完了 → 効果適用(輪作で穀物の売り注文が約+20%) ----
call vimtoria#core#init()
let s:st = vimtoria#core#state()
call vimtoria#econ#tick(s:st)
let s:sell_before = s:st.world.markets['JAP']['grain'].sell
let s:st.world.techs['JAP'].done['crop_rotation'] = 1
call vimtoria#tech#recompute_mods(s:st.world, 'JAP')
call assert_true(abs(vimtoria#tech#out_mult(s:st.world, 'JAP', 'grain_farm') - 1.2) < 0.001)
call vimtoria#econ#tick(s:st)
let s:sell_after = s:st.world.markets['JAP']['grain'].sell
call assert_true(s:sell_after > s:sell_before * 1.12,
      \ printf('輪作の効果が売り注文に出ていない: %.0f → %.0f', s:sell_before, s:sell_after))

" ---- 研究完了で mods が更新される(実際に走らせて完了させる) ----
call vimtoria#core#init()
let s:st = vimtoria#core#state()
call vimtoria#tech#start(s:st.world, 'JAP', 'joint_stock')
let s:cap_before = vimtoria#build#capacity(s:st.world, 'JAP')
let s:i = 0
while empty(keys(s:st.world.techs['JAP'].done)) && s:i < 60
  call vimtoria#econ#tick(s:st)
  let s:i += 1
endwhile
call assert_true(has_key(s:st.world.techs['JAP'].done, 'joint_stock'),
      \ '60週で株式会社が完了しない')
call assert_equal('', s:st.world.techs['JAP'].current)
call assert_true(vimtoria#build#capacity(s:st.world, 'JAP') > s:cap_before * 1.2,
      \ '株式会社の建設力+25%が効いていない')

" ---- 技術画面のアクション ----
call vimtoria#core#init()
let s:st = vimtoria#core#state()
call vimtoria#core#action('screen_tech')
call assert_equal(0, s:st.menu_idx)
call vimtoria#core#action('nav_j')
call vimtoria#core#action('open_state')
call assert_equal('steam_engine', s:st.world.techs['JAP'].current)
call vimtoria#core#action('back')

" ---- AI 国: 研究と建設を自動で行う ----
call vimtoria#core#init()
let s:st = vimtoria#core#state()
function! s:levels_sum(st, cid) abort
  let l:sum = 0.0
  for l:sid in vimtoria#data#map().country_states[a:cid]
    for l:b in values(a:st.world.buildings[l:sid])
      let l:sum += l:b.levels
    endfor
  endfor
  return l:sum
endfunction
let s:gbr_before = s:levels_sum(s:st, 'GBR')
let s:i = 0
while s:i < 104
  call vimtoria#econ#tick(s:st)
  let s:i += 1
endwhile
" AI は研究している(2年あれば少なくとも1つは完了しているはず)
call assert_true(!empty(s:st.world.techs['GBR'].done)
      \ || !empty(s:st.world.techs['GBR'].current), 'AI が研究していない')
" AI は建物を建てている
call assert_true(s:levels_sum(s:st, 'GBR') > s:gbr_before + 0.5,
      \ printf('AI が建設していない: %.1f → %.1f', s:gbr_before, s:levels_sum(s:st, 'GBR')))
" プレイヤー国は AI に操作されない(研究は空のまま)
call assert_true(empty(s:st.world.techs['JAP'].current), 'プレイヤー国が AI に操作された')
call assert_true(empty(s:st.world.queues['JAP']), 'プレイヤー国のキューに AI が積んだ')

" ---- 州間の職業移動: 求人のある州へ労働力が移る ----
call vimtoria#core#init()
let s:st = vimtoria#core#state()
" 蝦夷地に大きな農場を置く(欠員だらけ) → 他州から人が来る
let s:st.world.buildings['EZO']['grain_farm'] =
      \ {'levels': 20.0, 'f': 0.05, 'gross': 0.0}
let s:total_before = 0.0
for s:sid in vimtoria#data#map().country_states['JAP']
  let s:total_before += s:st.world.workforce[s:sid]
endfor
let s:ezo_before = s:st.world.workforce['EZO']
let s:i = 0
while s:i < 20
  call vimtoria#econ#tick(s:st)
  let s:i += 1
endwhile
call assert_true(s:st.world.workforce['EZO'] > s:ezo_before + 2.0,
      \ printf('蝦夷地へ労働力が移動していない: %.1f → %.1f',
      \        s:ezo_before, s:st.world.workforce['EZO']))
let s:total_after = 0.0
for s:sid in vimtoria#data#map().country_states['JAP']
  let s:total_after += s:st.world.workforce[s:sid]
endfor
call assert_true(abs(s:total_after - s:total_before) < 0.1,
      \ printf('移動で労働力総量が変わった: %.1f → %.1f', s:total_before, s:total_after))

" ---- 技術・Pop 画面の描画 ----
for s:screen in ['tech', 'pops']
  let s:st.screen = s:screen
  let s:lines = vimtoria#ui#build_lines(s:st)
  call assert_true(len(s:lines) > 5, s:screen . ': 描画行が少なすぎる')
endfor

call vimtoria#core#shutdown()

" ---- 結果出力 ----
if empty(v:errors)
  call writefile(['OK'], 'test/results.txt')
else
  call writefile(['FAIL'] + v:errors, 'test/results.txt')
endif
qa!
