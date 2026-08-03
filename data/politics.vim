scriptencoding utf-8
" data/politics.vim - 政治定義(利益集団・法律・政体・社会運動)
"
" 利益集団の勢力(clout)は支持基盤の職業の所得シェアで毎週決まる。
" 法律は5グループ(経済政策・労働法・税制・政体・参政権)。制定には
" 約26週かかり、勢力加重の支持が高いほど速い。支持が負のまま強行すると
" 急進性が上がる。
" approval: 各利益集団のその法律への態度(-2〜+2)
" req_tech: この技術を研究するまで制定できない(政体・参政権の解禁)
" 効果キー(law_mods): out / out_all / build_cap / research / mil / trade /
"   tax_eff(乗算)、wage_share(最大値)、tax_max(最小値)、rad(加算)

let g:vimtoria_data_politics = {}

let g:vimtoria_data_politics.const = {
      \ 'enact_points': 26.0,
      \ 'rad_sol_scale': 1.2,
      \ 'rad_uprising_threshold': 60.0,
      \ 'rad_uprising_chance': 40,
      \ 'rad_uprising_relief': 25.0,
      \ 'rad_enact_complete': 4.0,
      \ 'rad_forced_enact': 0.3,
      \ 'mov_spawn_chance': 20,
      \ 'mov_base_grow': 0.3,
      \ 'mov_rad': 0.35,
      \ 'mov_support_boost': 2.0,
      \ 'mov_relief': 15.0,
      \ }

let g:vimtoria_data_politics.ig_order = ['landowners', 'industrialists', 'labor']

let g:vimtoria_data_politics.igs = {
      \ 'landowners':     {'name': '地主',     'name_en': 'Landowners',     'professions': ['aristocrats', 'farmers']},
      \ 'industrialists': {'name': '実業家',   'name_en': 'Industrialists', 'professions': ['capitalists', 'shopkeepers']},
      \ 'labor':          {'name': '労働運動', 'name_en': 'Labor Movement', 'professions': ['laborers', 'machinists']},
      \ }

let g:vimtoria_data_politics.group_order =
      \ ['government', 'suffrage', 'econ_policy', 'labor_law', 'taxation']

let g:vimtoria_data_politics.groups = {
      \ 'government':  {'name': '政体',     'name_en': 'Government'},
      \ 'suffrage':    {'name': '参政権',   'name_en': 'Suffrage'},
      \ 'econ_policy': {'name': '経済政策', 'name_en': 'Economic Policy'},
      \ 'labor_law':   {'name': '労働法',   'name_en': 'Labor Law'},
      \ 'taxation':    {'name': '税制',     'name_en': 'Taxation'},
      \ }

let g:vimtoria_data_politics.law_order = [
      \ 'agrarianism', 'industrialism',
      \ 'laissez_faire', 'worker_protection',
      \ 'land_tax', 'income_tax',
      \ 'despotism', 'absolute_monarchy', 'liberal_democracy',
      \ 'socialist_state', 'anarchist_commune',
      \ 'census_suffrage', 'universal_male_suffrage', 'universal_suffrage',
      \ ]

