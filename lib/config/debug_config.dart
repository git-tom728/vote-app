/// 🔧 デバッグ設定
/// デモ用の一時的なデバッグログ設定
/// 後で簡単に無効化できるように独立したファイルとして作成

class DebugConfig {
  // 🚨 デモ後は必ず false に戻すこと！
  static const bool enableDebugLogs = false;
  
  // デバッグログの出力
  static void debugLog(String message, {Map<String, dynamic>? data}) {
    if (enableDebugLogs) {
      final timestamp = DateTime.now().toIso8601String();
      print('🔍 [$timestamp] $message');
      if (data != null) {
        print('   データ: $data');
      }
    }
  }
  
  // エラーログの出力
  static void debugError(String message, {Object? error, StackTrace? stackTrace}) {
    if (enableDebugLogs) {
      final timestamp = DateTime.now().toIso8601String();
      print('❌ [$timestamp] ERROR: $message');
      if (error != null) {
        print('   エラー詳細: $error');
      }
      if (stackTrace != null) {
        print('   スタックトレース: $stackTrace');
      }
    }
  }
  
  // 成功ログの出力
  static void debugSuccess(String message, {Map<String, dynamic>? data}) {
    if (enableDebugLogs) {
      final timestamp = DateTime.now().toIso8601String();
      print('✅ [$timestamp] SUCCESS: $message');
      if (data != null) {
        print('   データ: $data');
      }
    }
  }
  
  // 警告ログの出力
  static void debugWarning(String message, {Map<String, dynamic>? data}) {
    if (enableDebugLogs) {
      final timestamp = DateTime.now().toIso8601String();
      print('⚠️ [$timestamp] WARNING: $message');
      if (data != null) {
        print('   データ: $data');
      }
    }
  }
}
