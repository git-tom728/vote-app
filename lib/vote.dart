import 'package:flutter/material.dart';

class VoteScreen extends StatelessWidget {
  final List<Map<String, Map<String, bool>>> posts;
  final List<bool> isVoted;
  final Function(int, String) toggleVote;
  final Function(int) confirmVote;

  const VoteScreen({
    super.key,
    required this.posts,
    required this.isVoted,
    required this.toggleVote,
    required this.confirmVote,
  });

  @override
  Widget build(BuildContext context) {
    return posts.isEmpty
        ? const Center(child: Text("投稿がありません"))
        : ListView.builder(
          itemCount: posts.length,
          itemBuilder: (context, postIndex) {
            String title = posts[postIndex].keys.first;
            Map<String, bool> options = posts[postIndex][title]!;

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '題目: $title',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Column(
                      children:
                          options.keys.map((optionText) {
                            bool isSelected = options[optionText]!;
                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 5),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: isSelected ? Colors.blue : Colors.grey,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(10),
                                color:
                                    isSelected
                                        ? Colors.blue.withOpacity(0.2)
                                        : Colors.white,
                              ),
                              child: ListTile(
                                title: Text(optionText),
                                trailing:
                                    isVoted[postIndex]
                                        ? null
                                        : ElevatedButton(
                                          onPressed:
                                              () => toggleVote(
                                                postIndex,
                                                optionText,
                                              ),
                                          child: Text(
                                            isSelected ? '選択中' : '選択',
                                          ),
                                        ),
                              ),
                            );
                          }).toList(),
                    ),
                    if (!isVoted[postIndex])
                      ElevatedButton(
                        onPressed: () => confirmVote(postIndex),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: const Text(
                          '投票確定',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
  }
}
