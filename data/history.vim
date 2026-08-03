scriptencoding utf-8
" data/history.vim - 歴史イベント定義(1836〜1945年、約200件)
"
" s:h(id, 年, 月, 対象国, 日本語名, 英語名, 日本語説明, 英語説明, 効果)
" 対象国 '' は効果のない世界ニュース。効果キー:
"   open           1 で鎖国を解く(開国)
"   treasury_weeks 週間所得×係数を国庫に加算(負なら賠償・恐慌)
"   workforce_pct  全州の労働力を±(飢饉・移民・戦禍)
"   rad            急進性の即時増減
"   regiments_pct / ships_pct  陸軍・海軍の±
"   rel            [[国A, 国B, 増減], ...] 関係値の変化
"   cede           [州ID, 譲渡先] 州の割譲(現所有者が対象国の場合のみ)
"   duration + out/out_all/research/build_cap/trade  時限モディファイア
" 対象国が消滅している場合は発火しない(歴史は分岐した)。

let g:vimtoria_data_history = {}
let s:order = []
let s:events = {}
function! s:h(id, year, month, country, name, name_en, desc, desc_en, effects) abort
  let s:events[a:id] = {'year': a:year, 'month': a:month, 'country': a:country,
        \ 'name': a:name, 'name_en': a:name_en,
        \ 'desc': a:desc, 'desc_en': a:desc_en, 'effects': a:effects}
  call add(s:order, a:id)
endfunction

" ---- 1836-1845 ----
call s:h('texas_republic', 1836, 10, 'TEX', 'テキサス共和国の確立', 'The Texas Republic Secured',
      \ 'サン・ジャシントの勝利で独立が固まった', 'Victory at San Jacinto secures independence',
      \ {'rad': -5, 'regiments_pct': 0.1})
call s:h('panic_1837', 1837, 3, 'USA', '1837年恐慌', 'Panic of 1837',
      \ '銀行破綻が連鎖し不況に突入した', 'Bank failures cascade into depression',
      \ {'treasury_weeks': -0.75, 'rad': 5, 'out_all': 0.95, 'duration': 26})
call s:h('victoria_accession', 1837, 6, 'GBR', 'ヴィクトリア女王即位', 'Accession of Queen Victoria',
      \ '18歳の女王が即位し新時代が始まる', 'An 18-year-old queen begins a new era',
      \ {'rad': -5, 'research': 1.05, 'duration': 52})
call s:h('canada_rebellions', 1837, 11, 'GBR', 'カナダ反乱', 'Rebellions in Canada',
      \ '英領カナダで自治を求める反乱が起きた', 'Uprisings demand self-government in Canada',
      \ {'rad': 5})
call s:h('anti_corn_law', 1838, 9, 'GBR', '反穀物法同盟', 'Anti-Corn Law League',
      \ 'コブデンらが自由貿易運動を組織した', 'Cobden organizes the free-trade movement',
      \ {'rad': -2, 'trade': 1.05, 'duration': 52})
call s:h('lin_zexu', 1839, 6, 'QIN', '林則徐の阿片処分', 'Lin Zexu Destroys the Opium',
      \ '虎門で阿片2万箱が処分され英国が激怒した', '20,000 chests of opium destroyed at Humen; Britain is furious',
      \ {'rad': -3, 'rel': [['GBR', 'QIN', -40]]})
call s:h('opium_war', 1839, 11, 'QIN', 'アヘン戦争勃発', 'First Opium War Begins',
      \ '英国艦隊が清の沿岸に襲来した', 'The Royal Navy descends on the Chinese coast',
      \ {'out_all': 0.95, 'duration': 52, 'rel': [['GBR', 'QIN', -40]]})
call s:h('waitangi', 1840, 2, 'GBR', 'ワイタンギ条約', 'Treaty of Waitangi',
      \ 'ニュージーランドが英領となった', 'New Zealand comes under the British Crown',
      \ {'trade': 1.05, 'duration': 52})
call s:h('straits_convention', 1841, 7, 'OTT', 'ロンドン海峡条約', 'Straits Convention',
      \ '海峡の軍艦通航が国際規制された', 'Warship passage through the Straits is regulated',
      \ {'rad': -3, 'rel': [['RUS', 'OTT', 10]]})
call s:h('treaty_nanking', 1842, 8, 'QIN', '南京条約 — 開国', 'Treaty of Nanking — China Opened',
      \ '敗戦により香港割譲・五港開港。清は世界市場に組み込まれた', 'Defeat opens five ports; China is forced into the world market',
      \ {'open': 1, 'treasury_weeks': -0.5, 'rad': 8, 'rel': [['GBR', 'QIN', 10]]})
call s:h('great_britain_ship', 1843, 7, 'GBR', 'SSグレート・ブリテン進水', 'SS Great Britain Launched',
      \ '世界初の鉄製スクリュー外洋船が進水した', 'The first iron-hulled screw ocean liner is launched',
      \ {'ships_pct': 0.1, 'trade': 1.05, 'duration': 52})
call s:h('morse_telegraph', 1844, 5, 'USA', 'モールス電信の実用化', 'Morse Demonstrates the Telegraph',
      \ '「神の成し給うこと」— 首都間で電信が通じた', '"What hath God wrought" — the telegraph goes live',
      \ {'research': 1.1, 'duration': 52})
call s:h('franco_moroccan', 1844, 8, 'MOR', 'イスリーの戦い', 'Battle of Isly',
      \ '仏軍がモロッコ軍を破った', 'French forces defeat the Moroccan army',
      \ {'rad': 5, 'rel': [['FRA', 'MOR', -40]]})
call s:h('irish_famine', 1845, 9, 'GBR', 'アイルランド大飢饉', 'The Great Irish Famine',
      \ 'ジャガイモ疫病で飢餓と大量移民が始まった', 'Potato blight brings starvation and mass emigration',
      \ {'workforce_pct': -0.02, 'rad': 10})
call s:h('texas_annex_question', 1845, 12, 'USA', 'テキサス併合問題', 'The Texas Annexation Question',
      \ '合衆国のテキサス併合論がメキシコを刺激した', 'Annexationism inflames relations with Mexico',
      \ {'rel': [['USA', 'MEX', -30], ['USA', 'TEX', 40]]})

" ---- 1846-1855 ----
call s:h('mexican_war', 1846, 5, 'USA', '米墨戦争', 'Mexican-American War',
      \ 'リオ・グランデの国境紛争が戦争に発展した', 'A border clash on the Rio Grande becomes war',
      \ {'rel': [['USA', 'MEX', -50]]})
call s:h('corn_laws_repeal', 1846, 6, 'GBR', '穀物法廃止', 'Repeal of the Corn Laws',
      \ '英国が自由貿易へ大きく舵を切った', 'Britain commits to free trade',
      \ {'rad': -5, 'trade': 1.15, 'duration': 104})
call s:h('gold_rush', 1848, 1, 'USA', 'カリフォルニア・ゴールドラッシュ', 'California Gold Rush',
      \ 'サッターの製材所で金が見つかり人が殺到した', 'Gold at Sutter''s Mill draws a human flood',
      \ {'treasury_weeks': 1.0, 'workforce_pct': 0.02})
call s:h('feb_revolution_fra', 1848, 2, 'FRA', '二月革命', 'February Revolution',
      \ 'パリの蜂起で七月王政が倒れた', 'Paris rises and the July Monarchy falls',
      \ {'rad': 20})
call s:h('mar_revolution_aus', 1848, 3, 'AUS', 'ウィーン三月革命', 'Revolution in Vienna',
      \ 'メッテルニヒが亡命し帝国が揺らいだ', 'Metternich flees; the empire trembles',
      \ {'rad': 20})
call s:h('mar_revolution_pru', 1848, 3, 'PRU', 'ベルリン三月革命', 'Revolution in Berlin',
      \ '市街戦の末、国王は憲法制定を約束した', 'After street fighting the king promises a constitution',
      \ {'rad': 15})
call s:h('first_italian_war', 1848, 3, 'SAR', '第一次イタリア独立戦争', 'First Italian War of Independence',
      \ 'サルデーニャがオーストリアに挑んだ', 'Sardinia challenges Austria',
      \ {'rel': [['SAR', 'AUS', -50]]})
