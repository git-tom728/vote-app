/// 📱 アップデート通知ダイアログ
/// ユーザーにアプリの更新を促すダイアログ

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/version_service.dart';
import '../config/debug_config.dart';

class UpdateDialog {
  /// アップデート通知ダイアログを表示
  /// forceUpdate: true の場合、キャンセルボタンを表示しない
  static Future<void> show(
    BuildContext context, {
    required bool forceUpdate,
    required String message,
    required String storeUrl,
  }) async {
    if (!context.mounted) return;

    DebugConfig.debugLog('アップデートダイアログ表示', data: {
      'forceUpdate': forceUpdate,
      'message': message,
    });

    return showDialog(
      context: context,
      barrierDismissible: !forceUpdate, // 強制アップデートの場合は閉じられない
      builder: (context) => PopScope(
        canPop: !forceUpdate, // 強制アップデートの場合は戻るボタン無効
        child: AlertDialog(
          title: Row(
            children: [
              Icon(
                forceUpdate ? Icons.warning : Icons.info,
                color: forceUpdate ? Colors.orange : Colors.blue,
              ),
              const SizedBox(width: 8),
              Text(forceUpdate ? '更新が必要です' : '更新のお知らせ'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              const SizedBox(height: 16),
              if (forceUpdate)
                const Text(
                  '※ このバージョンではアプリを使用できません',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          actions: [
            if (!forceUpdate)
              TextButton(
                onPressed: () {
                  DebugConfig.debugLog('アップデートをスキップ');
                  Navigator.of(context).pop();
                },
                child: const Text('後で'),
              ),
            ElevatedButton(
              onPressed: () async {
                DebugConfig.debugLog('ストアを開く', data: {'url': storeUrl});
                await _openStore(storeUrl);
                if (!forceUpdate && context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: forceUpdate ? Colors.orange : Colors.blue,
              ),
              child: const Text('更新する'),
            ),
          ],
        ),
      ),
    );
  }

  /// ストアを開く
  static Future<void> _openStore(String storeUrl) async {
    try {
      final uri = Uri.parse(storeUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        DebugConfig.debugSuccess('ストアを開きました');
      } else {
        DebugConfig.debugError('ストアを開けませんでした', error: 'canLaunchUrl failed');
      }
    } catch (e, stackTrace) {
      DebugConfig.debugError('ストアを開く際のエラー', 
        error: e, stackTrace: stackTrace);
    }
  }

  /// アップデートチェックを実行し、必要に応じてダイアログを表示
  static Future<void> checkAndShowIfNeeded(BuildContext context) async {
    if (!context.mounted) return;

    try {
      final versionService = VersionService();
      final status = await versionService.checkForUpdate();

      if (!context.mounted) return;

      switch (status) {
        case UpdateStatus.forceUpdate:
          // 強制アップデート
          final storeUrl = Platform.isIOS
              ? versionService.iosStoreUrl
              : versionService.androidStoreUrl;
          
          await show(
            context,
            forceUpdate: true,
            message: versionService.forceUpdateMessage,
            storeUrl: storeUrl,
          );
          break;

        case UpdateStatus.updateAvailable:
          // 任意アップデート
          final storeUrl = Platform.isIOS
              ? versionService.iosStoreUrl
              : versionService.androidStoreUrl;
          
          await show(
            context,
            forceUpdate: false,
            message: versionService.updateMessage,
            storeUrl: storeUrl,
          );
          break;

        case UpdateStatus.upToDate:
          // 最新バージョン - 何もしない
          DebugConfig.debugSuccess('最新バージョンを使用中');
          break;

        case UpdateStatus.error:
          // エラー - 何もしない（アプリは通常通り動作）
          DebugConfig.debugWarning('アップデートチェックでエラーが発生しましたが、アプリは続行します');
          break;
      }
    } catch (e, stackTrace) {
      DebugConfig.debugError('アップデートチェックエラー', 
        error: e, stackTrace: stackTrace);
      // エラーが発生してもアプリは通常通り動作
    }
  }
}

