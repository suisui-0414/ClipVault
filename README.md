# ClipVault

**v1.1.2**

macOS用のメニューバー常駐型クリップボード履歴管理アプリです。Swift + SwiftUI(一部AppKit)で実装しています。

## 機能

- `NSPasteboard` をポーリングして変更を検知し、テキストのコピー履歴を自動で記録
- 履歴は最大10件まで保持し、`~/Library/Application Support/ClipVault/history.json` にローカル保存(再起動後も保持)
- メニューバーアイコンのクリック、または `⌃⌥V` のグローバルショートカットで履歴パネルを表示
- パネルはマウスカーソルの近くに表示され、他の場所をクリックすると自動で閉じる
- 履歴リストは高さ固定でスクロール表示(項目数が増えてもパネルの高さは変わらない)
- キーボード操作:
  - `↓` / `j`: 選択を下へ
  - `↑` / `k`: 選択を上へ
  - `Enter`: 選択中の項目をクリップボードにコピーしてパネルを閉じる
  - `Delete` / `Backspace`: 選択中の項目だけを履歴から削除
  - `Esc`: パネルを閉じる
- 各履歴行の✕ボタンから個別削除、「履歴をクリア」から全件削除が可能
- ログイン時に自動起動(`SMAppService` でログイン項目に登録)
- メニューバーアイコンを右クリックすると「ClipVaultを終了」を選べる(誤操作防止のため、通常の左クリック・ショートカットでは終了しない)
- Dockアイコンを表示しないアクセサリアプリとして動作

## 必要環境

- macOS 13以降
- Xcode Command Line Tools (Swift 5.9以降)

## ビルド・実行

```bash
swift run
```

開発中はこのコマンドで起動できます。メニューバーにクリップボードのアイコンが表示されます。

## アプリとしてビルド・配置する

```bash
scripts/release.sh <version> [build]
```

リリースビルドを行い、`.app` バンドルを作成して `/Applications` に配置・起動します。例: `scripts/release.sh 1.1`

## ショートカットの変更

グローバルショートカット(デフォルト `⌃⌥V`)を変更したい場合は、[Sources/ClipVault/AppDelegate.swift](Sources/ClipVault/AppDelegate.swift) 内の `GlobalHotKey` 初期化部分の `keyCode` / `modifiers` を編集してください。

## ライセンス

[MIT License](LICENSE)
