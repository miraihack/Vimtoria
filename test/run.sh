#!/bin/sh
# Vimtoria ヘッドレステストランナー
# test/test_*.vim を、Neovim と(本物の)Vim の両方が見つかればそれぞれで実行する。
set -u
cd "$(dirname "$0")/.." || exit 1

fail=0
ran=0

check_result() {
  label="$1"
  if [ ! -f test/results.txt ]; then
    echo "[$label] NG: テストが results.txt を出力しなかった"
    fail=1
  elif [ "$(head -1 test/results.txt)" = "OK" ]; then
    extra=$(sed -n '2p' test/results.txt)
    echo "[$label] OK${extra:+ ($extra)}"
  else
    echo "[$label] NG:"
    sed 's/^/    /' test/results.txt
    fail=1
  fi
  rm -f test/results.txt
}

have_nvim=0
have_vim=0
command -v nvim >/dev/null 2>&1 && have_nvim=1
# `vim` が Neovim のエイリアスでないことを確認
if command -v vim >/dev/null 2>&1 && vim --version 2>/dev/null | head -1 | grep -q '^VIM'; then
  have_vim=1
fi

for t in test/test_*.vim; do
  if [ "$have_nvim" = 1 ]; then
    rm -f test/results.txt
    nvim --headless -u NONE -i NONE -n \
      --cmd "set rtp^=$PWD" -S "$t" >/dev/null 2>&1
    check_result "nvim:$(basename "$t" .vim)"
    ran=1
  fi
  if [ "$have_vim" = 1 ]; then
    rm -f test/results.txt
    vim -es -N -u NONE -i NONE \
      --cmd "set rtp^=$PWD" -S "$t" >/dev/null 2>&1
    check_result "vim:$(basename "$t" .vim)"
    ran=1
  fi
done

if [ "$ran" = 0 ]; then
  echo "NG: vim / nvim が見つかりません"
  exit 1
fi
exit "$fail"
