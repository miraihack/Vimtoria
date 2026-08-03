scriptencoding utf-8
" data/tech.vim - 技術ツリー定義
"
" cost の単位は研究ポイント(rp)。研究力は const と労働力から決まる。
" effects:
"   out      : {建物ID: 産出倍率}(投入は増えない = 効率化)
"   build_cap: 建設力倍率
"   research : 研究力倍率
"   interest : 国債の年利をこの値に引き下げ
"   rail     : 1 なら鉄道網が石炭を毎週消費する(需要シンク)

let g:vimtoria_data_tech = {}

" 研究力 = rp_base + sqrt(労働力千人) / rp_div(大国の暴走を防ぐ平方根スケール)
let g:vimtoria_data_tech.const = {
      \ 'rp_base': 2.0,
      \ 'rp_div': 25.0,
      \ }

let g:vimtoria_data_tech.order = [
      \ 'crop_rotation', 'steam_engine', 'machine_tools', 'power_looms',
      \ 'bessemer_process', 'mechanized_farming', 'railways', 'joint_stock',
      \ 'public_schools', 'central_banking',
      \ ]

let g:vimtoria_data_tech.techs = {
      \ 'crop_rotation': {
      \   'name': '輪作', 'name_en': 'Crop Rotation', 'cost': 100.0, 'req': [],
      \   'desc': '農場(穀物・綿花)の産出 +20%',
      \   'desc_en': 'Farm output (grain & cotton) +20%',
      \   'effects': {'out': {'grain_farm': 1.2, 'cotton_farm': 1.2}}},
      \ 'steam_engine': {
      \   'name': '蒸気機関', 'name_en': 'Steam Engine', 'cost': 150.0, 'req': [],
      \   'desc': '鉱山(石炭・鉄)の産出 +25%',
      \   'desc_en': 'Mine output (coal & iron) +25%',
      \   'effects': {'out': {'coal_mine': 1.25, 'iron_mine': 1.25}}},
      \ 'machine_tools': {
      \   'name': '工作機械', 'name_en': 'Machine Tools', 'cost': 200.0, 'req': ['steam_engine'],
      \   'desc': '工具工房の産出 +30%',
      \   'desc_en': 'Tool workshop output +30%',
      \   'effects': {'out': {'tool_workshop': 1.3}}},
      \ 'power_looms': {
      \   'name': '力織機', 'name_en': 'Power Looms', 'cost': 250.0, 'req': ['steam_engine'],
      \   'desc': '織物工場の産出 +40%',
      \   'desc_en': 'Textile mill output +40%',
      \   'effects': {'out': {'textile_mill': 1.4}}},
      \ 'bessemer_process': {
      \   'name': '転炉製鋼', 'name_en': 'Bessemer Process', 'cost': 300.0, 'req': ['steam_engine'],
      \   'desc': '製鉄所の産出 +50%',
      \   'desc_en': 'Steel mill output +50%',
      \   'effects': {'out': {'steel_mill': 1.5}}},
      \ 'mechanized_farming': {
      \   'name': '農業機械化', 'name_en': 'Mechanized Farming', 'cost': 300.0, 'req': ['crop_rotation', 'machine_tools'],
      \   'desc': '農場の産出をさらに +30%',
      \   'desc_en': 'Farm output a further +30%',
      \   'effects': {'out': {'grain_farm': 1.3, 'cotton_farm': 1.3}}},
      \ 'railways': {
      \   'name': '鉄道', 'name_en': 'Railways', 'cost': 350.0, 'req': ['steam_engine'],
      \   'desc': '建設力 +50%。鉄道網が石炭を毎週消費する',
      \   'desc_en': 'Construction +50%; the rail network consumes coal weekly',
      \   'effects': {'build_cap': 1.5, 'rail': 1}},
      \ 'joint_stock': {
      \   'name': '株式会社', 'name_en': 'Joint-Stock Companies', 'cost': 250.0, 'req': [],
      \   'desc': '建設力 +25%',
      \   'desc_en': 'Construction +25%',
      \   'effects': {'build_cap': 1.25}},
      \ 'public_schools': {
      \   'name': '公教育', 'name_en': 'Public Schools', 'cost': 200.0, 'req': [],
      \   'desc': '研究力 +25%',
      \   'desc_en': 'Research +25%',
      \   'effects': {'research': 1.25}},
      \ 'central_banking': {
      \   'name': '中央銀行', 'name_en': 'Central Banking', 'cost': 300.0, 'req': ['joint_stock'],
      \   'desc': '国債の年利 5% → 3%',
      \   'desc_en': 'National debt interest 5% → 3%',
      \   'effects': {'interest': 0.03}},
      \ }
