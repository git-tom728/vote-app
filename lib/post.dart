import 'package:flutter/material.dart';

class PostScreen extends StatefulWidget {
  final Function(String, String, String, String) addPost;
  final List<Map<String, Map<String, bool>>> posts;

  const PostScreen({super.key, required this.addPost, required this.posts});

  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _option1Controller = TextEditingController();
  final TextEditingController _option2Controller = TextEditingController();
  final TextEditingController _option3Controller = TextEditingController();
  bool _showForm = false;

  void _handlePost() {
    widget.addPost(
      _titleController.text,
      _option1Controller.text,
      _option2Controller.text,
      _option3Controller.text,
    );
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
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: '題目'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _option1Controller,
                    decoration: const InputDecoration(labelText: '候補1'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _option2Controller,
                    decoration: const InputDecoration(labelText: '候補2'),
                  ),
                  const SizedBox(height: 10),
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
          child:
              widget.posts.isEmpty
                  ? const Center(child: Text("過去の投稿はありません"))
                  : ListView.builder(
                    itemCount: widget.posts.length,
                    itemBuilder: (context, index) {
                      String title = widget.posts[index].keys.first;
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
                  ),
        ),
      ],
    );
  }
}
