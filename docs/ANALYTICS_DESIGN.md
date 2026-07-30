# 利用ログ（アナリティクス）設計

ステータス：**設計確定（2026-07-31）**。送信先・クラッシュ検知ともFirebaseに決定済み・実装前。
関連：[SCREEN_DESIGN_PHASE2.md](SCREEN_DESIGN_PHASE2.md)（計測対象の導線）／
[DESIGN_PRINCIPLES.md](DESIGN_PRINCIPLES.md)（数値目標）／[TERMS.md](TERMS.md)（用語）

---

## 1. 目的と大原則

アプリの改善判断に使う**操作の過程**を記録する。誰が何を借りたかという**業務の結果は
SwiftDataに既に全部ある**ので、イベントログでは取らない（二重集計・数字のズレ防止）。

### 大原則

1. **記録は常時・送信は通信時**：イベントはまずローカルに保存し、ネットワーク接続時に
   まとめて送信する。完全オフライン運用の思想を崩さない。
   通信の契機は既存の図書情報取得（Wi-Fi接続時）と同じ機会を想定。
   この仕組みはFirebase SDKのオフラインバッファに委譲する（自前スプールは作らない・§5）
2. **イベントに識別子を一切載せない**：利用者ID・図書ID・家庭・組・検索文字列は記録しない。
   記録するのは**所要時間・件数・列挙値（enum）だけ**。これにより「個人情報ゼロ」を
   設計レベルで保証し、プライバシー説明を単純にする
3. **問いに紐づかないイベントは仕込まない**：下表の問い（Q1〜Q6）に対応しないイベントは追加しない。
   新しいイベントが必要になったら、まず本ドキュメントに問いを追記してから実装する
4. **DBから導出できる指標はイベント化しない**：貸出冊数・人気図書・延滞率・返却までの日数などは
   貸出記録から計算する（必要ならローカルの統計画面やエクスポートで見る）

### キオスク前提の注意

共用iPad 1台を多数の保護者・祖父母が代わる代わる操作するため、アナリティクスツールの
「ユーザー数」「セッション数」「リテンション」は**すべて意味を持たない**。
見るのは**フロー単位の指標**（1回の貸出・1回の返却がどう進んだか）のみ。

---

## 2. 答えたい問い

| # | 問い | 根拠・背景 |
|---|---|---|
| Q1 | 貸出・返却は目標どおり速く完了しているか | DESIGN_PRINCIPLES の数値目標（貸出3タップ・返却2タップ・取り消し1タップ） |
| Q2 | フローの途中で諦めた人はどこで消えたか | 離脱はDBに痕跡が残らない。ログでしか見えない |
| Q3 | 図書は見つけられているか（検索の質） | 0件ヒット・あいまい検索の発動は登録漏れ・表記ゆれの発見器 |
| Q4 | 作った機能は使われているか | 棚表示・五十音・延滞のみフィルタ・保護者枠の答え合わせ |
| Q5 | 間違えやすいUIはないか | Undo・貸出ブロックの頻度はUI改善のサイン |
| Q6 | アプリは落ちていないか | 現場でのクラッシュは報告が来ない。少ユーザーほど1クラッシュが致命的 |

Q6はイベントログではなく**クラッシュレポート（Crashlytics または MetricKit）**で扱う。
費用対効果が最も高く、導入優先度はイベントログより上（§6）。

---

## 3. イベント一覧（v1：10個）

命名はGA4流のsnake_case。用語はTERMS.mdの英語列に従う（Book／User／Loan）。
表は Phase A（2026-07-31 実装）の実装内容に合わせて更新済み。

### 貸出フロー（Q1・Q2・Q4）

| イベント | 発火タイミング | プロパティ |
|---|---|---|
| `borrow_flow_started` | 図書一覧で図書をタップし貸出シートが開いた（貸出中の案内シートは除く） | `find_method`: search / kana_index / shelf / scroll |
| `borrow_user_selected` | 名前一覧で名前をタップした | `elapsed_ms`（シート表示からの経過） |
| `borrow_completed` | 枠タップで貸出が確定した | `total_ms`（シート表示から完了まで）, `slot_type`: child / guardian, `guardian_fallback`: Bool（園児枠満杯で保護者枠を使ったか） |
| `borrow_abandoned` | 貸出シートが完了せず閉じた | `last_step`: user_selection / slot_selection, `reason`: user_closed / idle_timeout, `elapsed_ms` |
| `borrow_blocked_no_slot` | 家庭の画面に到達したが空き枠がなかった | なし |

- `borrow_user_selected` から `search_used` を落とした：貸出シートの名前一覧
  （`BorrowerListView`）には検索フィールドが無く、絞り込み手段は組チップだけのため
  （検索の有無を答えられるイベントが存在しない）
