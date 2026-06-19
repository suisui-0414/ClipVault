# ClipVault

macOS用のメニューバー常駐型クリップボード履歴管理アプリです。Swift + SwiftUI(一部AppKit)で実装しています。

## 機能

- `NSPasteboard` をポーリングして変更を検知し、テキストのコピー履歴を自動で記録
- 履歴は最大10件まで保持し、`~/Library/Application Support/ClipVault/history.json` にローカル保存(再起動後も保持)
- メニューバーアイコンのクリック、または `⌘⇧V` のグローバルショートカットで履歴パネルを表示
- パネルはマウスカーソルの近くに表示され、他の場所をクリックすると自動で閉じる
- キーボード操作:
  - `↓` / `j`: 選択を下へ
  - `↑` / `k`: 選択を上へ
  - `Enter`: 選択中の項目をクリップボードにコピーしてパネルを閉じる
  - `Delete` / `Backspace`: 選択中の項目だけを履歴から削除
  - `Esc`: パネルを閉じる
- 各履歴行の✕ボタンから個別削除、「履歴をクリア」から全件削除が可能
- Dockアイコンを表示しないアクセサリアプリとして動作

## 必要環境

- macOS 13以降
- Xcode Command Line Tools (Swift 5.9以降)

## ビルド・実行

```bash
swift run
```

開発中はこのコマンドで起動できます。メニューバーにクリップボードのアイコンが表示されます。

## アプリとしてビルドする

```bash
swift build -c release
```

`.build/release/ClipVault` に実行バイナリが生成されます。`.app` バンドル化して `/Applications` に配置する手順は別途スクリプト等で対応してください。

## ショートカットの変更

グローバルショートカット(デフォルト `⌘⇧V`)を変更したい場合は、[Sources/ClipVault/AppDelegate.swift](Sources/ClipVault/AppDelegate.swift) 内の `GlobalHotKey` 初期化部分の `keyCode` / `modifiers` を編集してください。

## ライセンス

特に指定なし。
