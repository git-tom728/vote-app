import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vote/services/backup_service.dart';
// import 'package:vote/services/log_service.dart';

class BackupPage extends StatefulWidget {
  const BackupPage({super.key});

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  final BackupService _backupService = BackupService();
  // final LogService _logService = LogService();
  List<Map<String, dynamic>> _backups = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  Future<void> _loadBackups() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final backups = await _backupService.getBackupList();
      setState(() {
        _backups = backups;
      });
    } catch (e) {
      _showError('バックアップ一覧の取得に失敗しました');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createBackup() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _backupService.backupData();
      await _loadBackups();
      _showSuccess('バックアップを作成しました');
    } catch (e) {
      _showError('バックアップの作成に失敗しました');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _rollbackBackup(String backupId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ロールバックの確認'),
        content: const Text('このバックアップにロールバックしますか？\n現在のデータは失われます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ロールバック'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _backupService.rollback(backupId);
      _showSuccess('ロールバックが完了しました');
    } catch (e) {
      _showError('ロールバックに失敗しました');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteBackup(String backupId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('バックアップの削除'),
        content: const Text('このバックアップを削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _backupService.deleteBackup(backupId);
      await _loadBackups();
      _showSuccess('バックアップを削除しました');
    } catch (e) {
      _showError('バックアップの削除に失敗しました');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('バックアップ管理'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: _createBackup,
                    child: const Text('新しいバックアップを作成'),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _backups.length,
                    itemBuilder: (context, index) {
                      final backup = _backups[index];
                      final timestamp = backup['timestamp'] as Timestamp?;
                      final metadata = backup['metadata'] as Map<String, dynamic>?;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: ListTile(
                          title: Text(
                            timestamp?.toDate().toString() ?? '不明な日時',
                          ),
                          subtitle: metadata != null
                              ? Text(
                                  'ユーザー: ${metadata['users_count']}, '
                                  '投稿: ${metadata['posts_count']}, '
                                  '投票: ${metadata['votes_count']}',
                                )
                              : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.restore),
                                onPressed: () => _rollbackBackup(backup['id']),
                                tooltip: 'ロールバック',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _deleteBackup(backup['id']),
                                tooltip: '削除',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
} 