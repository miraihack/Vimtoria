scriptencoding utf-8
" data/map.vim - 1836年の地球マップ定義
" template: ASCII 世界地図。{TAG} は州プレースホルダ(描画時に 5 文字で
"           置換されるため、置換後も桁が揃う)。~ は海。
" 桁ずれ防止のため、各行を固定幅 3 セグメントの連結で構成する:
"   セグメントA(幅40): 南北アメリカ・ハワイ
"   セグメントB(幅24): ヨーロッパ・アフリカ
"   セグメントC(幅34): ロシア・アジア・オセアニア
" states の row/col はローダが template から自動計算するので書かない。
" pop の単位は「万人」(1836年頃の概算)。

let g:vimtoria_data_map = {}

let s:seg_a = [
      \ '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~',
      \ '~~ ______ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~',
      \ '~ /{ALA} \_____________________ ~~~~~~~~',
      \ '~ \_                           \_ ~~~~~~',
      \ '~~~ \        {CAN}             \ ~~~~~~~',
      \ '~~~~ \_____________________    | ~~~~~~~',
      \ '~~~~~ |      {USA}            _/ ~~~~~~~',
      \ '~~~~~~\____       ___________/ ~~~~~~~~~',
      \ '~~~~~~~ \{CAL}|  {TEX}\__ ~~~~~~~~~~~~~~',
      \ '~~~~~~~~ \_ {MEX} \_/ ~~~~~~~~~~~~~~~~~~',
      \ '~ {HAW} ~~~ \__ ~~\_ ~~~ _______ ~~~~~~~',
      \ '~~~~~~~~~~~~ \__________/{NGR}  \__ ~~~~',
      \ '~~~~~~~~~~~~~~~~~~~~~~~ |         \_ ~~~',
      \ '~~~~~~~~~~~~~~~~~~~~~~~ |{PBC} {BRA} |~~',
      \ '~~~~~~~~~~~~~~~~~~~~~~~~ \          |~~~',
      \ '~~~~~~~~~~~~~~~~~~~~~~~~ |{CHI}{ARG}/ ~~',
      \ '~~~~~~~~~~~~~~~~~~~~~~~~~ \       / ~~~~',
      \ '~~~~~~~~~~~~~~~~~~~~~~~~~~ \_____/ ~~~~~',
      \ '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~',
      \ ]

let s:seg_b = [
      \ '~~~~~~~~~~~~~~~~~~~~~~~~',
      \ '~~~~~~~~~ ____ ~~~~~~~~~',
      \ '~ __ ~~~ /{SWE}\ ~~~~~~~',
      \ '~({GBR}) ~ \_   |~~~~~~~',
      \ '~~ \_/ ~ _/{NET}{PRU}\__',
      \ '~ ____/ {FRA}  {AUS} \__',
      \ '~/{POR}{SPA}\ {SAR}\ ~\_',
      \ '~\_________/ ~\{SIC}~ ~~',
      \ '~~ _____ ~~~ ~\_/~{GRE}~',
      \ '~ /{MOR}{ALG}\_______ ~~',
      \ '~ |         {EGY}\_ ~~~~',
      \ '~ |  {SOK}         \ ~~~',
      \ '~~ \          {ETH}| ~~~',
      \ '~~~ \_____        / ~~~~',
      \ '~~~~~~~~~ |      / ~~~~~',
      \ '~~~~~~~~~ |     | ~~~~~~',
      \ '~~~~~~~~~~ \{ZUL}| ~~~~~',
      \ '~~~~~~~~~~~ \___/ ~~~~~~',
      \ '~~~~~~~~~~~~~~~~~~~~~~~~',
      \ ]