call s:h('chartist_petition', 1848, 4, 'GBR', 'チャーティスト大請願', 'The Great Chartist Petition',
      \ '数百万筆の普通選挙請願が議会に届いた', 'Millions petition Parliament for the franchise',
      \ {'rad': 8})
call s:h('hungary_crushed', 1849, 8, 'AUS', 'ハンガリー鎮圧', 'Hungary Subdued',
      \ '露軍の援けを得て革命は鎮圧された', 'With Russian help the revolution is crushed',
      \ {'rad': -10, 'regiments_pct': -0.05})
call s:h('taiping', 1851, 1, 'QIN', '太平天国の乱', 'The Taiping Rebellion',
      \ '洪秀全の蜂起が南中国を席巻し始めた', 'Hong Xiuquan''s rising engulfs southern China',
      \ {'out_all': 0.85, 'duration': 260, 'rad': 25, 'workforce_pct': -0.03})
call s:h('great_exhibition', 1851, 5, 'GBR', '万国博覧会', 'The Great Exhibition',
      \ '水晶宮に世界の産業技術が集まった', 'The world''s industry gathers at the Crystal Palace',
      \ {'research': 1.15, 'trade': 1.05, 'duration': 52})
call s:h('napoleon3_coup', 1851, 12, 'FRA', 'ルイ・ナポレオンのクーデタ', 'Louis-Napoléon''s Coup',
      \ '大統領が議会を解散し帝政への道を開いた', 'The president dissolves the assembly, paving the way to empire',
      \ {'rad': 8})
call s:h('second_burma_war', 1852, 4, 'BUR', '第二次英緬戦争', 'Second Anglo-Burmese War',
      \ '下ビルマが英国に奪われた', 'Lower Burma falls to Britain',
      \ {'rad': 8, 'rel': [['GBR', 'BUR', -50]]})
call s:h('perry', 1853, 7, 'JAP', 'ペリー来航 — 開国', 'The Perry Expedition — Japan Opened',
      \ '黒船が浦賀に現れ、二百年の鎖国が終わった', 'Black Ships appear at Uraga; two centuries of seclusion end',
      \ {'open': 1, 'rad': 10, 'rel': [['JAP', 'USA', 10]]})
call s:h('crimean_war', 1853, 10, 'RUS', 'クリミア戦争', 'The Crimean War',
      \ '聖地管理問題から露土が開戦、英仏が参戦へ', 'A quarrel over the Holy Places ignites war; Britain and France join',
      \ {'rel': [['RUS', 'OTT', -50], ['RUS', 'GBR', -30], ['RUS', 'FRA', -30]]})
call s:h('kanagawa', 1854, 3, 'JAP', '日米和親条約', 'Treaty of Kanagawa',
      \ '下田・箱館が開かれ捕鯨船の補給が認められた', 'Shimoda and Hakodate open to American ships',
      \ {'rel': [['JAP', 'USA', 15]], 'trade': 1.05, 'duration': 52})
call s:h('sevastopol', 1855, 9, 'RUS', 'セヴァストポリ陥落', 'Fall of Sevastopol',
      \ '要塞が陥ちクリミア戦争の敗色が濃くなった', 'The fortress falls; defeat looms',
      \ {'rad': 10, 'regiments_pct': -0.1})

" ---- 1856-1865 ----
call s:h('treaty_paris_1856', 1856, 3, 'RUS', 'パリ条約', 'Treaty of Paris',
      \ '黒海の中立化を受け入れ戦争が終わった', 'The Black Sea is neutralized; the war ends',
      \ {'rad': -5, 'rel': [['RUS', 'OTT', 20]]})
call s:h('arrow_war', 1856, 10, 'QIN', 'アロー戦争', 'The Second Opium War',
      \ '英仏連合軍が再び清に矛先を向けた', 'An Anglo-French force turns on China again',
      \ {'rel': [['GBR', 'QIN', -40], ['FRA', 'QIN', -30]]})
call s:h('sepoy_mutiny', 1857, 5, 'GBR', 'インド大反乱', 'The Indian Rebellion',
      \ 'シパーヒーの蜂起が北インドを覆った', 'The sepoys rise across northern India',
      \ {'out_all': 0.92, 'duration': 78, 'rad': 10})
call s:h('panic_1857', 1857, 8, 'USA', '1857年恐慌', 'Panic of 1857',
      \ '鉄道株バブルの崩壊が世界不況を招いた', 'A railway bubble bursts into world recession',
      \ {'treasury_weeks': -0.6, 'out_all': 0.95, 'duration': 26})
call s:h('india_act', 1858, 8, 'GBR', 'インド統治法', 'Government of India Act',
      \ '東インド会社に代わり英王室の直接統治が始まった', 'The Crown takes over from the East India Company',
      \ {'rad': -5, 'build_cap': 1.05, 'duration': 52})
call s:h('harris_treaty', 1858, 7, 'JAP', '日米修好通商条約', 'The Harris Treaty',
      \ '不平等条約下で本格的な貿易が始まった', 'Full trade begins under unequal treaties',
      \ {'trade': 1.1, 'duration': 104, 'rad': 8})
call s:h('second_italian_war', 1859, 5, 'SAR', '第二次イタリア独立戦争', 'Second Italian War of Independence',
      \ '仏の支援を得てロンバルディアへ進軍した', 'With French help Sardinia marches into Lombardy',
      \ {'regiments_pct': 0.1, 'rel': [['SAR', 'AUS', -50], ['SAR', 'FRA', 30]]})
call s:h('origin_of_species', 1859, 11, 'GBR', '『種の起源』出版', 'On the Origin of Species',
      \ 'ダーウィンの進化論が思想界を揺るがした', 'Darwin''s theory shakes the intellectual world',
      \ {'research': 1.1, 'duration': 104})
call s:h('peking_convention', 1860, 10, 'QIN', '北京条約', 'Convention of Peking',
      \ '円明園が焼かれ、さらなる開港と賠償を強いられた', 'The Summer Palace burns; more ports and indemnities',
      \ {'treasury_weeks': -0.5, 'rad': 5})
call s:h('thousand_expedition', 1860, 5, 'SIC', 'ガリバルディの千人隊', 'Garibaldi''s Thousand',
      \ '赤シャツ隊がシチリアに上陸し王国が崩れ始めた', 'The Redshirts land in Sicily; the kingdom crumbles',
      \ {'rad': 25, 'rel': [['SAR', 'SIC', -60]]})
call s:h('serf_emancipation', 1861, 2, 'RUS', '農奴解放令', 'Emancipation of the Serfs',
      \ '2300万の農奴が法的自由を得た', 'Twenty-three million serfs gain legal freedom',
      \ {'rad': -10, 'out_all': 1.05, 'duration': 104})
call s:h('italy_kingdom', 1861, 3, 'SAR', 'イタリア王国成立', 'The Kingdom of Italy',
      \ 'ヴィットーリオ・エマヌエーレ2世が統一王を称した', 'Victor Emmanuel II is proclaimed King of Italy',
      \ {'rad': -5, 'build_cap': 1.05, 'duration': 104})
call s:h('us_civil_war', 1861, 4, 'USA', '南北戦争勃発', 'The American Civil War',
      \ 'サムター要塞への砲撃で内戦が始まった', 'The guns at Fort Sumter open a civil war',
      \ {'out_all': 0.88, 'duration': 208, 'rad': 20, 'workforce_pct': -0.02})
call s:h('french_mexico', 1861, 12, 'MEX', 'フランスのメキシコ出兵', 'French Intervention in Mexico',
      \ '債務不履行を口実に仏軍が上陸した', 'French troops land on the pretext of unpaid debts',
      \ {'rad': 10, 'rel': [['FRA', 'MEX', -50]]})
call s:h('bismarck_minister', 1862, 9, 'PRU', 'ビスマルク首相就任', 'Bismarck Takes Office',
      \ '「鉄と血」の演説が新時代を告げた', 'The "Iron and Blood" speech announces a new era',
      \ {'rad': -3, 'build_cap': 1.05, 'duration': 104})
call s:h('emancipation_proc', 1863, 1, 'USA', '奴隷解放宣言', 'The Emancipation Proclamation',
      \ '反乱州の奴隷解放が宣言された', 'Slaves in the rebel states are declared free',
      \ {'rad': -8})
call s:h('schleswig_war', 1864, 2, 'PRU', 'デンマーク戦争', 'The Second Schleswig War',
      \ '普墺連合軍がシュレースヴィヒを奪った', 'Prussia and Austria seize Schleswig',
      \ {'regiments_pct': 0.05})
