// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/report_service.dart';
import 'services/block_service.dart';

class VoteDetailScreen extends StatefulWidget {
  final String postId;
  final String title;
  final Map<String, dynamic> options;
  final bool isVoted;
  final String? selectedOption;
  final String? createdByEmail;
  final String? createdByUserId;

  const VoteDetailScreen({
    Key? key,
    required this.postId,
    required this.title,
    required this.options,
    required this.isVoted,
    this.selectedOption,
    this.createdByEmail,
    this.createdByUserId,
  }) : super(key: key);

  @override
  State<VoteDetailScreen> createState() => _VoteDetailScreenState();
}

class _VoteDetailScreenState extends State<VoteDetailScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ReportService _reportService = ReportService();
  final BlockService _blockService = BlockService();
  String? _selectedOption;
  bool _isBlocked = false;

  @override
  void initState() {
    super.initState();
    _selectedOption = widget.selectedOption;
    _checkIfBlocked();
  }

  Future<void> _checkIfBlocked() async {
    if (widget.createdByUserId != null) {
      final isBlocked = await _blockService.isUserBlocked(widget.createdByUserId!);
      setState(() {
        _isBlocked = isBlocked;
      });
    }
  }

  void _selectOption(String option) {
    if (widget.isVoted) return;
    setState(() {
      _selectedOption = option;
    });
  }

  Future<void> _vote(String selectedOption) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final voteRef = FirebaseFirestore.instance
        .collection('votes')
        .doc('${widget.postId}_${user.uid}');

    final voteSnap = await voteRef.get();

    if (voteSnap.exists) {
      // ignore: duplicate_ignore
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('すでに投票済みです。')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final postRef = FirebaseFirestore.instance
            .collection('posts')
            .doc(widget.postId);
        final postDoc = await transaction.get(postRef);

        if (!postDoc.exists) {
          throw Exception('投稿が存在しません');
        }

        final options = Map<String, dynamic>.from(postDoc.data()!['options']);
        options[selectedOption] = (options[selectedOption] ?? 0) + 1;

        transaction.update(postRef, {'options': options});

        transaction.set(voteRef, {
          'postId': widget.postId,
          'userId': user.uid,
          'selectedOption': selectedOption,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('投票しました！')),
      );
      Navigator.pop(context, true); // 投票成功を通知
    } catch (e) {
      // エラーの詳細をログに出力
      print('投票エラー: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('投票に失敗しました: ${e.toString()}')),
      );
    }
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('投稿を通報'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('この投稿を通報する理由を選択してください'),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('不適切なコンテンツ'),
              onTap: () => _submitReport('不適切なコンテンツ'),
            ),
            ListTile(
              title: const Text('スパム'),
              onTap: () => _submitReport('スパム'),
            ),
            ListTile(
              title: const Text('嫌がらせ'),
              onTap: () => _submitReport('嫌がらせ'),
            ),
            ListTile(
              title: const Text('その他'),
              onTap: () => _submitReport('その他'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitReport(String reason) async {
    Navigator.pop(context); // ダイアログを閉じる

    if (widget.createdByUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('投稿者情報が取得できませんでした')),
      );
      return;
    }

    try {
      await _reportService.reportPost(
        postId: widget.postId,
        reportedUserId: widget.createdByUserId!,
        reason: reason,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('通報を受け付けました')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('通報に失敗しました: $e')),
      );
    }
  }

  void _showBlockDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_isBlocked ? 'ユーザーのブロック解除' : 'ユーザーをブロック'),
        content: Text(
          _isBlocked
              ? 'このユーザーのブロックを解除しますか？'
              : 'このユーザーをブロックすると、このユーザーの投稿が表示されなくなります。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: _isBlocked ? _unblockUser : _blockUser,
            child: Text(_isBlocked ? 'ブロック解除' : 'ブロック'),
          ),
        ],
      ),
    );
  }

  Future<void> _blockUser() async {
    Navigator.pop(context); // ダイアログを閉じる

    if (widget.createdByUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('投稿者情報が取得できませんでした')),
      );
      return;
    }

    try {
      await _blockService.blockUser(widget.createdByUserId!);
      setState(() {
        _isBlocked = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ユーザーをブロックしました')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ブロックに失敗しました: $e')),
      );
    }
  }

  Future<void> _unblockUser() async {
    Navigator.pop(context); // ダイアログを閉じる

    if (widget.createdByUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('投稿者情報が取得できませんでした')),
      );
      return;
    }

    try {
      await _blockService.unblockUser(widget.createdByUserId!);
      setState(() {
        _isBlocked = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ブロックを解除しました')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ブロック解除に失敗しました: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.blue,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'report') {
                _showReportDialog();
              } else if (value == 'block') {
                _showBlockDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.flag, color: Colors.red),
                    SizedBox(width: 8),
                    Text('投稿を通報'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'block',
                child: Row(
                  children: [
                    Icon(_isBlocked ? Icons.check_circle : Icons.block, 
                         color: _isBlocked ? Colors.green : Colors.orange),
                    const SizedBox(width: 8),
                    Text(_isBlocked ? 'ブロック解除' : 'ユーザーをブロック'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .doc(widget.postId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final postData = snapshot.data!.data() as Map<String, dynamic>;
          final options = Map<String, dynamic>.from(postData['options']);
          final optionsList = postData.containsKey('optionsList') 
              ? List<String>.from(postData['optionsList'])
              : options.keys.toList();

          return ListView(
            children: [
              if (widget.createdByEmail != null)
                ListTile(
                  title: const Text('投稿者'),
                  subtitle: Text(widget.createdByEmail!),
                ),
              const Divider(),
              ...optionsList.map((option) => Column(
            children: [
              ListTile(
                title: Text(option),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${options[option] ?? 0}票',
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                    if (_selectedOption == option)
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(Icons.check, color: Colors.blue),
                      ),
                  ],
                ),
                onTap: widget.isVoted ? null : () => _selectOption(option),
              ),
              const Divider(height: 1),
            ],
          )).toList(),
          if (!widget.isVoted && _selectedOption != null) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton(
                onPressed: () => _vote(_selectedOption!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('投票する'),
              ),
            ),
          ],
            ],
          );
        },
      ),
    );
  }
} 