import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PostScreen extends StatefulWidget {
  const PostScreen({super.key});

  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  final _titleController = TextEditingController();
  final _option1Controller = TextEditingController();
  final _option2Controller = TextEditingController();
  final _option3Controller = TextEditingController();

  bool _showForm = false;

  Future<void> _handlePost() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final post = {
      'title': _titleController.text,
      'options': {
        _option1Controller.text: 0,
        _option2Controller.text: 0,
        _option3Controller.text: 0,
      },
      'createdBy': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance.collection('posts').add(post);

    _titleController.clear();
    _option1Controller.clear();
    _option2Controller.clear();
    _option3Controller.clear();

    setState(() {
      _showForm = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _showForm
            ? Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: '題目'),
                  ),
                  TextField(
                    controller: _option1Controller,
                    decoration: const InputDecoration(labelText: '候補1'),
                  ),
                  TextField(
                    controller: _option2Controller,
                    decoration: const InputDecoration(labelText: '候補2'),
                  ),
                  TextField(
                    controller: _option3Controller,
                    decoration: const InputDecoration(labelText: '候補3'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _handlePost,
                    child: const Text('投稿'),
                  ),
                ],
              ),
            )
            : ElevatedButton(
              onPressed: () {
                setState(() {
                  _showForm = true;
                });
              },
              child: const Text('投稿作成'),
            ),
        const SizedBox(height: 20),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('posts')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs;

              if (docs.isEmpty) {
                return const Center(child: Text('過去の投稿はありません'));
              }

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final title = data['title'] ?? '無題';

                  return Card(
                    child: ListTile(
                      title: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
