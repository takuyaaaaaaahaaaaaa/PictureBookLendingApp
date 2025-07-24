# 用語集（ドメインモデル版）

| 日本語（UI用） | 英語（コード・設計用） | 避ける用語（日本語・英語） | 説明・備考 |
|---|---|---|---|
| 絵本 | Book | 書籍, 本, 図書, Booklet, Literature | 保育園・幼稚園で使用する0歳〜5歳向けの読み聞かせ用本。ID、タイトル、著者を持つ |
| 利用者 | User | 園児, 子供, 児童, 園生, Child, Kid, Student | 絵本を借りる子ども。ID、名前、所属する組を持つ |
| 組 | group（プロパティ名） | クラス, チーム, グループ, Team, Class | 利用者の所属する組（例：もも組、ひよこ組）。Userエンティティのgroupプロパティとして管理 |
| 貸出記録 | Loan | 貸し出し, 借用, Lending, Borrowing | 個別の絵本貸出記録。貸出日、返却期限、返却日を管理 |
| 貸出日 | loanDate | 借用日, 貸出開始日, borrowDate, startDate | 絵本を貸し出した日付 |
| 返却期限 | dueDate | 返却予定日, 期限日, returnDate, deadline | 絵本を返却すべき期限日 |
| 返却日 | returnedDate | 実際返却日, 返却完了日, actualReturnDate | 絵本が実際に返却された日付（未返却時はnil） |
| 返却済み | isReturned | 返却フラグ, 完了ステータス, returned, completed | 絵本が返却済みかどうかの論理値（計算プロパティ） |
| 貸出期間 | loanPeriod | 貸出日数, 借用期間, lendingDuration, borrowingPeriod | 絵本を貸し出してから返却期限までの日数（例：14日間） |