call s:h('first_international', 1864, 9, '', '第一インターナショナル結成', 'The First International',
      \ 'ロンドンで国際労働者協会が生まれた', 'The International Workingmen''s Association forms in London',
      \ {})
call s:h('civil_war_ends', 1865, 4, 'USA', '南北戦争終結', 'The Civil War Ends',
      \ 'アポマトックスで南軍が降伏した', 'The Confederacy surrenders at Appomattox',
      \ {'rad': -15, 'out_all': 1.08, 'duration': 104})
call s:h('lincoln', 1865, 4, 'USA', 'リンカーン暗殺', 'Lincoln Assassinated',
      \ '再建を導くべき大統領が劇場に斃れた', 'The president who would lead Reconstruction is shot',
      \ {'rad': 8})

" ---- 1866-1875 ----
call s:h('austro_prussian_war', 1866, 6, 'PRU', '普墺戦争', 'The Austro-Prussian War',
      \ 'ドイツの覇権を賭けた七週間戦争が始まった', 'The Seven Weeks'' War for German supremacy',
      \ {'rel': [['PRU', 'AUS', -60]]})
call s:h('koniggratz', 1866, 7, 'AUS', 'ケーニヒグレーツの敗北', 'Defeat at Königgrätz',
      \ '普軍の後装銃の前に帝国軍が崩れた', 'The needle gun shatters the imperial army',
      \ {'rad': 10, 'regiments_pct': -0.1})
call s:h('alaska_purchase', 1867, 3, 'RUS', 'アラスカ売却', 'The Alaska Purchase',
      \ '720万ドルでアラスカが合衆国に売られた', 'Alaska is sold to the United States for $7.2 million',
      \ {'treasury_weeks': 0.5, 'cede': ['ALA', 'USA']})
call s:h('ausgleich', 1867, 6, 'AUS', 'アウスグライヒ', 'The Austro-Hungarian Compromise',
      \ '二重帝国への改組で帝国は延命した', 'The Dual Monarchy buys the empire time',
      \ {'rad': -15})
call s:h('taisei_hokan', 1867, 11, 'JAP', '大政奉還', 'Taisei Hōkan',
      \ '将軍慶喜が政権を朝廷に返上した', 'The last shōgun returns power to the Emperor',
      \ {'rad': 10})
call s:h('meiji_ishin', 1868, 1, 'JAP', '明治維新', 'The Meiji Restoration',
      \ '王政復古。日本は近代国家への道を疾走し始めた', 'Imperial rule restored; Japan races toward modernity',
      \ {'rad': -10, 'research': 1.2, 'out_all': 1.05, 'duration': 156})
call s:h('spain_1868', 1868, 9, 'SPA', 'スペイン名誉革命', 'The Glorious Revolution in Spain',
      \ 'イサベル2世が追放された', 'Isabella II is driven from the throne',
      \ {'rad': 15})
call s:h('suez_opens', 1869, 11, 'EGY', 'スエズ運河開通', 'The Suez Canal Opens',
      \ '地中海と紅海が結ばれ世界の航路が変わった', 'The Mediterranean meets the Red Sea; trade routes shift',
      \ {'treasury_weeks': -0.3, 'trade': 1.2, 'duration': 260})
call s:h('us_transcontinental', 1869, 5, 'USA', '大陸横断鉄道開通', 'The Golden Spike',
      \ 'プロモントリーで東西の線路が結ばれた', 'East meets West at Promontory Summit',
      \ {'build_cap': 1.1, 'trade': 1.1, 'duration': 104})
call s:h('franco_prussian', 1870, 7, 'FRA', '普仏戦争勃発', 'The Franco-Prussian War',
      \ 'エムス電報が戦争の引き金となった', 'The Ems Dispatch triggers war',
      \ {'rel': [['FRA', 'PRU', -70]]})
call s:h('sedan', 1870, 9, 'FRA', 'スダンの敗北', 'Catastrophe at Sedan',
      \ '皇帝が捕虜となり第二帝政が崩壊した', 'The Emperor is captured; the Second Empire falls',
      \ {'rad': 20, 'regiments_pct': -0.15})
call s:h('german_empire', 1871, 1, 'PRU', 'ドイツ帝国成立', 'The German Empire Proclaimed',
      \ 'ヴェルサイユ鏡の間で皇帝が戴冠した', 'An emperor is crowned in the Hall of Mirrors',
      \ {'rad': -5, 'out_all': 1.08, 'duration': 260})
call s:h('paris_commune', 1871, 3, 'FRA', 'パリ・コミューン', 'The Paris Commune',
      \ '世界初の労働者政権が72日間パリを支配した', 'The world''s first workers'' government holds Paris for 72 days',
      \ {'rad': 15})
call s:h('frankfurt_treaty', 1871, 5, 'FRA', 'フランクフルト講和', 'The Treaty of Frankfurt',
      \ 'アルザス喪失と50億フランの賠償が課された', 'Alsace lost and five billion francs owed',
      \ {'treasury_weeks': -1.0, 'rad': 5})
call s:h('gakusei', 1872, 8, 'JAP', '学制発布', 'The Education System Order',
      \ '「邑に不学の戸なからしめん」— 国民皆学が始まる', 'Universal schooling is decreed',
      \ {'research': 1.1, 'duration': 104})
call s:h('three_emperors', 1872, 9, 'PRU', '三帝同盟', 'The League of the Three Emperors',
      \ '独墺露の保守同盟が成立した', 'The conservative powers align',
      \ {'rel': [['PRU', 'RUS', 20], ['PRU', 'AUS', 20], ['RUS', 'AUS', 10]]})
call s:h('panic_1873_aus', 1873, 5, 'AUS', 'ウィーン株式恐慌', 'The Vienna Crash',
      \ '万博の熱狂の中で取引所が崩壊した', 'The exchange collapses amid Exhibition fever',
      \ {'treasury_weeks': -0.5, 'out_all': 0.93, 'duration': 104})
call s:h('panic_1873_usa', 1873, 9, 'USA', '1873年恐慌', 'The Panic of 1873',
      \ 'ジェイ・クック商会の破綻が大不況の引き金に', 'Jay Cooke''s failure triggers the Long Depression',
      \ {'treasury_weeks': -0.6, 'out_all': 0.92, 'duration': 104})
call s:h('suez_shares', 1875, 11, 'GBR', 'スエズ運河株買収', 'Buying the Suez Shares',
      \ 'ディズレーリがエジプトの持株を電撃買収した', 'Disraeli snaps up Egypt''s canal shares',
      \ {'treasury_weeks': -0.4, 'trade': 1.1, 'duration': 104})
call s:h('balkan_crisis_1875', 1875, 7, 'OTT', 'ヘルツェゴビナ蜂起', 'The Herzegovina Uprising',
      \ 'バルカンの反乱が帝国を揺さぶり始めた', 'Balkan revolt begins to shake the empire',
      \ {'rad': 8})

" ---- 1876-1885 ----
call s:h('ottoman_constitution', 1876, 12, 'OTT', 'ミドハト憲法', 'The Ottoman Constitution',
      \ '帝国初の憲法が公布された', 'The empire''s first constitution is proclaimed',
      \ {'rad': -8})
call s:h('north_china_famine', 1877, 1, 'QIN', '丁戊奇荒(華北大飢饉)', 'The North China Famine',
      \ '大旱魃が華北を襲い数百万が飢えた', 'Drought starves millions across the north',
      \ {'workforce_pct': -0.04, 'rad': 10})
call s:h('satsuma_rebellion', 1877, 2, 'JAP', '西南戦争', 'The Satsuma Rebellion',
      \ '西郷隆盛が鹿児島に挙兵した', 'Saigō Takamori rises in Kagoshima',
      \ {'out_all': 0.95, 'duration': 26, 'rad': 8})
call s:h('russo_turkish_war', 1877, 4, 'RUS', '露土戦争', 'The Russo-Turkish War',
      \ 'バルカンの正教徒保護を掲げて開戦した', 'Russia marches to protect the Balkan Orthodox',
      \ {'rel': [['RUS', 'OTT', -60]]})
call s:h('congress_berlin', 1878, 7, 'OTT', 'ベルリン会議', 'The Congress of Berlin',
      \ '列強がバルカンの地図を引き直した', 'The powers redraw the Balkan map',
      \ {'rad': 5, 'rel': [['RUS', 'OTT', 15]]})
