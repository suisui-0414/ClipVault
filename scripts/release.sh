#!/bin/bash
# .app バンドルをビルドし、/Applications に配置するリリーススクリプト
# 使い方: scripts/release.sh <version> [build]
set -euo pipefail

VERSION="${1:?バージョンを指定してください (例: scripts/release.sh 1.1)}"
BUILD="${2:-$VERSION}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

APP_NAME="ClipVault"
APP_DIR="build/${APP_NAME}.app"

echo "==> リリースビルド中 (version ${VERSION}, build ${BUILD})"
swift build -c release

echo "==> .app バンドルを作成中"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
cp ".build/release/${APP_NAME}" "$APP_DIR/Contents/MacOS/${APP_NAME}"

cat > "$APP_DIR/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>dev.suisui.${APP_NAME}</string>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleVersion</key>
    <string>${BUILD}</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

echo "==> ad-hoc署名中"
codesign --force --deep --sign - "$APP_DIR"

echo "==> 既存プロセスを終了 (リリース版・デバッグ版とも)"
pkill -f "/${APP_NAME}\$" 2>/dev/null || true

echo "==> /Applications に配置中"
rm -rf "/Applications/${APP_NAME}.app"
cp -R "$APP_DIR" "/Applications/${APP_NAME}.app"

echo "==> 起動"
open "/Applications/${APP_NAME}.app"

echo "完了: /Applications/${APP_NAME}.app (v${VERSION}, build ${BUILD})"
