import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vote/services/log_service.dart';
import 'package:vote/config/debug_config.dart';
import 'package:vote/constants/regions.dart';

class UserService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LogService _logService = LogService();
  DateTime? _lastUpdateTime;
  
  // 同時更新制限用のロック
  // static final _updateLocks = <String, DateTime>{};
  
  // メトリクス
  static final _metrics = <String, int>{};

  // パフォーマンス計測用のログ
  // void _logPerformance(String operation, DateTime startTime) {
  //   final duration = DateTime.now().difference(startTime);
  //   print('Performance: $operation took ${duration.inMilliseconds}ms');
  // }

  // メトリクスのインクリメント
  // void _incrementMetric(String name) {
  //   _metrics[name] = (_metrics[name] ?? 0) + 1;
  // }

  // 更新頻度のチェック（5秒に1回まで）
  bool canUpdateUsername() {
    if (_lastUpdateTime == null) return true;
    final now = DateTime.now();
    return now.difference(_lastUpdateTime!).inSeconds >= 5;
  }

  // ユーザー名のバリデーション
  bool isValidUsername(String username) {
    // 長さのチェック（3〜20文字）
    if (username.length < 3 || username.length > 20) {
      return false;
    }
    
    // 使用可能な文字のチェック（メールアドレスの@以前の部分で使用できる文字）
    final validCharacters = RegExp(r'^[a-zA-Z0-9._%+-]+$');
    if (!validCharacters.hasMatch(username)) {
      return false;
    }
    
    // ドットの連続使用を禁止
    if (username.contains('..')) {
      return false;
    }
    
    // 先頭と末尾のドットを禁止
    if (username.startsWith('.') || username.endsWith('.')) {
      return false;
    }
    
    return true;
  }

  // ユーザープロファイルの取得
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      DebugConfig.debugLog('getUserProfile開始');
      _logService.startTrace('get_user_profile');
      final user = _auth.currentUser;
      if (user == null) {
        DebugConfig.debugWarning('ユーザーがログインしていません');
        _logService.logWarning('ユーザーがログインしていません');
        return null;
      }

      DebugConfig.debugLog('Firestoreからプロファイル取得開始', data: {'uid': user.uid});
      final doc = await _firestore.collection('users').doc(user.uid).get();
      
      if (!doc.exists) {
        DebugConfig.debugWarning('プロファイルが存在しません', data: {'uid': user.uid});
      } else {
        DebugConfig.debugSuccess('プロファイル取得成功', data: {
          'uid': user.uid,
          'username': doc.data()?['username'],
        });
      }
      
      _logService.logInfo('ユーザープロフィール取得成功', data: {'uid': user.uid});
      _logService.stopTrace('get_user_profile');
      return doc.data();
    } catch (e, stackTrace) {
      DebugConfig.debugError('getUserProfileエラー', error: e, stackTrace: stackTrace);
      _logService.logError(
        e,
        stackTrace,
        reason: 'ユーザープロフィールの取得に失敗',
        parameters: {'uid': _auth.currentUser?.uid},
        errorCode: LogService.errorCodes['USER_PROFILE_FETCH'],
      );
      _logService.stopTrace('get_user_profile');
      rethrow;
    }
  }

  // ユーザー名の更新
  Future<bool> updateUsername(String newUsername) async {
    try {
      _logService.startTrace('update_username');
      final user = _auth.currentUser;
      if (user == null) {
        _logService.logWarning('ユーザーがログインしていません');
        return false;
      }

      // バリデーションの結果をログに出力
      _logService.logInfo(
        'ユーザー名のバリデーション',
        data: {
          'username': newUsername,
          'length': newUsername.length,
          'isValid': isValidUsername(newUsername),
        },
      );

      // ユーザー名の重複チェック
      final existingUser = await _firestore
          .collection('users')
          .where('username', isEqualTo: newUsername)
          .get();

      if (existingUser.docs.isNotEmpty) {
        _logService.logWarning(
          'ユーザー名が既に使用されています',
          data: {
            'username': newUsername,
            'existingUsers': existingUser.docs.length,
          },
        );
        return false;
      }

      // ユーザー名の更新
      await _firestore.collection('users').doc(user.uid).update({
        'username': newUsername,
        'lastUpdate': FieldValue.serverTimestamp(),
      });

      _logService.logInfo(
        'ユーザー名の更新に成功',
        data: {'uid': user.uid, 'newUsername': newUsername},
      );
      _logService.logEvent(
        name: 'username_updated',
        parameters: {
          'uid': user.uid,
          'new_username': newUsername,
        },
      );
      _logService.stopTrace('update_username');
      return true;
    } catch (e, stackTrace) {
      _logService.logError(
        e,
        stackTrace,
        reason: 'ユーザー名の更新に失敗',
        parameters: {
          'uid': _auth.currentUser?.uid,
          'newUsername': newUsername,
        },
        errorCode: LogService.errorCodes['USERNAME_UPDATE'],
      );
      _logService.stopTrace('update_username');
      return false;
    }
  }

  // 投稿数の取得
  Future<int> getPostCount() async {
    try {
      _logService.startTrace('get_post_count');
      final user = _auth.currentUser;
      if (user == null) {
        _logService.logWarning('ユーザーがログインしていません');
        return 0;
      }

      final snapshot = await _firestore
          .collection('posts')
          .where('userId', isEqualTo: user.uid)
          .count()
          .get();

      final count = snapshot.count ?? 0;
      _logService.logInfo(
        '投稿数の取得に成功',
        data: {'uid': user.uid, 'count': count},
      );
      _logService.stopTrace('get_post_count');
      return count;
    } catch (e, stackTrace) {
      _logService.logError(
        e,
        stackTrace,
        reason: '投稿数の取得に失敗',
        parameters: {'uid': _auth.currentUser?.uid},
        errorCode: LogService.errorCodes['POST_COUNT_FETCH'],
      );
      _logService.stopTrace('get_post_count');
      rethrow;
    }
  }

  // 投票数の取得
  Future<int> getVoteCount() async {
    try {
      _logService.startTrace('get_vote_count');
      final user = _auth.currentUser;
      if (user == null) {
        _logService.logWarning('ユーザーがログインしていません');
        return 0;
      }

      final snapshot = await _firestore
          .collection('votes')
          .where('userId', isEqualTo: user.uid)
          .count()
          .get();

      final count = snapshot.count ?? 0;
      _logService.logInfo(
        '投票数の取得に成功',
        data: {'uid': user.uid, 'count': count},
      );
      _logService.stopTrace('get_vote_count');
      return count;
    } catch (e, stackTrace) {
      _logService.logError(
        e,
        stackTrace,
        reason: '投票数の取得に失敗',
        parameters: {'uid': _auth.currentUser?.uid},
        errorCode: LogService.errorCodes['VOTE_COUNT_FETCH'],
      );
      _logService.stopTrace('get_vote_count');
      rethrow;
    }
  }

  // 地域（都道府県）の更新
  Future<bool> updateRegion(String region) async {
    try {
      DebugConfig.debugLog('地域更新開始', data: {'region': region});
      _logService.startTrace('update_region');
      final user = _auth.currentUser;
      if (user == null) {
        DebugConfig.debugWarning('ユーザーがログインしていません');
        _logService.logWarning('ユーザーがログインしていません');
        return false;
      }

      // バリデーション
      if (!Regions.isValidPrefecture(region)) {
        DebugConfig.debugError('無効な都道府県', error: region);
        _logService.logWarning('無効な都道府県が指定されました', data: {'region': region});
        return false;
      }

      // 地域の更新
      await _firestore.collection('users').doc(user.uid).update({
        'region': region,
        'lastUpdate': FieldValue.serverTimestamp(),
      });

      DebugConfig.debugSuccess('地域更新成功', data: {'uid': user.uid, 'region': region});
      _logService.logInfo(
        '地域の更新に成功',
        data: {'uid': user.uid, 'region': region},
      );
      _logService.logEvent(
        name: 'region_updated',
        parameters: {
          'uid': user.uid,
          'region': region,
        },
      );
      _logService.stopTrace('update_region');
      return true;
    } catch (e, stackTrace) {
      DebugConfig.debugError('地域更新エラー', error: e, stackTrace: stackTrace);
      _logService.logError(
        e,
        stackTrace,
        reason: '地域の更新に失敗',
        parameters: {
          'uid': _auth.currentUser?.uid,
          'region': region,
        },
        errorCode: LogService.errorCodes['USER_PROFILE_UPDATE'],
      );
      _logService.stopTrace('update_region');
      return false;
    }
  }

  // メトリクスの取得
  static Map<String, int> getMetrics() => Map.unmodifiable(_metrics);
  
  // メトリクスのリセット（テスト用）
  static void resetMetrics() => _metrics.clear();
} 