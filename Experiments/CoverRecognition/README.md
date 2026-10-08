# 表紙照合 PoC（Issue #270）

採用判断の要点は [Core ML と Core AI の比較メモ](CORE_AI_VS_CORE_ML.md) を参照。

独立 Swift Package の PoC に加え、本番アプリのローカルブランチへ Core ML の表紙検索を統合した。PoC の `CoreMLCoverEncoder` は Apple 公式の FastViT-T8 headless モデルに `CGImage` を入力し、768 次元 Float32 特徴ベクトルを返す。比較用の `VisionCoverEncoder` も含む。PoC の `CoverIndex` は書籍 UUID と複数の特徴ベクトルを JSON に原子的に保存し、コサイン類似度順に最大 3 件返す。撮影画像や特徴量を外部送信する処理はない。OCR も使わない。

登録画像を追加すると索引のサンプルが増える。これは固定モデルの**特徴ベクトル登録**であり、ネットワーク重みの再学習ではない。書籍削除時は `remove(bookID:)` を呼ぶ。`encoderVersion` が違う索引は読み込めず、元画像から全件再構築する必要がある。書影の取得は既存 `Book.localImageFileName` と `LocalImageStorageRepository` を使う想定。外部書影の Kingfisher キャッシュは 30 日期限なので、そこだけを永続索引の正本にはできない。

### 本番アプリへの統合（未配布）

- 新規の蔵書は、表紙画像の登録時に特徴ベクトルを作成し、書籍 ID とともに端末内へ保存する。貸出時は撮影した表紙の特徴ベクトルだけを作成し、保存済みの索引を検索する。
- 表紙画像の差し替え・蔵書削除は索引に反映する。モデルや前処理を変更した場合は、利用できる元画像から索引を再構築する。
- 既存の TestFlight 端末には、この機能導入前から登録済みの本があり得る。特徴ベクトルのない本だけを初回に順次処理し、中断後も再開できるようにする。ローカル画像がなく外部画像 URL のみ残る本は画像を再取得して処理する。取得できない本は未処理として残し、後で再試行または再撮影する。外部書影の再取得は画像ホストへの URL リクエストを伴う。撮影画像・特徴ベクトル・端末内の蔵書データは送信しない。
- 設定画面に常設の「一斉学習」ボタンは設けず、検索準備の進捗と未処理件数・再試行を表示する。この処理はモデルの追加学習ではない。
- 貸出時は最大 3 件を候補表示し、先生が選択する。候補がない場合は手動検索へ案内し、自動で貸出を確定しない。類似度の基準は実表紙での検証後に決める。

`minimumSimilarity=0.75` は PoC の仮値で、実物で校正されていない。候補は人が選ぶ前提で、自動貸出は実装しない。閾値未満なら手動検索へ進む。似た表紙や未登録本の偽候補率は未評価。同じ表紙の複本は画像だけでは識別できないため、候補選択後に管理番号や現物ラベルで個体を選ぶ必要がある。

本番アプリの `CoverRecognitionService` は書籍 ID ごとに現行表紙の特徴ベクトルを1本保存し、画像の差し替え時に置き換える。保存先は Documents の `CoverFeatures-v1.json`。起動・蔵書変更時に不足分を補完し、失敗分は設定画面から再試行できる。モデル・前処理バージョンが合わない索引は再生成する。候補閾値は PoC と異なる暫定値 **0.90** であり、実物で未校正のため配布前に検証が必要。モデルはアプリに同梱し、ライセンスを設定画面から参照できる。

### 統合後の検証（2026-10-08）

- Xcode 27.1 RC でアプリの iOS Simulator ビルド成功。FastViT の `.mlmodelc` がアプリに同梱されたことを確認。
- iOS 26.1 iPad Pro 13-inch (M5) Simulator で `CoverRecognitionTests` の **2件が通過**。合成画像による登録、検索、索引保存・再読込、削除に加え、模擬 HTTPS 応答から既存書影を再取得して登録する経路を確認。実際の楽天画像ホストへの接続は未実施。
- 同シミュレータで貸出一覧の「表紙から探す」、写真選択・カメラ・手動検索の入口、設定画面の検索準備件数を目視。カメラ撮影、写真ピッカーからの検索、実物絵本の精度、端末速度・発熱は未検証。

## 実行記録（2026-10-07）

- Xcode 27.1 RC、main `b31dc6c`、作業ブランチ `poc/on-device-cover-recognition`。
- `swift test --scratch-path /tmp/cover-recognition-build`: macOS で **5 件通過**。Core ML FastViT の別生成画像検索、Vision 比較画像検索、索引操作、Core ML kNN 更新・保存・再読込・予測を確認。合成図形の FastViT 類似度は対象 0.992、別図形 0.788（順位のみの検証値）。
- iOS 26.1 iPad Simulator: **4 件通過**。FastViT の画像入力・特徴抽出・ローカル検索、索引 2 件、Core ML kNN 更新が通過。Vision 画像抽出は revision 2 で `Failed to create espresso context`、revision 1 で `Could not create inference context` と失敗したため、最終シミュレータテスト対象から外した。
- iOS 27.0 iPad Simulator: コンパイル成功。Vision 画像抽出テストは `Could not create inference context` で失敗。Vision revision 2 と revision 1 の両方を試し、revision 1 でも失敗。実画像検索と目視 UI はシミュレータでは未達。
- 合成図形の結果を実物絵本の精度とは扱わない。実表紙、撮影角度・反射・遮蔽、速度、発熱、長時間動作は実機未評価。