call s:h('war_of_pacific', 1879, 2, 'CHI', '太平洋戦争(硝石戦争)', 'The War of the Pacific',
      \ '硝石地帯を巡りチリと連合が開戦した', 'Chile and the Confederation clash over the nitrate fields',
      \ {'rel': [['CHI', 'PBC', -70]]})
call s:h('dual_alliance', 1879, 10, 'PRU', '独墺同盟', 'The Dual Alliance',
      \ 'ベルリンとウィーンが秘密防御同盟を結んだ', 'Berlin and Vienna sign a secret defensive pact',
      \ {'rel': [['PRU', 'AUS', 30]]})
call s:h('alexander_assassinated', 1881, 3, 'RUS', 'アレクサンドル2世暗殺', 'Alexander II Assassinated',
      \ '解放皇帝が人民の意志党の爆弾に斃れた', 'The Tsar-Liberator falls to a terrorist bomb',
      \ {'rad': 12})
call s:h('tunisia_protectorate', 1881, 5, 'FRA', 'チュニジア保護領化', 'The Protectorate over Tunisia',
      \ 'バルドー条約でチュニスが仏の保護下に', 'The Bardo Treaty puts Tunis under French protection',
      \ {'trade': 1.05, 'duration': 104, 'rel': [['FRA', 'OTT', -30]]})
call s:h('triple_alliance', 1882, 5, 'PRU', '三国同盟', 'The Triple Alliance',
      \ '独墺伊の同盟が成立した', 'Germany, Austria and Italy align',
      \ {'rel': [['PRU', 'SAR', 20], ['AUS', 'SAR', 15]]})
call s:h('egypt_occupied', 1882, 7, 'GBR', 'エジプト占領', 'The Occupation of Egypt',
      \ 'アレクサンドリア砲撃の後、英軍が運河地帯を抑えた', 'After bombarding Alexandria, Britain seizes the Canal',
      \ {'rel': [['GBR', 'EGY', -50]]})
call s:h('krakatoa', 1883, 8, 'NET', 'クラカタウ大噴火', 'The Eruption of Krakatoa',
      \ '爆発音は世界を三周した', 'The blast is heard around the world',
      \ {'workforce_pct': -0.01, 'out_all': 0.97, 'duration': 26})
call s:h('berlin_conference', 1884, 11, 'PRU', 'ベルリン会議(アフリカ分割)', 'The Berlin Conference',
      \ '列強がアフリカ分割のルールを定めた', 'The powers set the rules for the Scramble for Africa',
      \ {'trade': 1.05, 'duration': 104})
call s:h('sino_french_war', 1885, 4, 'QIN', '清仏戦争終結', 'The Sino-French War Ends',
      \ 'ベトナムの宗主権を失った', 'China renounces its claim over Vietnam',
      \ {'rad': 3, 'rel': [['FRA', 'QIN', 10], ['FRA', 'VIE', -40]]})

" ---- 1886-1895 ----
call s:h('haymarket', 1886, 5, 'USA', 'ヘイマーケット事件', 'The Haymarket Affair',
      \ '8時間労働デモが爆弾と流血に終わった', 'An eight-hour-day rally ends in blood',
      \ {'rad': 8})
call s:h('golden_jubilee', 1887, 6, 'GBR', 'ヴィクトリア女王在位50年', 'The Golden Jubilee',
      \ '帝国の絶頂を祝う祝典が開かれた', 'The empire celebrates at its zenith',
      \ {'rad': -5})
call s:h('golden_law', 1888, 5, 'BRA', '黄金法(奴隷制廃止)', 'The Golden Law',
      \ 'イザベル皇女が奴隷制廃止に署名した', 'Princess Isabel signs slavery away',
      \ {'rad': -10, 'workforce_pct': 0.02})
call s:h('brazil_republic', 1889, 11, 'BRA', 'ブラジル共和国宣言', 'The Republic of Brazil',
      \ '軍のクーデタで帝政が終わった', 'A military coup ends the empire',
      \ {'rad': 12})
call s:h('meiji_constitution', 1889, 2, 'JAP', '大日本帝国憲法', 'The Meiji Constitution',
      \ 'アジア初の近代憲法が発布された', 'Asia''s first modern constitution is promulgated',
      \ {'rad': -10})
call s:h('paris_expo_1889', 1889, 7, 'FRA', 'パリ万博とエッフェル塔', 'The Exposition and the Eiffel Tower',
      \ '鉄の塔が革命百周年の空にそびえた', 'A tower of iron marks the Revolution''s centenary',
      \ {'research': 1.1, 'trade': 1.05, 'duration': 52})
call s:h('bismarck_dismissed', 1890, 3, 'PRU', 'ビスマルク罷免', 'Dropping the Pilot',
      \ '若い皇帝が老宰相を退けた', 'The young Kaiser dismisses the old chancellor',
      \ {'rad': 5})
call s:h('trans_siberian_start', 1891, 5, 'RUS', 'シベリア鉄道起工', 'The Trans-Siberian Railway Begun',
      \ 'ウラジオストクで皇太子が鍬入れした', 'The Tsarevich breaks ground at Vladivostok',
      \ {'build_cap': 1.1, 'duration': 260})
call s:h('franco_russian', 1892, 8, 'FRA', '露仏同盟', 'The Franco-Russian Alliance',
      \ '共和国とツァーリが手を結んだ', 'The Republic and the Tsar join hands',
      \ {'rel': [['FRA', 'RUS', 40]]})
call s:h('panic_1893', 1893, 5, 'USA', '1893年恐慌', 'The Panic of 1893',
      \ '鉄道と銀行の連鎖破綻が全国を襲った', 'Railroads and banks fail across the nation',
      \ {'treasury_weeks': -0.7, 'out_all': 0.93, 'duration': 78})
call s:h('sino_japanese_war', 1894, 8, 'JAP', '日清戦争', 'The First Sino-Japanese War',
      \ '朝鮮の支配権を巡り日清が開戦した', 'Japan and China go to war over Korea',
      \ {'rel': [['JAP', 'QIN', -60]]})
call s:h('shimonoseki_jap', 1895, 4, 'JAP', '下関条約', 'The Treaty of Shimonoseki',
      \ '台湾と巨額の賠償金を獲得した', 'Taiwan and a vast indemnity are won',
      \ {'treasury_weeks': 1.5, 'rad': -5})
call s:h('shimonoseki_qin', 1895, 4, 'QIN', '下関条約の屈辱', 'The Humiliation of Shimonoseki',
      \ '「眠れる獅子」の敗北が列強の野心に火を点けた', 'The "sleeping lion''s" defeat whets the powers'' appetite',
      \ {'treasury_weeks': -1.0, 'rad': 12})

" ---- 1896-1905 ----
call s:h('adwa', 1896, 3, 'ETH', 'アドワの戦い', 'The Battle of Adwa',
      \ 'メネリク2世が侵略軍を撃退した', 'Menelik II routs the invaders',
      \ {'rad': -8, 'regiments_pct': 0.1, 'rel': [['SAR', 'ETH', -40]]})
call s:h('first_olympics', 1896, 4, 'GRE', '第1回近代オリンピック', 'The First Modern Olympics',
      \ 'アテネに古代の祭典が甦った', 'The ancient games are reborn in Athens',
      \ {'rad': -3})
call s:h('greco_turkish_war', 1897, 4, 'GRE', '希土戦争', 'The Greco-Turkish War',
      \ 'クレタ問題から30日戦争が起きた', 'The Cretan question sparks the Thirty Days'' War',
      \ {'rad': 5, 'rel': [['GRE', 'OTT', -50]]})
call s:h('spanish_american', 1898, 4, 'USA', '米西戦争', 'The Spanish-American War',
      \ 'メイン号の爆沈が開戦の口実となった', '"Remember the Maine" carries America to war',
      \ {'rel': [['USA', 'SPA', -60]]})
call s:h('disaster_98', 1898, 12, 'SPA', '98年の破局', 'The Disaster of ''98',
      \ 'キューバ・フィリピンを失い帝国は終わった', 'Cuba and the Philippines are lost; the empire is over',
      \ {'rad': 15, 'ships_pct': -0.3})
