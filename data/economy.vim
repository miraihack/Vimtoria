scriptencoding utf-8
" data/economy.vim - 経済データ定義(財・職業・需要・建物・定数)
"
" 単位の約束:
"   人口     : 千人(map.vim の pop は万人なので ×10 して使う)
"   建物     : 1 レベル = 雇用 10 千人。levels は実数(小国でも動くように)
"   財の量   : 抽象単位/週
"   価格     : £/単位
"
" バランスの目安(share は初期配置の労働力配分):
"   share 合計 ≈ 0.57。残りは自給農(小収入で生計、必需品の 50% だけ市場で
"   購う)で、M2 の建設に回せる労働プールでもある。
"   需給は稼働率 f = 0.9 でほぼ均衡するよう調整してある。

let g:vimtoria_data_economy = {}

let g:vimtoria_data_economy.const = {
      \ 'workforce_rate': 0.2,
      \ 'level_size': 10.0,
      \ 'wage_share': 0.7,
      \ 'tax_rate': 0.075,
      \ 'tax_min': 0.0,
      \ 'tax_max': 0.30,
      \ 'tax_step': 0.025,
      \ 'price_range': 0.75,
      \ 'hire_step': 0.02,
      \ 'min_f': 0.05,
      \ 'init_f': 0.8,
      \ 'subsist_income': 2.0,
      \ 'subsist_needs': 0.5,
      \ 'upkeep_per_k': 3.5,
      \ 'mil_init_div': 150.0,
      \ 'mil_cap_div': 50.0,
      \ 'mil_upkeep_money': 30.0,
      \ 'mil_recruit_cost': 1000.0,
      \ 'mil_recruit_batch': 5.0,
      \ 'navy_init_mult': 0.5,
      \ 'navy_cap_div': 150.0,
      \ 'navy_upkeep_money': 50.0,
      \ 'navy_recruit_cost': 2500.0,
      \ 'navy_recruit_batch': 2.0,
      \ 'navy_min_invade': 10.0,
      \ 'navy_invade_ratio': 0.4,
      \ 'mil_casualty': 0.015,
      \ 'mil_debt_disband': 0.02,
      \ 'build_capacity_base': 3.0,
      \ 'build_capacity_div': 800.0,
      \ 'build_points': 50.0,
      \ 'build_queue_max': 20,
      \ 'build_new_f': 0.5,
      \ 'credit_mult': 0.5,
      \ 'dm_min': 0.5,
      \ 'dm_max': 1.5,
      \ 'rail_coal_per_k': 0.01,
      \ 'migration_rate': 0.02,
      \ 'trade_rate': 0.25,
      \ 'trade_threshold': 0.05,
      \ 'trade_maxdiff': 0.6,
      \ 'tariff_rate': 0.08,
      \ 'trade_war_mult': 0.5,
      \ 'ai_build_reserve': 20000.0,
      \ 'ai_queue_max': 2,
      \ }

" 建設 1 ポイントあたりの資材消費(市場価格で政府が購入)
let g:vimtoria_data_economy.build_goods = {
      \ 'wood': 4.0, 'tools': 2.0, 'steel': 1.0,
      \ }

" 連隊 1 個あたりの週次物資需要(軍需 = 市場の需要シンク)
let g:vimtoria_data_economy.mil_goods = {
      \ 'grain': 0.4, 'clothes': 0.15, 'tools': 0.05,
      \ }

" 艦艇 1 隻あたりの週次物資需要(海軍需)
let g:vimtoria_data_economy.navy_goods = {
      \ 'wood': 0.5, 'coal': 0.3, 'steel': 0.2,
      \ }

let g:vimtoria_data_economy.goods_order = [
      \ 'grain', 'cotton', 'wood', 'coal', 'iron',
      \ 'steel', 'tools', 'clothes', 'furniture', 'services',
      \ ]

let g:vimtoria_data_economy.goods = {
      \ 'grain':     {'name': '穀物',     'name_en': 'Grain',     'base': 20.0},
      \ 'cotton':    {'name': '綿花',     'name_en': 'Cotton',    'base': 25.0},
      \ 'wood':      {'name': '木材',     'name_en': 'Wood',      'base': 20.0},
      \ 'coal':      {'name': '石炭',     'name_en': 'Coal',      'base': 30.0},
      \ 'iron':      {'name': '鉄',       'name_en': 'Iron',      'base': 40.0},
      \ 'steel':     {'name': '鋼鉄',     'name_en': 'Steel',     'base': 60.0},
      \ 'tools':     {'name': '工具',     'name_en': 'Tools',     'base': 45.0},
      \ 'clothes':   {'name': '衣類',     'name_en': 'Clothes',   'base': 40.0},
      \ 'furniture': {'name': '家具',     'name_en': 'Furniture', 'base': 45.0},
      \ 'services':  {'name': 'サービス', 'name_en': 'Services',  'base': 35.0},
      \ }