let s:seg_c = [
      \ '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~',
      \ '______________________ ~~~~~~~~~~~',
      \ '( {RUS}       {SIB}  \__ ~~~~~~~~~',
      \ '|                 ___/ \ ~~ __ ~~~',
      \ '__                ___/ ~ /{EZO}| ~',
      \ '{OTT}{PER} __/{MAN}\ ~~ |{OSH}| ~~',
      \ '~\_ \_ {PEK}{KOR}\ ~ /{EDO}/ ~~~~~',
      \ '~~ \_{SZE}{SHG}| ~ /{KIN}/ ~~~~~~~',
      \ '~ /{IND}\ {BUR}{CTN}/ ~{SAI}/ ~~~~',
      \ '~~\    /{SIA}{VIE}\ ~{KYU}/ ~~~~~~',
      \ '~~ \__/ ~~ \_| ~~ {PHI} ~~~~~~~~~~',
      \ '~~~~~~~~ ~_{JAV}__~ ~~~~~~~~~~~~~~',
      \ '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~',
      \ '~~~~~~~~~~~ ______________ ~~~~~~~',
      \ '~~~~~~~~~~ /    {AUL}     \ ~~~~~~',
      \ '~~~~~~~~~~~ \_____________/ ~~~~~~',
      \ '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~',
      \ '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~',
      \ '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~',
      \ ]

let g:vimtoria_data_map.template = []
for s:i in range(len(s:seg_a))
  call add(g:vimtoria_data_map.template,
        \ s:seg_a[s:i] . s:seg_b[s:i] . s:seg_c[s:i])
endfor
unlet s:seg_a s:seg_b s:seg_c s:i

let g:vimtoria_data_map.country_order = [
      \ 'JAP', 'GBR', 'FRA', 'RUS', 'AUS', 'PRU', 'OTT', 'QIN', 'USA', 'SPA',
      \ 'POR', 'NET', 'SWE', 'SAR', 'SIC', 'GRE', 'EGY', 'PER', 'MEX', 'TEX',
      \ 'BRA', 'ARG', 'CHI', 'PBC', 'NGR', 'KOR', 'SIA', 'VIE', 'BUR', 'MOR',
      \ 'ETH', 'ZUL', 'SOK', 'HAW',
      \ ]

