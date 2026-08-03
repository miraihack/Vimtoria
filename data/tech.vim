scriptencoding utf-8
" data/tech.vim - 技術ツリー定義(1836〜1945年の技術・思想・経済政策、206件)
"
" s:def(id, 年代, 分野, 日本語名, 英語名, cost, 前提[], 効果 [, 対象国[]])
" の 1 行 = 1 技術で定義する。desc / desc_en は効果辞書から
" ローダ(autoload/vimtoria/data.vim)が自動生成する。
"
" 効果キー(vimtoria#tech#recompute_mods が集計):
"   out {建物ID: 倍率}  産出倍率(乗算)
"   out_all             全建物の産出倍率(乗算)
"   build_cap           建設力倍率(乗算)
"   research            研究力倍率(乗算)
"   trade               交易量倍率(乗算)
"   mil                 軍事力倍率(乗算)
"   mil_cap             連隊上限倍率(乗算)
"   interest            国債年利をこの値へ(最小値を採用)
"   tariff              関税収入倍率(乗算)
"   tax_eff             徴税効率倍率(乗算)
"   upkeep              政府維持費倍率(乗算)
"   rad                 急進性の週次増減(加算。負なら社会が安定)
"   rail                1 なら鉄道網が石炭を毎週消費
"
" 対象国リスト付きの技術は「固有技術」で、その国だけが研究できる。
" 政体・法律の解禁は data/politics.vim 側の req_tech がこのファイルの
" 技術 ID を参照する(desc への表記はローダが逆引きして付ける)。

let g:vimtoria_data_tech = {}

" 研究力 = rp_base + sqrt(労働力千人) / rp_div(大国の暴走を防ぐ平方根スケール)
let g:vimtoria_data_tech.const = {
      \ 'rp_base': 2.0,
      \ 'rp_div': 25.0,
      \ }

let g:vimtoria_data_tech.branch_order =
      \ ['agri', 'ind', 'infra', 'war', 'fin', 'soc', 'idea', 'nat']
let g:vimtoria_data_tech.branches = {
      \ 'agri':  {'name': '農業',         'name_en': 'Agriculture'},
      \ 'ind':   {'name': '工業',         'name_en': 'Industry'},
      \ 'infra': {'name': '交通・通信',   'name_en': 'Transport & Communication'},
      \ 'war':   {'name': '軍事',         'name_en': 'Military'},
      \ 'fin':   {'name': '経済・金融',   'name_en': 'Economy & Finance'},
      \ 'soc':   {'name': '社会・学術',   'name_en': 'Society & Science'},
      \ 'idea':  {'name': '政治思想',     'name_en': 'Political Thought'},
      \ 'nat':   {'name': '固有',         'name_en': 'National'},
      \ }

let s:order = []
let s:techs = {}
function! s:def(id, era, branch, name, name_en, cost, req, effects, ...) abort
  let l:t = {'era': a:era, 'branch': a:branch,
        \ 'name': a:name, 'name_en': a:name_en,
        \ 'cost': a:cost * 1.0, 'req': a:req, 'effects': a:effects}
  if a:0 > 0
    let l:t.country = a:1
  endif
  let s:techs[a:id] = l:t
  call add(s:order, a:id)
endfunction

