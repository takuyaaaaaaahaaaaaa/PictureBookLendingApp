# 本棚アイコンとオンボーディング画像

`PictureBookLendingAdminApp/PictureBookApp.icon` を Icon Composer で開く。

前から「Overlapping spines（右側の4冊）→ Picture book（うさぎと花の絵本）→ Bookshelf（棚と左側の4冊）」の順。右側の背表紙が絵本の端を隠し、本棚に挟まった構図になる。各SVGは1024×1024、位置は原点、倍率は1。絵本のみガラス効果を有効にし、表紙の絵が読めるよう半透明は無効にしている。棚の明暗は奥行きの形を示すための色分けで、光の反射はIcon Composerが付ける。

アプリにwatchOSターゲットがないため、対応形状はshared squaresのみ。

## オンボーディング画像を更新する

正本は `.icon/Assets` の3枚のSVG。オンボーディングではアプリアイコンの外側の背景やガラス反射を付けず、この3枚を重ねた透明PNGを使う。SVGを変更したら、以下をリポジトリのルートで実行して画像も更新する。

Node.jsと`sharp`を利用する。Codexのバンドル環境では `load_workspace_dependencies` が返すNode.jsを使用し、同じ応答のNode.js packagesパスを `NODE_PATH` に設定する。通常の開発環境では`sharp`が解決できるNode.js環境で実行する。

```javascript
// nodeに渡すスクリプト。全レイヤーが等倍・原点配置の現在の構成用。
const fs = require('node:fs');
const path = require('node:path');
const sharp = require('sharp');
const root = 'PictureBookLendingAdminApp';
const icon = path.join(root, 'PictureBookApp.icon');
const config = JSON.parse(fs.readFileSync(path.join(icon, 'icon.json'), 'utf8'));
const layers = [...config.groups].reverse().flatMap(group =>
  [...group.layers].reverse().map(layer => ({
    input: path.join(icon, 'Assets', layer['image-name'])
  }))
);
sharp({ create: { width: 1024, height: 1024, channels: 4, background: '#00000000' } })
  .composite(layers)
  .png()
  .toFile(path.join(root, 'PictureBookLendingAdmin/Assets.xcassets/OnboardingBookshelf.imageset/OnboardingBookshelf.png'))
  .catch(error => { console.error(error); process.exitCode = 1; });
```

レイヤーの位置・倍率を変更した場合は合成手順も合わせて調整する。画像参照は `SetupGuideView.swift` の `Image("OnboardingBookshelf")`。