## Core ML / Core AI との比較

本命の製品構成は、固定の**画像埋め込み Core ML モデル** + 書籍 ID 付きローカル索引。モデル変更・前処理変更の際には画像から索引を再生成する。画像経路の成立には [Apple Core ML Models の FastViTT8F16Headless](https://developer.apple.com/machine-learning/models/) を使用。公式 ZIP の SHA-256 は `cd669710c737dab9749a7eecdd0567abd0fef5f4f37f3dccd30c718b5bc0bb87`。モデルは **256×256 RGB 入力、768 要素 Float32 出力**、ImageNet-1k 学習の分類バックボーンで、表紙照合専用には学習されていない。中心正方形を切り抜いて 256×256 に縮小する前処理を PoC で実装した。モデルメタデータは [Apple のカスタムライセンス](https://github.com/apple/ml-fastvit/blob/main/LICENSE)を指しており、ライセンス本文をテストリソースに同梱した。本番採用は実表紙評価とライセンス確認の後に判断する。

Apple の [更新可能な線画分類器例](https://apple.github.io/coremltools/docs-guides/source/updatable-tiny-drawing-classifier-pipeline-model.html) は 28×28 グレースケール、128 次元の MIT 記載モデルと更新可能 kNN のパイプライン。表紙写真向けの精度根拠にならない。比較のため、隔離した `/tmp/cover-coreml-venv` に `coremltools 9.0` を導入し、`generate_knn_fixture.py` で**画像入力なし**・3 次元 Float32 ベクトル入力・`bookID` 文字列出力の更新可能 kNN を生成。生成物は `Tests/.../Resources` のテスト専用 fixture として保存した。`MLUpdateTask` による `.mlmodelc` の更新・保存・再読込・予測が Mac と iOS 26.1 iPad Simulator の両方で通過した。これは更新 API の動作確認であり、表紙画像の精度検証ではない。Python 3.14 用 `coremltools` はネイティブ Python バインディングが無く、仕様生成のみ可能だったためモデルコンパイルは Xcode の `coremlc` で実行した。

### Core AI の追加確認

Core ML は `.mlpackage` / `.mlmodelc` を `MLModel` で読み、`MLFeatureValue(pixelBuffer:)` から推論する。この PoC では FastViT の 768 次元出力を索引へ登録できた。Core AI は [Apple の統合ガイド](https://developer.apple.com/documentation/coreai/integrating-on-device-ai-models-in-your-app-with-core-ai)によると **`.aimodel` → `AIModel(contentsOf:)` → `loadFunction(named:)` → `InferenceFunction.run(inputs:)`** の経路を取る。`CoreAIProbe.swift` はそのロード、`NDArray` 推論、256×256 画像入力と 768 次元出力の署名検査を記した型検査用コード。FastViT の Core AI モデルや実推論の実装ではない。

| 検証 | 結果 |
| --- | --- |
| macOS 27.2 / Xcode 27.1 SDK | `CoreAIProbe.swift` の型検査に成功。`CoreAIFormatProbe.swift` をコンパイルして実行。FastViT `.mlpackage` の `AIModel` ロードは **特殊化段階**で `Missing hash file` により失敗。kNN `.mlmodelc` も `corruptedMetadata` で失敗。 |
| iPhoneOS 27.1 SDK | `CoreAIProbe.swift` の型検査に成功。実機でのロード・推論は未実施。 |
| iOS 27 Simulator SDK | `CoreAIProbe.swift` の型検査が `no such module 'CoreAI'` で失敗。シミュレータ実行には進めず。 |

Core AI は [公式ドキュメント](https://developer.apple.com/documentation/coreai)上、iOS/iPadOS/macOS 27 以降で、推論用 `.aimodel` を [Core AI PyTorch Extensions](https://apple.github.io/coreai-torch/) により PyTorch モデルから変換する。既存の Core ML `.mlpackage` を渡すだけでは使えなかった。**同一 FastViT 重みで実行エンジンだけを比べる実験は未達**であり、スコアや速度の比較はしていない。Apple の [Core AI Models](https://github.com/apple/coreai-models) のモデル一覧に FastViT の変換レシピは見つからなかった。追加実験には元の PyTorch 重み、`coreai-torch` などの変換ソフト、Xcode ガイドが求める Metal Toolchain が必要。この Mac に `coreai-build` と Metal Toolchain は見つからず、追加導入は行っていない。モデルのライセンスと同一前処理・重みの再確認も必要。

Core AI のモデル特殊化は**実行端末向けの最適化**であり、蔵書を覚える追加学習ではない。Core AI で固定画像埋め込みを推論できた場合も、蔵書追加はアプリ側のローカル索引へのベクトル登録となる。Core AI の端末内重み更新 API は未確認で、Core ML の `MLUpdateTask` と同一視しない。アプリの最低 iOS 26.0 は変更していない。

## 次の実機検証

1. 私的データを含まない、利用許諾を確認した複数の実表紙を登録し、別撮影画像、似た表紙、未登録本を分けて収集する。外部送信はしない。
2. iOS 26 以上の iPad 実機で FastViT の検索の順位・未登録率・誤候補率を測り、閾値を校正する。Vision の実機動作も必要なら比較する。
3. FastViT と表紙用途により適した画像埋め込みモデルを実表紙で比較し、ライセンス・入力正規化・端末上の所要時間を確認する。
4. 実カメラの反射、速度、発熱を測る。同じ表紙の複本は候補表示後に管理番号で個体を確認し、既存の貸出フローで確定する。
