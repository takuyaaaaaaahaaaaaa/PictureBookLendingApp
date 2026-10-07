# 表紙照合 PoC（Issue #270）

本番アプリには未接続の独立 Swift Package。入力は `CGImage`、`VisionCoverEncoder.encode` の出力は Vision revision 1 の Float 特徴ベクトル。`CoverIndex` は書籍 UUID と複数の特徴ベクトルを JSON に原子的に保存し、コサイン類似度順に最大 3 件返す。画像、特徴量、蔵書データを送信する処理はない。OCR も使わない。モデルは Apple OS に同梱の Vision 特徴抽出器で、外部モデルを配布しない。

登録画像を追加すると索引のサンプルが増える。これは固定モデルの**特徴ベクトル登録**であり、ネットワーク重みの再学習ではない。書籍削除時は `remove(bookID:)` を呼ぶ。`encoderVersion` が違う索引は読み込めず、元画像から全件再構築する必要がある。書影の取得は既存 `Book.localImageFileName` と `LocalImageStorageRepository` を使う想定。外部書影の Kingfisher キャッシュは 30 日期限なので、そこだけを永続索引の正本にはできない。

`minimumSimilarity=0.75` は PoC の仮値で、実物で校正されていない。候補は人が選ぶ前提で、自動貸出は実装しない。閾値未満なら手動検索へ進む。似た表紙や未登録本の偽候補率は未評価。同じ表紙の複本は画像だけでは識別できないため、候補選択後に管理番号や現物ラベルで個体を選ぶ必要がある。

## 実行記録（2026-10-07）

- Xcode 27.1 RC、main `b31dc6c`、作業ブランチ `poc/on-device-cover-recognition`。
- `swift test --scratch-path /tmp/cover-recognition-build`: macOS で 4 件通過。別生成の合成図形画像による特徴抽出と検索、索引の追加・削除・保存・再読込、次元不一致、未登録扱い、バージョン不一致、Core ML kNN の更新・保存・再読込・予測を確認。
- iOS 26.1 iPad Simulator: コンパイル成功。索引 2 件と Core ML kNN 更新 1 件が通過。Vision 画像抽出テストは revision 2 で `Failed to create espresso context`、revision 1 で `Could not create inference context` と失敗。
- iOS 27.0 iPad Simulator: コンパイル成功。Vision 画像抽出テストは `Could not create inference context` で失敗。Vision revision 2 と revision 1 の両方を試し、revision 1 でも失敗。実画像検索と目視 UI はシミュレータでは未達。
- 合成図形の結果を実物絵本の精度とは扱わない。実表紙、撮影角度・反射・遮蔽、速度、発熱、長時間動作は実機未評価。

## Core ML / Core AI との比較

本命の製品構成は、権利と入出力が確認できた固定の**画像埋め込み Core ML モデル** + 書籍 ID 付きローカル索引。モデル変更・前処理変更の際には画像から索引を再生成する。本 PoC の索引はその構成でも再利用できるが、適切な表紙用 Core ML モデルの採用・変換・実行は未実施。

Apple の [更新可能な線画分類器例](https://apple.github.io/coremltools/docs-guides/source/updatable-tiny-drawing-classifier-pipeline-model.html) は 28×28 グレースケール、128 次元の MIT 記載モデルと更新可能 kNN のパイプライン。表紙写真向けの精度根拠にならない。比較のため、隔離した `/tmp/cover-coreml-venv` に `coremltools 9.0` を導入し、`generate_knn_fixture.py` で**画像入力なし**・3 次元 Float32 ベクトル入力・`bookID` 文字列出力の更新可能 kNN を生成。生成物は `Tests/.../Resources` のテスト専用 fixture として保存した。`MLUpdateTask` による `.mlmodelc` の更新・保存・再読込・予測が Mac と iOS 26.1 iPad Simulator の両方で通過した。これは更新 API の動作確認であり、表紙画像の精度検証ではない。Python 3.14 用 `coremltools` はネイティブ Python バインディングが無く、仕様生成のみ可能だったためモデルコンパイルは Xcode の `coremlc` で実行した。

Core AI は Xcode 27.1 の **iPhoneOS 27.1 SDK** に `CoreAI.framework` があり、公開 API は iOS/iPadOS 27 以降。一方、同 Xcode の iPhoneSimulator SDK の公開 Frameworks には `CoreAI.framework` が見つからず、このシミュレータでの Core AI 実行比較はできない。アプリの最低 iOS は 26.0 のまま。Core AI の推論とローカル索引は候補構成だが、端末内モデル更新 API があるとは確認していない。Core ML `MLUpdateTask` と同一視しない。

## 次の実機検証

1. 私的データを含まない、利用許諾を確認した複数の実表紙を登録し、別撮影画像、似た表紙、未登録本を分けて収集する。外部送信はしない。
2. iOS 26 以上の iPad 実機で Vision の特徴抽出が動くか確認。検索の順位・未登録率・誤候補率を測り、閾値を校正する。
3. 利用可能な表紙用 Core ML 埋め込みモデルのライセンス、入力画像の色・サイズ・正規化、出力次元を確認して同じ索引に接続し、比較する。
4. 個体の管理番号選択を含む候補 UI を作り、貸出確定は既存の確認画面に委ねる。実カメラの反射、速度、発熱を測る。
