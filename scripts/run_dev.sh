#!/bin/bash
# 開発環境でアプリを起動するスクリプト

echo "🔧 開発環境でアプリを起動します..."
echo "📱 Firebase Project: vote-app1 (開発用)"
echo ""

# 開発環境のエントリーポイントを指定してアプリを起動
flutter run --dart-define=ENVIRONMENT=development -t lib/main.dart

# または、mainDev()を使用する場合:
# flutter run --target lib/main_dev.dart

