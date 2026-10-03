# 表示設定Menuの検証（2026-10-03）

iPad横向きの並び順・表示形式を、縦向きと同じ2つのMenuにまとめ、右端に配置する変更。
かな群と設定群は24ptの間隔を設け、狭幅・大きな文字ではかなMenuと設定群を別行にする。
かな選択・解除と並び順・表示形式の選択肢は既存のものを維持する。

## 検証

- `CI=true` / Xcode 27.1 Beta / iOS 26.5 / 専用iPad Pro 13-inch (M5) Simulator
- 全体build成功、全テスト200件成功（失敗・スキップ0件）
- 関連テスト48件成功：UI、BookListFilterStateTests、BookSectionTests
- 変更したSwiftファイルのswift-format lint成功
- 2つのMenuの選択肢、管理番号順への変更、かなMenuの選択肢と解除を操作して確認
- 通常文字サイズ・AX3のiPad縦横/明暗、320pt幅の通常文字・AX3明暗を実画像で確認

PNGは変更対象のBookListControlsをそのまま用いた専用のサンプル表示アプリから撮影した。
BookSortType、BookDisplayMode、KanaGroupもリポジトリの定義を使用し、実利用者・園児・図書データは使っていない。
320pt画像はiPad内の320pt固定幅コンテナで検証したもので、実際のSplit View操作ではない。
一部はiPadOSのウィンドウ表示で撮影している。アプリ全体の画面や棚の色を変更するものではない。

## 未検証

実機での使い心地、実際のSplit Viewの操作、VoiceOverによる読み上げ順は未検証。
独立した外部レビューは今回の依頼に従い送信していない。