" capital: 起動時に選択される代表州
let g:vimtoria_data_map.countries = {
      \ 'JAP': {'name': '日本(江戸幕府)',             'capital': 'EDO', 'hl': 'VimtoriaCountry1'},
      \ 'GBR': {'name': 'イギリス',                   'capital': 'GBR', 'hl': 'VimtoriaCountry2'},
      \ 'FRA': {'name': 'フランス王国',               'capital': 'FRA', 'hl': 'VimtoriaCountry5'},
      \ 'RUS': {'name': 'ロシア帝国',                 'capital': 'RUS', 'hl': 'VimtoriaCountry4'},
      \ 'AUS': {'name': 'オーストリア帝国',           'capital': 'AUS', 'hl': 'VimtoriaCountry2'},
      \ 'PRU': {'name': 'プロイセン王国',             'capital': 'PRU', 'hl': 'VimtoriaCountry7'},
      \ 'OTT': {'name': 'オスマン帝国',               'capital': 'OTT', 'hl': 'VimtoriaCountry6'},
      \ 'QIN': {'name': '清',                         'capital': 'PEK', 'hl': 'VimtoriaCountry3'},
      \ 'USA': {'name': 'アメリカ合衆国',             'capital': 'USA', 'hl': 'VimtoriaCountry5'},
      \ 'SPA': {'name': 'スペイン王国',               'capital': 'SPA', 'hl': 'VimtoriaCountry3'},
      \ 'POR': {'name': 'ポルトガル王国',             'capital': 'POR', 'hl': 'VimtoriaCountry7'},
      \ 'NET': {'name': 'オランダ王国',               'capital': 'NET', 'hl': 'VimtoriaCountry8'},
      \ 'SWE': {'name': 'スウェーデン=ノルウェー',    'capital': 'SWE', 'hl': 'VimtoriaCountry5'},
      \ 'SAR': {'name': 'サルデーニャ王国',           'capital': 'SAR', 'hl': 'VimtoriaCountry6'},
      \ 'SIC': {'name': '両シチリア王国',             'capital': 'SIC', 'hl': 'VimtoriaCountry4'},
      \ 'GRE': {'name': 'ギリシャ王国',               'capital': 'GRE', 'hl': 'VimtoriaCountry5'},
      \ 'EGY': {'name': 'エジプト(ムハンマド・アリー朝)', 'capital': 'EGY', 'hl': 'VimtoriaCountry2'},
      \ 'PER': {'name': 'ペルシア(ガージャール朝)',   'capital': 'PER', 'hl': 'VimtoriaCountry8'},
      \ 'MEX': {'name': 'メキシコ共和国',             'capital': 'MEX', 'hl': 'VimtoriaCountry3'},
      \ 'TEX': {'name': 'テキサス共和国',             'capital': 'TEX', 'hl': 'VimtoriaCountry6'},
      \ 'BRA': {'name': 'ブラジル帝国',               'capital': 'BRA', 'hl': 'VimtoriaCountry2'},
      \ 'ARG': {'name': 'アルゼンチン連合',           'capital': 'ARG', 'hl': 'VimtoriaCountry6'},
      \ 'CHI': {'name': 'チリ共和国',                 'capital': 'CHI', 'hl': 'VimtoriaCountry8'},
      \ 'PBC': {'name': 'ペルー=ボリビア国家連合',    'capital': 'PBC', 'hl': 'VimtoriaCountry7'},
      \ 'NGR': {'name': 'ヌエバ・グラナダ共和国',     'capital': 'NGR', 'hl': 'VimtoriaCountry4'},
      \ 'KOR': {'name': '朝鮮(李朝)',                 'capital': 'KOR', 'hl': 'VimtoriaCountry5'},
      \ 'SIA': {'name': 'シャム(ラタナコーシン朝)',   'capital': 'SIA', 'hl': 'VimtoriaCountry4'},
      \ 'VIE': {'name': '越南(阮朝)',                 'capital': 'VIE', 'hl': 'VimtoriaCountry2'},
      \ 'BUR': {'name': 'ビルマ(コンバウン朝)',       'capital': 'BUR', 'hl': 'VimtoriaCountry6'},
      \ 'MOR': {'name': 'モロッコ',                   'capital': 'MOR', 'hl': 'VimtoriaCountry4'},
      \ 'ETH': {'name': 'エチオピア帝国',             'capital': 'ETH', 'hl': 'VimtoriaCountry6'},
      \ 'ZUL': {'name': 'ズールー王国',               'capital': 'ZUL', 'hl': 'VimtoriaCountry4'},
      \ 'SOK': {'name': 'ソコト帝国',                 'capital': 'SOK', 'hl': 'VimtoriaCountry5'},
      \ 'HAW': {'name': 'ハワイ王国',                 'capital': 'HAW', 'hl': 'VimtoriaCountry8'},
      \ }