" ================= 農業 (20) =================
call s:def('crop_rotation',       1836, 'agri', '輪作',                 'Crop Rotation',            100, [], {'out': {'grain_farm': 1.2, 'cotton_farm': 1.2}})
call s:def('seed_drill',          1836, 'agri', '条播機',               'Seed Drill',               150, [], {'out': {'grain_farm': 1.1}})
call s:def('cotton_gin_improved', 1836, 'agri', '綿繰り機の改良',       'Improved Cotton Gin',      200, [], {'out': {'cotton_farm': 1.25}})
call s:def('plantation_economy',  1836, 'agri', 'プランテーション経営', 'Plantation Economy',       250, [], {'out': {'cotton_farm': 1.15}, 'trade': 1.05})
call s:def('selective_breeding',  1850, 'agri', '品種改良',             'Selective Breeding',       400, ['crop_rotation'], {'out': {'grain_farm': 1.15, 'cotton_farm': 1.1}})
call s:def('land_drainage',       1850, 'agri', '暗渠排水',             'Land Drainage',            400, [], {'out': {'grain_farm': 1.1, 'cotton_farm': 1.05}})
call s:def('guano_fertilizer',    1850, 'agri', 'グアノ肥料',           'Guano Fertilizer',         450, [], {'out': {'grain_farm': 1.2}})
call s:def('canned_food',         1850, 'agri', '缶詰',                 'Canned Food',              500, [], {'out': {'grain_farm': 1.05}, 'mil': 1.05})
call s:def('mechanized_farming',  1850, 'agri', '農業機械化',           'Mechanized Farming',       300, ['crop_rotation', 'machine_tools'], {'out': {'grain_farm': 1.3, 'cotton_farm': 1.3}})
call s:def('barbed_wire',         1870, 'agri', '有刺鉄線',             'Barbed Wire',              800, [], {'out': {'grain_farm': 1.1}})
call s:def('grain_silos',         1870, 'agri', '穀物サイロ',           'Grain Silos',              800, [], {'out': {'grain_farm': 1.1}})
call s:def('reaper_machine',      1870, 'agri', '自動刈取機',           'Mechanical Reaper',        900, ['mechanized_farming'], {'out': {'grain_farm': 1.25}})
call s:def('agronomy_institutes', 1870, 'agri', '農学研究所',           'Agronomy Institutes',     1000, ['universities'], {'out': {'grain_farm': 1.1, 'cotton_farm': 1.1}, 'research': 1.05})
call s:def('refrigerated_transport', 1890, 'agri', '冷凍輸送',          'Refrigerated Transport',  1800, ['steamships'], {'out': {'grain_farm': 1.1}, 'trade': 1.15})
call s:def('mendelian_genetics',  1890, 'agri', 'メンデル遺伝学',       'Mendelian Genetics',      1900, ['evolution_theory'], {'out': {'grain_farm': 1.1}, 'research': 1.05})
call s:def('chemical_fertilizer', 1890, 'agri', '化学肥料',             'Chemical Fertilizer',     2000, ['organic_chemistry'], {'out': {'grain_farm': 1.3}})
call s:def('tractor',             1910, 'agri', 'トラクター',           'Tractor',                 3000, ['internal_combustion'], {'out': {'grain_farm': 1.3, 'cotton_farm': 1.2}})
call s:def('haber_process',       1910, 'agri', 'ハーバー・ボッシュ法', 'Haber Process',           3500, ['chemical_fertilizer'], {'out': {'grain_farm': 1.4}})
call s:def('crop_dusting',        1930, 'agri', '農薬の空中散布',       'Crop Dusting',            4500, ['aviation'], {'out': {'grain_farm': 1.15}})
call s:def('combine_harvester',   1930, 'agri', 'コンバイン',           'Combine Harvester',       5000, ['tractor'], {'out': {'grain_farm': 1.35}})

