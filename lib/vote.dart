import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VoteScreen extends StatelessWidget {
  const VoteScreen({super.key});

  // 投票処理
  Future<void> _vote(String postId, String selectedOption) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final postRef = FirebaseFirestore.instance.collection('posts').doc(postId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(postRef);
      final data = snapshot.data();

      // すでに投票していたら何もしない（例：uidリストに含まれてたら）
      final votedUsers = List<String>.from(data?['votedUsers'] ?? []);
      if (votedUsers.contains(user.uid)) return;

      final options = Map<String, dynamic>.from(data?['options'] ?? {});
      options[selectedOption] = (options[selectedOption] ?? 0) + 1;

      votedUsers.add(user.uid);

      transaction.update(postRef, {
        'options': options,
        'votedUsers': votedUsers,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('posts')
              .orderBy('createdAt', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();

        final posts = snapshot.data!.docs;

        if (posts.isEmpty) {
          return const Center(child: Text("投稿がありません"));
        }

        return ListView.builder(
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            final data = post.data() as Map<String, dynamic>;
            final title = data['title'] ?? '';
            final options = Map<String, dynamic>.from(data['options'] ?? {});
            final votedUsers = List<String>.from(data['votedUsers'] ?? []);
            final userId = FirebaseAuth.instance.currentUser?.uid;

            final hasVoted = userId != null && votedUsers.contains(userId);

            return Card(
              margin: const EdgeInsets.all(10),
              child: Padding(
                padding: const EdgeInsets.all(16),
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
                    const SizedBox(height: 10),
                    for (final entry in options.entries)
                      ListTile(
                        title: Text("${entry.key}（${entry.value}票）"),
                        trailing:
                            hasVoted
                                ? null
                                : ElevatedButton(
                                  onPressed: () => _vote(post.id, entry.key),
                                  child: const Text("投票"),
                                ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
