# Vimtoria

Vimscript のみで動く、Paradox「Victoria 3」風の経済グランドストラテジー。
舞台は **1836年の地球**(34カ国・52州)。Vim 8.2+ / Neovim 両対応。外部依存なし。

開発計画は [PLANNING.md](PLANNING.md) を参照。現在は **M3(深化)** まで実装済み:
34 の国民市場で毎週、建物の生産・Pop の需要・需給価格・賃金・雇用調整が回る。
建設画面(`gc`)で自国の州に建物を建て(信用限度まで国債で赤字建設も可能)、
予算画面(`gb`)で税率を調整し、技術画面(`gt`)で研究を進める。
AI 国も毎週研究と建設を行い、失業者は求人のある州へ移動していく。
生活水準が上がると Pop の消費も増える。

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
| `h j k l` | マップ上で州を選択(建設・技術画面では `j k` がメニュー選択) |
| `Enter` | マップ: 州の詳細 / 建設画面: キューへ追加 / 技術画面: 研究開始 |
| `gm` `gb` `gc` `gt` `gp` | 市場 / 予算 / 建設 / 技術 / Pop 画面 |
| `x` | 建設画面: キュー末尾を取消 |
| `+` `-` | 予算画面: 税率を変更 |
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
