# Vimtoria

Vimscript のみで動く、Paradox「Victoria 3」風の経済グランドストラテジー。
舞台は **1836年の地球**(34カ国・52州)。Vim 8.2+ / Neovim 両対応。外部依存なし。

開発計画は [PLANNING.md](PLANNING.md) を参照。現在は **M0(骨格)** まで実装済み。

## 起動

プラグインとして runtimepath に追加するか、リポジトリ内で:

```sh
nvim --cmd "set rtp^=$PWD" +Vimtoria
```

プレイヤー国は既定で日本(江戸幕府)。変更する場合は起動前に:

```vim
let g:vimtoria_player_country = 'GBR'  " 例: イギリス
```

## キー操作

| キー | 動作 |
|---|---|
| `Space` | 停止 / 再開(起動時は停止中) |
| `1`〜`4` | ゲーム速度(1 ティック = ゲーム内 1 週間) |
| `h j k l` | マップ上で州を選択 |
| `Enter` | 選択中の州の詳細 |
| `gm` `gb` `gc` `gt` `gp` | 市場 / 予算 / 建設 / 技術 / Pop 画面(M2 以降で実装) |
| `q` | サブ画面からマップへ戻る。マップ上では終了(確認あり) |

## テスト

```sh
test/run.sh
```

Neovim と(本物の)Vim の両方が見つかれば、それぞれでヘッドレス実行される。

## 構成

```
plugin/vimtoria.vim          :Vimtoria コマンド定義のみ
autoload/vimtoria/core.vim   ゲームループ・時間・状態ストア
autoload/vimtoria/ui.vim     バッファ管理・描画・キーマップ
autoload/vimtoria/map.vim    州選択ナビゲーション
autoload/vimtoria/data.vim   data/ のローダ(州座標の自動計算)
autoload/vimtoria/screens/   各画面の描画(状態 → 行リストの純関数)
data/map.vim                 1836年の世界地図・国・州の定義(Mod ポイント)
syntax/vimtoria.vim          画面ハイライト
test/                        ヘッドレステスト
```