" ================= 工業 (33) =================
call s:def('steam_engine',        1836, 'ind', '蒸気機関',             'Steam Engine',             150, [], {'out': {'coal_mine': 1.25, 'iron_mine': 1.25}})
call s:def('mine_safety_lamp',    1836, 'ind', '安全灯',               'Safety Lamp',              150, [], {'out': {'coal_mine': 1.1}})
call s:def('jacquard_loom',       1836, 'ind', 'ジャカード織機',       'Jacquard Loom',            200, [], {'out': {'textile_mill': 1.15}})
call s:def('coke_smelting',       1836, 'ind', 'コークス製鉄',         'Coke Smelting',            200, [], {'out': {'steel_mill': 1.2}})
call s:def('crucible_steel',      1836, 'ind', 'るつぼ鋼',             'Crucible Steel',           220, [], {'out': {'tool_workshop': 1.15}})
call s:def('puddling_process',    1836, 'ind', 'パドル法',             'Puddling Process',         250, [], {'out': {'steel_mill': 1.15}})
call s:def('gas_lighting',        1836, 'ind', 'ガス灯',               'Gas Lighting',             250, [], {'out': {'urban_center': 1.1}, 'out_all': 1.01})
call s:def('machine_tools',       1836, 'ind', '工作機械',             'Machine Tools',            200, ['steam_engine'], {'out': {'tool_workshop': 1.3}})
call s:def('power_looms',         1836, 'ind', '力織機',               'Power Looms',              250, ['steam_engine'], {'out': {'textile_mill': 1.4}})
call s:def('vulcanized_rubber',   1850, 'ind', '加硫ゴム',             'Vulcanized Rubber',        400, [], {'out_all': 1.02})
call s:def('sewing_machine',      1850, 'ind', 'ミシン',               'Sewing Machine',           450, ['machine_tools'], {'out': {'textile_mill': 1.2}})
call s:def('steam_hammer',        1850, 'ind', '蒸気ハンマー',         'Steam Hammer',             450, ['steam_engine'], {'out': {'steel_mill': 1.1, 'tool_workshop': 1.1}})
call s:def('interchangeable_parts', 1850, 'ind', '互換性部品',         'Interchangeable Parts',    500, ['machine_tools'], {'out': {'tool_workshop': 1.2}, 'mil': 1.05})
call s:def('deep_shaft_mining',   1850, 'ind', '深部採鉱',             'Deep Shaft Mining',        500, ['steam_engine'], {'out': {'coal_mine': 1.2, 'iron_mine': 1.15}})
call s:def('bessemer_process',    1850, 'ind', '転炉製鋼',             'Bessemer Process',         300, ['steam_engine'], {'out': {'steel_mill': 1.5}})
call s:def('machine_woodworking', 1870, 'ind', '木工機械',             'Machine Woodworking',      850, ['machine_tools'], {'out': {'logging_camp': 1.2, 'furniture_workshop': 1.2}})
call s:def('machine_shop_practice', 1870, 'ind', '機械工場の実務',     'Machine Shop Practice',    900, ['machine_tools'], {'out': {'tool_workshop': 1.25}})
call s:def('dynamite',            1870, 'ind', 'ダイナマイト',         'Dynamite',                 900, [], {'out': {'coal_mine': 1.25, 'iron_mine': 1.25}, 'build_cap': 1.05})
call s:def('synthetic_dye',       1870, 'ind', '合成染料',             'Synthetic Dyes',          1000, ['organic_chemistry'], {'out': {'textile_mill': 1.15}})
call s:def('pneumatic_drill',     1870, 'ind', '削岩機',               'Pneumatic Drill',         1000, [], {'out': {'coal_mine': 1.2, 'iron_mine': 1.2}})
call s:def('oil_drilling',        1870, 'ind', '石油採掘',             'Oil Drilling',            1100, [], {'trade': 1.05, 'mil': 1.05})
call s:def('open_hearth',         1870, 'ind', '平炉法',               'Open Hearth Process',     1200, ['bessemer_process'], {'out': {'steel_mill': 1.3}})
call s:def('electric_lighting',   1890, 'ind', '電灯',                 'Electric Lighting',       1800, ['electricity'], {'out_all': 1.03})
call s:def('electric_motor',      1890, 'ind', '電動機',               'Electric Motor',          2000, ['electricity'], {'out_all': 1.04})
call s:def('oil_refining',        1890, 'ind', '石油精製',             'Oil Refining',            2000, ['oil_drilling'], {'out_all': 1.03})
call s:def('aluminum_smelting',   1890, 'ind', 'アルミ精錬',           'Aluminum Smelting',       2200, ['electricity'], {'out_all': 1.02, 'mil': 1.05})
call s:def('scientific_management', 1910, 'ind', '科学的管理法',       'Scientific Management',   2800, [], {'out_all': 1.04})
call s:def('bakelite',            1910, 'ind', 'ベークライト',         'Bakelite',                2800, ['organic_chemistry'], {'out': {'furniture_workshop': 1.2}, 'out_all': 1.02})
call s:def('stainless_steel',     1910, 'ind', 'ステンレス鋼',         'Stainless Steel',         3000, ['open_hearth'], {'out': {'tool_workshop': 1.2, 'steel_mill': 1.1}})
call s:def('electric_arc_furnace', 1910, 'ind', '電気炉',              'Electric Arc Furnace',    3200, ['electricity', 'open_hearth'], {'out': {'steel_mill': 1.3}})
call s:def('assembly_line',       1910, 'ind', '流れ作業方式',         'Assembly Line',           3200, ['electric_motor'], {'out_all': 1.06})
call s:def('synthetic_rubber',    1930, 'ind', '合成ゴム',             'Synthetic Rubber',        4500, ['oil_refining'], {'out_all': 1.03, 'mil': 1.05})
call s:def('mass_production',     1930, 'ind', '大量生産方式',         'Mass Production',         5000, ['assembly_line'], {'out_all': 1.08})

