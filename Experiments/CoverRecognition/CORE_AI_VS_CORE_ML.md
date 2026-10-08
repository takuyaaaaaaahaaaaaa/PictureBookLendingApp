# えほん台帳の表紙検索：Core ML と Core AI の比較

2026-10-08 時点。対象は、先生が表紙を撮影し、端末内の登録済み蔵書から**候補を選んで**貸出へ進む機能。既存アプリの最低 iOS は **26.0**。本番実装・OS 変更・配布の判断ではなく、[独立 PoC](README.md)と Apple 公式資料に基づく採用判断メモ。

## 最初に四つの役割を分ける

1. **画像モデル**：写真を比較しやすい数値列（特徴量）にする。PoC は Apple 配布の FastViT T8 headless。256×256 RGB 画像から 768 個の数値を出す。ImageNet で学習した汎用モデルであり、絵本用の精度は未確認。[Apple のモデル一覧](https://developer.apple.com/machine-learning/models/)
2. **実行基盤**：端末上でモデルを動かす。現在のモデルは Core ML 形式（`.mlpackage`）なので `MLModel` で動く。Core AI は別の `.aimodel` 形式を `AIModel` と `InferenceFunction` で動かす。[Core AI の統合ガイド](https://developer.apple.com/documentation/coreai/integrating-on-device-ai-models-in-your-app-with-core-ai)
3. **蔵書索引**：特徴量に本 ID を付けて端末内に保存し、撮影した表紙の特徴量との近さで候補を並べる。PoC の `CoverIndex` が担当する。これは Core ML / Core AI のどちらでもアプリ側に必要。OCR を必須とせず、画像・特徴量・蔵書データを送信しない構成にできる。
4. **端末内追加学習**：モデルの内部を更新する別の処理。Core ML には更新可能モデルに対する `MLUpdateTask` がある。ただし PoC で確認したのは **3 次元ベクトル用 kNN** の例の追加で、FastViT のニューラルネットワーク重み更新ではない。Core AI に同等の重み更新 API があるとは確認できていない。[Apple の更新例](https://developer.apple.com/documentation/coreml/personalizing-a-model-with-on-device-updates)

つまり、新しい絵本の画像を登録するたびに特徴量を索引へ追加すれば、その本が候補になる。**この日常操作にニューラルネットワークの再学習は不要**。モデルを変えると特徴量の意味が変わるので、保存した元画像から索引を作り直す。

## このアプリでの比較

| 判断点 | Core ML + 固定モデル + ローカル索引 | Core AI + 固定モデル + ローカル索引 |
| --- | --- | --- |
| 既存 iOS 26 対応 | PoC が iOS 26.1 iPad Simulator で画像→特徴量→検索まで通過。最低 OS を変えずに進められる。 | [公開 API は iOS / iPadOS 27 以降](https://developer.apple.com/documentation/coreai)。単独採用には最低 OS 変更、または Core ML との二重実装が必要。 |
| モデル準備 | Apple 配布の FastViT `.mlpackage` をそのまま利用した。入出力と[ライセンス](https://github.com/apple/ml-fastvit/blob/8af5928238cab99c45f64fc3e4e7b1516b8224ba/LICENSE)を確認。 | `.aimodel` が必要。既存 `.mlpackage` を `AIModel` へ直接渡すと Mac では特殊化時に失敗。Apple は元の PyTorch モデルから [Core AI PyTorch Extensions](https://apple.github.io/coreai-torch/) で変換する手順を示す。 |
| 登録・削除・復元 | 本 ID とベクトルの追加・削除、索引の保存・再読込、モデル版不一致の拒否を PoC で確認。復元時の蔵書データとの再同期は未統合。 | 索引側の設計は同じ。ただし Core AI モデルの特徴量が Core ML と同じとは限らず、移行時は元画像から再索引化とスコア再校正が必要。 |
| 少数登録画像 | 1 冊 1 枚でも索引には追加可能。撮影条件が違う場合の精度は未確認で、複数例の登録余地を残す。 | 実行基盤だけを変えても、このデータ不足は解決しない。 |
| 似た表紙・未知本 | 類似度の閾値で手動検索へ戻し、人が候補を選ぶ。閾値 `0.75` は仮値。誤候補・未知本の試験は未実施。 | 同じ安全策が必要。Core AI 採用だけで識別精度が上がる根拠はない。 |
| 運用・開発負担 | 既存形式と API で試験済み。ただし写真保持、索引更新、バックアップ復元、モデルライセンス表示、実機測定は残る。 | さらにモデルの変換、Metal Toolchain、iOS 27 対応端末、二重実装や移行を検討する負担がある。Apple の[統合ガイド](https://developer.apple.com/documentation/coreai/integrating-on-device-ai-models-in-your-app-with-core-ai)は `.aimodel` を含む Xcode ビルドに Metal Toolchain が必要とする。 |
| オフラインとプライバシー | モデルを同梱し、ローカル索引を使えば外部送信なし。PoC に送信処理はない。 | モデルを同梱すれば同様に可能。フレームワーク名だけでプライバシーが保証されるわけではなく、アプリの保存・通信設計で決まる。 |

## 実際に確かめた範囲

- **Core ML**：FastViT の画像入力→768 次元特徴量→本 ID 付き索引検索を Mac と iOS 26.1 iPad Simulator で実行。合成画像による経路テストであり、実表紙の精度試験ではない。Mac 5 テスト、iPad Simulator 4 テスト通過。`MLUpdateTask` による別の kNN 教材の更新・保存・再読込も通過。
- **Core AI**：Mac および実機向け iOS 27.1 SDK で API プローブの型検査に成功。iOS 27 Simulator SDK は `import CoreAI` が `no such module 'CoreAI'` で失敗。Mac で Core ML FastViT `.mlpackage` を `AIModel` に渡すと **初期化中の特殊化段階**で `Missing hash file`、kNN `.mlmodelc` は `corruptedMetadata`。Core AI の `.aimodel` ロード成功・推論・FastViT との同一重み比較は未実施。[型検査用コード](CoreAIProbe.swift)／[形式確認コード](CoreAIFormatProbe.swift)
- **実機**：実カメラ、反射・斜め撮影、端末の速度・発熱、長時間動作は未検証。シミュレータから実機性能は推定しない。Vision の比較用特徴抽出は iPad Simulator で失敗したが、Core ML FastViT の推論は通過している。

## 判断と、結論が変わる条件

**現時点は Core ML の固定埋め込みモデル + ローカル索引を継続候補にする。** iOS 26 のまま画像経路が動き、先生による追加登録は索引更新だけで実現できるため。Core AI は将来の比較対象として残す。これはモデルの精度や推論性能で Core ML が勝ったという結論ではない。

採用を左右する最大の未検証事項は、実物の絵本で**同じ本の別撮影を上位に出せるか、似た表紙や未登録本を誤確定させないか**。FastViT が不十分なら、表紙向けに適した別の固定画像埋め込みモデルを権利・入力・出力を確認して比較する。Core AI が必要になるのは、iOS 27 対応を許容でき、`.aimodel` へ同一重みと前処理を揃えて変換したうえで、実機上の品質・速度・電力に明確な利益が出る場合。

## 次の最小検証

1. 園児や園の私的データを使わず、利用許諾のある実表紙を数十種類集める。本ごとに登録用と**別撮影**の検索用を分け、似た表紙と未登録本も含める。写真・特徴量は端末外へ送らない。
2. iOS 26 の iPad 実機で Core ML の上位候補率、未知本の保留率、誤候補率、撮影時間・発熱を測る。候補選択と管理番号確認を経て貸出へ進み、自動確定しない。同じ表紙の複本は画像だけでは個体を識別しない。
3. 追加・削除・バックアップ復元後の索引を蔵書と照合し、モデル／前処理バージョン変更時には保存した元画像から再構築できるか確認する。
4. Core AI 比較を進める場合のみ、元の PyTorch 重み、`coreai-torch`、Metal Toolchain とそのライセンス・導入条件を確認する。導入や新規ライセンス受諾は本調査では行わない。同一画像・同一前処理・可能なら同一重みで実機比較する。

### 公式資料

- [Core ML Models：FastViT](https://developer.apple.com/machine-learning/models/)
- [Core ML：Personalizing a Model with On-Device Updates](https://developer.apple.com/documentation/coreml/personalizing-a-model-with-on-device-updates)
- [Core AI：概要](https://developer.apple.com/documentation/coreai)
- [Core AI：アプリへの統合](https://developer.apple.com/documentation/coreai/integrating-on-device-ai-models-in-your-app-with-core-ai)
- [Core AI Models：Apple の変換レシピ集](https://github.com/apple/coreai-models)