" owner=1 の職業は賃金でなく配当を受け取る
let g:vimtoria_data_economy.professions = {
      \ 'farmers':     {'name': '農民',   'name_en': 'Farmers',     'owner': 0},
      \ 'laborers':    {'name': '労働者', 'name_en': 'Laborers',    'owner': 0},
      \ 'machinists':  {'name': '機械工', 'name_en': 'Machinists',  'owner': 0},
      \ 'shopkeepers': {'name': '店主',   'name_en': 'Shopkeepers', 'owner': 0},
      \ 'capitalists': {'name': '資本家', 'name_en': 'Capitalists', 'owner': 1},
      \ 'aristocrats': {'name': '貴族',   'name_en': 'Aristocrats', 'owner': 1},
      \ }

" 週次需要(雇用 1 千人あたり)。owner は base に加えて追加分を消費する
let g:vimtoria_data_economy.needs_base = {
      \ 'grain': 2.0, 'clothes': 0.3, 'furniture': 0.05, 'services': 0.2,
      \ }
let g:vimtoria_data_economy.needs_owner = {
      \ 'clothes': 0.5, 'furniture': 0.5, 'services': 1.0,
      \ }

" out/in は 1 レベル・稼働率 100% あたりの週次量。
" jobs は 1 レベルあたりの雇用(千人)。share は初期配置の労働力配分。
let g:vimtoria_data_economy.buildings_order = [
      \ 'grain_farm', 'cotton_farm', 'logging_camp', 'coal_mine', 'iron_mine',
      \ 'tool_workshop', 'textile_mill', 'furniture_workshop', 'steel_mill',
      \ 'urban_center',
      \ ]

let g:vimtoria_data_economy.buildings = {
      \ 'grain_farm': {
      \   'name': '穀物農場', 'name_en': 'Grain Farm',
      \   'out': {'grain': 50.0}, 'in': {'tools': 1.0},
      \   'jobs': {'farmers': 9.0, 'aristocrats': 1.0}, 'share': 0.35},
      \ 'cotton_farm': {
      \   'name': '綿花農場', 'name_en': 'Cotton Farm',
      \   'out': {'cotton': 50.0}, 'in': {'tools': 1.0},
      \   'jobs': {'farmers': 9.0, 'aristocrats': 1.0}, 'share': 0.03},
      \ 'logging_camp': {
      \   'name': '伐採所', 'name_en': 'Logging Camp',
      \   'out': {'wood': 25.0}, 'in': {'tools': 1.0},
      \   'jobs': {'laborers': 9.0, 'capitalists': 1.0}, 'share': 0.025},
      \ 'coal_mine': {
      \   'name': '炭鉱', 'name_en': 'Coal Mine',
      \   'out': {'coal': 45.0}, 'in': {'tools': 2.0},
      \   'jobs': {'laborers': 9.0, 'aristocrats': 1.0}, 'share': 0.0025},
      \ 'iron_mine': {
      \   'name': '鉄山', 'name_en': 'Iron Mine',
      \   'out': {'iron': 40.0}, 'in': {'tools': 2.0},
      \   'jobs': {'laborers': 9.0, 'aristocrats': 1.0}, 'share': 0.006},
      \ 'tool_workshop': {
      \   'name': '工具工房', 'name_en': 'Tool Workshop',
      \   'out': {'tools': 35.0}, 'in': {'wood': 10.0, 'iron': 10.0},
      \   'jobs': {'machinists': 8.0, 'capitalists': 2.0}, 'share': 0.015},
      \ 'textile_mill': {
      \   'name': '織物工場', 'name_en': 'Textile Mill',
      \   'out': {'clothes': 45.0}, 'in': {'cotton': 25.0, 'tools': 1.0},
      \   'jobs': {'machinists': 8.0, 'capitalists': 2.0}, 'share': 0.06},
      \ 'furniture_workshop': {
      \   'name': '家具工房', 'name_en': 'Furniture Workshop',
      \   'out': {'furniture': 35.0}, 'in': {'wood': 15.0, 'steel': 5.0, 'tools': 1.0},
      \   'jobs': {'machinists': 8.0, 'capitalists': 2.0}, 'share': 0.025},
      \ 'steel_mill': {
      \   'name': '製鉄所', 'name_en': 'Steel Mill',
      \   'out': {'steel': 30.0}, 'in': {'iron': 20.0, 'coal': 20.0},
      \   'jobs': {'machinists': 8.0, 'capitalists': 2.0}, 'share': 0.004},
      \ 'urban_center': {
      \   'name': '商業地区', 'name_en': 'Urban Center',
      \   'out': {'services': 50.0}, 'in': {},
      \   'jobs': {'shopkeepers': 9.0, 'capitalists': 1.0}, 'share': 0.05},
      \ }