" ================= 交通・通信 (28) =================
call s:def('macadam_roads',       1836, 'infra', '舗装道路',           'Macadam Roads',            150, [], {'build_cap': 1.05, 'trade': 1.05})
call s:def('lighthouse_network',  1836, 'infra', '灯台網',             'Lighthouse Network',       180, [], {'trade': 1.08})
call s:def('clipper_ships',       1836, 'infra', '快速帆船',           'Clipper Ships',            200, [], {'trade': 1.1})
call s:def('postal_reform',       1836, 'infra', '近代郵便制度',       'Postal Reform',            200, [], {'research': 1.05, 'trade': 1.05})
call s:def('canal_building',      1836, 'infra', '運河網',             'Canal Building',           250, [], {'trade': 1.1, 'build_cap': 1.05})
call s:def('telegraph',           1850, 'infra', '電信',               'Telegraph',                450, [], {'research': 1.1, 'trade': 1.1})
call s:def('civil_engineering',   1850, 'infra', '土木工学',           'Civil Engineering',        500, [], {'build_cap': 1.1})
call s:def('steamships',          1850, 'infra', '蒸気船',             'Steamships',               500, ['steam_engine'], {'trade': 1.2})
call s:def('railways',            1850, 'infra', '鉄道',               'Railways',                 350, ['steam_engine'], {'build_cap': 1.5, 'rail': 1})
call s:def('observation_network', 1850, 'infra', '気象観測網',         'Weather Observation',      420, ['telegraph'], {'trade': 1.05, 'out': {'grain_farm': 1.05}})
call s:def('compound_engine',     1870, 'infra', '複式蒸気機関',       'Compound Engine',          900, ['steamships'], {'trade': 1.1})
call s:def('transatlantic_cable', 1870, 'infra', '大洋横断ケーブル',   'Transoceanic Cables',     1000, ['telegraph'], {'trade': 1.15, 'research': 1.05})
call s:def('steel_hulls',         1870, 'infra', '鋼鉄船体',           'Steel Hulls',             1100, ['bessemer_process'], {'trade': 1.15, 'mil': 1.05})
call s:def('suez_canal',          1870, 'infra', 'スエズ運河',         'Suez Canal',              1200, ['civil_engineering'], {'trade': 1.2})
call s:def('transcontinental_rail', 1870, 'infra', '大陸横断鉄道',     'Transcontinental Railroads', 1300, ['railways'], {'build_cap': 1.1, 'trade': 1.15})
call s:def('streetcars',          1890, 'infra', '路面電車',           'Streetcars',              1600, ['electricity'], {'out': {'urban_center': 1.15}})
call s:def('port_cranes',         1890, 'infra', '港湾クレーン',       'Port Cranes',             1700, ['steel_hulls'], {'trade': 1.15})
call s:def('telephone',           1890, 'infra', '電話',               'Telephone',               1800, ['telegraph'], {'research': 1.1, 'out_all': 1.02})
call s:def('subway',              1890, 'infra', '地下鉄',             'Subways',                 1900, ['electricity'], {'out': {'urban_center': 1.2}})
call s:def('reinforced_concrete', 1890, 'infra', '鉄筋コンクリート',   'Reinforced Concrete',     1900, ['civil_engineering'], {'build_cap': 1.15})
call s:def('internal_combustion', 1890, 'infra', '内燃機関',           'Internal Combustion Engine', 2200, ['oil_refining'], {'research': 1.05})
call s:def('radio',               1910, 'infra', '無線通信',           'Radio',                   2800, ['telephone'], {'research': 1.1, 'trade': 1.05, 'mil': 1.05})
call s:def('skyscrapers',         1910, 'infra', '摩天楼',             'Skyscrapers',             3000, ['reinforced_concrete'], {'out': {'urban_center': 1.25}, 'build_cap': 1.05})
call s:def('electrified_rail',    1910, 'infra', '鉄道電化',           'Railway Electrification', 3000, ['railways', 'electricity'], {'build_cap': 1.1, 'trade': 1.05})
call s:def('automobile',          1910, 'infra', '自動車',             'Automobile',              3000, ['internal_combustion'], {'trade': 1.1, 'out_all': 1.03})
call s:def('aviation',            1910, 'infra', '航空機',             'Aviation',                3200, ['internal_combustion'], {'mil': 1.1, 'research': 1.05})
call s:def('panama_canal',        1910, 'infra', 'パナマ運河',         'Panama Canal',            3400, ['suez_canal'], {'trade': 1.15})
call s:def('trucking',            1930, 'infra', '貨物自動車輸送',     'Motor Freight',           4200, ['automobile'], {'trade': 1.15, 'build_cap': 1.1})
call s:def('commercial_aviation', 1930, 'infra', '民間航空',           'Commercial Aviation',     4800, ['aviation'], {'trade': 1.1, 'research': 1.05})

