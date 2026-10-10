# 操作色と状態色

2026-10-02のオーナー承認：本棚の配置と木地を保ち、操作はくすんだ暖色、貸出中は淡紫の面＋濃藍の文字、貸出可は緑、延滞は赤で区別する。状態には文字とSF Symbolを併記する。

| トークン | 用途 |
| --- | --- |
| `accent` | 借りる・返却・表示切替などの操作。本体／Widget共通のAccentColorを参照 |
| `lent` / `lentForeground` | 貸出中・空き枠なしの文字とアイコン |
| `lentSurface` | 貸出中・空き枠なしの面。専用文字色との組で使用 |
| `available` | 貸出可。緑＋チェックのアイコン＋文字 |
| `overdue` | 延滞。赤＋警告アイコン＋文字 |
| `returned` | 返却済み。緑＋チェックのアイコン＋文字 |
| `destructive` | 削除などの破壊的操作。赤。標準コントロールのdestructiveロールは維持 |
| `cardSurface` | カードの面 |
| `chipSurface` | 補助ラベルの面。標準のボタン・チップを自前描画に置き換えない |
| `onEmphasis` | 不透明なアクセント／状態色の塗り面上の文字。ライトは白、ダークは濃い文字 |

UIパッケージのAsset Catalogで明暗を定義し、`AppColor`から参照する。`accent`のRGBは再定義しない。本体とWidgetのAccentColorは同じ内容に保つ。木地の`ShelfWoodColors`とシステムのprimary／secondary／tertiary文字色は変更しない。

本棚の「借りる」ボタンは操作なので暖色、同じ位置の「貸出中」は状態案内なので淡紫の面と濃藍の文字を使う。貸出可の緑を借りるボタンの色へ兼用しない。

## 現行の操作色と変更範囲

上の操作色の説明と下の淡色への調整は2026-10-02時点の方針。後続の [PR #264](https://github.com/takuyaaaaaaahaaaaaa/PictureBookLendingApp/pull/264) で用途別の操作色を追加し、[PR #299](https://github.com/takuyaaaaaaahaaaaaa/PictureBookLendingApp/pull/299) で表紙検索も表示切替・返却と同じ組に揃えた。

| 現行の組 | 用途 | ライト／ダークの背景アセット値 |
| --- | --- | --- |
| `accent`（本体／Widgetの`AccentColor`） | 環境のアクセントと、それを参照する標準コントロール・操作 | `#99673F`／`#D2A07A` |
| `libraryAction`＋`onEmphasis` | 表紙検索、表示切替、返却 | `#67452F`／`#DEBD8D` |
| `borrowAction`＋`borrowActionForeground` | 借りる操作と貸出・返却完了表示 | 専用アセットの明暗対応値 |

`accent`は`Color.accentColor`の参照であり、用途別トークンのRGBコピーではない。`libraryAction`などはUIパッケージのAsset Catalogを`bundle: .module`で参照する。用途が違うので一律に同じ値へ揃えない。全体の色味を変更する場合は本体／WidgetのAccentColorを同じ内容に保ち、用途別トークンと明示overrideが追従するかは個別に確認する。表の値はアセット値であり、環境tintの実際の解決色や合成後の見え方を保証しない。

## 確認場所

- DebugのUIカタログ先頭：明暗を横並びにした全トークン、塗り面＋文字、木地上の操作・状態表示。
- Debugカタログ先頭の「本棚を確認（サンプル・保存なし）」から開けるApp層の`BookshelfColorPreview`：横幅1194の明暗、狭幅390＋大きい文字。サンプルのみで表紙はプレースホルダー。
- WidgetはAccentColorのみを揃える。ロック画面のアクセサリfamilyでシステムの色処理を確認するまで固定描画を変更しない。

これは#228〜#230の色のまとまりであり、#226の全面的な標準コントロール化、#231〜#234のレイアウト・状態保持全体の完了を意味しない。追加Previewは今回の色変更の確認用。iPad Pro 13-inch（iPadOS 27.0）シミュレータの横向きで、本棚サンプルとトークン一覧の明暗を目視確認済み（2026-10-02）。サンプルはカタログからの遷移なので戻る操作と開発用タブがある。検索欄を通常トップと同じ常時表示にし、NavigationStackの二重化を除いて大タイトルを維持する。実機、文字サイズ拡大、色フィルタでの確認は別途必要。

## 淡色への調整（#228）

2026-10-02追加承認：生成参考モックの柔らかい配色に合わせ、貸出中は淡い面＋濃い文字、主操作はくすんだ茶色にする。モックは画素ごとに色が異なるため、画像の採取色をそのまま正式なトークンとは扱わない。

| 組 | ライト | ダーク |
| --- | --- | --- |
| accent | `#99673F` | `#D2A07A` |
| lentSurface | `#E0DFF6` | `#33364F` |
| lentForeground | `#3E4A89` | `#B3BBF5` |
| onEmphasis | `#FFFFFF` | `#241A13` |

主操作はaccent＋onEmphasis、貸出中はlentSurface＋lentForegroundを使う。状態色すべてを一律に薄くしない。緑の貸出可／返却済み、赤の延滞／破壊的操作、木地は既存の色方針を維持する。UIパッケージでAsset Catalogの明暗解決と文字コントラストをテストする。本体／Widgetのaccentは同一JSONで管理する。

参照モックの質感・架空の表紙・独自のタブ形状は実装対象に含めない。今回のサンプルは実データを保存せず、表紙はプレースホルダーを使う。