call s:h('hundred_days', 1898, 9, 'QIN', '戊戌の政変', 'The Hundred Days'' Reform Fails',
      \ '西太后が変法派を粛清した', 'The Empress Dowager crushes the reformers',
      \ {'rad': 8, 'research': 0.95, 'duration': 52})
call s:h('boer_war', 1899, 10, 'GBR', 'ボーア戦争', 'The Second Boer War',
      \ '南アの金鉱を巡る泥沼の戦争が始まった', 'A bitter war begins over the gold of the Rand',
      \ {'out_all': 0.97, 'duration': 130})
call s:h('boxer_rebellion', 1900, 6, 'QIN', '義和団の乱', 'The Boxer Rebellion',
      \ '「扶清滅洋」を掲げ公使館区域が包囲された', 'The Legations are besieged under "Support the Qing, destroy the foreign"',
      \ {'out_all': 0.9, 'duration': 52, 'rad': 15,
      \  'rel': [['QIN', 'GBR', -30], ['QIN', 'RUS', -30], ['QIN', 'JAP', -30]]})
call s:h('victoria_dies', 1901, 1, 'GBR', 'ヴィクトリア女王死去', 'The Death of Queen Victoria',
      \ '63年の治世が終わり一つの時代が閉じた', 'Sixty-three years of reign come to an end',
      \ {'rad': 3})
call s:h('boxer_protocol', 1901, 9, 'QIN', '北京議定書', 'The Boxer Protocol',
      \ '4億5千万両の賠償金が課された', 'An indemnity of 450 million taels is imposed',
      \ {'treasury_weeks': -1.5, 'rad': 10})
call s:h('marconi', 1901, 12, 'GBR', '大西洋横断無線', 'Wireless Across the Atlantic',
      \ 'マルコーニの信号がニューファンドランドに届いた', 'Marconi''s signal reaches Newfoundland',
      \ {'research': 1.1, 'duration': 52})
call s:h('anglo_japanese', 1902, 1, 'GBR', '日英同盟', 'The Anglo-Japanese Alliance',
      \ '「光栄ある孤立」が終わった', '"Splendid isolation" comes to an end',
      \ {'rel': [['GBR', 'JAP', 50]]})
call s:h('wright_flight', 1903, 12, 'USA', 'ライト兄弟初飛行', 'First Flight at Kitty Hawk',
      \ '12秒・36メートル — 人類が空を飛んだ', 'Twelve seconds, 120 feet — mankind flies',
      \ {'research': 1.1, 'duration': 52})
call s:h('russo_japanese_war', 1904, 2, 'JAP', '日露戦争', 'The Russo-Japanese War',
      \ '旅順奇襲で極東の覇権を賭けた戦いが始まった', 'A surprise attack on Port Arthur opens the struggle for the East',
      \ {'rel': [['JAP', 'RUS', -70]]})
call s:h('entente_cordiale', 1904, 4, 'GBR', '英仏協商', 'The Entente Cordiale',
      \ '千年の宿敵が手を結んだ', 'A thousand-year rivalry is set aside',
      \ {'rel': [['GBR', 'FRA', 40]]})
call s:h('bloody_sunday', 1905, 1, 'RUS', '血の日曜日', 'Bloody Sunday',
      \ '冬宮前で請願の群衆に発砲された', 'Troops fire on petitioners before the Winter Palace',
      \ {'rad': 20})
call s:h('portsmouth', 1905, 9, 'JAP', 'ポーツマス条約', 'The Treaty of Portsmouth',
      \ '勝利したが賠償金は得られず民衆は憤った', 'Victory without indemnity enrages the public',
      \ {'rad': 5, 'rel': [['JAP', 'RUS', 20]]})
call s:h('october_manifesto', 1905, 10, 'RUS', '十月詔書', 'The October Manifesto',
      \ 'ドゥーマ開設が約束され革命は退いた', 'A Duma is promised; the revolution recedes',
      \ {'rad': -15})

" ---- 1906-1915 ----
call s:h('dreadnought_launch', 1906, 2, 'GBR', 'ドレッドノート進水', 'HMS Dreadnought',
      \ '全巨砲艦の登場で各国海軍が旧式化した', 'The all-big-gun ship makes every navy obsolete',
      \ {'ships_pct': 0.1})
call s:h('sf_earthquake', 1906, 4, 'USA', 'サンフランシスコ地震', 'The San Francisco Earthquake',
      \ '地震と火災が都市を焼き尽くした', 'Quake and fire consume the city',
      \ {'treasury_weeks': -0.5, 'out_all': 0.97, 'duration': 26})
call s:h('anglo_russian', 1907, 8, 'GBR', '英露協商', 'The Anglo-Russian Entente',
      \ 'グレート・ゲームが終わり三国協商が完成した', 'The Great Game ends; the Triple Entente is complete',
      \ {'rel': [['GBR', 'RUS', 40]]})
call s:h('panic_1907', 1907, 10, 'USA', '1907年恐慌', 'The Panic of 1907',
      \ 'モルガンが私財で金融システムを救った', 'J.P. Morgan personally holds the system together',
      \ {'treasury_weeks': -0.6, 'out_all': 0.95, 'duration': 39})
call s:h('young_turks', 1908, 7, 'OTT', '青年トルコ革命', 'The Young Turk Revolution',
      \ '憲法復活を求める将校らが蜂起した', 'Officers rise to restore the constitution',
      \ {'rad': -12, 'research': 1.1, 'duration': 104})
call s:h('bosnian_crisis', 1908, 10, 'AUS', 'ボスニア併合危機', 'The Bosnian Crisis',
      \ 'ボスニア併合が露・セルビアを激昂させた', 'The annexation of Bosnia infuriates Russia',
      \ {'rel': [['AUS', 'RUS', -30], ['AUS', 'OTT', -20]]})
call s:h('portugal_republic', 1910, 10, 'POR', 'ポルトガル革命', 'The Portuguese Revolution',
      \ '王政が倒れ共和国が宣言された', 'The monarchy falls; a republic is proclaimed',
      \ {'rad': 15})
call s:h('korea_annexation_crisis', 1910, 8, 'JAP', '韓国併合条約', 'The Korea Annexation Treaty',
      \ '大韓帝国の主権が奪われた', 'Korean sovereignty is extinguished',
      \ {'rel': [['JAP', 'KOR', -60], ['JAP', 'QIN', -20]]})
call s:h('mexican_revolution', 1910, 11, 'MEX', 'メキシコ革命', 'The Mexican Revolution',
      \ 'ディアス独裁への蜂起が全国に広がった', 'Revolt against the Díaz dictatorship spreads',
      \ {'rad': 25, 'out_all': 0.9, 'duration': 156})
call s:h('xinhai', 1911, 10, 'QIN', '辛亥革命', 'The Xinhai Revolution',
      \ '武昌蜂起が各省に飛び火し王朝が揺らいだ', 'The Wuchang rising spreads province by province',
      \ {'rad': 30, 'out_all': 0.92, 'duration': 104})
call s:h('republic_china', 1912, 1, 'QIN', '中華民国の宣言', 'The Republic Proclaimed',
      \ '孫文が臨時大総統に就いた(清朝の命運は貴方次第だ)', 'Sun Yat-sen becomes provisional president — the dynasty''s fate is in your hands',
      \ {'rad': 10})
call s:h('titanic', 1912, 4, 'GBR', 'タイタニック沈没', 'The Sinking of the Titanic',
      \ '不沈艦の悲劇が世界を震わせた', 'The unsinkable ship goes down',
      \ {'rad': 2})
call s:h('first_balkan_war', 1912, 10, 'OTT', '第一次バルカン戦争', 'The First Balkan War',
      \ 'バルカン同盟が帝国の欧州領に襲いかかった', 'The Balkan League falls upon the empire''s European lands',
      \ {'out_all': 0.95, 'duration': 52, 'rad': 10, 'rel': [['OTT', 'GRE', -50]]})
call s:h('federal_reserve', 1913, 12, 'USA', '連邦準備制度', 'The Federal Reserve',
      \ '中央銀行制度がついに整った', 'America at last gets a central bank',
      \ {'rad': -2, 'build_cap': 1.05, 'duration': 104})
call s:h('sarajevo', 1914, 6, 'AUS', 'サラエボ事件', 'Assassination at Sarajevo',
      \ '皇位継承者夫妻が銃弾に斃れた', 'The heir and his wife are shot',
      \ {'rad': 5, 'rel': [['AUS', 'RUS', -40]]})
