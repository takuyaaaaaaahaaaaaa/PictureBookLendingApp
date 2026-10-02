# PR243 Widget実表示・起動QA（2026-10-02）

専用の空iPhone 17 / iOS 27.0（24A434）シミュレータ、Debugビルド。Xcode DeviceInteractionでロック画面を長押しし、カスタマイズ画面から対応3形式を追加。編集画面を閉じた通常のロック画面で実表示を確認した。Xcode Preview画像ではなく、物理端末の検証でもない。

検証ソースは統合head `e34d98a8c6eed6592881cee014e5effee739029b`。Widgetソース・assetはPR243 head `f5cdb1e9ffe6895ce4272f58511c59126cc53174`から差分なし。アプリ側の到達画面には後続PRの統合状態を含む。

| 画像 | 操作・結果 |
| --- | --- |
| 01-three-families.png | accessoryInline（本アイコン＋えほん台帳）、accessoryCircular（本アイコン）、accessoryRectangular（えほん台帳／をタップして開く）を通常ロック画面で確認。 |
| 02-inline-open.png | インラインをタップし、空の「貸出」画面へ前面復帰。 |
| 03-circular-open.png | 円形をタップし、空の「貸出」画面へ前面復帰。 |
| 04-rectangular-open.png | 長方形をタップし、空の「貸出」画面へ前面復帰。 |
| 05-cold-launch.png | 対象アプリだけを終了し、再度ロック画面の円形をタップ。新しいPIDで起動し、空の「貸出」画面へ到達。 |

3形式とも到達先bundle `AmazingComingTommy.PictureBookLendingAdmin` をUI階層で確認。前面復帰時PIDは68750、コールド起動後PIDは85819。静止画像だけで起動経路を立証するものではなく、操作結果とUI階層の確認を併用している。

画像5枚は公開前に目視確認済み。空データの専用シミュレータのみで、本番の児童・図書・貸出記録、個人の通知、APIキー、認証情報を含まない。PNG付帯情報も確認し、EXIFは色空間と画像寸法のみ。通信ログや端末操作セッションキーは添付しない。

確認範囲では文字切れ・重なり・残留placeholder・クラッシュは観測しなかった。操作セッションは正常終了済み。物理端末、最低対応OS、全壁紙・表示モードでの見え方は未検証。コード中の色の直接指定や未対応systemMedium Previewの存在について、今回の表示確認だけで解消したとは扱わない。

製品コードのhead/base、PRのDraft状態、既存画像は変更していない。