let g:vimtoria_data_politics.laws = {
      \ 'agrarianism': {
      \   'group': 'econ_policy', 'name': '農本主義', 'name_en': 'Agrarianism',
      \   'desc': '農場の産出 +10%、建設力 -5%',
      \   'desc_en': 'Farm output +10%, construction -5%',
      \   'effects': {'out': {'grain_farm': 1.1, 'cotton_farm': 1.1}, 'build_cap': 0.95},
      \   'approval': {'landowners': 2, 'industrialists': -1, 'labor': 0}},
      \ 'industrialism': {
      \   'group': 'econ_policy', 'name': '産業奨励', 'name_en': 'Industrialism',
      \   'desc': '工場の産出 +10%、建設力 +10%',
      \   'desc_en': 'Factory output +10%, construction +10%',
      \   'effects': {'out': {'tool_workshop': 1.1, 'textile_mill': 1.1,
      \               'furniture_workshop': 1.1, 'steel_mill': 1.1}, 'build_cap': 1.1},
      \   'approval': {'landowners': -2, 'industrialists': 2, 'labor': 0}},
      \ 'laissez_faire': {
      \   'group': 'labor_law', 'name': '自由放任', 'name_en': 'Laissez-Faire',
      \   'desc': '賃金分配 65%(配当 35%)',
      \   'desc_en': 'Wage share 65% (dividends 35%)',
      \   'effects': {'wage_share': 0.65},
      \   'approval': {'landowners': 1, 'industrialists': 2, 'labor': -2}},
      \ 'worker_protection': {
      \   'group': 'labor_law', 'name': '労働保護', 'name_en': 'Worker Protection',
      \   'desc': '賃金分配 75%(配当 25%)',
      \   'desc_en': 'Wage share 75% (dividends 25%)',
      \   'effects': {'wage_share': 0.75},
      \   'approval': {'landowners': -1, 'industrialists': -2, 'labor': 2}},
      \ 'land_tax': {
      \   'group': 'taxation', 'name': '地租', 'name_en': 'Land Tax',
      \   'desc': '税率上限 15%',
      \   'desc_en': 'Tax cap 15%',
      \   'effects': {'tax_max': 0.15},
      \   'approval': {'landowners': 1, 'industrialists': 0, 'labor': 0}},
      \ 'income_tax': {
      \   'group': 'taxation', 'name': '所得税', 'name_en': 'Income Tax',
      \   'desc': '税率上限 30%',
      \   'desc_en': 'Tax cap 30%',
      \   'effects': {'tax_max': 0.30},
      \   'approval': {'landowners': -1, 'industrialists': -1, 'labor': 0}},
      \ 'despotism': {
      \   'group': 'government', 'name': '専制政治', 'name_en': 'Autocracy',
      \   'desc': '軍事力 +5%、研究力 -10%、交易 -10%、急進性 +0.10/週',
      \   'desc_en': 'Military +5%, research -10%, trade -10%, radicalism +0.10/wk',
      \   'effects': {'mil': 1.05, 'research': 0.9, 'trade': 0.9, 'rad': 0.1},
      \   'approval': {'landowners': 2, 'industrialists': -1, 'labor': -2}},
      \ 'absolute_monarchy': {
      \   'group': 'government', 'name': '絶対王政', 'name_en': 'Absolute Monarchy',
      \   'desc': '軍事力 +10%、建設力 +5%、研究力 -5%、急進性 +0.05/週',
      \   'desc_en': 'Military +10%, construction +5%, research -5%, radicalism +0.05/wk',
      \   'effects': {'mil': 1.1, 'build_cap': 1.05, 'research': 0.95, 'rad': 0.05},
      \   'approval': {'landowners': 2, 'industrialists': 0, 'labor': -2}},
      \ 'liberal_democracy': {
      \   'group': 'government', 'name': '自由主義', 'name_en': 'Liberal Democracy',
      \   'desc': '研究力 +15%、交易 +25%、建設力 +5%、軍事力 -5%、急進性 -0.20/週',
      \   'desc_en': 'Research +15%, trade +25%, construction +5%, military -5%, radicalism -0.20/wk',
      \   'effects': {'research': 1.15, 'trade': 1.25, 'build_cap': 1.05,
      \               'mil': 0.95, 'rad': -0.2},
      \   'req_tech': 'liberal_thought',
      \   'approval': {'landowners': -2, 'industrialists': 2, 'labor': 1}},
      \ 'socialist_state': {
      \   'group': 'government', 'name': '社会主義', 'name_en': 'Socialist State',
      \   'desc': '賃金分配 85%、建設力 +10%、全産出 -8%、交易 -15%、急進性 -0.40/週',
      \   'desc_en': 'Wage share 85%, construction +10%, all output -8%, trade -15%, radicalism -0.40/wk',
      \   'effects': {'wage_share': 0.85, 'build_cap': 1.1, 'out_all': 0.92,
      \               'trade': 0.85, 'rad': -0.4},
      \   'req_tech': 'scientific_socialism',
      \   'approval': {'landowners': -2, 'industrialists': -2, 'labor': 2}},
      \ 'anarchist_commune': {
      \   'group': 'government', 'name': '無政府主義', 'name_en': 'Anarchist Commune',
      \   'desc': '全産出 +5%、急進性 -0.80/週、徴税効率 -50%、軍事力 -40%、建設力 -10%、交易 -20%',
      \   'desc_en': 'All output +5%, radicalism -0.80/wk, tax efficiency -50%, military -40%, construction -10%, trade -20%',
      \   'effects': {'out_all': 1.05, 'rad': -0.8, 'tax_eff': 0.5,
      \               'mil': 0.6, 'build_cap': 0.9, 'trade': 0.8},
      \   'req_tech': 'anarchist_thought',
      \   'approval': {'landowners': -2, 'industrialists': -1, 'labor': 1}},
      \ 'census_suffrage': {
      \   'group': 'suffrage', 'name': '制限選挙', 'name_en': 'Census Suffrage',
      \   'desc': '財産による制限選挙。特別な効果はない',
      \   'desc_en': 'Property-based franchise. No special effects',
      \   'effects': {},
      \   'approval': {'landowners': 1, 'industrialists': 1, 'labor': -1}},
      \ 'universal_male_suffrage': {
      \   'group': 'suffrage', 'name': '男子普通選挙', 'name_en': 'Universal Male Suffrage',
      \   'desc': '急進性 -0.15/週、研究力 +5%',
      \   'desc_en': 'Radicalism -0.15/wk, research +5%',
      \   'effects': {'rad': -0.15, 'research': 1.05},
      \   'req_tech': 'chartism',
      \   'approval': {'landowners': -2, 'industrialists': 0, 'labor': 2}},
      \ 'universal_suffrage': {
      \   'group': 'suffrage', 'name': '男女普通選挙', 'name_en': 'Universal Suffrage',
      \   'desc': '急進性 -0.30/週、研究力 +10%',
      \   'desc_en': 'Radicalism -0.30/wk, research +10%',
      \   'effects': {'rad': -0.3, 'research': 1.1},
      \   'req_tech': 'feminism',
      \   'approval': {'landowners': -2, 'industrialists': -1, 'labor': 2}},
      \ }