- `borrow_blocked_no_slot` から `elapsed_ms` を落とした：このイベントは
  家庭の枠領域が表示された時点で発火するもので、利用者の操作の完了を表さないため
  所要時間に意味がない

### 検索（Q3）

| イベント | 発火タイミング | プロパティ |
|---|---|---|
| `book_search_performed` | 図書検索の入力が確定した（デバウンス後） | `query_length`, `result_count`, `fuzzy_triggered`: Bool（あいまい検索フォールバックが発動したか）, `zero_hit`: Bool（あいまい検索でも0件か） |

検索文字列そのものは記録しない（大原則2）。改善に必要なのは「見つからなかった事実」であり、
0件ヒットが増えたら実機のそばで聞き取りする方が早い。

### 返却フロー（Q1・Q4）

| イベント | 発火タイミング | プロパティ |
|---|---|---|
| `return_family_opened` | 名前一覧から家庭の画面を開いた | `find_method`: search_name / search_book_title / browse, `overdue_filter_active`: Bool |
| `return_completed` | 返却が確定した | `elapsed_ms`（家庭の画面表示から）, `was_overdue`: Bool |

v1の`find_method`は `group_index` / `scroll` を `browse`（検索せず一覧から選んだ）に
統合した。組チップは`BorrowerListView`内でスクロール位置を動かすだけで、
どのチップを押したかは呼び出し側のContainerに伝わらないため、
判別にはUI層の改修（チップ操作のコールバック追加）が必要になる。
「検索が使われているか」が先に知りたい問いであり、
ブラウズ内訳が必要になった時点で改修する（将来課題）。

### つまずき・俯瞰（Q4・Q5）

| イベント | 発火タイミング | プロパティ |
|---|---|---|
| `undo_performed` | Undoカードで取り消した | `flow`: borrow / return |
| `overdue_filter_toggled` | 返却タブ「延滞のみ」フィルタをONにした | なし（先生の月末俯瞰＝1タップ動線の答え合わせ） |

`flow: borrow` は**貸出フローの中で行われた返却の取り消し**を意味する
（枠が埋まっている人がその場で返して借り直す「本の入れ替え」のやり直し）。
貸出そのものを取り消すUndoは存在しない。`flow: return` は返却タブでの返却の取り消し。

---

## 4. 指標の定義（ダッシュボードで見る数字）

| 指標 | 計算 | 目標・見方 |
|---|---|---|
| **貸出所要時間**（North Star） | `borrow_completed.total_ms` の**中央値とp90** | 平均は使わない（置き去り等の外れ値に弱い）。悪化したらリリースを疑う |
| 貸出完了率 | `borrow_completed ÷ borrow_flow_started` | 離脱率の裏返し。`borrow_abandoned.last_step` で犯人特定 |
| 返却所要時間 | `return_completed.elapsed_ms` の中央値とp90 | 返却2タップ目標の実測値 |
| 0件ヒット率 | `zero_hit=true ÷ book_search_performed` | 高い→登録漏れ or 表記ゆれ。**改善アクションに最直結** |
| あいまい検索発動率 | `fuzzy_triggered=true ÷ book_search_performed` | 高い→タイプミスが多い＝67歳基準の入力UIを疑う |
| 図書の見つけ方の内訳 | `borrow_flow_started.find_method` の構成比 | 棚表示 vs 検索 vs 五十音。次に磨く機能の判断材料 |
| 保護者枠フォールバック率 | `guardian_fallback=true ÷ borrow_completed` | 発見6「2枠が知られていない」の改善確認 |
| Undo率 | `undo_performed ÷ (borrow_completed + return_completed)` | 高い→間違えやすいUI。`flow`別に見る |

### 計測できないと分かっていること（v1の制約）

- **ブラウズで本を探している時間**は測らない。キオスクは放置時間が混ざるため
  「一覧表示から本タップまで」に意味のある起点を置けない。v1では `find_method` の
  構成比と検索イベントの質で代替し、必要になったら「無操作N秒後の最初のタッチを
  来訪開始とみなす」方式を検討する
- **バックグラウンド滞在時間**：フロー計測中にアプリがバックグラウンドへ行った場合、
  その所要時間は集計から除外する（`scenePhase` で検知）

---

## 5. 実装方針

**語彙はApp層・配管はInfrastructure層**に分ける（2026-07-31 オーナー相談で決定）。

```
Infrastructure層  AnalyticsService プロトコル＋実装（track(name:params:) の汎用API）
                  ConsoleAnalytics（DEBUG）／FirebaseAnalyticsService（Analytics.logEventの薄いラッパー）
                  ── イベントの意味を知らない「記録して送る」だけの配管
App層             AnalyticsEvent enum（画面語彙の型安全な定義）
                  ＋ name/params への変換（Presentation配下・+Formatterと同じ役回り）
                  ContainerViewがフロー節目で track を呼ぶ
```

