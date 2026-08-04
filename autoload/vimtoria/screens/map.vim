scriptencoding utf-8
" screens/map.vim - 世界地図画面
"
" 州は略称タグではなく州名(言語設定に応じて日本語/英語)で表示する。
" テンプレートの {TAG} はラベルのアンカー位置で、州名が 5 桁より広い場合は
" 右隣の地形に重ねて描く。同じ行でラベル同士が重なる場合は右へ詰める。
" 描画時に各ラベルの位置(バイト範囲と表示幅範囲)を記録し、
" <Enter>(カーソル位置)とマウスクリックの州解決に使う。

" row -> [[sid, byte_start, byte_end, disp_start, disp_end], ...]
" 位置は 1 周目のもの。バッファには世界が 2 周分並ぶ(ループスクロール用)
let s:labels = {}
let s:lines = []
let s:row_bytes = []
let s:ready = 0

function! vimtoria#screens#map#render(st) abort
  let l:data = vimtoria#data#map()
  let l:sel = a:st.selected
  let s:labels = {}
  let s:lines = []
  let s:row_bytes = []
  let s:ready = 1
  let l:lines = []
  let l:row = 0
  for l:tmpl in l:data.template
    let l:line = has_key(l:data.row_tags, l:row)
          \ ? s:layout(l:data, l:row, l:tmpl, l:sel) : l:tmpl
    " 世界を 2 周分並べる。横スクロールが端に達したら ui.vim が
    " 見た目の同じ反対側のコピーへ巻き戻し、地球を一周できる
    call add(l:lines, l:line . l:line)
    call add(s:lines, l:line)
    call add(s:row_bytes, len(l:line))
    let l:row += 1
  endfor
  call add(l:lines, '')
  " フッタ(選択情報・メッセージ・歴史イベントのログ)は、右へスクロール
  " していても読めるよう、現在の水平スクロール位置まで字下げして描く
  let l:ind = repeat(' ', vimtoria#ui#map_leftcol())
  let l:stt = l:data.states[l:sel]
  let l:ocid = a:st.world.owner[l:sel]
  let l:country = l:data.countries[l:ocid]
  let l:own = l:ocid ==# a:st.country ? vimtoria#i18n#t('map_own') : ''
  call add(l:lines, l:ind . printf(vimtoria#i18n#t('map_selected'),
        \ vimtoria#i18n#name(l:stt), vimtoria#i18n#name(l:country), l:own,
        \ vimtoria#i18n#pop(l:stt.pop)))
  let l:snames = []
  for l:sid in a:st.world.country_states[l:ocid]
    call add(l:snames, vimtoria#i18n#name(l:data.states[l:sid]))
  endfor
  call add(l:lines, l:ind . printf(vimtoria#i18n#t('map_states_of'),
        \ vimtoria#i18n#name(l:country),
        \ join(l:snames, vimtoria#i18n#t('list_sep'))))
  if !empty(a:st.msg)
    call add(l:lines, l:ind . '  » ' . a:st.msg)
  endif
  " 最近の出来事(直近3件)。[-3:] は要素数が3未満だと空になるので使わない
  if !empty(a:st.world.eventlog)
    call add(l:lines, '')
    call add(l:lines, l:ind . vimtoria#i18n#t('map_recent'))
    let l:log = a:st.world.eventlog
    for l:e in l:log[len(l:log) > 3 ? len(l:log) - 3 : 0 :]
      call add(l:lines, l:ind . '  ' . l:e)
    endfor
  endif
  call add(l:lines, '')
  call add(l:lines, l:ind . printf(vimtoria#i18n#t('map_world'),
        \ len(l:data.countries), len(l:data.states)))
  return l:lines
endfunction

" 1 行分のラベル配置。テンプレートは ASCII なので、ラベル挿入前の
" バイト位置 = 表示幅位置として扱える。
function! s:layout(data, row, tmpl, sel) abort
  let l:base = substitute(a:tmpl, '{\u\{3}}', '     ', 'g')
  let l:out = ''
  let l:pos = 0
  let l:entries = []
  for [l:col, l:sid] in a:data.row_tags[a:row]
    let l:name = vimtoria#i18n#name(a:data.states[l:sid])
    let l:label = l:sid ==# a:sel ? '[' . l:name . ']' : l:name
    let l:w = strdisplaywidth(l:label)
    " 直前のラベルとは最低 1 桁空ける(名前の切れ目を読めるように)
    let l:min = empty(l:entries) ? l:pos : l:pos + 1
    let l:start = l:col < l:min ? l:min : l:col
    let l:out .= strpart(l:base, l:pos, l:start - l:pos)
    let l:bs = len(l:out)
    let l:out .= l:label
    call add(l:entries, [l:sid, l:bs, len(l:out), l:start, l:start + l:w])
    let l:pos = l:start + l:w
  endfor
  let l:out .= strpart(l:base, l:pos)
  let s:labels[a:row] = l:entries
  return l:out
endfunction

" ラベル位置がまだ無ければ現在の状態で計算しておく
" (クリック/Enter は描画後にしか起きないが、ヘッドレステスト用の保険)
function! s:ensure() abort
  if !s:ready
    call vimtoria#screens#map#render(vimtoria#core#state())
  endif
endfunction

" テスト用: 現在のラベル位置テーブルを返す
function! vimtoria#screens#map#labels() abort
  call s:ensure()
  return s:labels
endfunction

" 1 周分の行のバイト長(2 周目の座標の正規化・変換に使う)
function! vimtoria#screens#map#row_bytes(row) abort
  call s:ensure()
  return a:row >= 0 && a:row < len(s:row_bytes) ? s:row_bytes[a:row] : 0
endfunction

" 2 周分に複製された行のバイト位置を 1 周目の位置に正規化する
function! s:norm(row, col) abort
  let l:rb = a:row >= 0 && a:row < len(s:row_bytes) ? s:row_bytes[a:row] : 0
  return l:rb > 0 && a:col >= l:rb ? a:col - l:rb : a:col
endfunction

" 指定した州のラベル位置 [row, byte_start, byte_end, disp_start, disp_end]。
" 未配置なら []。概況ポップアップの位置決めに使う
function! vimtoria#screens#map#label_pos(sid) abort
  call s:ensure()
  for [l:r, l:entries] in items(s:labels)
    for l:e in l:entries
      if l:e[0] ==# a:sid
        return [str2nr(l:r), l:e[1], l:e[2], l:e[3], l:e[4]]
      endif
    endfor
  endfor
  return []
endfunction

" ラベル直上の判定のみ(カーソル位置の <Enter> 用)。col はバイト位置
" (2 周目のコピー上の位置でもよい)
function! vimtoria#screens#map#hit(row, col) abort
  call s:ensure()
  let l:col = s:norm(a:row, a:col)
  for l:e in get(s:labels, a:row, [])
    if l:col >= l:e[1] && l:col < l:e[2]
      return l:e[0]
    endif
  endfor
  return ''
endfunction

" クリック用の州解決。ラベル直上ならその州、近傍なら最寄りのラベル、
" 遠洋なら空文字。col はバイト位置(2 周目のコピー上でもよい)
function! vimtoria#screens#map#resolve(row, col) abort
  call s:ensure()
  let l:hit = vimtoria#screens#map#hit(a:row, a:col)
  if !empty(l:hit)
    return l:hit
  endif
  let l:col = s:norm(a:row, a:col)
  " 近傍判定はバイトでなく表示幅の座標で行う(ラベルは全角を含むため)
  let l:disp = a:row >= 0 && a:row < len(s:lines)
        \ ? strdisplaywidth(strpart(s:lines[a:row], 0, l:col)) : l:col
  let l:best = ''
  let l:best_score = 16
  for [l:r, l:entries] in items(s:labels)
    let l:dy = abs(a:row - str2nr(l:r))
    if l:dy > 4
      continue
    endif
    for l:e in l:entries
      let l:dx = l:disp < l:e[3] ? l:e[3] - l:disp
            \ : (l:disp >= l:e[4] ? l:disp - l:e[4] + 1 : 0)
      let l:score = l:dx + 3 * l:dy
      if l:score < l:best_score
        let l:best_score = l:score
        let l:best = l:e[0]
      endif
    endfor
  endfor
  return l:best
endfunction
