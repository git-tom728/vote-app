import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VoteScreen extends StatefulWidget {
  const VoteScreen({Key? key}) : super(key: key);

  @override
  State<VoteScreen> createState() => _VoteScreenState();
}

class _VoteScreenState extends State<VoteScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _vote(String postId) async {
    final user = _auth.currentUser;
    if (user == null) return;

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

    await voteRef.set({
      'postId': postId,
      'userId': user.uid,
      'timestamp': FieldValue.serverTimestamp(),
    });

    final postRef = FirebaseFirestore.instance.collection('posts').doc(postId);
    await postRef.update({'votes': FieldValue.increment(1)});

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('投票しました！')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('投票一覧')),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('posts')
                .orderBy('timestamp', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const CircularProgressIndicator();

          final posts = snapshot.data!.docs;

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              final postId = post.id;
              final content = post['content'];
              final votes = post['votes'] ?? 0;

              return ListTile(
                title: Text(content),
                subtitle: Text('投票数: $votes'),
                trailing: ElevatedButton(
                  onPressed: () => _vote(postId),
                  child: const Text('投票'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
