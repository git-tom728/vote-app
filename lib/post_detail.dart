import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;
  final String title;
  final Map<String, dynamic> options;
  final String? createdByEmail;

  const PostDetailScreen({
    Key? key,
    required this.postId,
    required this.title,
    required this.options,
    this.createdByEmail,
  }) : super(key: key);

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.blue,
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

          final post = snapshot.data!.data() as Map<String, dynamic>;
          final options = Map<String, dynamic>.from(post['options']);
          // ignore: avoid_types_as_parameter_names
          final totalVotes = options.values.fold<int>(0, (sum, count) => sum + (count as int));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (widget.createdByEmail != null)
                ListTile(
                  title: const Text('投稿者'),
                  subtitle: Text(widget.createdByEmail!),
                ),
              const Divider(),
              ...options.entries.map((entry) {
                final percentage = totalVotes > 0
                    ? (entry.value as int) / totalVotes * 100
                    : 0.0;
                
                return Column(
                  children: [
                    ListTile(
                      title: Text(entry.key),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: percentage / 100,
                            backgroundColor: Colors.grey[200],
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${entry.value}票 (${percentage.toStringAsFixed(1)}%)',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                  ],
                );
              }).toList(),
              const SizedBox(height: 16),
              Text(
                '総投票数: $totalVotes票',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          );
        },
      ),
    );
  }
} 