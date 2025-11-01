/// 🌍 環境設定
/// アプリの実行環境（開発/本番）を管理

enum Environment {
  /// 開発環境（テスト用）
  development,
  
  /// 本番環境（リリース用）
  production,
}

class EnvironmentConfig {
  // 現在の環境（デフォルトは開発環境）
  static Environment _currentEnvironment = Environment.development;
  
  /// 現在の環境を取得
  static Environment get current => _currentEnvironment;
  
  /// 環境を設定（アプリ起動時に呼び出す）
  static void setEnvironment(Environment env) {
    _currentEnvironment = env;
  }
  
  /// 開発環境かどうか
  static bool get isDevelopment => _currentEnvironment == Environment.development;
  
  /// 本番環境かどうか
  static bool get isProduction => _currentEnvironment == Environment.production;
  
  /// 環境名を取得
  static String get environmentName {
    switch (_currentEnvironment) {
      case Environment.development:
        return '開発環境';
      case Environment.production:
        return '本番環境';
    }
  }
  
  /// 環境の短縮名を取得
  static String get environmentShortName {
    switch (_currentEnvironment) {
      case Environment.development:
        return 'DEV';
      case Environment.production:
        return 'PROD';
    }
  }
  
  /// 環境の色を取得（UI表示用）
  static int get environmentColor {
    switch (_currentEnvironment) {
      case Environment.development:
        return 0xFFFF9800; // オレンジ
      case Environment.production:
        return 0xFF4CAF50; // グリーン
    }
  }
}