- イベント語彙（`find_method: shelf` 等）は**画面の関心事でありドメイン概念ではない**
  （TERMS.mdに載せる概念でもない）ため、Domain層には置かない
- プロトコルをApp層に置かない理由：Infrastructure → App の依存は禁止のため、
  App層定義のプロトコルはInfrastructure層から実装できない。またスプール実装
  （ファイルI/O・送信）は責任分離表で Container ❌ の「データ永続化・API通信」に当たる
- プロトコルは実装と同じInfrastructure層に同居するが、App層はprotocol型で受けるため
  DEBUG用実装への差し替え・テスト用モックは従来どおり可能
- イベント追加時はApp層のenumに1ケース足すだけで、Infrastructure層は無変更
- 所要時間の計測はContainerViewの`@State`（シート表示時刻の記録）で行い、
  Modelにはアナリティクスの関心事を持ち込まない
- **送信先は Firebase Analytics に決定**（2026-07-31 オーナー決定）。理由：
  - Crashlytics（§6）と同一SDKファミリーで、導入・コンソール・学習コストが1回で済む
  - SDK標準のオフラインバッファが「記録は常時・送信は通信時」をそのまま満たし、
    自前スプールの実装が不要になる
  - 無料で、無料配布・維持費ゼロの要件に合う
  - ※GA4は収集から約72時間超の遅延イベントを落とす仕様があるが、
    園のiPadは図書情報取得でWi-Fi接続する運用のため許容と判断（2026-07-29）
  - 将来の乗り換え（TelemetryDeck等）に備え、FirebaseはAnalyticsServiceプロトコルの
    背後に隠しApp層へ露出させない
- **広告ID無しの構成で導入する**：SPMでは `FirebaseAnalyticsWithoutAdIdSupport` を選択し、
  Info.plistで広告パーソナライズ信号を無効化する
  （`GOOGLE_ANALYTICS_DEFAULT_ALLOW_AD_PERSONALIZATION_SIGNALS = NO`）。
  ATT（トラッキング許可ダイアログ）を不要にし、プライバシー申告を最小にする
- **段階導入**：
  - **Phase A**：イベント定義＋ConsoleAnalytics（DEBUG・送信なし）。実機で自分の操作を
    眺めてイベント設計の妥当性を検証する
  - **Phase B**：FirebaseAnalyticsService を接続し、§8のチェックリストを消化する

---

## 6. クラッシュレポート（Q6・別トラック最優先）

イベントログとは独立に、**先にクラッシュ検知だけ導入する**。
**Firebase Crashlytics に決定**（2026-07-31 オーナー決定）。

- MetricKitを不採用とした理由：クラッシュ診断はアプリ内に届くだけで、
  **送信先の収集基盤を自前で持つ必要がある**＝サーバレス・維持費ゼロの前提と矛盾する。
  SDKなしの代替（Xcode Organizerのクラッシュレポート）は「デベロッパと共有」に
  オプトインした端末の分しか届かず、数園規模では実質ゼロ件になる
- CrashlyticsはAnalyticsと同居前提の設計で、クラッシュ直前のイベントが
  パンくずとして残る（例：「貸出シート表示直後に落ちている」が特定できる）
- 現場の保育士・保護者はクラッシュしても報告してくれない。検知手段ゼロの現状が最大のリスク
- 導入時の注意：dSYMアップロードのビルドフェーズ設定が必要。
  Xcode Cloudでビルドする場合はポストビルドスクリプトでのアップロードを別途構成する

---

## 7. やらないこと（非目標）

- **ヒートマップ・スクリーン録画系SDK**：画面に園児名が常時表示されるアプリのため導入しない
- **利用者・図書を特定できるログ**：大原則2のとおり
- **業務指標のイベント化**：貸出冊数・人気図書・延滞率はDBから導出
- **リテンション・DAU等のユーザー系指標**：共用キオスクでは無意味

---

## 8. リリース前チェックリスト（Phase B着手時）

- [ ] プライバシーポリシーに収集内容（匿名の操作イベント・クラッシュ情報）を明記
- [ ] App Storeプライバシー表示（Nutrition Label）の申告を更新（利用状況データ・診断データ）
- [ ] PrivacyInfo.xcprivacy（プライバシーマニフェスト）に収集データ種別を記載
  （Firebase SDK側のマニフェストはSDKに同梱されるため、アプリ側の申告と整合を確認）
- [ ] `FirebaseAnalyticsWithoutAdIdSupport` での導入と広告パーソナライズ無効化を確認（§5）
- [ ] dSYMアップロードの動作確認（ローカルビルド・Xcode Cloud両方）
- [ ] 導入園向けの説明文面（何を集めて何を集めないか）を用意
