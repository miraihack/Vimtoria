scriptencoding utf-8
" data/diplomacy.vim - 外交・軍事定義
"
" 関係値は -100〜+100。正は毎週 0.1、負は 0.05 ずつ 0 へ漂う
" (歴史的な確執はゆっくりとしか癒えない)。

let g:vimtoria_data_diplomacy = {}

let g:vimtoria_data_diplomacy.const = {
      \ 'improve_cost': 10000.0,
      \ 'improve_gain': 15.0,
      \ 'improve_cd_weeks': 26,
      \ 'ally_threshold': 60.0,
      \ 'drift_pos': 0.1,
      \ 'drift_neg': 0.05,
      \ 'ai_war_chance': 5,
      \ 'ai_war_relation': -40.0,
      \ 'ai_war_advantage': 1.6,
      \ 'ai_ally_chance': 10,
      \ 'ai_giveup_score': -40.0,
      \ 'ai_giveup_chance': 50,
      \ }

" 1836年時点の歴史的な関係(残りは 0 から)
let g:vimtoria_data_diplomacy.presets = [
      \ ['GBR', 'FRA', -20.0],
      \ ['GBR', 'RUS', -15.0],
      \ ['GBR', 'USA', -10.0],
      \ ['FRA', 'PRU', -20.0],
      \ ['AUS', 'PRU', -15.0],
      \ ['RUS', 'OTT', -40.0],
      \ ['EGY', 'OTT', -35.0],
      \ ['GRE', 'OTT', -30.0],
      \ ['MEX', 'TEX', -60.0],
      \ ['MEX', 'USA', -20.0],
      \ ['JAP', 'QIN', -10.0],
      \ ['SPA', 'POR', -10.0],
      \ ['ARG', 'BRA', -15.0],
      \ ['CHI', 'PBC', -25.0],
      \ ['PER', 'RUS', -15.0],
      \ ['ZUL', 'GBR', -20.0],
      \ ]
