#!/bin/bash

# App Store用スクリーンショット自動撮影スクリプト
set -e

echo "🚀 App Store用スクリーンショット撮影を開始..."

# デバイス一覧
DEVICES=(
  "iPhone 15 Pro Max"
  "iPhone XS Max" 
  "iPad Pro (12.9-inch) (6th generation)"
)

# 各デバイスでスクリーンショット撮影
for DEVICE in "${DEVICES[@]}"; do
  echo "📱 $DEVICE での撮影開始..."
  
  # シミュレーター起動
  DEVICE_ID=$(xcrun simctl list devices | grep "$DEVICE" | head -1 | grep -o '[A-F0-9-]\{36\}')
  if [ -z "$DEVICE_ID" ]; then
    echo "❌ $DEVICE が見つかりません"
    continue
  fi
  
  echo "デバイスID: $DEVICE_ID"
  xcrun simctl boot "$DEVICE_ID" || true
  sleep 5
  
  # アプリ起動（Release mode）
  echo "アプリ起動中..."
  flutter run -d "$DEVICE_ID" --release &
  FLUTTER_PID=$!
  
  # アプリ起動待機
  sleep 25
  
  # 複数画面のスクリーンショット撮影
  TIMESTAMP=$(date +%Y%m%d_%H%M%S)
  DEVICE_NAME=$(echo "$DEVICE" | sed 's/ /_/g' | sed 's/(//g' | sed 's/)//g')
  
  # メイン画面
  xcrun simctl io "$DEVICE_ID" screenshot "screenshot_${DEVICE_NAME}_main_${TIMESTAMP}.png"
  echo "📸 メイン画面撮影完了"
  
  sleep 3
  
  # プロフィール画面（タブ切り替え想定）
  xcrun simctl io "$DEVICE_ID" screenshot "screenshot_${DEVICE_NAME}_profile_${TIMESTAMP}.png"
  echo "📸 プロフィール画面撮影完了"
  
  # Flutter プロセス終了
  kill $FLUTTER_PID || true
  sleep 2
  
  # シミュレーター終了
  xcrun simctl shutdown "$DEVICE_ID" || true
  
  echo "✅ $DEVICE での撮影完了"
done

echo "🎉 全デバイスでのスクリーンショット撮影完了！"
echo "📁 ファイル一覧:"
ls -la screenshot_*.png
