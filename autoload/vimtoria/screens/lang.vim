scriptencoding utf-8
" screens/lang.vim - 起動時の言語選択画面(この画面だけは常に二言語併記)

let s:CHOICES = [['ja', '日本語'], ['en', 'English']]

function! vimtoria#screens#lang#choices() abort
  return s:CHOICES
endfunction

function! vimtoria#screens#lang#render(st) abort
  let l:lines = []
  call add(l:lines, '  ━━ Language / 言語 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
  call add(l:lines, '')
  call add(l:lines, '  Choose with j/k, confirm with Enter / j/k で選び Enter で決定')
  call add(l:lines, '')
  let l:i = 0
  for [l:code, l:label] in s:CHOICES
    call add(l:lines, printf('  %s %s',
          \ l:i == a:st.menu_idx ? '>' : ' ', l:label))
    let l:i += 1
  endfor
  call add(l:lines, '')
  call add(l:lines, '  (let g:vimtoria_lang = ''ja''/''en'' でこの画面をスキップできます)')
  call add(l:lines, '  (set g:vimtoria_lang = ''ja''/''en'' to skip this screen)')
  return l:lines
endfunction