" 社会運動: 対応する思想(req_tech)を研究済みで、要求する法律が未施行の
" 国に発生しうる。支持が育つほど急進性を押し上げ、要求法の制定を後押しする。
" grow: industrial=実業家の勢力で成長 / labor=労働運動の勢力と低SoLで成長 /
"       steady=時間とともに着実に成長
let g:vimtoria_data_politics.movement_order = ['liberal', 'socialist', 'suffrage']
let g:vimtoria_data_politics.movements = {
      \ 'liberal': {
      \   'name': '自由主義運動', 'name_en': 'Liberal Movement',
      \   'target': 'liberal_democracy', 'req_tech': 'liberal_thought',
      \   'grow': 'industrial'},
      \ 'socialist': {
      \   'name': '社会主義運動', 'name_en': 'Socialist Movement',
      \   'target': 'socialist_state', 'req_tech': 'scientific_socialism',
      \   'grow': 'labor'},
      \ 'suffrage': {
      \   'name': '婦人参政権運動', 'name_en': 'Women''s Suffrage Movement',
      \   'target': 'universal_suffrage', 'req_tech': 'feminism',
      \   'grow': 'steady'},
      \ }

" 初期法律。既定は農業国セット、先進国・特定国は override
let g:vimtoria_data_politics.default_laws = {
      \ 'government': 'absolute_monarchy',
      \ 'suffrage': 'census_suffrage',
      \ 'econ_policy': 'agrarianism',
      \ 'labor_law': 'laissez_faire',
      \ 'taxation': 'land_tax',
      \ }

let g:vimtoria_data_politics.country_laws = {
      \ 'GBR': {'econ_policy': 'industrialism', 'taxation': 'income_tax',
      \         'government': 'liberal_democracy'},
      \ 'FRA': {'econ_policy': 'industrialism', 'taxation': 'income_tax',
      \         'government': 'liberal_democracy'},
      \ 'USA': {'econ_policy': 'industrialism', 'taxation': 'income_tax',
      \         'government': 'liberal_democracy',
      \         'suffrage': 'universal_male_suffrage'},
      \ 'TEX': {'government': 'liberal_democracy'},
      \ 'NET': {'econ_policy': 'industrialism', 'taxation': 'income_tax'},
      \ 'PRU': {'econ_policy': 'industrialism'},
      \ 'SWE': {'econ_policy': 'industrialism'},
      \ 'JAP': {'government': 'despotism'},
      \ 'RUS': {'government': 'despotism'},
      \ 'QIN': {'government': 'despotism'},
      \ 'OTT': {'government': 'despotism'},
      \ 'PER': {'government': 'despotism'},
      \ 'EGY': {'government': 'despotism'},
      \ 'SIA': {'government': 'despotism'},
      \ 'VIE': {'government': 'despotism'},
      \ 'BUR': {'government': 'despotism'},
      \ 'MOR': {'government': 'despotism'},
      \ 'ETH': {'government': 'despotism'},
      \ 'ZUL': {'government': 'despotism'},
      \ 'SOK': {'government': 'despotism'},
      \ 'MAD': {'government': 'despotism'},
      \ 'HAW': {'government': 'despotism'},
      \ 'MEX': {'government': 'despotism'},
      \ 'ARG': {'government': 'despotism'},
      \ 'PBC': {'government': 'despotism'},
      \ 'NGR': {'government': 'despotism'},
      \ 'VEN': {'government': 'despotism'},
      \ 'ECU': {'government': 'despotism'},
      \ 'CHI': {'government': 'despotism'},
      \ }
