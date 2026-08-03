" vimtoria.vim - Vim で遊ぶ経済グランドストラテジー
" エントリポイント。実装はすべて autoload/ に置き、起動コストを最小にする。

if exists('g:loaded_vimtoria')
  finish
endif
let g:loaded_vimtoria = 1

command! Vimtoria call vimtoria#core#start()
