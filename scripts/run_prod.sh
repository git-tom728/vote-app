#!/bin/bash
# 本番環境でアプリを起動するスクリプト

echo "🚀 本番環境でアプリを起動します..."
echo "📱 Firebase Project: vote-app1 (本番用)"
echo ""

# 本番環境のエントリーポイントを指定してアプリを起動
flutter run --dart-define=ENVIRONMENT=production -t lib/main.dart

