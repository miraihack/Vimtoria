scriptencoding utf-8
" data/events.vim - ランダムイベント定義
"
" 毎週 chance/1000 の確率で各国にイベントが発生する(ログはプレイヤー国のみ)。
" effects:
"   out           : {建物ID: 産出倍率}(duration 週の間)
"   out_all       : 全建物の産出倍率(duration 週の間)
"   research      : 研究力倍率(duration 週の間)
"   build_cap     : 建設力倍率(duration 週の間)
"   treasury_weeks: 週間所得 × この値 を国庫に加算(即時、国の規模に自動対応)
"   workforce_pct : 無作為な自国州の労働力を ±この割合 変える(即時)
"   duration      : 継続週数(0 なら即時効果のみ)

let g:vimtoria_data_events = {}

let g:vimtoria_data_events.chance = 60

let g:vimtoria_data_events.order = [
      \ 'bumper_harvest', 'crop_failure', 'mine_accident', 'trade_windfall',
      \ 'corruption', 'innovation', 'strikes', 'building_boom',
      \ 'epidemic', 'immigration',
      \ ]

let g:vimtoria_data_events.events = {
      \ 'bumper_harvest': {
      \   'name': '豊作', 'desc': '天候に恵まれ、農場の産出 +30%(12週)',
      \   'effects': {'out': {'grain_farm': 1.3, 'cotton_farm': 1.3}, 'duration': 12}},
      \ 'crop_failure': {
      \   'name': '凶作', 'desc': '冷害により農場の産出 -30%(12週)',
      \   'effects': {'out': {'grain_farm': 0.7, 'cotton_farm': 0.7}, 'duration': 12}},
      \ 'mine_accident': {
      \   'name': '鉱山事故', 'desc': '大規模な落盤。鉱山の産出 -40%(8週)',
      \   'effects': {'out': {'coal_mine': 0.6, 'iron_mine': 0.6}, 'duration': 8}},
      \ 'trade_windfall': {
      \   'name': '交易の追い風', 'desc': '関税収入が舞い込んだ(+週間所得の75%)',
      \   'effects': {'treasury_weeks': 0.75, 'duration': 0}},
      \ 'corruption': {
      \   'name': '汚職発覚', 'desc': '国庫から資金が消えていた(-週間所得の40%)',
      \   'effects': {'treasury_weeks': -0.4, 'duration': 0}},
      \ 'innovation': {
      \   'name': '発明家の登場', 'desc': '研究力 +50%(26週)',
      \   'effects': {'research': 1.5, 'duration': 26}},
      \ 'strikes': {
      \   'name': '労働争議', 'desc': 'ストライキで全建物の産出 -10%(8週)',
      \   'effects': {'out_all': 0.9, 'duration': 8}},
      \ 'building_boom': {
      \   'name': '建設ブーム', 'desc': '建設力 +50%(12週)',
      \   'effects': {'build_cap': 1.5, 'duration': 12}},
      \ 'epidemic': {
      \   'name': '疫病', 'desc': '流行病により一州の労働力 -2%',
      \   'effects': {'workforce_pct': -0.02, 'duration': 0}},
      \ 'immigration': {
      \   'name': '移民の流入', 'desc': '新天地を求め、一州の労働力 +3%',
      \   'effects': {'workforce_pct': 0.03, 'duration': 0}},
      \ }
