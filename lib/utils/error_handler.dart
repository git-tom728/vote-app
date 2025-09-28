// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;

// ═══════════════════════════════════════════════════════════════════════════════════
// 📋 SnackBar設定クラス (SnackBar Configuration Class)
// ═══════════════════════════════════════════════════════════════════════════════════

/// SnackBarの基本設定クラス
class SnackBarConfig {
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final Color textColor;
  final Duration duration;
  final bool showAction;
  final String actionLabel;
  final Color actionTextColor;

  const SnackBarConfig({
    required this.icon,
    required this.backgroundColor,
    this.iconColor = Colors.white,
    this.textColor = Colors.white,
    this.duration = const Duration(seconds: 3),
    this.showAction = false,
    this.actionLabel = 'OK',
    this.actionTextColor = Colors.white,
  });
}

// ═══════════════════════════════════════════════════════════════════════════════════
// 📋 VBAスタイル設定クラス (VBA-Style Configuration Classes)
// ═══════════════════════════════════════════════════════════════════════════════════

/// 操作設定クラス（VBAの変数宣言に相当）
class OperationConfig {
  // 基本設定
  String operationName;
  bool logOperation;
  
  // UI設定
  BuildContext? context;
  bool showLoading;
  String loadingMessage;
  bool showSuccessMessage;
  String? successMessage;
  String? customErrorMessage;
  
  // コールバック設定
  Function(dynamic error)? onError;
  
  // 結果格納用（VBAの戻り値に相当）
  dynamic result;
  bool isSuccess;
  dynamic error;
  String? errorMessage;

  OperationConfig({
    required this.operationName,
    this.logOperation = true,
    this.context,
    this.showLoading = false,
    this.loadingMessage = '処理中...',
    this.showSuccessMessage = false,
    this.successMessage,
    this.customErrorMessage,
    this.onError,
    this.result,
    this.isSuccess = false,
    this.error,
    this.errorMessage,
  });

  /// 設定をリセット（VBAのClearに相当）
  void clear() {
    result = null;
    isSuccess = false;
    error = null;
    errorMessage = null;
  }

  /// 設定をコピー（VBAのCopyに相当）
  OperationConfig copy() {
    return OperationConfig(
      operationName: operationName,
      logOperation: logOperation,
      context: context,
      showLoading: showLoading,
      loadingMessage: loadingMessage,
      showSuccessMessage: showSuccessMessage,
      successMessage: successMessage,
      customErrorMessage: customErrorMessage,
      onError: onError,
    );
  }
}

/// SnackBar処理依頼クラス（VBAのSnackBar変数宣言に相当）
class SnackBarRequest {
  // 基本設定
  BuildContext context;
  String message;
  String type;
  
  // カスタマイズ設定
  Duration? customDuration;
  SnackBarConfig? customConfig;
  bool? showAction;
  String? actionLabel;
  VoidCallback? onActionPressed;

  SnackBarRequest({
    required this.context,
    required this.message,
    required this.type,
    this.customDuration,
    this.customConfig,
    this.showAction,
    this.actionLabel,
    this.onActionPressed,
  });

  /// 設定をコピー（VBAのCopyに相当）
  SnackBarRequest copy() {
    return SnackBarRequest(
      context: context,
      message: message,
      type: type,
      customDuration: customDuration,
      customConfig: customConfig,
      showAction: showAction,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
    );
  }

  /// エラー用の設定を適用（VBAのSetErrorに相当）
  void setAsError(dynamic error, {String? customMessage}) {
    type = 'error';
    message = customMessage ?? ErrorHandler.getGeneralErrorMessage(error);
  }

  /// 成功用の設定を適用（VBAのSetSuccessに相当）
  void setAsSuccess(String successMessage) {
    type = 'success';
    message = successMessage;
  }

  /// 警告用の設定を適用（VBAのSetWarningに相当）
  void setAsWarning(String warningMessage) {
    type = 'warning';
    message = warningMessage;
  }

