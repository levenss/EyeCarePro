#!/bin/bash
set -e

APP_NAME="A护眼宝"
BUNDLE_ID="com.zep.eyecare"
BUILD_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_BUNDLE="${BUILD_DIR}/${APP_NAME}.app"

echo "==> 🚀 开始编译 ${APP_NAME} (Apple Silicon ARM64)..."

# 1. 编译 Swift 源码
swiftc -O -target arm64-apple-macos14.0 \
  "${BUILD_DIR}/src/Models.swift" \
  "${BUILD_DIR}/src/OverlayManager.swift" \
  "${BUILD_DIR}/src/RestReminderView.swift" \
  "${BUILD_DIR}/src/RestTimerManager.swift" \
  "${BUILD_DIR}/src/ContentView.swift" \
  "${BUILD_DIR}/src/AppDelegate.swift" \
  "${BUILD_DIR}/src/main.swift" \
  -o "${BUILD_DIR}/${APP_NAME}"

echo "==> 📦 打包 macOS Application Bundle..."
rm -rf "${APP_BUNDLE}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

cp "${BUILD_DIR}/${APP_NAME}" "${APP_BUNDLE}/Contents/MacOS/"
cp "${BUILD_DIR}/Info.plist" "${APP_BUNDLE}/Contents/"
cp "${BUILD_DIR}/AppIcon.icns" "${APP_BUNDLE}/Contents/Resources/"

echo "==> 🔏 签署应用 (Ad-hoc Signature)..."
codesign --force --deep --sign - "${APP_BUNDLE}"

echo "==> ✅ 编译完成！生成路径: ${APP_BUNDLE}"
echo "==> 可直接双击运行或复制到 /Applications/ 使用。"