call s:h('ww1_aus', 1914, 7, 'AUS', '第一次世界大戦 — 墺の動員', 'The Great War — Austria Mobilizes',
      \ '最後通牒から総力戦が始まった', 'An ultimatum spirals into total war',
      \ {'regiments_pct': 0.3, 'out_all': 0.92, 'trade': 0.7, 'duration': 208})
call s:h('ww1_pru', 1914, 8, 'PRU', '第一次世界大戦 — 独の動員', 'The Great War — Germany Mobilizes',
      \ 'シュリーフェン・プランが発動された', 'The Schlieffen Plan is set in motion',
      \ {'regiments_pct': 0.3, 'out_all': 0.92, 'trade': 0.7, 'duration': 208})
call s:h('ww1_fra', 1914, 8, 'FRA', '第一次世界大戦 — 仏の動員', 'The Great War — France Mobilizes',
      \ '「聖なる団結」の下に国民が結集した', 'The nation unites in the Union sacrée',
      \ {'regiments_pct': 0.3, 'out_all': 0.92, 'trade': 0.7, 'duration': 208, 'rad': 5})
call s:h('ww1_gbr', 1914, 8, 'GBR', '第一次世界大戦 — 英の参戦', 'The Great War — Britain Joins',
      \ 'ベルギー侵犯が英国を戦争に引き込んだ', 'The violation of Belgium brings Britain in',
      \ {'regiments_pct': 0.3, 'out_all': 0.92, 'trade': 0.7, 'duration': 208, 'rad': 5})
call s:h('ww1_rus', 1914, 8, 'RUS', '第一次世界大戦 — 露の動員', 'The Great War — Russia Mobilizes',
      \ '蒸気ローラーが西へ動き出した', 'The steamroller lurches westward',
      \ {'regiments_pct': 0.3, 'out_all': 0.92, 'trade': 0.7, 'duration': 208, 'rad': 5})
call s:h('italy_enters_ww1', 1915, 5, 'SAR', 'イタリア参戦', 'Italy Enters the War',
      \ '「未回収のイタリア」を求めて参戦した', 'Italy joins for the terre irredente',
      \ {'regiments_pct': 0.2, 'out_all': 0.95, 'duration': 156})
call s:h('gallipoli', 1915, 4, 'OTT', 'ガリポリの戦い', 'The Gallipoli Campaign',
      \ '海峡を守り抜き連合軍を撃退した', 'The Straits hold; the Allies are repelled',
      \ {'rad': -5, 'regiments_pct': -0.05})

" ---- 1916-1925 ----
call s:h('verdun', 1916, 2, 'FRA', 'ヴェルダンの戦い', 'The Battle of Verdun',
      \ '「彼らを通すな」— 消耗戦の地獄が始まった', '"They shall not pass" — the mincing machine begins',
      \ {'workforce_pct': -0.01, 'rad': 8})
call s:h('somme', 1916, 7, 'GBR', 'ソンムの戦い', 'The Battle of the Somme',
      \ '初日だけで6万の死傷者が出た', 'Sixty thousand casualties on the first day alone',
      \ {'workforce_pct': -0.01, 'rad': 8})
call s:h('unrestricted_subs', 1917, 2, 'PRU', '無制限潜水艦作戦', 'Unrestricted Submarine Warfare',
      \ '中立国船舶への無警告攻撃が再開された', 'Neutral shipping is attacked without warning',
      \ {'rel': [['PRU', 'USA', -50]]})
call s:h('feb_revolution_rus', 1917, 3, 'RUS', '二月革命', 'The February Revolution',
      \ 'パンを求める暴動が帝政を倒した', 'Bread riots topple the Tsar',
      \ {'rad': 30})
call s:h('usa_enters_ww1', 1917, 4, 'USA', 'アメリカ参戦', 'America Enters the War',
      \ '「世界を民主主義にとって安全に」', '"The world must be made safe for democracy"',
      \ {'regiments_pct': 0.4, 'out_all': 1.05, 'duration': 104})
call s:h('october_revolution', 1917, 11, 'RUS', '十月革命', 'The October Revolution',
      \ 'ボリシェヴィキが冬宮を占拠した', 'The Bolsheviks storm the Winter Palace',
      \ {'rad': 20, 'out_all': 0.85, 'duration': 156})
call s:h('brest_litovsk', 1918, 3, 'RUS', 'ブレスト＝リトフスク条約', 'The Treaty of Brest-Litovsk',
      \ '広大な西部領土を手放して戦争から離脱した', 'Russia buys peace with vast western lands',
      \ {'treasury_weeks': -0.5, 'rad': 5})
call s:h('romanovs', 1918, 7, 'RUS', 'ロマノフ家の処刑', 'The Execution of the Romanovs',
      \ 'エカテリンブルクで王朝が終わった', 'The dynasty ends in an Ekaterinburg cellar',
      \ {'rad': 5})
call s:h('flu_usa', 1918, 9, 'USA', 'スペイン風邪', 'The Spanish Flu',
      \ '大流行が若者を最も多く奪った', 'The pandemic takes the young hardest',
      \ {'workforce_pct': -0.02})
call s:h('flu_gbr', 1918, 9, 'GBR', 'スペイン風邪', 'The Spanish Flu',
      \ '塹壕と都市を疫病が席巻した', 'The plague sweeps trench and city alike',
      \ {'workforce_pct': -0.02})
call s:h('flu_fra', 1918, 9, 'FRA', 'スペイン風邪', 'The Spanish Flu',
      \ '戦争末期の国土を疫病が襲った', 'The epidemic strikes a war-weary land',
      \ {'workforce_pct': -0.02})
call s:h('flu_pru', 1918, 9, 'PRU', 'スペイン風邪', 'The Spanish Flu',
      \ '封鎖下の疲弊した国民を疫病が襲った', 'Disease strikes a blockaded, exhausted people',
      \ {'workforce_pct': -0.02})
call s:h('flu_rus', 1918, 10, 'RUS', 'スペイン風邪', 'The Spanish Flu',
      \ '内戦の混乱に疫病が重なった', 'Plague piles onto civil war',
      \ {'workforce_pct': -0.02})
call s:h('flu_jap', 1918, 10, 'JAP', 'スペイン風邪', 'The Spanish Flu',
      \ '「流行性感冒」が列島を縦断した', 'The influenza runs the length of the archipelago',
      \ {'workforce_pct': -0.02})
call s:h('flu_qin', 1918, 10, 'QIN', 'スペイン風邪', 'The Spanish Flu',
      \ '大流行が街道沿いに広がった', 'The pandemic spreads along the great roads',
      \ {'workforce_pct': -0.02})
call s:h('german_revolution', 1918, 11, 'PRU', '休戦とドイツ革命', 'Armistice and Revolution',
      \ '皇帝は退位し、11時に銃声が止んだ', 'The Kaiser abdicates; the guns fall silent at the eleventh hour',
      \ {'rad': 25, 'regiments_pct': -0.4})
call s:h('austria_dissolution', 1918, 11, 'AUS', '帝国の解体', 'The Empire Dissolves',
      \ '諸民族が独立を宣言し二重帝国は消えた', 'The nationalities depart; the Dual Monarchy is no more',
      \ {'rad': 25, 'out_all': 0.9, 'duration': 104, 'workforce_pct': -0.02})
call s:h('versailles_fra', 1919, 6, 'FRA', 'ヴェルサイユ条約', 'The Treaty of Versailles',
      \ '鏡の間で勝利の講和が結ばれた', 'Peace is signed in the Hall of Mirrors',
      \ {'rad': -8, 'treasury_weeks': 0.5})
call s:h('versailles_pru', 1919, 6, 'PRU', 'ヴェルサイユの重荷', 'The Burden of Versailles',
      \ '戦争責任条項と巨額賠償が課された', 'War guilt and crushing reparations are imposed',
      \ {'treasury_weeks': -1.5, 'rad': 15, 'regiments_pct': -0.3})
call s:h('may_fourth', 1919, 5, 'QIN', '五四運動', 'The May Fourth Movement',
      \ '山東問題への抗議が新文化運動に発展した', 'Protest over Shandong becomes a new culture movement',
      \ {'rad': 10, 'research': 1.05, 'duration': 52})
