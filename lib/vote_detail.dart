// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VoteDetailScreen extends StatefulWidget {
  final String postId;
  final String title;
  final Map<String, dynamic> options;
  final bool isVoted;
  final String? selectedOption;
  final String? createdByEmail;

  const VoteDetailScreen({
    Key? key,
    required this.postId,
    required this.title,
    required this.options,
    required this.isVoted,
    this.selectedOption,
    this.createdByEmail,
  }) : super(key: key);

  @override
  State<VoteDetailScreen> createState() => _VoteDetailScreenState();
}

class _VoteDetailScreenState extends State<VoteDetailScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _selectedOption;

  @override
  void initState() {
    super.initState();
    _selectedOption = widget.selectedOption;
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('投票に失敗しました。')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.blue,
      ),
      body: ListView(
        children: [
          if (widget.createdByEmail != null)
            ListTile(
              title: const Text('投稿者'),
              subtitle: Text(widget.createdByEmail!),
            ),
          const Divider(),
          ...widget.options.keys.map((option) => Column(
            children: [
              ListTile(
                title: Text(option),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${widget.options[option] ?? 0}票',
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
      ),
    );
  }
} 