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
      \   'name': '豊作', 'name_en': 'Bumper Harvest',
      \   'desc': '天候に恵まれ、農場の産出 +30%(12週)',
      \   'desc_en': 'Fine weather: farm output +30% (12 wk)',
      \   'effects': {'out': {'grain_farm': 1.3, 'cotton_farm': 1.3}, 'duration': 12}},
      \ 'crop_failure': {
      \   'name': '凶作', 'name_en': 'Crop Failure',
      \   'desc': '冷害により農場の産出 -30%(12週)',
      \   'desc_en': 'A cold snap: farm output -30% (12 wk)',
      \   'effects': {'out': {'grain_farm': 0.7, 'cotton_farm': 0.7}, 'duration': 12}},
      \ 'mine_accident': {
      \   'name': '鉱山事故', 'name_en': 'Mine Accident',
      \   'desc': '大規模な落盤。鉱山の産出 -40%(8週)',
      \   'desc_en': 'A major cave-in: mine output -40% (8 wk)',
      \   'effects': {'out': {'coal_mine': 0.6, 'iron_mine': 0.6}, 'duration': 8}},
      \ 'trade_windfall': {
      \   'name': '交易の追い風', 'name_en': 'Trade Windfall',
      \   'desc': '関税収入が舞い込んだ(+週間所得の75%)',
      \   'desc_en': 'Tariff revenue rolls in (+75% of weekly income)',
      \   'effects': {'treasury_weeks': 0.75, 'duration': 0}},
      \ 'corruption': {
      \   'name': '汚職発覚', 'name_en': 'Corruption Scandal',
      \   'desc': '国庫から資金が消えていた(-週間所得の40%)',
      \   'desc_en': 'Funds have gone missing (-40% of weekly income)',
      \   'effects': {'treasury_weeks': -0.4, 'duration': 0}},
      \ 'innovation': {
      \   'name': '発明家の登場', 'name_en': 'Brilliant Inventor',
      \   'desc': '研究力 +50%(26週)',
      \   'desc_en': 'Research +50% (26 wk)',
      \   'effects': {'research': 1.5, 'duration': 26}},
      \ 'strikes': {
      \   'name': '労働争議', 'name_en': 'Strikes',
      \   'desc': 'ストライキで全建物の産出 -10%(8週)',
      \   'desc_en': 'Walkouts: all output -10% (8 wk)',
      \   'effects': {'out_all': 0.9, 'duration': 8}},
      \ 'building_boom': {
      \   'name': '建設ブーム', 'name_en': 'Building Boom',
      \   'desc': '建設力 +50%(12週)',
      \   'desc_en': 'Construction +50% (12 wk)',
      \   'effects': {'build_cap': 1.5, 'duration': 12}},
      \ 'epidemic': {
      \   'name': '疫病', 'name_en': 'Epidemic',
      \   'desc': '流行病により一州の労働力 -2%',
      \   'desc_en': 'Disease strikes: one state loses 2% of its workforce',
      \   'effects': {'workforce_pct': -0.02, 'duration': 0}},
      \ 'immigration': {
      \   'name': '移民の流入', 'name_en': 'Immigration Wave',
      \   'desc': '新天地を求め、一州の労働力 +3%',
      \   'desc_en': 'Newcomers arrive: one state gains 3% workforce',
      \   'effects': {'workforce_pct': 0.03, 'duration': 0}},
      \ 'uprising': {
      \   'name': '反乱', 'name_en': 'Uprising',
      \   'desc': '急進派の蜂起で全建物の産出 -20%(12週)',
      \   'desc_en': 'Radicals revolt: all output -20% (12 wk)',
      \   'effects': {'out_all': 0.8, 'duration': 12}},
      \ }
" 注: uprising は order(ランダム抽選プール)に含まれず、
"     急進性が高いときに政治システムから直接発火する