call s:h('amritsar', 1919, 4, 'GBR', 'アムリットサル事件', 'The Amritsar Massacre',
      \ '広場の群衆への発砲が帝国の道義を砕いた', 'Firing on the crowd shatters imperial legitimacy',
      \ {'rad': 8})
call s:h('league_of_nations', 1920, 1, '', '国際連盟発足', 'The League of Nations',
      \ '「戦争を終わらせる」ための機構が生まれた', 'An institution to end war is born',
      \ {})
call s:h('us_suffrage', 1920, 8, 'USA', '憲法修正第19条', 'The Nineteenth Amendment',
      \ '女性参政権が憲法に刻まれた', 'Women''s suffrage enters the Constitution',
      \ {'rad': -10})
call s:h('nep', 1921, 3, 'RUS', 'ネップ(新経済政策)', 'The New Economic Policy',
      \ '市場の部分的復活で経済が息を吹き返した', 'A partial return to markets revives the economy',
      \ {'rad': -10, 'out_all': 1.1, 'duration': 156})
call s:h('march_on_rome', 1922, 10, 'SAR', 'ローマ進軍', 'The March on Rome',
      \ '黒シャツ隊が権力を握った', 'The Blackshirts seize power',
      \ {'rad': 15})
call s:h('kanto_earthquake', 1923, 9, 'JAP', '関東大震災', 'The Great Kantō Earthquake',
      \ '東京と横浜が地震と火災で壊滅した', 'Tokyo and Yokohama are devastated by quake and fire',
      \ {'workforce_pct': -0.02, 'treasury_weeks': -0.8, 'out_all': 0.9, 'duration': 52})
call s:h('hyperinflation', 1923, 11, 'PRU', 'ハイパーインフレーション', 'Hyperinflation',
      \ 'パン1個が数千億マルクになった', 'A loaf of bread costs billions of marks',
      \ {'treasury_weeks': -1.5, 'out_all': 0.9, 'duration': 52, 'rad': 15})
call s:h('first_labour_gov', 1924, 1, 'GBR', '初の労働党政権', 'The First Labour Government',
      \ 'マクドナルドが労働者階級初の首相となった', 'MacDonald forms the first Labour ministry',
      \ {'rad': -8})
call s:h('universal_suffrage_jp', 1925, 5, 'JAP', '普通選挙法', 'Universal Male Suffrage in Japan',
      \ '25歳以上の男子に選挙権が与えられた', 'All men over 25 gain the vote',
      \ {'rad': -8})

" ---- 1926-1935 ----
call s:h('general_strike', 1926, 5, 'GBR', 'ゼネラル・ストライキ', 'The General Strike',
      \ '炭鉱夫に連帯して全国がストに入った', 'The nation strikes in solidarity with the miners',
      \ {'out_all': 0.93, 'duration': 13, 'rad': 10})
call s:h('northern_expedition', 1926, 7, 'QIN', '北伐', 'The Northern Expedition',
      \ '国民革命軍が軍閥打倒に北上した', 'The National Revolutionary Army marches north',
      \ {'rad': 10, 'out_all': 0.95, 'duration': 52})
call s:h('lindbergh', 1927, 5, 'USA', 'リンドバーグの大西洋横断', 'Lindbergh Crosses the Atlantic',
      \ '33時間の単独飛行が世界を熱狂させた', 'Thirty-three hours alone over the ocean',
      \ {'rad': -3, 'research': 1.05, 'duration': 26})
call s:h('kellogg_briand', 1928, 8, 'FRA', '不戦条約', 'The Kellogg-Briand Pact',
      \ '戦争放棄が国際法に書き込まれた', 'War is renounced as an instrument of policy',
      \ {'rad': -3, 'rel': [['FRA', 'PRU', 20]]})
call s:h('wall_street_crash', 1929, 10, 'USA', 'ウォール街大暴落', 'The Wall Street Crash',
      \ '暗黒の木曜日 — 繁栄の20年代が終わった', 'Black Thursday ends the Roaring Twenties',
      \ {'treasury_weeks': -1.0, 'out_all': 0.8, 'duration': 156, 'rad': 15})
call s:h('depression_gbr', 1930, 3, 'GBR', '世界恐慌の波及', 'The Depression Reaches Britain',
      \ '輸出が崩れ失業者が街に溢れた', 'Exports collapse; the dole queues lengthen',
      \ {'out_all': 0.85, 'trade': 0.7, 'duration': 130, 'rad': 10})
call s:h('depression_pru', 1930, 3, 'PRU', '世界恐慌の波及', 'The Depression Reaches Germany',
      \ '失業600万 — 共和国の土台が軋んだ', 'Six million unemployed strain the republic',
      \ {'out_all': 0.85, 'trade': 0.7, 'duration': 130, 'rad': 15})
call s:h('depression_fra', 1930, 9, 'FRA', '世界恐慌の波及', 'The Depression Reaches France',
      \ '遅れて来た不況が長く居座った', 'The slump arrives late and stays long',
      \ {'out_all': 0.88, 'trade': 0.7, 'duration': 130, 'rad': 8})
call s:h('depression_jap', 1930, 1, 'JAP', '昭和恐慌', 'The Shōwa Depression',
      \ '生糸価格の暴落が農村を直撃した', 'The silk crash devastates the villages',
      \ {'out_all': 0.85, 'trade': 0.7, 'duration': 130, 'rad': 12})
call s:h('coffee_crash', 1930, 10, 'BRA', 'コーヒー恐慌', 'The Coffee Crash',
      \ '価格維持のためコーヒーが海に捨てられた', 'Coffee is dumped into the sea to prop up prices',
      \ {'treasury_weeks': -0.8, 'trade': 0.7, 'duration': 104, 'rad': 10})
call s:h('salt_march', 1930, 3, 'GBR', '塩の行進', 'The Salt March',
      \ 'ガンディーが海へ歩き、帝国の専売に挑んだ', 'Gandhi walks to the sea against the salt monopoly',
      \ {'rad': 8})
call s:h('mukden_incident', 1931, 9, 'JAP', '満洲事変', 'The Mukden Incident',
      \ '柳条湖の爆破を口実に関東軍が動いた', 'A staged explosion launches the Kwantung Army',
      \ {'regiments_pct': 0.1, 'rad': 3, 'rel': [['JAP', 'QIN', -50]]})
call s:h('gold_standard_exit', 1931, 9, 'GBR', '金本位制離脱', 'Britain Leaves Gold',
      \ 'ポンドの金兌換が停止された', 'Sterling''s link to gold is cut',
      \ {'treasury_weeks': -0.3, 'trade': 0.9, 'duration': 52})
call s:h('may_15_incident', 1932, 5, 'JAP', '五・一五事件', 'The May 15 Incident',
      \ '海軍青年将校が首相を殺害した', 'Young naval officers murder the premier',
      \ {'rad': 10})
call s:h('hitler_power', 1933, 1, 'PRU', 'ヒトラー政権掌握', 'Hitler Comes to Power',
      \ '首相任命と全権委任法で独裁が確立した', 'Chancellorship and the Enabling Act cement a dictatorship',
      \ {'regiments_pct': 0.2, 'out_all': 1.05, 'duration': 156, 'rad': -5})
call s:h('new_deal', 1933, 3, 'USA', 'ニューディール', 'The New Deal',
      \ '「恐れるべきは恐怖そのもの」— 復興計画が始動した', '"Nothing to fear but fear itself" — recovery begins',
      \ {'build_cap': 1.15, 'duration': 156, 'rad': -10})
call s:h('japan_leaves_league', 1933, 3, 'JAP', '国際連盟脱退', 'Japan Leaves the League',
      \ '松岡代表が総会から退場した', 'Matsuoka walks out of the Assembly',
      \ {'rel': [['JAP', 'GBR', -20], ['JAP', 'USA', -20]]})
call s:h('kirov_purges', 1934, 12, 'RUS', 'キーロフ暗殺と大粛清', 'The Kirov Murder and the Purges',
      \ '暗殺を口実に粛清の歯車が回り始めた', 'An assassination sets the purge machinery turning',
      \ {'rad': -10, 'research': 0.9, 'duration': 156, 'regiments_pct': -0.1})
call s:h('italy_ethiopia', 1935, 10, 'SAR', 'エチオピア侵攻', 'The Invasion of Ethiopia',
      \ '国際連盟の制裁は機能しなかった', 'League sanctions prove toothless',
      \ {'rel': [['SAR', 'ETH', -70]]})
