scriptencoding utf-8
" screens/todo.vim - 未実装画面のプレースホルダ
" M2 以降で screens/ 配下の個別ファイルに置き換わる。

let s:MILESTONE = {
      \ 'market': 'M2', 'budget': 'M2', 'construction': 'M2',
      \ 'tech': 'M3', 'pops': 'M3',
      \ }

function! vimtoria#screens#todo#render(st) abort
  let l:name = vimtoria#ui#screen_name(a:st.screen)
  return [
        \ printf('  ━━ %s ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', l:name),
        \ '',
        \ printf('    この画面は %s で実装予定です。',
        \        get(s:MILESTONE, a:st.screen, '将来')),
        \ '',
        \ '    q でマップへ戻れます。時間はこの画面でも進みます。',
        \ ]
endfunction