  /// 情報用の設定を適用（VBAのSetInfoに相当）
  void setAsInfo(String infoMessage) {
    type = 'info';
    message = infoMessage;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════════
// 🎯 ERROR HANDLER - アプリ全体のエラーハンドリングユーティリティ
// ═══════════════════════════════════════════════════════════════════════════════════
//
// 【構成】
// 1️⃣ エラーメッセージ変換 (Error Message Translation)
//    ・login.dart - Firebase Authエラーメッセージ変換
//    ・register.dart - Firebase Auth & Firestoreエラーメッセージ変換
//    ・vote.dart, post.dart - Firestoreエラーメッセージ変換
//    ・myself.dart - 認証・データベース関連エラーメッセージ変換
//
// 2️⃣ UI表示機能 (UI Display Functions) 
//    ・全ファイル共通 - SnackBar, Dialog表示
//    ・特に使用: login.dart, register.dart, post_create.dart
//
// 3️⃣ ログ出力機能 (Logging Functions)
//    ・main.dart - AuthGate認証状態ログ
//    ・login.dart, register.dart - 認証処理ログ
//    ・vote.dart, post.dart - データ操作ログ
//    ・myself.dart - ユーザー操作ログ
//
// 4️⃣ 操作ラッパー (Operation Wrappers)
//    🔧 共有パーツ: _handleOperationStart, _handleOperationSuccess, _handleOperationError, _showLoadingIfNeeded
//    ・login.dart - handleFirebase<UserCredential>
//    ・register.dart - handleFirebase<UserCredential>, handleAsync<DocumentReference>
//    ・vote.dart, post.dart - handleFirebase<DocumentReference>, handleAsync<QuerySnapshot>
//    ・post_create.dart - handleFirebase<DocumentReference>
//
// 5️⃣ ミックスイン (Mixin for State Classes)
//    ・login.dart - showError, showSuccess, handleFirebase
//    ・register.dart - showError, showSuccess, handleFirebase
//    ・post_create.dart - showError, showSuccess, handleAsync
//    ・vote.dart, post.dart - showError, showWarning, handleFirebase
//    ・myself.dart - showError, showSuccess, showConfirm, handleFirebase
//
// ═══════════════════════════════════════════════════════════════════════════════════

/// アプリ全体で使用するエラーハンドリングユーティリティ
class ErrorHandler {
  
  // ═══════════════════════════════════════════════════════════════════════════════════
  // 1️⃣ エラーメッセージ変換 (Error Message Translation)
  // ═══════════════════════════════════════════════════════════════════════════════════
  
  // 🔐 Firebase Auth関連エラー
  /// Firebase Authエラーを日本語メッセージに変換
  static String getAuthErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'このメールアドレスは登録されていません';
        case 'wrong-password':
          return 'パスワードが正しくありません';
        case 'email-already-in-use':
          return 'このメールアドレスは既に使用されています';
        case 'weak-password':
          return 'パスワードが弱すぎます。6文字以上で設定してください';
        case 'invalid-email':
          return 'メールアドレスの形式が正しくありません';
        case 'requires-recent-login':
          return '最近ログインしていないため、再認証が必要です';
        case 'too-many-requests':
          return '試行回数が多すぎます。しばらく待ってから再試行してください';
        case 'network-request-failed':
          return 'ネットワーク接続を確認してください';
        case 'operation-not-allowed':
          return 'この操作は許可されていません';
        case 'user-disabled':
          return 'このアカウントは無効化されています';
        case 'invalid-credential':
          return '認証情報が無効です';
        default:
          return error.message ?? '認証エラーが発生しました';
      }
    }
    return error.toString();
  }

  // 🗄️ Firestore関連エラー
  /// Firestore エラーを日本語メッセージに変換
  static String getFirestoreErrorMessage(dynamic error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'データにアクセスする権限がありません';
        case 'not-found':
          return '指定されたデータが見つかりません';
        case 'already-exists':
          return '既に存在するデータです';
        case 'cancelled':
          return '操作がキャンセルされました';
        case 'invalid-argument':
          return '無効な引数が指定されました';
        case 'deadline-exceeded':
          return '操作がタイムアウトしました';
        case 'unavailable':
          return 'サービスが一時的に利用できません';
        case 'unauthenticated':
          return 'ログインが必要です';
        case 'resource-exhausted':
          return 'リソースの制限に達しました';
        default:
          return error.message ?? 'データベースエラーが発生しました';
      }
    }
    return error.toString();
  }

  // 🌐 汎用エラーメッセージ
  /// 一般的なエラーメッセージを取得
  static String getGeneralErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      return getAuthErrorMessage(error);
    } else if (error is FirebaseException) {
      return getFirestoreErrorMessage(error);
    } else {
      return error.toString();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════════════
  // 2️⃣ UI表示機能 (UI Display Functions)
  // ═══════════════════════════════════════════════════════════════════════════════════

  // 📢 SnackBar表示

  // ═══════════════════════════════════════════════════════════════════════════════════
  // 🔧 SnackBar基本形設定 (SnackBar Base Configuration)
  // ═══════════════════════════════════════════════════════════════════════════════════

  /// SnackBar種類別の基本設定
  static const Map<String, SnackBarConfig> _snackBarConfigs = {
    'error': SnackBarConfig(
      icon: Icons.error_outline,
      backgroundColor: Colors.red,
      duration: Duration(seconds: 5),
      showAction: true,
    ),
    'warning': SnackBarConfig(
      icon: Icons.warning_amber_rounded,
      backgroundColor: Colors.orange,
      duration: Duration(seconds: 4),
      showAction: true,
    ),
    'success': SnackBarConfig(
      icon: Icons.check_circle_outline,
      backgroundColor: Colors.green,
      duration: Duration(seconds: 3),
      showAction: false,
    ),
    'info': SnackBarConfig(
      icon: Icons.info_outline,
      backgroundColor: Colors.blue,
      duration: Duration(seconds: 3),
      showAction: false,
    ),
  };

  /// 🔧 共有パーツ - SnackBar基本形作成
  /// 設定に基づいてSnackBarを作成する共通処理
  static SnackBar _buildBaseSnackBar(
    String message,
    String type, {
    SnackBarConfig? customConfig,
    Duration? customDuration,
    bool? showAction,
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    final config = customConfig ?? _snackBarConfigs[type] ?? _snackBarConfigs['info']!;
    final duration = customDuration ?? config.duration;
    final hasAction = showAction ?? config.showAction;

    return SnackBar(
      content: Row(
        children: [
          Icon(config.icon, color: config.iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: config.textColor),
            ),
          ),
        ],
      ),
      backgroundColor: config.backgroundColor,
      duration: duration,
      action: hasAction
          ? SnackBarAction(
              label: actionLabel ?? config.actionLabel,
              textColor: config.actionTextColor,
              onPressed: onActionPressed ?? () {
                // デフォルトはSnackBarを閉じる（contextは呼び出し元で処理）
              },
            )
          : null,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════════════
  // 📢 SnackBar表示メソッド (SnackBar Display Methods)
  // ═══════════════════════════════════════════════════════════════════════════════════

  /// 🔧 統一SnackBar表示（VBAスタイル処理フロー）
  /// 1. 処理依頼 → 2. 変数代入 → 3. 共有パーツに引数渡し
  /// 【使用する共有パーツ】procProcessSnackBarRequest
  static void showSnackBar(
    BuildContext context,
    String message,
    String type, {
    Duration? customDuration,
    SnackBarConfig? customConfig,
    bool? showAction,
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    // VBAスタイル: 処理依頼オブジェクトを作成
    final request = SnackBarRequest(
      context: context,
      message: message,
      type: type,
      customDuration: customDuration,
      customConfig: customConfig,
      showAction: showAction,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
    );

    // エラーハンドラー内で変数代入→共有パーツに引数渡し
    procProcessSnackBarRequest(request);
  }

  // ═══════════════════════════════════════════════════════════════════════════════════
  // 📢 従来型SnackBar表示メソッド (Legacy SnackBar Methods) - 既存コード互換用
  // ═══════════════════════════════════════════════════════════════════════════════════

  /// エラーSnackBarを表示
  /// 【使用する共有パーツ】showSnackBar
  static void showErrorSnackBar(
    BuildContext context,
    dynamic error, {
    String? customMessage,
    Duration? customDuration,
    SnackBarConfig? customConfig,
    String? actionLabel,
  }) {
    final message = customMessage ?? getGeneralErrorMessage(error);
    showSnackBar(
      context,
      message,
      'error',
      customDuration: customDuration,
      customConfig: customConfig,
      actionLabel: actionLabel,
    );
  }

  /// 警告SnackBarを表示
  /// 【使用する共有パーツ】showSnackBar
  static void showWarningSnackBar(
    BuildContext context,
    String message, {
    Duration? customDuration,
    SnackBarConfig? customConfig,
    String? actionLabel,
  }) {
    showSnackBar(
      context,
      message,
      'warning',
      customDuration: customDuration,
      customConfig: customConfig,
      actionLabel: actionLabel,
    );
  }

  /// 成功SnackBarを表示
  /// 【使用する共有パーツ】showSnackBar
  static void showSuccessSnackBar(
    BuildContext context,
    String message, {
    Duration? customDuration,
    SnackBarConfig? customConfig,
    bool? showAction,
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    showSnackBar(
      context,
      message,
      'success',
      customDuration: customDuration,
      customConfig: customConfig,
      showAction: showAction,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
    );
  }

  /// 情報SnackBarを表示
  /// 【使用する共有パーツ】showSnackBar
  static void showInfoSnackBar(
    BuildContext context,
    String message, {
    Duration? customDuration,
    SnackBarConfig? customConfig,
    bool? showAction,
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    showSnackBar(
      context,
      message,
      'info',
      customDuration: customDuration,
      customConfig: customConfig,
      showAction: showAction,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
    );
  }

  // 💬 Dialog表示
  /// エラーダイアログを表示
  static Future<void> showErrorDialog(
    BuildContext context,
    dynamic error, {
    String? title,
    String? customMessage,
  }) async {
    final message = customMessage ?? getGeneralErrorMessage(error);
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.error, color: Colors.red),
              const SizedBox(width: 8),
              Text(title ?? 'エラー'),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  /// 確認ダイアログを表示
  static Future<bool> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String content,
    String confirmText = 'OK',
    String cancelText = 'キャンセル',
    Color? confirmColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancelText),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: confirmColor != null
                  ? TextButton.styleFrom(foregroundColor: confirmColor)
                  : null,
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  /// ローディングダイアログを表示
  static void showLoadingDialog(
    BuildContext context, {
    String message = '処理中...',
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Text(message),
            ],
          ),
        );
      },
    );
  }

  /// ローディングダイアログを閉じる
  static void hideLoadingDialog(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  // ═══════════════════════════════════════════════════════════════════════════════════
  // 3️⃣ ログ出力機能 (Logging Functions)
  // ═══════════════════════════════════════════════════════════════════════════════════

  /// デバッグ用エラーログ出力
  static void logError(String operation, dynamic error) {
    developer.log('❌ Error in $operation: $error', name: 'ErrorHandler');
    if (error is Exception) {
      developer.log('   Exception type: ${error.runtimeType}', name: 'ErrorHandler');
    }
  }

  /// デバッグ用情報ログ出力
  static void logInfo(String message) {
    developer.log('ℹ️ Info: $message', name: 'ErrorHandler');
  }

  /// デバッグ用警告ログ出力
  static void logWarning(String message) {
    developer.log('⚠️ Warning: $message', name: 'ErrorHandler');
  }

  // ═══════════════════════════════════════════════════════════════════════════════════
  // 4️⃣ 操作ラッパー (Operation Wrappers)
  // ═══════════════════════════════════════════════════════════════════════════════════

  // ═══════════════════════════════════════════════════════════════════════════════════
  // 🔧 VBAスタイル共有プロシージャ (VBA-Style Shared Procedures)
  // ═══════════════════════════════════════════════════════════════════════════════════

  /// 🔧 プロシージャ - 操作開始（VBAのSub StartOperation）
  /// 設定オブジェクトを受け取り、開始処理を実行
  static void procStartOperation(OperationConfig config) {
    if (config.logOperation) {
      logInfo('🚀 ${config.operationName} 開始');
    }
  }

  /// 🔧 プロシージャ - ローディング表示（VBAのSub ShowLoading）
  /// 設定オブジェクトを受け取り、ローディング表示を実行
  static void procShowLoading(OperationConfig config) {
    if (config.showLoading && config.context != null) {
      showLoadingDialog(config.context!, message: config.loadingMessage);
    }
  }

  /// 🔧 プロシージャ - 成功処理（VBAのSub HandleSuccess）
  /// 設定オブジェクトを受け取り、成功時の処理を実行し、結果を設定
  static void procHandleSuccess(OperationConfig config, dynamic result) {
    // 結果を設定（VBAの変数代入に相当）
    config.result = result;
    config.isSuccess = true;
    config.error = null;
    config.errorMessage = null;

    // ログ出力
    if (config.logOperation) {
      logInfo('✅ ${config.operationName} 成功');
    }

    // ローディングを閉じる
    if (config.showLoading && config.context != null) {
      hideLoadingDialog(config.context!);
    }

    // 成功メッセージ表示
    if (config.showSuccessMessage && 
        config.successMessage != null && 
        config.context != null) {
      showSuccessSnackBar(config.context!, config.successMessage!);
    }
  }

  /// 🔧 プロシージャ - エラー処理（VBAのSub HandleError）
  /// 設定オブジェクトを受け取り、エラー時の処理を実行し、結果を設定
  static void procHandleError(OperationConfig config, dynamic error) {
    // 結果を設定（VBAの変数代入に相当）
    config.result = null;
    config.isSuccess = false;
    config.error = error;
    config.errorMessage = config.customErrorMessage ?? getGeneralErrorMessage(error);

    // ログ出力
    logError(config.operationName, error);

    // ローディングを閉じる
    if (config.showLoading && config.context != null) {
      hideLoadingDialog(config.context!);
    }

    // エラーハンドリング
    if (config.onError != null) {
      config.onError!(error);
    } else if (config.context != null) {
      showErrorSnackBar(
        config.context!, 
        error, 
        customMessage: config.customErrorMessage
      );
    }
  }

  /// 🔧 プロシージャ - ローディング非表示（VBAのSub HideLoading）
  /// 設定オブジェクトを受け取り、ローディングを非表示
  static void procHideLoading(OperationConfig config) {
    if (config.showLoading && config.context != null) {
      hideLoadingDialog(config.context!);
    }
  }

  /// 🔧 プロシージャ - SnackBar処理依頼受付（VBAのSub ProcessSnackBarRequest）
  /// SnackBarRequest オブジェクトを受け取り、変数を代入して共有パーツに処理を依頼
  static void procProcessSnackBarRequest(SnackBarRequest request) {
    // VBAスタイル: 変数に代入
    final context = request.context;
    final message = request.message;
    final type = request.type;
    final customDuration = request.customDuration;
    final customConfig = request.customConfig;
    final showAction = request.showAction;
    final actionLabel = request.actionLabel;
    final onActionPressed = request.onActionPressed;

    // 共有パーツに引数として渡して処理
    procShowSnackBar(
      context,
      message,
      type,
      customDuration: customDuration,
      customConfig: customConfig,
      showAction: showAction,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
    );
  }

  /// 🔧 プロシージャ - SnackBar表示（VBAのSub ShowSnackBar）
  /// 設定オブジェクトとメッセージを受け取り、SnackBarを表示
  static void procShowSnackBar(
    BuildContext context,
    String message,
    String type, {
    Duration? customDuration,
    SnackBarConfig? customConfig,
    bool? showAction,
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    // デフォルトのアクション処理（SnackBarを閉じる）
    void defaultAction() {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }

    final snackBar = _buildBaseSnackBar(
      message,
      type,
      customConfig: customConfig,
      customDuration: customDuration,
      showAction: showAction,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed ?? defaultAction,
    );
    
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  // ═══════════════════════════════════════════════════════════════════════════════════
  // 🔧 従来型共有パーツ (Legacy Shared Components) - 既存コード互換用
  // ═══════════════════════════════════════════════════════════════════════════════════

  /// 🔧 共有パーツ - 操作の開始処理
  /// すべての操作ラッパーで使用される開始時の共通処理
  static void _handleOperationStart(String operationName, bool logOperation) {
    if (logOperation) {
      logInfo('🚀 $operationName 開始');
    }
  }

  /// 🔧 共有パーツ - 操作の成功処理  
  /// すべての操作ラッパーで使用される成功時の共通処理
  static void _handleOperationSuccess(
    String operationName,
    bool logOperation,
    BuildContext? context,
    bool showLoading,
    bool showSuccessMessage,
    String? successMessage,
  ) {
    if (logOperation) {
      logInfo('✅ $operationName 成功');
    }

    // ローディングを閉じる
    if (showLoading && context != null) {
      hideLoadingDialog(context);
    }

    // 成功メッセージ表示
    if (showSuccessMessage && successMessage != null && context != null) {
      showSuccessSnackBar(context, successMessage);
    }
  }

  /// 🔧 共有パーツ - 操作のエラー処理
  /// すべての操作ラッパーで使用されるエラー時の共通処理
  static void _handleOperationError(
    String operationName,
    dynamic error,
    BuildContext? context,
    bool showLoading,
    String? customErrorMessage,
    Function(dynamic error)? onError,
  ) {
    logError(operationName, error);

    // ローディングを閉じる
    if (showLoading && context != null) {
      hideLoadingDialog(context);
    }

    // カスタムエラーハンドリング
    if (onError != null) {
      onError(error);
    } else if (context != null) {
      showErrorSnackBar(context, error, customMessage: customErrorMessage);
    }
  }

  /// 🔧 共有パーツ - ローディング表示の管理
  /// 条件に応じてローディングダイアログを表示する共通処理
  static void _showLoadingIfNeeded(
    BuildContext? context,
    bool showLoading,
    String loadingMessage,
  ) {
    if (showLoading && context != null) {
      showLoadingDialog(context, message: loadingMessage);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════════════
  // ⚡ 実装メソッド (Implementation Methods) - 共有パーツを使用した具体的な処理
  // ═══════════════════════════════════════════════════════════════════════════════════

  // ═══════════════════════════════════════════════════════════════════════════════════
  // ⚡ VBAスタイル実装メソッド (VBA-Style Implementation Methods)
  // ═══════════════════════════════════════════════════════════════════════════════════

  /// ⚡ VBAスタイル非同期処理（VBAのFunction ExecuteAsync）
  /// 設定オブジェクトを受け取り、処理を実行し、結果を設定オブジェクトに格納
  /// 【使用するプロシージャ】procStartOperation, procShowLoading, procHandleSuccess, procHandleError
  static Future<void> executeAsyncOperation(
    OperationConfig config,
    Future<dynamic> Function() operation,
  ) async {
    // VBAスタイル: 変数をクリア
    config.clear();
    
    // プロシージャ呼び出し: 開始処理
    procStartOperation(config);
    procShowLoading(config);

    try {
      // 処理実行
      final result = await operation();
      
      // プロシージャ呼び出し: 成功処理
      procHandleSuccess(config, result);
    } catch (error) {
      // プロシージャ呼び出し: エラー処理
      procHandleError(config, error);
    }
  }

  /// ⚡ VBAスタイル同期処理（VBAのFunction ExecuteSync）
  /// 設定オブジェクトを受け取り、処理を実行し、結果を設定オブジェクトに格納
  /// 【使用するプロシージャ】procStartOperation, procHandleSuccess, procHandleError
  static void executeSyncOperation(
    OperationConfig config,
    dynamic Function() operation,
  ) {
    // VBAスタイル: 変数をクリア
    config.clear();
    
    // プロシージャ呼び出し: 開始処理
    procStartOperation(config);

    try {
      // 処理実行
      final result = operation();
      
      // プロシージャ呼び出し: 成功処理（ローディング無し）
      final tempShowLoading = config.showLoading;
      config.showLoading = false; // 同期処理なのでローディング無効
      procHandleSuccess(config, result);
      config.showLoading = tempShowLoading; // 元に戻す
    } catch (error) {
      // プロシージャ呼び出し: エラー処理（ローディング無し）
      final tempShowLoading = config.showLoading;
      config.showLoading = false; // 同期処理なのでローディング無効
      procHandleError(config, error);
      config.showLoading = tempShowLoading; // 元に戻す
    }
  }

  /// ⚡ VBAスタイルFirebase処理（VBAのFunction ExecuteFirebase）
  /// Firebase専用の設定オブジェクトを受け取り、処理を実行
  /// 【使用するプロシージャ】procShowLoading, procHandleSuccess, procHandleError
  static Future<void> executeFirebaseOperation(
    OperationConfig config,
    Future<dynamic> Function() operation,
  ) async {
    // VBAスタイル: 変数をクリア
    config.clear();
    
    // Firebase専用ログ
    if (config.logOperation) {
      logInfo('🔥 Firebase ${config.operationName} 開始');
    }
    
    procShowLoading(config);

    try {
      // 処理実行
      final result = await operation();
      
      // Firebase専用成功ログ
      if (config.logOperation) {
        logInfo('✅ Firebase ${config.operationName} 成功');
      }

      // プロシージャ呼び出し: 成功処理（ログは既に出力済み）
      final tempLogOperation = config.logOperation;
      config.logOperation = false; // 重複ログ防止
      procHandleSuccess(config, result);
      config.logOperation = tempLogOperation; // 元に戻す
    } on FirebaseAuthException catch (error) {
      logError('Firebase Auth ${config.operationName}', error);
      procHandleError(config, error);
    } on FirebaseException catch (error) {
      logError('Firebase ${config.operationName}', error);
      procHandleError(config, error);
    } catch (error) {
      logError('${config.operationName}（予期しないエラー）', error);
      procHandleError(config, error);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════════════
  // ⚡ 従来型実装メソッド (Legacy Implementation Methods) - 既存コード互換用
  // ═══════════════════════════════════════════════════════════════════════════════════

  // ⚡ 汎用非同期処理
  /// 非同期処理の統一ラッパー - エラーハンドリングを自動化
  /// 【使用する共有パーツ】_handleOperationStart, _showLoadingIfNeeded, _handleOperationSuccess, _handleOperationError
  static Future<T?> handleAsyncOperation<T>(
    String operationName,
    Future<T> Function() operation, {
    BuildContext? context,
    String? customErrorMessage,
    bool showLoading = false,
    String loadingMessage = '処理中...',
    bool showSuccessMessage = false,
    String? successMessage,
    bool logOperation = true,
  }) async {
    // 共有パーツ使用
    _handleOperationStart(operationName, logOperation);
    _showLoadingIfNeeded(context, showLoading, loadingMessage);

    try {
      final result = await operation();
      
      // 共有パーツ使用
      _handleOperationSuccess(
        operationName,
        logOperation,
        context,
        showLoading,
        showSuccessMessage,
        successMessage,
      );

      return result;
    } catch (error) {
      // 共有パーツ使用
      _handleOperationError(
        operationName,
        error,
        context,
        showLoading,
        customErrorMessage,
        null, // onErrorはnull
      );

      return null;
    }
  }

  // 🔄 同期処理
  /// 同期処理の統一ラッパー - エラーハンドリングを自動化
  /// 【使用する共有パーツ】_handleOperationStart, _handleOperationSuccess, _handleOperationError
  static T? handleSyncOperation<T>(
    String operationName,
    T Function() operation, {
    BuildContext? context,
    String? customErrorMessage,
    bool logOperation = true,
  }) {
    // 共有パーツ使用
    _handleOperationStart(operationName, logOperation);

    try {
      final result = operation();
      
      // 共有パーツ使用（同期処理なのでローディング関連はfalse）
      _handleOperationSuccess(
        operationName,
        logOperation,
        context,
        false, // showLoading
        false, // showSuccessMessage
        null,  // successMessage
      );

      return result;
    } catch (error) {
      // 共有パーツ使用
      _handleOperationError(
        operationName,
        error,
        context,
        false, // showLoading
        customErrorMessage,
        null,  // onError
      );

      return null;
    }
  }

  // 🔥 Firebase専用処理
  /// Firebase操作専用ラッパー - Firebase特有のエラー処理を強化
  /// 【使用する共有パーツ】_showLoadingIfNeeded, _handleOperationSuccess, _handleOperationError
  static Future<T?> handleFirebaseOperation<T>(
    String operationName,
    Future<T> Function() operation, {
    BuildContext? context,
    String? customErrorMessage,
    bool showLoading = false,
    String loadingMessage = '処理中...',
    bool showSuccessMessage = false,
    String? successMessage,
    bool logOperation = true,
    Function(dynamic error)? onError,
  }) async {
    // Firebase専用ログ
    if (logOperation) {
      logInfo('🔥 Firebase $operationName 開始');
    }
    
    _showLoadingIfNeeded(context, showLoading, loadingMessage);

    try {
      final result = await operation();
      
      // Firebase専用成功ログ
      if (logOperation) {
        logInfo('✅ Firebase $operationName 成功');
      }

      // 共有パーツ使用（ログは既に出力済みなのでfalse）
      _handleOperationSuccess(
        operationName,
        false, // logOperation - 既に出力済み
        context,
        showLoading,
        showSuccessMessage,
        successMessage,
      );

      return result;
    } on FirebaseAuthException catch (error) {
      logError('Firebase Auth $operationName', error);
      _handleOperationError(
        'Firebase Auth $operationName',
        error,
        context,
        showLoading,
        customErrorMessage,
        onError,
      );
      return null;
    } on FirebaseException catch (error) {
      logError('Firebase $operationName', error);
      _handleOperationError(
        'Firebase $operationName',
        error,
        context,
        showLoading,
        customErrorMessage,
        onError,
      );
      return null;
    } catch (error) {
      logError('$operationName（予期しないエラー）', error);
      _handleOperationError(
        '$operationName（予期しないエラー）',
        error,
        context,
        showLoading,
        customErrorMessage,
        onError,
      );
      return null;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════════
// 5️⃣ ミックスイン (Mixin for State Classes)
// ═══════════════════════════════════════════════════════════════════════════════════

/// エラーハンドリングのミックスイン
/// 各Stateクラスで使用可能
mixin ErrorHandlerMixin<T extends StatefulWidget> on State<T> {
  
  // 📢 UI表示メソッド

  /// 🔧 統一SnackBar表示（ミックスイン版）
  void showMessage(String message, String type, {
    Duration? customDuration,
    SnackBarConfig? customConfig,
    bool? showAction,
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    ErrorHandler.showSnackBar(
      context,
      message,
      type,
      customDuration: customDuration,
      customConfig: customConfig,
      showAction: showAction,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
    );
  }

  // 従来型メソッド（互換用）
  void showError(dynamic error, {String? customMessage}) {
    final message = customMessage ?? ErrorHandler.getGeneralErrorMessage(error);
    showMessage(message, 'error');
  }

  void showWarning(String message) {
    showMessage(message, 'warning');
  }

  void showSuccess(String message) {
    showMessage(message, 'success');
  }

  void showInfo(String message) {
    showMessage(message, 'info');
  }

  Future<bool> showConfirm({
    required String title,
    required String content,
    String confirmText = 'OK',
    String cancelText = 'キャンセル',
    Color? confirmColor,
  }) {
    return ErrorHandler.showConfirmDialog(
      context,
      title: title,
      content: content,
      confirmText: confirmText,
      cancelText: cancelText,
      confirmColor: confirmColor,
    );
  }

  // ⚡ VBAスタイル操作メソッド
  /// VBAスタイル非同期処理（ミックスイン版）
  Future<void> executeAsync(
    String operationName,
    Future<dynamic> Function() operation, {
    bool showLoading = false,
    String loadingMessage = '処理中...',
    bool showSuccessMessage = false,
    String? successMessage,
    String? customErrorMessage,
    bool logOperation = true,
    Function(dynamic error)? onError,
  }) async {
    final config = OperationConfig(
      operationName: operationName,
      context: context,
      showLoading: showLoading,
      loadingMessage: loadingMessage,
      showSuccessMessage: showSuccessMessage,
      successMessage: successMessage,
      customErrorMessage: customErrorMessage,
      logOperation: logOperation,
      onError: onError,
    );
    
    await ErrorHandler.executeAsyncOperation(config, operation);
    
    // 結果をログ出力（デバッグ用）
    if (logOperation) {
      if (config.isSuccess) {
        ErrorHandler.logInfo('VBA実行結果: 成功');
      } else {
        ErrorHandler.logInfo('VBA実行結果: エラー - ${config.errorMessage}');
      }
    }
  }

  /// VBAスタイルFirebase処理（ミックスイン版）
  Future<void> executeFirebaseAsync(
    String operationName,
    Future<dynamic> Function() operation, {
    bool showLoading = false,
    String loadingMessage = '処理中...',
    bool showSuccessMessage = false,
    String? successMessage,
    String? customErrorMessage,
    bool logOperation = true,
    Function(dynamic error)? onError,
  }) async {
    final config = OperationConfig(
      operationName: operationName,
      context: context,
      showLoading: showLoading,
      loadingMessage: loadingMessage,
      showSuccessMessage: showSuccessMessage,
      successMessage: successMessage,
      customErrorMessage: customErrorMessage,
      logOperation: logOperation,
      onError: onError,
    );
    
    await ErrorHandler.executeFirebaseOperation(config, operation);
    
    // 結果をログ出力（デバッグ用）
    if (logOperation) {
      if (config.isSuccess) {
        ErrorHandler.logInfo('Firebase VBA実行結果: 成功');
      } else {
        ErrorHandler.logInfo('Firebase VBA実行結果: エラー - ${config.errorMessage}');
      }
    }
  }

  // ⚡ 従来型操作ラッパーメソッド
  /// 非同期処理の統一ラッパー（ミックスイン版）
  Future<R?> handleAsync<R>(
    String operationName,
    Future<R> Function() operation, {
    String? customErrorMessage,
    bool showLoading = false,
    String loadingMessage = '処理中...',
    bool showSuccessMessage = false,
    String? successMessage,
    bool logOperation = true,
  }) {
    return ErrorHandler.handleAsyncOperation<R>(
      operationName,
      operation,
      context: context,
      customErrorMessage: customErrorMessage,
      showLoading: showLoading,
      loadingMessage: loadingMessage,
      showSuccessMessage: showSuccessMessage,
      successMessage: successMessage,
      logOperation: logOperation,
    );
  }

  /// Firebase操作の統一ラッパー（ミックスイン版）
  Future<R?> handleFirebase<R>(
    String operationName,
    Future<R> Function() operation, {
    String? customErrorMessage,
    bool showLoading = false,
    String loadingMessage = '処理中...',
    bool showSuccessMessage = false,
    String? successMessage,
    bool logOperation = true,
    Function(dynamic error)? onError,
  }) {
    return ErrorHandler.handleFirebaseOperation<R>(
      operationName,
      operation,
      context: context,
      customErrorMessage: customErrorMessage,
      showLoading: showLoading,
      loadingMessage: loadingMessage,
      showSuccessMessage: showSuccessMessage,
      successMessage: successMessage,
      logOperation: logOperation,
      onError: onError,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════════
// 📖 使用例 (Usage Examples)
// ═══════════════════════════════════════════════════════════════════════════════════
//
// 【基本的な使用方法】
// 1. Stateクラスでミックスインを使用:
//    class _MyPageState extends State<MyPage> with ErrorHandlerMixin {
//    → 使用ファイル: login.dart, register.dart, post_create.dart, vote.dart, myself.dart
//
// 2. Firebase操作をラップ (login.dart, register.dartの例):
//    final result = await handleFirebase<UserCredential>(
//      'ログイン',
//      () async => await auth.signInWithEmailAndPassword(email: email, password: password),
//      showSuccessMessage: true,
//      successMessage: 'ログインに成功しました',
//    );
//
// 3. 汎用非同期処理をラップ (vote.dart, post.dartの例):
//    final data = await handleAsync<List<Post>>(
//      'データ取得',
//      () async => await fetchPosts(),
//      showLoading: true,
//      customErrorMessage: 'データの取得に失敗しました',
//    );
//
// 4. 統一SnackBar表示 (VBAスタイル):
//    // タイプ指定で統一表示
//    showMessage('エラーが発生しました', 'error');
//    showMessage('処理が完了しました', 'success');
//    showMessage('注意してください', 'warning');
//    showMessage('情報をお知らせします', 'info');
//    
//    // カスタマイズ例
//    showMessage('カスタムエラー', 'error',
//      customDuration: Duration(seconds: 10),
//      actionLabel: '再試行',
//      onActionPressed: () => retry());
//
// 5. 従来型表示 (互換用):
//    showError(error);                    // エラー表示
//    showSuccess('処理が完了しました');      // 成功表示
//    showWarning('注意してください');        // 警告表示
//    final confirmed = await showConfirm(  // 確認ダイアログ
//      title: '確認', 
//      content: '削除しますか？'
//    );
//
// 6. VBAスタイル処理フロー（シンプル版）:
//    // 1. 処理依頼オブジェクト作成（VBAの変数宣言）
//    final request = SnackBarRequest(
//      context: context,
//      message: 'エラーが発生しました',
//      type: 'error',
//      customDuration: Duration(seconds: 10),
//      actionLabel: '再試行',
//    );
//    
//    // 2. 設定変更（VBAの変数代入）
//    request.setAsError(someError, customMessage: 'カスタムエラー');
//    request.actionLabel = '修正';
//    
//    // 3. 処理依頼→変数代入→共有パーツ実行
//    procProcessSnackBarRequest(request);
//
// 7. 簡単な呼び出し（内部でVBAスタイル処理）:
//    ErrorHandler.showSnackBar(context, 'メッセージ', 'error');
//    ErrorHandler.showSnackBar(context, 'カスタム', 'success',
//      customConfig: SnackBarConfig(
//        icon: Icons.star,
//        backgroundColor: Colors.purple,
//        duration: Duration(seconds: 8),
//        showAction: true,
//        actionLabel: 'カスタム',
//      ));
//
// 6. VBAスタイル使用例:
//    // 設定オブジェクトを作成（VBAの変数宣言）
//    final config = OperationConfig(
//      operationName: 'ユーザーログイン',
//      context: context,
//      showLoading: true,
//      showSuccessMessage: true,
//      successMessage: 'ログインしました',
//    );
//    
//    // 非同期処理実行（VBAのFunction呼び出し）
//    await executeAsyncOperation(config, () async {
//      return await FirebaseAuth.instance.signInWithEmailAndPassword(
//        email: email, password: password);
//    });
//    
//    // 結果を確認（VBAの戻り値チェック）
//    if (config.isSuccess) {
//      print('成功: ${config.result}');
//    } else {
//      print('エラー: ${config.errorMessage}');
//    }
//
//    // Firebase専用実行
//    await executeFirebaseOperation(config, () async {
//      return await FirebaseFirestore.instance.collection('users').add(data);
//    });
//
//    // 同期処理実行
//    executeSyncOperation(config, () {
//      return someCalculation();
//    });
//
//    // SnackBar共有プロシージャ直接呼び出し
//    procShowSnackBar(context, 'カスタムメッセージ', 'error',
//      customDuration: Duration(seconds: 10),
//      actionLabel: '再試行');
//    
//    procShowSnackBar(context, '処理完了', 'success',
//      showAction: true, 
//      actionLabel: '確認',
//      onActionPressed: () => print('確認ボタンが押されました'));
//
// 【VBAスタイルの利点】
// ・変数に設定値を格納してから実行（VBAライク）
// ・結果が設定オブジェクトに格納される（戻り値が明確）
// ・プロシージャの組み合わせで柔軟な処理が可能
// ・設定の再利用や複製が簡単
//
// 【ファイル別主要使用パターン】
// ・main.dart: logInfo, logError (AuthGate認証ログ)
// ・login.dart: handleFirebase, showError, showSuccess
// ・register.dart: handleFirebase, showError, showSuccess
// ・post_create.dart: handleAsync, showError, showSuccess
// ・vote.dart: handleFirebase, showError, showWarning
// ・post.dart: handleAsync, showError
// ・myself.dart: handleFirebase, showConfirm, showError, showSuccess
//
// ═══════════════════════════════════════════════════════════════════════════════════