" ================= 軍事 (28) =================
call s:def('percussion_caps',     1836, 'war', '雷管',                 'Percussion Caps',          200, [], {'mil': 1.05})
call s:def('military_academies',  1836, 'war', '士官学校',             'Military Academies',       250, [], {'mil': 1.05})
call s:def('coastal_fortifications', 1850, 'war', '沿岸要塞',          'Coastal Fortifications',   400, [], {'mil': 1.05})
call s:def('minie_ball',          1850, 'war', 'ミニエー弾',           'Minié Ball',               450, ['percussion_caps'], {'mil': 1.05})
call s:def('conscription',        1850, 'war', '国民皆兵',             'Mass Conscription',        450, [], {'mil': 1.05, 'mil_cap': 1.2})
call s:def('rifled_muskets',      1850, 'war', 'ライフル銃',           'Rifled Muskets',           500, ['percussion_caps'], {'mil': 1.1})
call s:def('general_staff',       1850, 'war', '参謀本部',             'General Staff System',     500, ['military_academies'], {'mil': 1.1})
call s:def('observation_balloons', 1870, 'war', '観測気球',            'Observation Balloons',     800, [], {'mil': 1.03})
call s:def('staff_wargames',      1870, 'war', '図上演習',             'Staff Wargames',           850, ['general_staff'], {'mil': 1.05, 'research': 1.02})
call s:def('breech_loaders',      1870, 'war', '後装銃',               'Breech-Loading Rifles',    900, ['rifled_muskets'], {'mil': 1.1})
call s:def('logistics_corps',     1870, 'war', '兵站部隊',             'Logistics Corps',          950, ['railways'], {'mil': 1.1, 'mil_cap': 1.1})
call s:def('ironclads',           1870, 'war', '装甲艦',               'Ironclads',               1000, ['steam_engine'], {'mil': 1.1, 'trade': 1.05})
call s:def('repeating_rifles',    1870, 'war', '連発銃',               'Repeating Rifles',        1000, ['breech_loaders'], {'mil': 1.1})
call s:def('torpedoes',           1890, 'war', '魚雷',                 'Torpedoes',               1700, [], {'mil': 1.05})
call s:def('smokeless_powder',    1890, 'war', '無煙火薬',             'Smokeless Powder',        1700, ['organic_chemistry'], {'mil': 1.1})
call s:def('machine_guns',        1890, 'war', '機関銃',               'Machine Guns',            1800, ['repeating_rifles'], {'mil': 1.15})
call s:def('modern_artillery',    1890, 'war', '速射砲',               'Quick-Firing Artillery',  1900, ['smokeless_powder'], {'mil': 1.1})
call s:def('trench_warfare',      1910, 'war', '塹壕戦術',             'Trench Warfare',          2600, ['machine_guns'], {'mil': 1.05})
call s:def('chemical_weapons',    1910, 'war', '毒ガス',               'Chemical Weapons',        2800, ['organic_chemistry'], {'mil': 1.1, 'rad': 0.05})
call s:def('naval_gunnery',       1910, 'war', '射撃管制',             'Naval Fire Control',      2900, ['modern_artillery'], {'mil': 1.1})
call s:def('submarines',          1910, 'war', '潜水艦',               'Submarines',              3000, ['oil_refining'], {'mil': 1.1})
call s:def('dreadnoughts',        1910, 'war', '弩級戦艦',             'Dreadnoughts',            3200, ['steel_hulls'], {'mil': 1.15})
call s:def('tanks',               1910, 'war', '戦車',                 'Tanks',                   3400, ['automobile'], {'mil': 1.2})
call s:def('military_aviation',   1930, 'war', '軍用機',               'Military Aviation',       4400, ['aviation'], {'mil': 1.2})
call s:def('motorized_infantry',  1930, 'war', '自動車化歩兵',         'Motorized Infantry',      4600, ['trucking'], {'mil': 1.15})
call s:def('total_war_doctrine',  1930, 'war', '総力戦体制',           'Total War Doctrine',      4800, ['mass_politics'], {'mil': 1.2, 'rad': 0.1})
call s:def('aircraft_carriers',   1930, 'war', '航空母艦',             'Aircraft Carriers',       5000, ['military_aviation', 'dreadnoughts'], {'mil': 1.15})
call s:def('radar',               1930, 'war', 'レーダー',             'Radar',                   5200, ['radio'], {'mil': 1.15})

