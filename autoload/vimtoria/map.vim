scriptencoding utf-8
" map.vim - マップ上の州選択ナビゲーション

" from の州から dir (h/j/k/l) 方向にある最も近い州を返す。
" 行と桁で解像度が違う(マップは横長)ため、軸外のずれには重い罰則を掛ける。
function! vimtoria#map#neighbor(from, dir) abort
  let l:states = vimtoria#data#map().states
  let l:cur = l:states[a:from]
  let l:best = a:from
  let l:best_score = 999999
  for [l:id, l:stt] in items(l:states)
    if l:id ==# a:from
      continue
    endif
    let l:dx = l:stt.col - l:cur.col
    let l:dy = l:stt.row - l:cur.row
    if a:dir ==# 'h' && l:dx >= 0 | continue | endif
    if a:dir ==# 'l' && l:dx <= 0 | continue | endif
    if a:dir ==# 'k' && l:dy >= 0 | continue | endif
    if a:dir ==# 'j' && l:dy <= 0 | continue | endif
    if a:dir ==# 'h' || a:dir ==# 'l'
      let l:score = abs(l:dx) + 4 * abs(l:dy)
    else
      let l:score = 4 * abs(l:dy) + abs(l:dx)
    endif
    if l:score < l:best_score
      let l:best_score = l:score
      let l:best = l:id
    endif
  endfor
  return l:best
endfunction
