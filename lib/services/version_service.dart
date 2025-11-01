/// 📱 バージョン管理サービス
/// Firebase Remote Configを使用して最新バージョンを管理し、
/// ユーザーにアップデートを促す機能を提供

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../config/debug_config.dart';

class VersionService {
  static final VersionService _instance = VersionService._internal();
  factory VersionService() => _instance;
  VersionService._internal();

  late FirebaseRemoteConfig _remoteConfig;
  late PackageInfo _packageInfo;
  bool _initialized = false;

  /// 初期化
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      DebugConfig.debugLog('VersionService: 初期化開始');

      // パッケージ情報を取得
      _packageInfo = await PackageInfo.fromPlatform();
      DebugConfig.debugLog('現在のバージョン', data: {
        'version': _packageInfo.version,
        'buildNumber': _packageInfo.buildNumber,
      });

      // Remote Configの初期化
      _remoteConfig = FirebaseRemoteConfig.instance;
      
      // Remote Configの設定
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 1), // 1時間に1回チェック
      ));

      // デフォルト値を設定
      await _remoteConfig.setDefaults({
        'latest_version': '1.0.0',
        'minimum_version': '1.0.0',
        'force_update': false,
        'update_message_ja': 'アプリの新しいバージョンが利用可能です。',
        'force_update_message_ja': 'このバージョンはサポートが終了しました。最新バージョンにアップデートしてください。',
        'ios_store_url': 'https://apps.apple.com/jp/app/your-app-id',
        'android_store_url': 'https://play.google.com/store/apps/details?id=your.package.name',
      });

      // Remote Configの値を取得
      await _remoteConfig.fetchAndActivate();
      
      _initialized = true;
      DebugConfig.debugSuccess('VersionService: 初期化完了');
    } catch (e, stackTrace) {
      DebugConfig.debugError('VersionService: 初期化エラー', 
        error: e, stackTrace: stackTrace);
      // エラーが発生してもアプリは動作させる
      _initialized = true;
    }
  }

  /// 現在のバージョンを取得
  String get currentVersion => _packageInfo.version;

  /// 現在のビルド番号を取得
  String get currentBuildNumber => _packageInfo.buildNumber;

  /// 最新バージョンを取得
  String get latestVersion => _remoteConfig.getString('latest_version');

  /// 最低必須バージョンを取得
  String get minimumVersion => _remoteConfig.getString('minimum_version');

  /// 強制アップデートが必要かどうか
  bool get forceUpdate => _remoteConfig.getBool('force_update');

  /// アップデートメッセージ（通常）
  String get updateMessage => _remoteConfig.getString('update_message_ja');

  /// アップデートメッセージ（強制）
  String get forceUpdateMessage => _remoteConfig.getString('force_update_message_ja');

  /// App StoreのURL（iOS）
  String get iosStoreUrl => _remoteConfig.getString('ios_store_url');

  /// Google Play StoreのURL（Android）
  String get androidStoreUrl => _remoteConfig.getString('android_store_url');

  /// アップデートが必要かチェック
  /// 戻り値: UpdateStatus
  Future<UpdateStatus> checkForUpdate() async {
    if (!_initialized) {
      await initialize();
    }

    try {
      DebugConfig.debugLog('アップデートチェック開始');

      // Remote Configの値を再取得（キャッシュ時間を考慮）
      await _remoteConfig.fetchAndActivate();

      final current = _parseVersion(currentVersion);
      final latest = _parseVersion(latestVersion);
      final minimum = _parseVersion(minimumVersion);

      DebugConfig.debugLog('バージョン比較', data: {
        'current': currentVersion,
        'latest': latestVersion,
        'minimum': minimumVersion,
        'forceUpdate': forceUpdate,
      });

      // 最低必須バージョンより古い場合は強制アップデート
      if (_isVersionLessThan(current, minimum) || forceUpdate) {
        DebugConfig.debugWarning('強制アップデートが必要');
        return UpdateStatus.forceUpdate;
      }

      // 最新バージョンより古い場合は任意アップデート
      if (_isVersionLessThan(current, latest)) {
        DebugConfig.debugLog('アップデートが利用可能');
        return UpdateStatus.updateAvailable;
      }

      DebugConfig.debugSuccess('最新バージョンを使用中');
      return UpdateStatus.upToDate;
    } catch (e, stackTrace) {
      DebugConfig.debugError('アップデートチェックエラー', 
        error: e, stackTrace: stackTrace);
      return UpdateStatus.error;
    }
  }

  /// バージョン文字列をパース（例: "1.0.2" -> [1, 0, 2]）
  List<int> _parseVersion(String version) {
    try {
      return version.split('.').map((e) => int.parse(e)).toList();
    } catch (e) {
      DebugConfig.debugError('バージョンのパースエラー', error: e);
      return [0, 0, 0];
    }
  }

  /// バージョンAがバージョンBより古いかチェック
  bool _isVersionLessThan(List<int> versionA, List<int> versionB) {
    for (int i = 0; i < 3; i++) {
      final a = i < versionA.length ? versionA[i] : 0;
      final b = i < versionB.length ? versionB[i] : 0;
      
      if (a < b) return true;
      if (a > b) return false;
    }
    return false; // 同じバージョン
  }
}

/// アップデートステータス
enum UpdateStatus {
  /// 最新バージョンを使用中
  upToDate,
  /// アップデートが利用可能（任意）
  updateAvailable,
  /// 強制アップデートが必要
  forceUpdate,
  /// エラー
  error,
}

