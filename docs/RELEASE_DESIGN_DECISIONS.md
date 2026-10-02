# リリース前デザインのオーナー決定

## #233 広幅時の主操作位置 — 2026-10-02 決定

今回は画面全体の下部操作バーを追加しない。本の表紙直下・家庭カード内の「借りる/返す」を維持する。
オーナーは、対象との対応を保ち、全体バーに伴う対象選択や誤操作対策を今回の変更へ持ち込まない提案に同意した。

- 各本や家庭の近くに操作があり、どの対象への操作かを判断できる。
- 画面全体の下部バーには対象選択状態・選択解除・誤操作防止を別途設計する必要がある。
- #231の幅に応じた操作群の折り畳みを採用する。
- 大文字で窮屈になる貸出行は、その行の中で操作を下へ回す。全体バー移行とは別の可読性改善。
- 全体バーを再検討するときは、対象画面と選択方式を限定した別Issueで比較する。

## PRの分割方針

オーナーへの説明どおり1本の巨大PRにはしない。依存する差分は順番にレビューし、本棚の余白とPrivacyも別PRにする。
各PRはdraftで作成し、下記の依存baseで差分を最小化する。最終SHA・検証結果・未検証事項はPR本文を正とする。

| 最小単位 | ブランチ | 比較のbase |
| --- | --- | --- |
| #228 色方針 | codex/release-228-color-policy | main |
| #227 app/widget Accent | codex/release-227-accent | codex/release-228-color-policy |
| #229 semantic colors | codex/release-229-semantic-colors | codex/release-227-accent |
| #230 color catalog | codex/release-230-color-catalog | codex/release-229-semantic-colors |
| 本棚余白/タイトルと見本 | codex/release-shelf-spacing | codex/release-230-color-catalog |
| #231 実幅で操作群切替・Tab | codex/release-231-adaptive-controls | codex/release-shelf-spacing |
| #232 本IDで位置保持 | codex/release-232-scroll-state | codex/release-231-adaptive-controls |
| #234 18 Preview/幅切替ホスト | codex/release-234-preview-matrix | codex/release-232-scroll-state |
| 貸出行のAX可読性 | codex/release-loan-accessibility | codex/release-234-preview-matrix |
| #233 オーナー決定 | codex/release-233-action-position | codex/release-loan-accessibility |
| Privacy同意・撤回 | codex/release-privacy-consent | codex/release-233-action-position |

本棚の初期見本は本棚余白・タイトル検証の足場として本棚PRに含める。#234の完了対象となる18ケースは後の専用PRに分離する。
最初はstacked baseで重複差分を避け、先行PRを取り込んだ後に次のbaseをmainへ更新できる。各PRで比較baseと依存PRを明示する。
ブランチを分けるだけで独立レビューを終えたことにはしない。PR公開前に最終差分へ必要なレビューと検証を行う。

## スクリーンショット

UI変更PRへのサンプル画像添付はオーナー承認済み。最新実画面を目視したものを使い、before/afterの変更範囲・ライト/ダーク・幅・Dynamic Typeをキャプションへ書く。
Xcode MCPのPreview取得ツールは2026-10-02のこのセッションでは見つからなかった。18 Previewはコード/ビルド確認であり、Previewレンダリング画像と呼ばない。代わりに専用iPadOS 26.5シミュレータとDEBUGカタログの実画面を使う。
