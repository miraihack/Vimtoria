#!/bin/sh
# Vimtoria ヘッドレステストランナー
# Neovim と(本物の)Vim の両方が見つかればそれぞれで実行する。
set -u
cd "$(dirname "$0")/.." || exit 1

fail=0
ran=0

check_result() {
  editor="$1"
  if [ ! -f test/results.txt ]; then
    echo "[$editor] NG: テストが results.txt を出力しなかった"
    fail=1
  elif [ "$(head -1 test/results.txt)" = "OK" ]; then
    echo "[$editor] OK"
  else
    echo "[$editor] NG:"
    sed 's/^/    /' test/results.txt
    fail=1
  fi
  rm -f test/results.txt
}

if command -v nvim >/dev/null 2>&1; then
  rm -f test/results.txt
  nvim --headless -u NONE -i NONE -n \
    --cmd "set rtp^=$PWD" -S test/test_core.vim >/dev/null 2>&1
  check_result nvim
  ran=1
fi

# `vim` が Neovim のエイリアスでないことを確認してから実行
if command -v vim >/dev/null 2>&1 && vim --version 2>/dev/null | head -1 | grep -q '^VIM'; then
  rm -f test/results.txt
  vim -es -N -u NONE -i NONE \
    --cmd "set rtp^=$PWD" -S test/test_core.vim >/dev/null 2>&1
  check_result vim
  ran=1
fi

if [ "$ran" = 0 ]; then
  echo "NG: vim / nvim が見つかりません"
  exit 1
fi
exit "$fail"