let g:vimtoria_data_map.states = {
      \ 'EZO': {'name': '蝦夷地',               'country': 'JAP', 'pop': 5},
      \ 'OSH': {'name': '奥羽',                 'country': 'JAP', 'pop': 400},
      \ 'EDO': {'name': '江戸',                 'country': 'JAP', 'pop': 900},
      \ 'KIN': {'name': '上方',                 'country': 'JAP', 'pop': 800},
      \ 'SAI': {'name': '西国',                 'country': 'JAP', 'pop': 500},
      \ 'KYU': {'name': '九州',                 'country': 'JAP', 'pop': 600},
      \ 'MAN': {'name': '満洲',                 'country': 'QIN', 'pop': 250},
      \ 'PEK': {'name': '直隷',                 'country': 'QIN', 'pop': 2300},
      \ 'SHG': {'name': '江南',                 'country': 'QIN', 'pop': 7000},
      \ 'CTN': {'name': '広東',                 'country': 'QIN', 'pop': 1900},
      \ 'SZE': {'name': '四川',                 'country': 'QIN', 'pop': 3800},
      \ 'KOR': {'name': '朝鮮',                 'country': 'KOR', 'pop': 850},
      \ 'RUS': {'name': 'ヨーロッパ・ロシア',   'country': 'RUS', 'pop': 4800},
      \ 'SIB': {'name': 'シベリア',             'country': 'RUS', 'pop': 270},
      \ 'ALA': {'name': 'ロシア領アメリカ',     'country': 'RUS', 'pop': 1},
      \ 'GBR': {'name': 'ブリテン諸島',         'country': 'GBR', 'pop': 2500},
      \ 'CAN': {'name': '英領カナダ',           'country': 'GBR', 'pop': 120},
      \ 'IND': {'name': '英領インド',           'country': 'GBR', 'pop': 13000},
      \ 'AUL': {'name': '豪州植民地',           'country': 'GBR', 'pop': 15},
      \ 'FRA': {'name': 'フランス本土',         'country': 'FRA', 'pop': 3350},
      \ 'ALG': {'name': '仏領アルジェリア',     'country': 'FRA', 'pop': 300},
      \ 'SPA': {'name': 'スペイン本土',         'country': 'SPA', 'pop': 1230},
      \ 'PHI': {'name': 'フィリピン',           'country': 'SPA', 'pop': 350},
      \ 'POR': {'name': 'ポルトガル',           'country': 'POR', 'pop': 350},
      \ 'NET': {'name': 'オランダ本土',         'country': 'NET', 'pop': 290},
      \ 'JAV': {'name': '蘭領東インド',         'country': 'NET', 'pop': 980},
      \ 'PRU': {'name': 'プロイセン',           'country': 'PRU', 'pop': 1400},
      \ 'SWE': {'name': 'スカンディナヴィア',   'country': 'SWE', 'pop': 440},
      \ 'AUS': {'name': 'オーストリア',         'country': 'AUS', 'pop': 3350},
      \ 'SAR': {'name': 'ピエモンテ',           'country': 'SAR', 'pop': 450},
      \ 'SIC': {'name': 'ナポリ=シチリア',      'country': 'SIC', 'pop': 820},
      \ 'GRE': {'name': 'ギリシャ',             'country': 'GRE', 'pop': 75},
      \ 'OTT': {'name': 'アナトリア',           'country': 'OTT', 'pop': 2400},
      \ 'EGY': {'name': 'エジプト',             'country': 'EGY', 'pop': 450},
      \ 'MOR': {'name': 'モロッコ',             'country': 'MOR', 'pop': 300},
      \ 'PER': {'name': 'ペルシア',             'country': 'PER', 'pop': 650},
      \ 'ETH': {'name': 'エチオピア',           'country': 'ETH', 'pop': 300},
      \ 'ZUL': {'name': 'ズールーランド',       'country': 'ZUL', 'pop': 25},
      \ 'SOK': {'name': 'ソコト',               'country': 'SOK', 'pop': 1000},
      \ 'USA': {'name': '合衆国東部',           'country': 'USA', 'pop': 1540},
      \ 'TEX': {'name': 'テキサス',             'country': 'TEX', 'pop': 4},
      \ 'MEX': {'name': 'メキシコ本土',         'country': 'MEX', 'pop': 700},
      \ 'CAL': {'name': 'アルタ・カリフォルニア', 'country': 'MEX', 'pop': 3},
      \ 'BRA': {'name': 'ブラジル',             'country': 'BRA', 'pop': 700},
      \ 'ARG': {'name': 'ラ・プラタ',           'country': 'ARG', 'pop': 70},
      \ 'CHI': {'name': 'チリ',                 'country': 'CHI', 'pop': 100},
      \ 'PBC': {'name': 'ペルー=ボリビア',      'country': 'PBC', 'pop': 250},
      \ 'NGR': {'name': 'ヌエバ・グラナダ',     'country': 'NGR', 'pop': 160},
      \ 'SIA': {'name': 'シャム',               'country': 'SIA', 'pop': 400},
      \ 'VIE': {'name': '越南',                 'country': 'VIE', 'pop': 800},
      \ 'BUR': {'name': 'ビルマ',               'country': 'BUR', 'pop': 400},
      \ 'HAW': {'name': 'ハワイ',               'country': 'HAW', 'pop': 11},
      \ }
