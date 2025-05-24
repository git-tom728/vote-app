import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyselfPage extends StatefulWidget {
  const MyselfPage({super.key});

  @override
  State<MyselfPage> createState() => _MyselfPageState();
}

class _MyselfPageState extends State<MyselfPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int postCount = 0;
  int voteCount = 0;
  Map<String, dynamic>? userProfile;
  final _nicknameController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      // ユーザープロフィール情報を取得
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          userProfile = userDoc.data();
          _nicknameController.text = userDoc.data()?['nickname'] ?? '';
        });
      }

      // 投稿数を取得
      final postsSnapshot = await _firestore
          .collection('posts')
          .where('userId', isEqualTo: user.uid)
          .get();
      
      // 投票数を取得
      final votesSnapshot = await _firestore
          .collection('votes')
          .where('userId', isEqualTo: user.uid)
          .get();

      setState(() {
        postCount = postsSnapshot.docs.length;
        voteCount = votesSnapshot.docs.length;
      });
    }
  }

  Future<void> _updateNickname() async {
    final User? user = _auth.currentUser;
    if (user != null && _nicknameController.text.trim().isNotEmpty) {
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'nickname': _nicknameController.text.trim(),
        });
        
        setState(() {
          userProfile = {
            ...userProfile!,
            'nickname': _nicknameController.text.trim(),
          };
          _isEditing = false;
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ニックネームを更新しました')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ニックネームの更新に失敗しました')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = _auth.currentUser;
    
    return Scaffold(
      body: user == null
          ? const Center(child: Text('ログインが必要です'))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'アカウント情報',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          if (userProfile != null) ...[
                            Row(
                              children: [
                                const Text('ニックネーム: '),
                                if (!_isEditing) ...[
                                  Text(userProfile!['nickname']),
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _isEditing = true;
                                      });
                                    },
                                    child: const Icon(
                                      Icons.edit,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ] else ...[
                                  Expanded(
                                    child: TextField(
                                      controller: _nicknameController,
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: _updateNickname,
                                    child: const Icon(
                                      Icons.check,
                                      size: 16,
                                      color: Colors.green,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _nicknameController.text = userProfile!['nickname'];
                                        _isEditing = false;
                                      });
                                    },
                                    child: const Icon(
                                      Icons.close,
                                      size: 16,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                          Text('メールアドレス: ${user.email}'),
                          const SizedBox(height: 8),
                          Text('投稿数: $postCount'),
                          const SizedBox(height: 8),
                          Text('投票数: $voteCount'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
} 