" ================= 経済・金融 (27) =================
call s:def('savings_banks',       1836, 'fin', '貯蓄銀行',             'Savings Banks',            200, [], {'interest': 0.047})
call s:def('cheque_clearing',     1836, 'fin', '手形交換所',           'Clearing Houses',          220, [], {'interest': 0.048, 'trade': 1.05})
call s:def('classical_economics', 1836, 'fin', '古典派経済学',         'Classical Economics',      280, [], {'trade': 1.1, 'research': 1.05})
call s:def('free_trade_doctrine', 1836, 'fin', '自由貿易論',           'Free Trade Doctrine',      300, ['classical_economics'], {'trade': 1.2, 'tariff': 0.8})
call s:def('protective_tariffs',  1836, 'fin', '保護関税論',           'Protective Tariffs',       300, ['classical_economics'], {'tariff': 1.5, 'trade': 0.95})
call s:def('joint_stock',         1850, 'fin', '株式会社',             'Joint-Stock Companies',    250, [], {'build_cap': 1.25})
call s:def('national_budgeting',  1850, 'fin', '近代予算制度',         'Modern Budgeting',         400, [], {'upkeep': 0.95})
call s:def('commodity_exchanges', 1850, 'fin', '商品取引所',           'Commodity Exchanges',      450, [], {'trade': 1.1})
call s:def('actuarial_science',   1850, 'fin', '保険数理',             'Actuarial Science',        480, [], {'interest': 0.045, 'trade': 1.05})
call s:def('limited_liability',   1850, 'fin', '有限責任制',           'Limited Liability',        500, ['joint_stock'], {'build_cap': 1.1})
call s:def('corporate_law',       1870, 'fin', '会社法',               'Corporate Law',            850, ['limited_liability'], {'build_cap': 1.1})
call s:def('stock_ticker',        1870, 'fin', '株式相場表示機',       'Stock Ticker',             900, ['telegraph'], {'build_cap': 1.05, 'research': 1.02})
call s:def('investment_banking',  1870, 'fin', '投資銀行',             'Investment Banking',       900, ['limited_liability'], {'build_cap': 1.1, 'interest': 0.045})
call s:def('civil_service_reform', 1870, 'fin', '官僚制改革',          'Civil Service Reform',     900, [], {'upkeep': 0.95, 'research': 1.05})
call s:def('tax_administration',  1870, 'fin', '近代税務行政',         'Modern Tax Administration', 950, [], {'tax_eff': 1.1})
call s:def('gold_standard',       1870, 'fin', '金本位制',             'Gold Standard',           1000, [], {'interest': 0.04, 'trade': 1.15})
call s:def('marginalism',         1870, 'fin', '限界効用理論',         'Marginalist Economics',   1100, ['classical_economics'], {'research': 1.05, 'trade': 1.05})
call s:def('central_banking',     1870, 'fin', '中央銀行',             'Central Banking',          300, ['joint_stock'], {'interest': 0.03})
call s:def('credit_unions',       1890, 'fin', '信用組合',             'Credit Unions',           1500, [], {'interest': 0.04, 'rad': -0.05})
call s:def('department_stores',   1890, 'fin', '百貨店',               'Department Stores',       1600, [], {'out': {'urban_center': 1.2}})
call s:def('social_insurance',    1890, 'fin', '社会保険',             'Social Insurance',        1800, [], {'rad': -0.1})
call s:def('labor_exchanges',     1910, 'fin', '職業紹介所',           'Labor Exchanges',         2400, ['social_insurance'], {'out_all': 1.02, 'rad': -0.05})
call s:def('advertising',         1910, 'fin', '広告産業',             'Advertising',             2500, [], {'out': {'urban_center': 1.15}, 'trade': 1.05})
call s:def('old_age_pensions',    1910, 'fin', '老齢年金',             'Old-Age Pensions',        2600, ['social_insurance'], {'rad': -0.1})
call s:def('monetary_policy',     1910, 'fin', '金融政策',             'Monetary Policy',         2800, ['central_banking'], {'interest': 0.025})
call s:def('fiat_currency',       1930, 'fin', '管理通貨制度',         'Fiat Currency',           4400, ['monetary_policy'], {'interest': 0.02, 'build_cap': 1.05})
call s:def('keynesianism',        1930, 'fin', 'ケインズ経済学',       'Keynesian Economics',     5000, ['monetary_policy'], {'build_cap': 1.15, 'tax_eff': 1.05})

" ================= 社会・学術 (28) =================
call s:def('vaccination',         1836, 'soc', '種痘の普及',           'Vaccination',              200, [], {'out_all': 1.02})
call s:def('public_schools',      1836, 'soc', '公教育',               'Public Schools',           200, [], {'research': 1.25})
call s:def('kindergarten',        1850, 'soc', '幼稚園',               'Kindergartens',            380, [], {'research': 1.03})
call s:def('penny_press',         1850, 'soc', '大衆新聞',             'Penny Press',              400, ['rotary_press'], {'research': 1.05})
call s:def('anesthesia',          1850, 'soc', '麻酔',                 'Anesthesia',               420, [], {'research': 1.02, 'out_all': 1.01})
call s:def('nursing_profession',  1850, 'soc', '近代看護',             'Modern Nursing',           420, [], {'out_all': 1.01, 'mil': 1.05})
call s:def('rotary_press',        1850, 'soc', '輪転印刷機',           'Rotary Press',             450, [], {'research': 1.1})
call s:def('statistics',          1850, 'soc', '近代統計学',           'Modern Statistics',        480, [], {'research': 1.05, 'tax_eff': 1.05})
call s:def('evolution_theory',    1850, 'soc', '進化論',               'Theory of Evolution',      500, [], {'research': 1.1})
call s:def('universities',        1850, 'soc', '近代大学',             'Modern Universities',      550, ['public_schools'], {'research': 1.15})
call s:def('organic_chemistry',   1850, 'soc', '有機化学',             'Organic Chemistry',        600, [], {'research': 1.1})
call s:def('public_libraries',    1870, 'soc', '公共図書館',           'Public Libraries',         800, ['public_schools'], {'research': 1.05})
call s:def('pasteurization',      1870, 'soc', '低温殺菌法',           'Pasteurization',           900, ['organic_chemistry'], {'out_all': 1.02})
call s:def('antiseptics',         1870, 'soc', '消毒法',               'Antiseptics',              950, [], {'out_all': 1.02})
call s:def('periodic_table',      1870, 'soc', '周期表',               'Periodic Table',           950, ['organic_chemistry'], {'research': 1.1})
call s:def('germ_theory',         1870, 'soc', '病原菌説',             'Germ Theory',             1000, ['pasteurization'], {'out_all': 1.03})
call s:def('modern_sewers',       1870, 'soc', '上下水道',             'Modern Sewerage',         1000, ['civil_engineering'], {'out': {'urban_center': 1.15}, 'out_all': 1.02})
call s:def('womens_education',    1870, 'soc', '女子教育',             'Women''s Education',      1000, ['public_schools'], {'research': 1.1})
call s:def('compulsory_education', 1870, 'soc', '義務教育',            'Compulsory Education',    1100, ['public_schools'], {'research': 1.15, 'rad': -0.05})
call s:def('electricity',         1870, 'soc', '電磁気学',             'Electromagnetism',        1200, [], {'research': 1.1})
call s:def('psychology',          1890, 'soc', '心理学',               'Psychology',              1600, ['universities'], {'research': 1.05})
call s:def('x_rays',              1890, 'soc', 'X線',                  'X-Rays',                  1900, ['electricity'], {'research': 1.1})
call s:def('research_labs',       1890, 'soc', '企業研究所',           'Research Laboratories',   2000, ['universities'], {'research': 1.2})
call s:def('cinema',              1910, 'soc', '映画',                 'Cinema',                  2500, ['electricity'], {'out': {'urban_center': 1.15}})
call s:def('relativity',          1910, 'soc', '相対性理論',           'Theory of Relativity',    3400, ['research_labs'], {'research': 1.15})
call s:def('quantum_mechanics',   1910, 'soc', '量子力学',             'Quantum Mechanics',       3500, ['research_labs'], {'research': 1.2})
call s:def('radio_broadcasting',  1930, 'soc', 'ラジオ放送',           'Radio Broadcasting',      4200, ['radio'], {'research': 1.05, 'rad': -0.05})
call s:def('antibiotics',         1930, 'soc', 'ペニシリン',           'Penicillin',              5000, ['germ_theory'], {'out_all': 1.05, 'mil': 1.05})

