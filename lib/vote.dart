import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'vote_detail.dart';

class VoteScreen extends StatefulWidget {
  const VoteScreen({Key? key}) : super(key: key);

  @override
  State<VoteScreen> createState() => _VoteScreenState();
}

class _VoteScreenState extends State<VoteScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // 選択された選択肢を保持する変数
  Map<String, String?> _selectedOptions = {};
  // 投票済みの投稿を管理する変数
  Set<String> _votedPosts = {};
  // 展開されている投稿を管理する変数
  Set<String> _expandedPosts = {};

  @override
  void initState() {
    super.initState();
    // 初期化時に投票済みの投稿を取得
    _loadVotedPosts();
  }

  // 投票済みの投稿を取得する
  Future<void> _loadVotedPosts() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final votesSnapshot = await FirebaseFirestore.instance
        .collection('votes')
        .where('userId', isEqualTo: user.uid)
        .get();

    setState(() {
      _votedPosts = votesSnapshot.docs
          .map((doc) => doc.data()['postId'] as String)
          .toSet();
      
      // 投票済みの投稿の選択肢を設定
      for (var doc in votesSnapshot.docs) {
        _selectedOptions[doc.data()['postId'] as String] = 
            doc.data()['selectedOption'] as String;
      }
    });
  }

  void _selectOption(String postId, String option) {
    // 投票済みの場合は選択できないようにする
    if (_votedPosts.contains(postId)) return;
    
    setState(() {
      _selectedOptions[postId] = option;
    });
  }

  void _vote(String postId, String selectedOption) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // 投票済みかチェック
    final voteRef = FirebaseFirestore.instance
        .collection('votes')
        .doc('${postId}_${user.uid}');

    final voteSnap = await voteRef.get();

    if (voteSnap.exists) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('すでに投票済みです。')));
      return;
    }

    try {
    // トランザクションで投票を処理
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      // 投稿データを取得
      final postRef = FirebaseFirestore.instance
          .collection('posts')
          .doc(postId);
      final postDoc = await transaction.get(postRef);

        // 投稿が存在しない場合は処理を中断
        if (!postDoc.exists) {
          throw Exception('投稿が存在しません');
        }

      // 現在のoptionsを取得
      final options = Map<String, dynamic>.from(postDoc.data()!['options']);

      // 選択された選択肢の投票数を+1
      options[selectedOption] = (options[selectedOption] ?? 0) + 1;

      // 更新を実行
      transaction.update(postRef, {'options': options});

      // 投票記録を保存
      transaction.set(voteRef, {
        'postId': postId,
        'userId': user.uid,
        'selectedOption': selectedOption,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });

    // 投票済みの状態を更新
    setState(() {
      _votedPosts.add(postId);
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('投票しました！')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('投票に失敗しました。投稿が削除された可能性があります。')));
    }
  }

  void _toggleExpanded(String postId) {
    setState(() {
      if (_expandedPosts.contains(postId)) {
        _expandedPosts.remove(postId);
      } else {
        _expandedPosts.add(postId);
      }
    });
  }

  // 投稿カードのコンテンツを構築
  Widget _buildPostContent(
    String postId,
    String title,
    Map<String, dynamic> options,
    bool isVoted,
    bool isExpanded,
    String? createdByEmail,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // タイトル行（クリッカブル）
        InkWell(
          onTap: () => _toggleExpanded(postId),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.grey,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (createdByEmail != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '投稿者: $createdByEmail',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isVoted)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '投票済み',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        // 折りたたまれている場合は選択した選択肢のみ表示
        if (!isExpanded && isVoted && _selectedOptions.containsKey(postId))
          Padding(
            padding: const EdgeInsets.only(left: 24, top: 4, bottom: 4),
            child: Text(
              '選択: ${_selectedOptions[postId]}',
              style: const TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        // 展開時のコンテンツ
        if (isExpanded) ...[
          const SizedBox(height: 12),
          ...options.keys.map(
            (option) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
              child: ElevatedButton(
                onPressed: isVoted ? null : () => _selectOption(postId, option),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedOptions[postId] == option
                      ? Colors.blue
                      : Colors.grey[200],
                  foregroundColor: _selectedOptions[postId] == option
                      ? Colors.white
                      : Colors.black,
                  disabledBackgroundColor: _selectedOptions[postId] == option
                      ? Colors.blue
                      : Colors.grey[200],
                  disabledForegroundColor: _selectedOptions[postId] == option
                      ? Colors.white
                      : Colors.black54,
                ),
                child: Text(option),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${options[option] ?? 0}票',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_selectedOptions.containsKey(postId) && !isVoted) ...[
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: () => _vote(postId, _selectedOptions[postId]!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child: const Text('投票する'),
              ),
            ),
          ],
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
                .collection('posts')
                .orderBy('createdAt', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final posts = snapshot.data!.docs;

          if (posts.isEmpty) {
            return const Center(child: Text('投稿がありません'));
          }

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index].data() as Map<String, dynamic>;
              final postId = posts[index].id;
              
              // 投稿データが不完全な場合はスキップ
              if (!post.containsKey('title') || !post.containsKey('options')) {
                return const SizedBox.shrink();
              }

              final title = post['title'] ?? 'タイトルなし';
              final options = Map<String, dynamic>.from(post['options']);
              final isVoted = _votedPosts.contains(postId);
              final isExpanded = _expandedPosts.contains(postId);
              final createdByEmail = post['createdByEmail'] as String?;

              return Card(
                margin: const EdgeInsets.all(1),
                child: ListTile(
                  title: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: isVoted && _selectedOptions.containsKey(postId)
                      ? Text(
                          '選択: ${_selectedOptions[postId]}',
                          style: const TextStyle(
                            color: Colors.blue,
                          ),
                        )
                      : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isVoted)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            '投票済み',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VoteDetailScreen(
                          postId: postId,
                          title: title,
                          options: options,
                          isVoted: isVoted,
                          selectedOption: _selectedOptions[postId],
                          createdByEmail: createdByEmail,
                  ),
                      ),
                    );
                    
                    if (result == true) {
                      _loadVotedPosts(); // 投票後に状態を更新
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
