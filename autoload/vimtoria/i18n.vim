scriptencoding utf-8
" i18n.vim - 表示言語(日本語/英語)の管理
"
" ゲームデータの名称は data/*.vim の name / name_en を vimtoria#i18n#name() で、
" 説明は desc / desc_en を vimtoria#i18n#desc() で引く。
" UI 文字列は s:T の {key: [日本語, 英語]} から vimtoria#i18n#t() で引く。
" 言語は起動時の言語選択画面か g:vimtoria_lang で決まる(既定 'ja')。

let s:lang = 'ja'

function! vimtoria#i18n#init() abort
  let l:g = get(g:, 'vimtoria_lang', '')
  if l:g ==# 'ja' || l:g ==# 'en'
    let s:lang = l:g
  endif
endfunction

function! vimtoria#i18n#lang() abort
  return s:lang
endfunction

function! vimtoria#i18n#set(lang) abort
  if a:lang ==# 'ja' || a:lang ==# 'en'
    let s:lang = a:lang
  endif
endfunction

function! vimtoria#i18n#t(key) abort
  return s:T[a:key][s:lang ==# 'en']
endfunction

" データ定義の名称/説明(name_en 未定義なら日本語にフォールバック)
function! vimtoria#i18n#name(def) abort
  return s:lang ==# 'en' && has_key(a:def, 'name_en') ? a:def.name_en : a:def.name
endfunction

function! vimtoria#i18n#desc(def) abort
  return s:lang ==# 'en' && has_key(a:def, 'desc_en') ? a:def.desc_en : a:def.desc
endfunction

" 人口(単位: 万人)の表示
function! vimtoria#i18n#pop(pop) abort
  if s:lang ==# 'en'
    return a:pop >= 100 ? printf('%.1fM', a:pop / 100.0) : printf('%dk', a:pop * 10)
  endif
  return printf('%d万人', a:pop)
endfunction

let s:T = {
      \ 'list_sep': ['・', ', '],
      \
      \ 'scr_map':          ['世界地図', 'World Map'],
      \ 'scr_state':        ['州情報', 'State'],
      \ 'scr_market':       ['市場', 'Market'],
      \ 'scr_budget':       ['予算', 'Budget'],
      \ 'scr_construction': ['建設', 'Construction'],
      \ 'scr_tech':         ['技術', 'Technology'],
      \ 'scr_pops':         ['Pop', 'Pops'],
      \ 'scr_ranking':      ['列強ランキング', 'Great Powers'],
      \ 'scr_politics':     ['政治', 'Politics'],
      \ 'scr_diplo':        ['外交', 'Diplomacy'],
      \ 'scr_military':     ['軍事', 'Military'],
      \ 'scr_select':       ['国選択', 'Country Selection'],
      \ 'scr_lang':         ['言語選択', 'Language'],
      \
      \ 'hdr_fmt':    [' VIMTORIA ┃ %s ┃ %s ┃ 国庫 £%s ┃ %s',
      \               ' VIMTORIA ┃ %s ┃ %s ┃ Treasury £%s ┃ %s'],
      \ 'hdr_paused': ['❚❚ 停止中', '❚❚ PAUSED'],
      \ 'hdr_speed':  [' 速度%d', ' speed %d'],
      \
      \ 'hint_map': [' Space:停止 1-4:速度 hjkl/クリック:州選択 Enter:カーソル位置/選択中の州の詳細'
      \   . ' gm:市場 gb:予算 gc:建設 gt:技術 gv:政治 gd:外交 ga:軍事 gp:Pop gr:列強 S/L:セーブ/ロード q:終了',
      \   ' Space:pause 1-4:speed hjkl/click:select Enter:state under cursor (or selected)'
      \   . ' gm:market gb:budget gc:build gt:tech gv:politics gd:diplomacy ga:military gp:pops gr:powers S/L:save/load q:quit'],
      \ 'hint_construction': [' j/k:建物を選択 Enter:キューへ追加 x:末尾を取消 Space:停止/再開 q:マップへ戻る',
      \   ' j/k:choose building Enter:add to queue x:cancel last Space:pause q:back to map'],
      \ 'hint_budget': [' +/-:税率を変更 Space:停止/再開 1-4:速度 q:マップへ戻る',
      \   ' +/-:adjust tax rate Space:pause 1-4:speed q:back to map'],
      \ 'hint_tech': [' j/k:技術を選択 Enter:研究開始 Space:停止/再開 q:マップへ戻る',
      \   ' j/k:choose tech Enter:start research Space:pause q:back to map'],
      \ 'hint_politics': [' j/k:法律を選択 Enter:制定開始 Space:停止/再開 q:マップへ戻る',
      \   ' j/k:choose law Enter:start enacting Space:pause q:back to map'],
      \ 'hint_diplo': [' j/k:国を選択 i:関係改善 a:同盟/破棄 w:宣戦布告 p:白紙和平 q:マップへ戻る',
      \   ' j/k:choose country i:improve relations a:alliance w:declare war p:white peace q:back to map'],
      \ 'hint_military': [' r:徴募(+5連隊) d:解散(-5連隊) Space:停止/再開 q:マップへ戻る',
      \   ' r:recruit (+5 regiments) d:disband (-5) Space:pause q:back to map'],
      \ 'hint_select': [' j/k:国を選択 Enter:この国でプレイ開始 q:終了',
      \   ' j/k:choose country Enter:start playing q:quit'],
      \ 'hint_lang': [' j/k:選択 Enter:決定 / j/k:choose Enter:confirm',
      \   ' j/k:選択 Enter:決定 / j/k:choose Enter:confirm'],
      \ 'hint_default': [' Space:停止/再開 1-4:速度 q/Esc:マップへ戻る',
      \   ' Space:pause 1-4:speed q/Esc:back to map'],
      \
      \ 'map_selected':  ['  選択: %s — %s%s / 人口 %s', '  Selected: %s — %s%s / population %s'],
      \ 'map_own':       ['(自国)', ' (yours)'],
      \ 'map_states_of': ['  %s の州: %s', '  States of %s: %s'],
      \ 'map_recent':    ['  ── 最近の出来事 ──', '  ── Recent events ──'],
      \ 'map_world':     ['  1836年の世界 — %dカ国 %d州', '  The world of 1836 — %d countries, %d states'],
      \
      \ 'st_title':  ['  ━━ 州情報: %s (%s) ━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
      \              '  ━━ State: %s (%s) ━━━━━━━━━━━━━━━━━━━━━━━━━━━━'],
      \ 'st_owner':  ['    所属国: %s%s', '    Owner: %s%s'],
      \ 'st_pop':    ['    人口:   %s ┃ 労働力 %.0f千人 ┃ 雇用 %.0f千人 ┃ 自給農 %.0f千人',
      \              '    Population: %s ┃ workforce %.0fk ┃ employed %.0fk ┃ subsistence %.0fk'],
      \ 'st_col_building': ['建物', 'Building'],
      \ 'st_cols':   ['%8s %8s %12s', '%8s %8s %12s'],
      \ 'st_col_levels': ['レベル', 'Levels'],
      \ 'st_col_f':      ['稼働率', 'Util.'],
      \ 'st_col_gross':  ['週間粗利', 'Wkly gross'],
      \
      \ 'mk_title': ['  ━━ 市場: %s ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
      \             '  ━━ Market: %s ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'],
      \ 'mk_stats': ['  週間GDP £%s ┃ 週間所得 £%s ┃ 失業率(自給農含む) %.1f%% ┃ 生活水準 %.2f',
      \             '  Weekly GDP £%s ┃ weekly income £%s ┃ unemployment (incl. subsistence) %.1f%% ┃ SoL %.2f'],
      \ 'mk_col_goods': ['財', 'Goods'],
      \ 'mk_cols':  ['%9s %9s %10s %10s  %s', '%9s %9s %10s %10s  %s'],
      \ 'mk_col_price': ['価格', 'Price'],
      \ 'mk_col_base':  ['基準', 'Base'],
      \ 'mk_col_buy':   ['買い注文', 'Buy'],
      \ 'mk_col_sell':  ['売り注文', 'Sell'],
      \ 'mk_col_bal':   ['需給', 'Balance'],
      \ 'mk_short': ['▲不足', '▲ short'],
      \ 'mk_over':  ['▼過剰', '▼ surplus'],
      \ 'mk_even':  ['─均衡', '─ balanced'],
      \ 'mk_note':  ['  ※価格は需給で毎週変動する(基準価格の ±75% でクランプ)。',
      \             '  Prices move weekly with supply and demand (clamped to ±75% of base).'],
      \
      \ 'bg_title':    ['  ━━ 予算: %s ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
      \                '  ━━ Budget: %s ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'],
      \ 'bg_treasury': ['  国庫: £%s', '  Treasury: £%s'],
      \ 'bg_debt':     ['  国庫: -£%s(債務)', '  Treasury: -£%s (debt)'],
      \ 'bg_credit':   ['  信用限度: £%s(週間所得の%.0f%%)┃ 年利 %.0f%%',
      \                '  Credit limit: £%s (%.0f%% of weekly income) ┃ interest %.0f%%/yr'],
      \ 'bg_tax':      ['  所得税率: %.1f%%  (+/- で %.1f%% ずつ変更、%.0f%%〜%.0f%%)',
      \                '  Income tax: %.1f%%  (+/- adjusts by %.1f%%, range %.0f%%-%.0f%%)'],
      \ 'bg_lastweek': ['  ── 先週の収支 ──', '  ── Last week ──'],
      \ 'bg_row_tax':      ['    税収          +£%s', '    Tax revenue     +£%s'],
      \ 'bg_row_upkeep':   ['    政府維持費    -£%s', '    Gov. upkeep     -£%s'],
      \ 'bg_row_mil':      ['    軍事費        -£%s', '    Military        -£%s'],
      \ 'bg_row_interest': ['    利払い        -£%s', '    Interest        -£%s'],
      \ 'bg_row_spend':    ['    建設支出      -£%s', '    Construction    -£%s'],
      \ 'bg_row_net':      ['    収支          %s£%s', '    Net             %s£%s'],
      \ 'bg_ref':  ['  参考: 週間所得 £%s ┃ 生活水準 %.2f(増税すると低下)',
      \            '  Weekly income £%s ┃ SoL %.2f (higher taxes lower it)'],
      \ 'bg_note': ['  ※建設は信用限度まで借金しながら進む。中央銀行の研究で年利が下がる。',
      \            '  Construction may run into debt up to the credit limit; Central Banking lowers interest.'],
      \
      \ 'cs_title':   ['  ━━ 建設: %s ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
      \               '  ━━ Construction: %s ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'],
      \ 'cs_stats':   ['  建設力 %.1fpt/週 ┃ 資材費 £%.0f/pt ┃ 先週の建設支出 £%s',
      \               '  Capacity %.1fpt/wk ┃ materials £%.0f/pt ┃ last week''s spend £%s'],
      \ 'cs_target':  ['  建設先: %s%s', '  Build site: %s%s'],
      \ 'cs_not_own': [' ※自国領ではありません(マップで自国州を選択してから gc)',
      \               ' — not your territory (select one of your states on the map, then gc)'],
      \ 'cs_menu':    ['  ── 建物メニュー ──', '  ── Buildings ──'],
      \ 'cs_out':     ['%s %.0f/週', '%s %.0f/wk'],
      \ 'cs_outputs': ['産出: ', 'out: '],
      \ 'cs_queue':   ['  ── 建設キュー (%d/%d) ──', '  ── Queue (%d/%d) ──'],
      \ 'cs_empty':   ['  (空 — Enter で追加)', '  (empty — press Enter to add)'],
      \
      \ 'tc_title':  ['  ━━ 技術: %s ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
      \              '  ━━ Technology: %s ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'],
      \ 'tc_none':   ['(未選択 — j/k で選び Enter で研究開始)',
      \              '(none — pick with j/k, press Enter to start)'],
      \ 'tc_cur':    ['  研究力 %.1frp/週 ┃ 研究中: %s', '  Research %.1frp/wk ┃ current: %s'],
      \ 'tc_req':    [' 要:', ' req:'],
      \ 'tc_legend': ['  ✓:研究済 ▶:研究中 ・:研究可 ×:前提未達(切替えても進捗は保存される)',
      \              '  ✓:done ▶:current ・:available ×:locked (progress is kept per tech)'],
      \
      \ 'pp_title':   ['  ━━ Pop: %s ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
      \               '  ━━ Pops: %s ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'],
      \ 'pp_stats':   ['  労働力 %.0f千人 ┃ 雇用 %.0f千人 ┃ 自給農 %.0f千人 ┃ 生活水準 %.2f',
      \               '  Workforce %.0fk ┃ employed %.0fk ┃ subsistence %.0fk ┃ SoL %.2f'],
      \ 'pp_byprof':  ['  ── 職業別雇用 ──', '  ── Employment by profession ──'],
      \ 'pp_prof_row': ['    %s %8.0f千人', '    %s %8.0fk'],
      \ 'pp_bystate': ['  ── 州別(失業者は毎週、求人のある州へ少しずつ移動する) ──',
      \               '  ── By state (the unemployed slowly migrate to states with jobs) ──'],
      \ 'pp_col_state': ['州', 'State'],
      \ 'pp_cols':    ['%10s %10s %10s', '%10s %10s %10s'],
      \ 'pp_col_wf':  ['労働力', 'Workforce'],
      \ 'pp_col_emp': ['雇用', 'Employed'],
      \ 'pp_col_sub': ['自給農', 'Subsist.'],
      \ 'pp_row':     ['    %s%9.0f千 %9.0f千 %9.0f千', '    %s%9.0fk %9.0fk %9.0fk'],
      \
      \ 'rk_title': ['  ━━ 列強ランキング(週間GDP順) ━━━━━━━━━━━━━━━━━━━━',
      \             '  ━━ Great Powers (by weekly GDP) ━━━━━━━━━━━━━━━━━━━━'],
      \ 'rk_col_rank':    ['   順位 ', '   Rank '],
      \ 'rk_col_country': ['国', 'Country'],
      \ 'rk_cols': ['%12s %8s %6s %6s %14s', '%12s %8s %6s %6s %14s'],
      \ 'rk_col_gdp':  ['週間GDP', 'Wkly GDP'],
      \ 'rk_col_sol':  ['生活水準', 'SoL'],
      \ 'rk_col_tech': ['技術', 'Tech'],
      \ 'rk_col_army': ['陸軍', 'Army'],
      \ 'rk_col_gold': ['国庫', 'Treasury'],
      \ 'rk_me':   ['(自国)', ' (you)'],
      \ 'rk_note': ['  スコアの目安: GDP は経済規模、生活水準は豊かさ、技術は先進性。',
      \            '  GDP measures economic size, SoL prosperity, tech advancement.'],
      \
      \ 'pl_title': ['  ━━ 政治: %s ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
      \             '  ━━ Politics: %s ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'],
      \ 'pl_none':  ['(なし — j/k で法律を選び Enter で制定開始)',
      \             '(none — pick a law with j/k, press Enter to start)'],
      \ 'pl_enact': ['%s %.0f/%.0f(支持 %+.2f%s)', '%s %.0f/%.0f (support %+.2f%s)'],
      \ 'pl_forcing': [' — 強行中、急進性が上がる', ' — forcing, radicalism rising'],
      \ 'pl_rad':   ['  急進性 %.1f/100%s ┃ 制定中: %s', '  Radicalism %.1f/100%s ┃ enacting: %s'],
      \ 'pl_danger': ['(反乱の危険!)', ' (uprising risk!)'],
      \ 'pl_igs':   ['  ── 利益集団 ──', '  ── Interest groups ──'],
      \ 'pl_ig_row': ['    %s 勢力 %4.0f%%  現行法への態度 %+d %s',
      \              '    %s clout %4.0f%%  attitude to current laws %+d %s'],
      \ 'pl_happy': ['(満足)', '(pleased)'],
      \ 'pl_angry': ['(不満)', '(angry)'],
      \ 'pl_laws':  ['  ── 法律 ──', '  ── Laws ──'],
      \ 'pl_enacting': [' 制定中', ' enacting'],
      \ 'pl_support':  [' 支持 %+.2f', ' support %+.2f'],
      \ 'pl_note1': ['  支持が正なら制定が速い。負のまま強行すると急進性が上がり、',
      \             '  Positive support speeds up enactment. Forcing a law with negative support'],
      \ 'pl_note2': ['  急進性 60 超で反乱(全産出 -20%)の危険がある。',
      \             '  raises radicalism; above 60 there is a risk of an uprising (all output -20%).'],
      \
      \ 'dp_title': ['  ━━ 外交: %s ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
      \             '  ━━ Diplomacy: %s ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'],
      \ 'dp_hint':  ['  宣戦の奪取目標はマップで選択中の州(相手領の場合)になる',
      \             '  The war goal is the state selected on the map (if it belongs to the target)'],
      \ 'dp_col_country': ['国', 'Country'],
      \ 'dp_cols':  ['%6s  %-8s %8s', '%6s  %-8s %8s'],
      \ 'dp_col_rel':    ['関係', 'Rel.'],
      \ 'dp_col_status': ['状態', 'Status'],
      \ 'dp_col_power':  ['戦力', 'Power'],
      \ 'dp_gone':  ['滅亡', 'gone'],
      \ 'dp_atwar': ['交戦中', 'at war'],
      \ 'dp_ally':  ['同盟', 'ally'],
      \ 'dp_wars':  ['  ── 世界の戦争 ──', '  ── Wars of the world ──'],
      \ 'dp_none':  ['  (なし)', '  (none)'],
      \ 'dp_war_row': ['  %s ┃ 戦況 %+.0f(+100で攻撃側勝利)┃ 目標: %s',
      \              '  %s ┃ score %+.0f (+100 = attacker wins) ┃ goal: %s'],
      \
      \ 'ml_title': ['  ━━ 軍事: %s ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
      \             '  ━━ Military: %s ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'],
      \ 'ml_stats': ['  連隊 %.0f / 上限 %.0f ┃ 総戦力 %.0f(技術ボーナス込み)',
      \             '  Regiments %.0f / cap %.0f ┃ strength %.0f (incl. tech bonus)'],
      \ 'ml_upkeep': ['  週間維持費 £%s + 物資: %s', '  Weekly upkeep £%s + goods: %s'],
      \ 'ml_recruit': ['  徴募: %.0f個連隊あたり £%s と労働力 %.0f千人(最大州から)',
      \              '  Recruiting %.0f regiments costs £%s and %.0fk workforce (from your largest state)'],
      \ 'ml_wars': ['  ── 交戦中の戦争 ──', '  ── Your wars ──'],
      \ 'ml_att':  ['攻撃側', 'attacker'],
      \ 'ml_def':  ['防御側', 'defender'],
      \ 'ml_war_row': ['  vs %s(%s)┃ 戦況 %+.0f ┃ 目標: %s',
      \              '  vs %s (%s) ┃ score %+.0f ┃ goal: %s'],
      \ 'ml_none': ['  (なし — 宣戦は外交画面 gd から)', '  (none — declare war from the diplomacy screen, gd)'],
      \ 'ml_top':  ['  ── 陸軍力トップ10 ──', '  ── Top 10 armies ──'],
      \ 'ml_me':   [' ←自国', ' ← you'],
      \
      \ 'sl_title': ['  ━━ プレイする国を選択 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
      \             '  ━━ Choose your country ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'],
      \ 'sl_hint':  ['  j/k で選び、Enter で 1836年1月1日 からプレイ開始。',
      \             '  Pick with j/k, press Enter to start on Jan 1, 1836.'],
      \ 'sl_col_country': ['国', 'Country'],
      \ 'sl_cols':  ['%4s %10s %8s %6s  %s', '%4s %10s %8s %6s  %s'],
      \ 'sl_col_states': ['州', 'St.'],
      \ 'sl_col_pop':    ['人口(万)', 'Pop(10k)'],
      \ 'sl_col_wf':     ['労働力', 'Wkforce'],
      \ 'sl_col_army':   ['陸軍', 'Army'],
      \ 'sl_col_econ':   ['経済体制', 'Econ. policy'],
      \ 'sl_note':  ['  大国は経済も軍も強いが研究は頭打ちしやすい。小国は身軽だが油断すると併合される。',
      \             '  Great powers are strong but research plateaus; small nations are nimble but risk annexation.'],
      \
      \ 'msg_play_start': ['%s でプレイ開始(Space で時間が流れる)', 'Playing as %s (press Space to unpause)'],
      \ 'msg_enqueued':   ['%s をキューに追加しました', 'Added %s to the queue'],
      \ 'msg_research_started': ['%s の研究を開始しました', 'Started researching %s'],
      \ 'msg_enact_started':    ['%s の制定を開始しました', 'Started enacting %s'],
      \ 'msg_recruited':  ['5個連隊を徴募しました', 'Recruited 5 regiments'],
      \ 'msg_disbanded':  ['5個連隊を解散しました', 'Disbanded 5 regiments'],
      \ 'msg_cancelled':  ['末尾のキュー項目を取り消しました', 'Cancelled the last queue item'],
      \ 'msg_tax_cap':    ['現行の税制では %.0f%% が上限です(gv で税制を変更)',
      \                   'The current taxation law caps the rate at %.0f%% (change it via gv)'],
      \ 'msg_saved':      ['セーブしました: %s', 'Saved: %s'],
      \ 'msg_save_fail':  ['セーブに失敗しました: %s', 'Save failed: %s'],
      \ 'msg_no_save':    ['セーブデータがありません: %s', 'No save file: %s'],
      \ 'msg_load_fail':  ['セーブデータを読み込めません: %s', 'Could not read the save file: %s'],
      \ 'msg_bad_save':   ['セーブデータの形式が不正です', 'The save file format is invalid'],
      \ 'msg_loaded':     ['ロードしました(停止中): %s', 'Loaded (paused): %s'],
      \ 'confirm_load':   ['セーブデータをロードしますか?(現在の進行は失われます)',
      \                   'Load the saved game? (current progress will be lost)'],
      \ 'confirm_quit':   ['Vimtoria を終了しますか?(S でセーブできます)',
      \                   'Quit Vimtoria? (press S to save first)'],
      \ 'msg_improved':        ['%s との関係を改善しました', 'Improved relations with %s'],
      \ 'msg_alliance_formed': ['%s と同盟を結びました', 'Formed an alliance with %s'],
      \ 'msg_alliance_broken': ['%s との同盟を破棄しました', 'Broke the alliance with %s'],
      \ 'msg_war_declared':    ['%s に宣戦布告(目標: %s)', 'Declared war on %s (goal: %s)'],
      \ 'msg_no_states':       ['相手国に州がありません', 'The target country has no states'],
      \ 'msg_white_peace':     ['白紙和平が成立しました', 'White peace concluded'],
      \
      \ 'err_not_owned':   ['%s は自国領ではありません', '%s is not your territory'],
      \ 'err_queue_full':  ['キューが一杯です(最大%d件)', 'The queue is full (max %d)'],
      \ 'err_queue_empty': ['キューは空です', 'The queue is empty'],
      \ 'err_tech_done':   ['%s は研究済みです', '%s is already researched'],
      \ 'err_tech_req':    ['前提技術が未研究です: %s', 'Missing prerequisites: %s'],
      \ 'err_law_active':  ['%s は既に施行されています', '%s is already in effect'],
      \ 'err_law_enacting': ['%s は制定中です', '%s is already being enacted'],
      \ 'err_dip_cd':      ['外交官はまだ交渉中です(26週に1回)', 'Your diplomats are still busy (once per 26 weeks)'],
      \ 'err_no_funds':    ['資金不足です(£%.0f 必要)', 'Not enough funds (£%.0f needed)'],
      \ 'err_ally_war':    ['交戦中の相手とは同盟できません', 'Cannot ally with an enemy at war'],
      \ 'err_ally_rel':    ['関係が %.0f 以上必要です', 'Requires relations of at least %.0f'],
      \ 'err_war_self':    ['自国には宣戦できません', 'Cannot declare war on yourself'],
      \ 'err_war_ally':    ['同盟国には宣戦できません', 'Cannot declare war on an ally'],
      \ 'err_war_already': ['既に交戦中です', 'Already at war'],
      \ 'err_war_dead':    ['相手国は消滅しています', 'That country no longer exists'],
      \ 'err_no_war':      ['交戦していません', 'Not at war with them'],
      \ 'err_mil_cap':     ['連隊が上限に達しています(労働力を増やすと上限も増える)',
      \                    'Regiment cap reached (it grows with your workforce)'],
      \ 'err_mil_workforce': ['徴募できる労働力がありません', 'No workforce available to recruit from'],
      \ 'err_mil_none':    ['解散できる連隊がありません', 'No regiments to disband'],
      \
      \ 'evt_fmt':         ['【%s】%s%s', '[%s] %s%s'],
      \ 'log_law_enacted': ['【法律制定】%s が施行された', '[Law] %s has been enacted'],
      \ 'log_war_declared': ['【宣戦布告】%s が %s に宣戦(目標: %s)',
      \                    '[War] %s declares war on %s (goal: %s)'],
      \ 'log_white_peace': ['【和平】%s と %s が白紙和平', '[Peace] White peace between %s and %s'],
      \ 'log_war_won':     ['【講和】%s が勝利し %s を併合', '[Peace] %s wins the war and annexes %s'],
      \ 'log_war_lost':    ['【講和】%s の侵攻は撃退された', '[Peace] The invasion by %s has been repelled'],
      \ }