" ================= 政治思想 (21) =================
call s:def('romanticism',         1836, 'idea', 'ロマン主義',           'Romanticism',              200, [], {'research': 1.02})
call s:def('utilitarianism',      1836, 'idea', '功利主義',             'Utilitarianism',           250, [], {'research': 1.05})
call s:def('abolitionism',        1836, 'idea', '奴隷制廃止運動',       'Abolitionism',             280, [], {'rad': -0.05, 'research': 1.02})
call s:def('nationalism',         1836, 'idea', 'ナショナリズム',       'Nationalism',              300, ['romanticism'], {'mil': 1.05})
call s:def('chartism',            1836, 'idea', 'チャーティスト運動',   'Chartism',                 300, [], {'rad': -0.05})
call s:def('utopian_socialism',   1836, 'idea', '空想的社会主義',       'Utopian Socialism',        300, [], {'rad': -0.05})
call s:def('liberal_thought',     1836, 'idea', '自由主義思想',         'Liberalism',               350, ['utilitarianism'], {'research': 1.05})
call s:def('positivism',          1850, 'idea', '実証主義',             'Positivism',               450, [], {'research': 1.08})
call s:def('communist_manifesto', 1850, 'idea', '共産党宣言',           'The Communist Manifesto',  500, ['utopian_socialism'], {'research': 1.02})
call s:def('anarchist_thought',   1850, 'idea', '無政府主義思想',       'Anarchism',                550, ['utopian_socialism'], {'research': 1.02})
call s:def('red_cross',           1870, 'idea', '赤十字',               'Red Cross',                800, [], {'rad': -0.05, 'mil': 1.02})
call s:def('social_darwinism',    1870, 'idea', '社会進化論',           'Social Darwinism',         900, ['evolution_theory'], {'mil': 1.05})
call s:def('imperialism',         1870, 'idea', '帝国主義論',           'Imperialism',             1000, ['nationalism'], {'mil': 1.1, 'trade': 1.1})
call s:def('scientific_socialism', 1870, 'idea', '科学的社会主義',      'Scientific Socialism',    1000, ['communist_manifesto'], {'research': 1.05})
call s:def('feminism',            1870, 'idea', 'フェミニズム',         'Feminism',                1100, ['womens_education'], {'research': 1.05})
call s:def('pan_movements',       1890, 'idea', 'パン・ナショナリズム', 'Pan-Nationalism',         1500, ['nationalism'], {'mil': 1.05})
call s:def('internationalism',    1890, 'idea', '国際主義',             'Internationalism',        1600, [], {'trade': 1.1, 'rad': -0.05})
call s:def('syndicalism',         1890, 'idea', 'サンディカリスム',     'Syndicalism',             1700, ['anarchist_thought'], {'rad': -0.05})
call s:def('mass_politics',       1890, 'idea', '大衆政党',             'Mass Politics',           1700, [], {'rad': -0.1, 'tax_eff': 1.05})
call s:def('social_democracy',    1890, 'idea', '社会民主主義',         'Social Democracy',        1800, ['scientific_socialism'], {'rad': -0.15})
call s:def('propaganda',          1910, 'idea', '宣伝技術',             'Mass Propaganda',         2600, ['penny_press'], {'rad': -0.15, 'mil': 1.05})

