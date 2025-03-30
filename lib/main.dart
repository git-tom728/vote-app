import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Firebase 初期化前に必要
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '投稿 & 投票システム',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // 0: 投稿画面, 1: 投票画面
  final List<Map<String, Map<String, bool>>> _posts = [];
  final List<bool> _isVoted = []; // 各投稿の投票確定状態を管理

  // 投稿データを追加
  void _addPost(String title, String option1, String option2, String option3) {
    setState(() {
      _posts.add({
        title: {option1: false, option2: false, option3: false},
      });
      _isVoted.add(false);
    });
  }

  // 投票の選択処理（1つだけ選択可能）
  void _toggleVote(int postIndex, String optionKey) {
    if (_isVoted[postIndex]) return;
    setState(() {
      String title = _posts[postIndex].keys.first;
      _posts[postIndex][title]!.updateAll((key, value) => false);
      _posts[postIndex][title]![optionKey] = true;
    });
  }

  // 投票確定ボタンを押したら変更不可にする
  void _confirmVote(int postIndex) {
    setState(() {
      _isVoted[postIndex] = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text(_selectedIndex == 0 ? '投稿' : '投票'),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          PostScreen(addPost: _addPost, posts: _posts),
          VoteScreen(
            posts: _posts,
            isVoted: _isVoted,
            toggleVote: _toggleVote,
            confirmVote: _confirmVote,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.post_add), label: "投稿"),
          BottomNavigationBarItem(icon: Icon(Icons.how_to_vote), label: "投票"),
        ],
      ),
    );
  }
}

// 投稿画面
class PostScreen extends StatefulWidget {
  final Function(String, String, String, String) addPost;
  final List<Map<String, Map<String, bool>>> posts; // 追加

  const PostScreen({super.key, required this.addPost, required this.posts});

  @override
  // ignore: library_private_types_in_public_api
  _PostScreenState createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _option1Controller = TextEditingController();
  final TextEditingController _option2Controller = TextEditingController();
  final TextEditingController _option3Controller = TextEditingController();
  bool _showForm = false; // 投稿フォームの表示・非表示を制御

  // 投稿処理
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
      _showForm = false; // 投稿後にフォームを隠す
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
                children: <Widget>[
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
                  _showForm = true; // ボタンを押すとフォームを表示
                });
              },
              child: const Text('投稿作成'),
            ),
        const SizedBox(height: 20),

        // 過去の投稿一覧
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

// 投票画面
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
                                        // ignore: deprecated_member_use
                                        ? Colors.blue.withOpacity(0.2)
                                        : Colors.white,
                              ),
                              child: ListTile(
                                title: Text(optionText),
                                trailing:
                                    isVoted[postIndex]
                                        ? null // ✅ 投票確定後はボタンを非表示
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
