scriptencoding utf-8
" syntax/vimtoria.vim - ゲーム画面のハイライト
" 国別の州タグ色はデータ駆動のため ui.vim の matchadd() が担当し、
" ここでは固定要素(ヘッダ・海・選択枠)とハイライトグループ定義のみ行う。

if exists('b:current_syntax')
  finish
endif

syntax match VimtoriaHeaderLine /\%1l.*/
syntax match VimtoriaHintLine /\%2l.*/
syntax match VimtoriaSea /\~/

hi def link VimtoriaHeaderLine Title
hi def link VimtoriaHintLine Comment
hi def VimtoriaSea ctermfg=6 guifg=#3f8fbf

" 選択中の州 [TAG](matchadd が優先度 20 で適用)
hi def VimtoriaSelected cterm=bold,reverse gui=bold,reverse

" 国色(Country1 = プレイヤー既定国の日本)
hi def VimtoriaCountry1 cterm=bold ctermfg=2 gui=bold guifg=#7bc96f
hi def VimtoriaCountry2 ctermfg=1 guifg=#e06c75
hi def VimtoriaCountry3 ctermfg=3 guifg=#e5c07b
hi def VimtoriaCountry4 ctermfg=5 guifg=#c678dd
hi def VimtoriaCountry5 ctermfg=4 guifg=#61afef
hi def VimtoriaCountry6 ctermfg=6 guifg=#56b6c2
hi def VimtoriaCountry7 ctermfg=7 guifg=#abb2bf
hi def VimtoriaCountry8 ctermfg=9 guifg=#d19a66

let b:current_syntax = 'vimtoria'