call s:h('german_rearmament', 1935, 3, 'PRU', '再軍備宣言', 'Rearmament Declared',
      \ '徴兵制復活とヴェルサイユ体制の公然たる破棄', 'Conscription returns; Versailles is openly defied',
      \ {'regiments_pct': 0.3, 'ships_pct': 0.2})

" ---- 1936-1945 ----
call s:h('spanish_civil_war', 1936, 7, 'SPA', 'スペイン内戦', 'The Spanish Civil War',
      \ '将軍たちの蜂起が国を二つに裂いた', 'The generals'' rising tears the country in two',
      \ {'out_all': 0.8, 'duration': 156, 'rad': 25, 'workforce_pct': -0.02})
call s:h('feb_26_incident', 1936, 2, 'JAP', '二・二六事件', 'The February 26 Incident',
      \ '雪の帝都を青年将校が占拠した', 'Young officers seize snowbound Tokyo',
      \ {'rad': 10})
call s:h('marco_polo_bridge', 1937, 7, 'JAP', '盧溝橋事件', 'The Marco Polo Bridge Incident',
      \ '北京郊外の銃声が全面戦争に発展した', 'Shots outside Peking spiral into full war',
      \ {'rel': [['JAP', 'QIN', -70]]})
call s:h('nanjing', 1937, 12, 'QIN', '南京の陥落', 'The Fall of Nanjing',
      \ '首都陥落と暴虐が世界を戦慄させた', 'The capital falls amid atrocities that shock the world',
      \ {'rad': 15, 'workforce_pct': -0.01})
call s:h('anschluss_crisis', 1938, 3, 'AUS', 'アンシュルス危機', 'The Anschluss Crisis',
      \ '独国境に軍が集結し併合圧力が強まった', 'German troops mass on the border; annexation looms',
      \ {'rad': 15, 'rel': [['PRU', 'AUS', -50]]})
call s:h('munich', 1938, 9, 'GBR', 'ミュンヘン協定', 'The Munich Agreement',
      \ '「我々の時代の平和」— 宥和の頂点', '"Peace for our time" — appeasement''s high-water mark',
      \ {'rad': -5, 'rel': [['GBR', 'PRU', 10]]})
call s:h('kristallnacht', 1938, 11, 'PRU', '水晶の夜', 'Kristallnacht',
      \ '組織的な迫害が公然と始まった', 'Organized persecution begins in the open',
      \ {'rad': 5, 'workforce_pct': -0.005})
call s:h('molotov_ribbentrop', 1939, 8, 'PRU', '独ソ不可侵条約', 'The Molotov-Ribbentrop Pact',
      \ '不倶戴天の両国が秘密議定書で手を結んだ', 'Sworn enemies shake hands over a secret protocol',
      \ {'rel': [['PRU', 'RUS', 40]]})
call s:h('ww2_pru', 1939, 9, 'PRU', '第二次世界大戦勃発', 'The Second World War Begins',
      \ 'ポーランド侵攻が新たな大戦の幕を開けた', 'The invasion of Poland opens a new world war',
      \ {'regiments_pct': 0.4, 'out_all': 0.95, 'trade': 0.6, 'duration': 260})
call s:h('ww2_gbr', 1939, 9, 'GBR', '英国の宣戦', 'Britain Declares War',
      \ 'チェンバレンが沈痛なラジオ放送で宣戦を告げた', 'Chamberlain''s somber broadcast announces war',
      \ {'regiments_pct': 0.3, 'trade': 0.7, 'duration': 260, 'rad': 5})
call s:h('ww2_fra', 1939, 9, 'FRA', 'フランスの宣戦', 'France Declares War',
      \ '再び独仏が戦火を交えることになった', 'France and Germany are at war once more',
      \ {'regiments_pct': 0.3, 'trade': 0.7, 'duration': 260, 'rad': 5})
call s:h('fall_of_paris', 1940, 6, 'FRA', 'パリ陥落', 'The Fall of Paris',
      \ '6週間で首都が陥ち、国土は分断された', 'The capital falls in six weeks; the country is split',
      \ {'rad': 25, 'out_all': 0.85, 'duration': 130, 'regiments_pct': -0.3})
call s:h('battle_of_britain', 1940, 9, 'GBR', 'バトル・オブ・ブリテン', 'The Battle of Britain',
      \ '「かくも多くの人々が、かくも少数に負う」', '"Never was so much owed by so many to so few"',
      \ {'rad': -10, 'out_all': 0.95, 'duration': 52})
call s:h('barbarossa', 1941, 6, 'RUS', 'バルバロッサ作戦', 'Operation Barbarossa',
      \ '史上最大の陸戦が祖国を襲った', 'The largest land invasion in history strikes the motherland',
      \ {'regiments_pct': 0.5, 'out_all': 0.85, 'duration': 208,
      \  'workforce_pct': -0.03, 'rad': 10, 'rel': [['PRU', 'RUS', -80]]})
call s:h('pearl_harbor', 1941, 12, 'JAP', '真珠湾攻撃', 'The Attack on Pearl Harbor',
      \ '機動部隊がオアフを奇襲した', 'The carrier fleet strikes Oahu',
      \ {'ships_pct': 0.1, 'rel': [['JAP', 'USA', -80], ['JAP', 'GBR', -60]]})
call s:h('usa_enters_ww2', 1941, 12, 'USA', 'アメリカ参戦', 'America Enters the War',
      \ '「屈辱の日」— 民主主義の兵器廠が起動した', 'The "date which will live in infamy" wakes the arsenal of democracy',
      \ {'regiments_pct': 0.5, 'out_all': 1.1, 'duration': 208})
call s:h('midway_usa', 1942, 6, 'USA', 'ミッドウェー海戦', 'The Battle of Midway',
      \ '5分間で太平洋の潮目が変わった', 'Five minutes turn the tide of the Pacific',
      \ {'ships_pct': 0.1})
call s:h('midway_jap', 1942, 6, 'JAP', 'ミッドウェーの敗北', 'Defeat at Midway',
      \ '正規空母4隻を一挙に失った', 'Four fleet carriers are lost in a single day',
      \ {'ships_pct': -0.25, 'rad': 5})
call s:h('stalingrad', 1943, 2, 'RUS', 'スターリングラードの勝利', 'Victory at Stalingrad',
      \ '第6軍の降伏で戦争の流れが逆転した', 'The Sixth Army''s surrender reverses the war',
      \ {'rad': -10, 'regiments_pct': 0.1})
call s:h('dday', 1944, 6, 'GBR', 'ノルマンディー上陸', 'D-Day',
      \ '史上最大の上陸作戦が第二戦線を開いた', 'The greatest amphibious operation opens the second front',
      \ {'rad': -5})
call s:h('bretton_woods', 1944, 7, 'USA', 'ブレトンウッズ会議', 'The Bretton Woods Conference',
      \ '戦後世界経済の設計図が描かれた', 'The postwar economic order is designed',
      \ {'trade': 1.2, 'duration': 260})
call s:h('yalta', 1945, 2, '', 'ヤルタ会談', 'The Yalta Conference',
      \ '三巨頭が戦後世界を分割した', 'The Big Three carve up the postwar world',
      \ {})
call s:h('germany_defeated', 1945, 5, 'PRU', '欧州戦線の終結', 'Defeat in Europe',
      \ '首都は瓦礫となり無条件降伏に至った', 'The capital in ruins, surrender is unconditional',
      \ {'out_all': 0.7, 'duration': 104, 'rad': 30,
      \  'regiments_pct': -0.6, 'treasury_weeks': -1.0})
call s:h('japan_surrenders', 1945, 8, 'JAP', '原爆投下と終戦', 'The Atomic Bombs and Surrender',
      \ '広島・長崎への原爆投下、そして玉音放送', 'Hiroshima, Nagasaki, and the Emperor''s broadcast',
      \ {'workforce_pct': -0.03, 'out_all': 0.7, 'duration': 104,
      \  'rad': 25, 'regiments_pct': -0.6, 'ships_pct': -0.7})
call s:h('united_nations', 1945, 10, '', '国際連合発足', 'The United Nations',
      \ 'サンフランシスコで新たな国際秩序が生まれた', 'A new world order is founded at San Francisco',
      \ {})

let g:vimtoria_data_history.order = s:order
let g:vimtoria_data_history.events = s:events
delfunction s:h
