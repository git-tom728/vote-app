import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vote/services/log_service.dart';

class BackupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LogService _logService = LogService();

  // データのバックアップ
  Future<void> backupData() async {
    try {
      _logService.startTrace('backup_data');
      
      // ユーザーデータのバックアップ
      final usersSnapshot = await _firestore.collection('users').get();
      final usersData = usersSnapshot.docs.map((doc) => {
        'id': doc.id,
        'data': doc.data(),
      }).toList();
      
      // 投稿データのバックアップ
      final postsSnapshot = await _firestore.collection('posts').get();
      final postsData = postsSnapshot.docs.map((doc) => {
        'id': doc.id,
        'data': doc.data(),
      }).toList();
      
      // 投票データのバックアップ
      final votesSnapshot = await _firestore.collection('votes').get();
      final votesData = votesSnapshot.docs.map((doc) => {
        'id': doc.id,
        'data': doc.data(),
      }).toList();

      // バックアップデータの保存
      final backupRef = await _firestore.collection('backups').add({
        'timestamp': FieldValue.serverTimestamp(),
        'users': usersData,
        'posts': postsData,
        'votes': votesData,
        'metadata': {
          'users_count': usersData.length,
          'posts_count': postsData.length,
          'votes_count': votesData.length,
        }
      });

      _logService.logInfo(
        'バックアップ完了',
        data: {
          'backup_id': backupRef.id,
          'users_count': usersData.length,
          'posts_count': postsData.length,
          'votes_count': votesData.length,
        },
      );
      
      _logService.stopTrace('backup_data');
    } catch (e, stackTrace) {
      _logService.logError(
        e,
        stackTrace,
        reason: 'バックアップに失敗',
      );
      _logService.stopTrace('backup_data');
      rethrow;
    }
  }

  // バックアップ一覧の取得
  Future<List<Map<String, dynamic>>> getBackupList() async {
    try {
      _logService.startTrace('get_backup_list');
      
      final snapshot = await _firestore
          .collection('backups')
          .orderBy('timestamp', descending: true)
          .get();

      final backups = snapshot.docs.map((doc) => {
        'id': doc.id,
        'timestamp': doc.data()['timestamp'],
        'metadata': doc.data()['metadata'],
      }).toList();

      _logService.logInfo(
        'バックアップ一覧の取得完了',
        data: {'count': backups.length},
      );
      
      _logService.stopTrace('get_backup_list');
      return backups;
    } catch (e, stackTrace) {
      _logService.logError(
        e,
        stackTrace,
        reason: 'バックアップ一覧の取得に失敗',
      );
      _logService.stopTrace('get_backup_list');
      rethrow;
    }
  }

  // ロールバック処理
  Future<void> rollback(String backupId) async {
    try {
      _logService.startTrace('rollback_data');
      
      // バックアップデータの取得
      final backupDoc = await _firestore
          .collection('backups')
          .doc(backupId)
          .get();
      
      if (!backupDoc.exists) {
        throw Exception('バックアップが見つかりません');
      }

      final backupData = backupDoc.data()!;
      
      // バッチ処理で一括更新
      final batch = _firestore.batch();
      
      // ユーザーデータの復元
      for (final user in backupData['users']) {
        batch.set(
          _firestore.collection('users').doc(user['id']),
          user['data'],
        );
      }
      
      // 投稿データの復元
      for (final post in backupData['posts']) {
        batch.set(
          _firestore.collection('posts').doc(post['id']),
          post['data'],
        );
      }
      
      // 投票データの復元
      for (final vote in backupData['votes']) {
        batch.set(
          _firestore.collection('votes').doc(vote['id']),
          vote['data'],
        );
      }
      
      await batch.commit();
      
      _logService.logInfo(
        'ロールバック完了',
        data: {
          'backup_id': backupId,
          'metadata': backupData['metadata'],
        },
      );
      
      _logService.stopTrace('rollback_data');
    } catch (e, stackTrace) {
      _logService.logError(
        e,
        stackTrace,
        reason: 'ロールバックに失敗',
        parameters: {'backup_id': backupId},
      );
      _logService.stopTrace('rollback_data');
      rethrow;
    }
  }

  // バックアップの削除
  Future<void> deleteBackup(String backupId) async {
    try {
      _logService.startTrace('delete_backup');
      
      await _firestore
          .collection('backups')
          .doc(backupId)
          .delete();

      _logService.logInfo(
        'バックアップの削除完了',
        data: {'backup_id': backupId},
      );
      
      _logService.stopTrace('delete_backup');
    } catch (e, stackTrace) {
      _logService.logError(
        e,
        stackTrace,
        reason: 'バックアップの削除に失敗',
        parameters: {'backup_id': backupId},
      );
      _logService.stopTrace('delete_backup');
      rethrow;
    }
  }
} 