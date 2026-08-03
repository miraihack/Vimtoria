scriptencoding utf-8
" data/politics.vim - 政治定義(利益集団・法律)
"
" 利益集団の勢力(clout)は支持基盤の職業の所得シェアで毎週決まる。
" 法律は3グループ。制定には約26週かかり、勢力加重の支持が高いほど速い。
" 支持が負のまま強行すると急進性が上がる。
" approval: 各利益集団のその法律への態度(-2〜+2)

let g:vimtoria_data_politics = {}

let g:vimtoria_data_politics.const = {
      \ 'enact_points': 26.0,
      \ 'rad_sol_scale': 1.2,
      \ 'rad_uprising_threshold': 60.0,
      \ 'rad_uprising_chance': 40,
      \ 'rad_uprising_relief': 25.0,
      \ 'rad_enact_complete': 4.0,
      \ 'rad_forced_enact': 0.3,
      \ }

let g:vimtoria_data_politics.ig_order = ['landowners', 'industrialists', 'labor']

let g:vimtoria_data_politics.igs = {
      \ 'landowners':     {'name': '地主',     'professions': ['aristocrats', 'farmers']},
      \ 'industrialists': {'name': '実業家',   'professions': ['capitalists', 'shopkeepers']},
      \ 'labor':          {'name': '労働運動', 'professions': ['laborers', 'machinists']},
      \ }

let g:vimtoria_data_politics.group_order = ['econ_policy', 'labor_law', 'taxation']

let g:vimtoria_data_politics.groups = {
      \ 'econ_policy': {'name': '経済政策'},
      \ 'labor_law':   {'name': '労働法'},
      \ 'taxation':    {'name': '税制'},
      \ }

let g:vimtoria_data_politics.law_order = [
      \ 'agrarianism', 'industrialism',
      \ 'laissez_faire', 'worker_protection',
      \ 'land_tax', 'income_tax',
      \ ]

let g:vimtoria_data_politics.laws = {
      \ 'agrarianism': {
      \   'group': 'econ_policy', 'name': '農本主義',
      \   'desc': '農場の産出 +10%、建設力 -5%',
      \   'effects': {'out': {'grain_farm': 1.1, 'cotton_farm': 1.1}, 'build_cap': 0.95},
      \   'approval': {'landowners': 2, 'industrialists': -1, 'labor': 0}},
      \ 'industrialism': {
      \   'group': 'econ_policy', 'name': '産業奨励',
      \   'desc': '工場の産出 +10%、建設力 +10%',
      \   'effects': {'out': {'tool_workshop': 1.1, 'textile_mill': 1.1,
      \               'furniture_workshop': 1.1, 'steel_mill': 1.1}, 'build_cap': 1.1},
      \   'approval': {'landowners': -2, 'industrialists': 2, 'labor': 0}},
      \ 'laissez_faire': {
      \   'group': 'labor_law', 'name': '自由放任',
      \   'desc': '賃金分配 65%(配当 35%)',
      \   'effects': {'wage_share': 0.65},
      \   'approval': {'landowners': 1, 'industrialists': 2, 'labor': -2}},
      \ 'worker_protection': {
      \   'group': 'labor_law', 'name': '労働保護',
      \   'desc': '賃金分配 75%(配当 25%)',
      \   'effects': {'wage_share': 0.75},
      \   'approval': {'landowners': -1, 'industrialists': -2, 'labor': 2}},
      \ 'land_tax': {
      \   'group': 'taxation', 'name': '地租',
      \   'desc': '税率上限 15%',
      \   'effects': {'tax_max': 0.15},
      \   'approval': {'landowners': 1, 'industrialists': 0, 'labor': 0}},
      \ 'income_tax': {
      \   'group': 'taxation', 'name': '所得税',
      \   'desc': '税率上限 30%',
      \   'effects': {'tax_max': 0.30},
      \   'approval': {'landowners': -1, 'industrialists': -1, 'labor': 0}},
      \ }

" 初期法律。既定は農業国セット、工業先進国は override
let g:vimtoria_data_politics.default_laws = {
      \ 'econ_policy': 'agrarianism',
      \ 'labor_law': 'laissez_faire',
      \ 'taxation': 'land_tax',
      \ }

let g:vimtoria_data_politics.country_laws = {
      \ 'GBR': {'econ_policy': 'industrialism', 'taxation': 'income_tax'},
      \ 'FRA': {'econ_policy': 'industrialism', 'taxation': 'income_tax'},
      \ 'NET': {'econ_policy': 'industrialism', 'taxation': 'income_tax'},
      \ 'PRU': {'econ_policy': 'industrialism'},
      \ 'USA': {'econ_policy': 'industrialism', 'taxation': 'income_tax'},
      \ 'SWE': {'econ_policy': 'industrialism'},
      \ }