" ================= 固有技術 (21) =================
call s:def('zollverein',          1836, 'nat', '関税同盟',             'Zollverein',               300, [], {'trade': 1.2, 'tax_eff': 1.05}, ['PRU'])
call s:def('silk_export',         1850, 'nat', '生糸輸出振興',         'Silk Export Promotion',    400, [], {'trade': 1.15, 'out': {'textile_mill': 1.1}}, ['JAP'])
call s:def('coffee_economy',      1850, 'nat', 'コーヒー経済',         'Coffee Economy',           400, [], {'trade': 1.15, 'out': {'grain_farm': 1.1}}, ['BRA'])
call s:def('cotton_boom',         1850, 'nat', '綿花ブーム',           'Cotton Boom',              450, [], {'out': {'cotton_farm': 1.3}, 'trade': 1.1}, ['EGY'])
call s:def('folk_schools',        1850, 'nat', '国民学校',             'Folk Schools',             450, [], {'research': 1.15}, ['SWE'])
call s:def('manifest_destiny',    1850, 'nat', '明白なる使命',         'Manifest Destiny',         500, [], {'build_cap': 1.1, 'mil': 1.05}, ['USA'])
call s:def('tanzimat',            1850, 'nat', 'タンジマート改革',     'Tanzimat Reforms',         500, [], {'tax_eff': 1.1, 'research': 1.1, 'rad': -0.1}, ['OTT'])
call s:def('risorgimento',        1850, 'nat', 'リソルジメント',       'Risorgimento',             500, [], {'mil': 1.1, 'build_cap': 1.05}, ['SAR'])
call s:def('city_of_london',      1850, 'nat', 'シティ金融市場',       'The City of London',       500, [], {'interest': 0.04, 'build_cap': 1.05}, ['GBR'])
call s:def('prussian_general_staff', 1850, 'nat', '大参謀本部',        'Prussian General Staff',   550, ['general_staff'], {'mil': 1.2}, ['PRU'])
call s:def('pax_britannica',      1850, 'nat', 'パクス・ブリタニカ',   'Pax Britannica',           600, [], {'trade': 1.25, 'mil': 1.05}, ['GBR'])
call s:def('meiji_restoration',   1870, 'nat', '明治維新',             'Meiji Restoration',        900, [], {'out_all': 1.05, 'research': 1.15, 'mil': 1.1}, ['JAP'])
call s:def('emancipation_serfs',  1870, 'nat', '農奴解放令',           'Emancipation of the Serfs', 900, [], {'out_all': 1.08, 'rad': -0.1}, ['RUS'])
call s:def('haussmann_renovation', 1870, 'nat', 'パリ大改造',          'Haussmann''s Renovation',  900, [], {'out': {'urban_center': 1.25}, 'build_cap': 1.1}, ['FRA'])
call s:def('land_grant_colleges', 1870, 'nat', '国有地付与大学',       'Land-Grant Colleges',      900, [], {'research': 1.15}, ['USA'])
call s:def('self_strengthening',  1870, 'nat', '洋務運動',             'Self-Strengthening Movement', 900, [], {'mil': 1.1, 'out': {'steel_mill': 1.2, 'tool_workshop': 1.1}}, ['QIN'])
call s:def('fukoku_kyohei',       1870, 'nat', '富国強兵',             'Fukoku Kyohei',           1000, ['meiji_restoration'], {'mil': 1.15, 'build_cap': 1.1}, ['JAP'])
call s:def('mission_civilisatrice', 1890, 'nat', '文明化の使命',       'Mission Civilisatrice',   1600, [], {'trade': 1.1, 'mil': 1.05}, ['FRA'])
call s:def('chinese_exam_reform', 1890, 'nat', '科挙改革',             'Imperial Examination Reform', 1600, [], {'research': 1.15}, ['QIN'])
call s:def('two_power_standard',  1890, 'nat', '二国標準主義',         'Two-Power Standard',      1900, [], {'mil': 1.15}, ['GBR'])
call s:def('trans_siberian',      1890, 'nat', 'シベリア横断鉄道',     'Trans-Siberian Railway',  2000, ['railways'], {'build_cap': 1.1, 'trade': 1.15}, ['RUS'])

let g:vimtoria_data_tech.order = s:order
let g:vimtoria_data_tech.techs = s:techs
delfunction s:def
