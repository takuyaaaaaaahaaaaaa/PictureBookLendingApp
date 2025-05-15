# PictureBookLendingCore

このモジュールは絵本貸し出しシステムの共通データモデルを提供します。

## モデル

### Book（絵本）
- `id`: UUID - 絵本の一意識別子
- `title`: String - 絵本のタイトル
- `author`: String - 著者名

### User（利用者）
- `id`: UUID - 利用者の一意識別子
- `name`: String - 利用者名
- `group`: String - クラス/組

### Loan（貸出）
- `id`: UUID - 貸出の一意識別子
- `bookId`: UUID - 貸し出された絵本のID
- `userId`: UUID - 借りた利用者のID
- `loanDate`: Date - 貸出日
- `dueDate`: Date - 返却期限日
- `returnedDate`: Date? - 返却日（未返却の場合はnil）

## 使用方法

このパッケージは管理アプリと利用者アプリの両方から参照され、共通のデータモデルを提供します。
