import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'post_detail.dart';
import 'post_create.dart';

class PostScreen extends StatelessWidget {
  const PostScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
                    .collection('posts')
                    .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
            builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('エラーが発生しました: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

          final posts = snapshot.data!.docs;

              return ListView.builder(
            itemCount: posts.length,
                itemBuilder: (context, index) {
              final post = posts[index].data() as Map<String, dynamic>;
              final postId = posts[index].id;
              final options = Map<String, int>.from(post['options'] as Map);
              // ignore: avoid_types_as_parameter_names
              final totalVotes = options.values.fold(0, (sum, votes) => sum + votes);

              return ListTile(
                title: Text(post['title']),
                subtitle: Text('総投票数: $totalVotes'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PostDetailScreen(
                        postId: postId,
                        title: post['title'],
                        options: options,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
        ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PostCreateScreen(),
            ),
          );
          if (result == true) {
            // ignore: use_build_context_synchronously
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('投稿が完了しました')),
            );
          }
        },
        backgroundColor: Colors.blue,
        label: const Text(
          '新規作成',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
    );
  }
}
