import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class LogService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;
  final FirebasePerformance _performance = FirebasePerformance.instance;

  // パフォーマンス計測用のトレース
  final Map<String, Trace> _traces = {};

  // エラーコードの定義
  static const Map<String, String> errorCodes = {
    'USER_PROFILE_FETCH': 'E001',
    'USERNAME_UPDATE': 'E002',
    'POST_COUNT_FETCH': 'E003',
    'VOTE_COUNT_FETCH': 'E004',
    'AUTH_ERROR': 'E005',
  };

  // 文字列をハッシュ化する
  String _hashString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 8); // 短いハッシュを使用
  }

  // 個人情報をマスクする
  Map<String, dynamic> _maskPersonalInfo(Map<String, dynamic>? data) {
    if (data == null) return {};
    
    final masked = Map<String, dynamic>.from(data);
    if (masked.containsKey('uid')) {
      masked['uid'] = _hashString(masked['uid'].toString());
    }
    if (masked.containsKey('email')) {
      masked['email'] = _hashString(masked['email'].toString());
    }
    if (masked.containsKey('username')) {
      masked['username'] = _hashString(masked['username'].toString());
    }
    return masked;
  }

  // トレースの開始
  void startTrace(String name) {
    final trace = _performance.newTrace(name);
    trace.start();
    _traces[name] = trace;
  }

  // トレースの終了
  void stopTrace(String name) {
    final trace = _traces[name];
    if (trace != null) {
      trace.stop();
      _traces.remove(name);
    }
  }

  // パフォーマンスメトリクスの記録
  void recordMetric(String traceName, String metricName, int value) {
    final trace = _traces[traceName];
    if (trace != null) {
      trace.setMetric(metricName, value);
    }
  }

  // イベントの記録
  Future<void> logEvent({
    required String name,
    Map<String, dynamic>? parameters,
  }) async {
    final maskedParams = _maskPersonalInfo(parameters);
    await _analytics.logEvent(
      name: name,
      parameters: Map<String, Object>.from(maskedParams),
    );
  }

  // エラーの記録
  Future<void> logError(
    dynamic error,
    StackTrace stackTrace, {
    String? reason,
    Map<String, dynamic>? parameters,
    String? errorCode,
  }) async {
    final maskedParams = _maskPersonalInfo(parameters);
    final code = errorCode ?? 'E000';
    
    await _crashlytics.recordError(
      error,
      stackTrace,
      reason: '[$code] ${reason ?? 'Error occurred'}',
      information: maskedParams.entries.map((e) => '${e.key}: ${e.value}').toList(),
    );
  }

  // ユーザープロパティの設定
  Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    final maskedValue = _hashString(value);
    await _analytics.setUserProperty(
      name: name,
      value: maskedValue,
    );
  }

  // カスタムログの記録
  void logInfo(String message, {Map<String, dynamic>? data}) {
    final maskedData = _maskPersonalInfo(data);
    if (maskedData.isNotEmpty) {
    }
  }

  void logWarning(String message, {Map<String, dynamic>? data}) {
    final maskedData = _maskPersonalInfo(data);
    if (maskedData.isNotEmpty) {
    }
  }
} 