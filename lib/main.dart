import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'login.dart';
import 'post.dart';
import 'vote.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Login Demo',
      home: const AuthGate(), // ← ここをLoginPageからAuthGateに変更！
    );
  }
}

// 🔥【追加】ログインしてるかどうかで画面を出し分けるクラス
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(), // ログイン状態を監視
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          return const HomeScreen(); // ログイン済みなら投稿・投票画面へ
        } else {
          return const LoginPage(); // ログインしてなければログインページへ
        }
      },
    );
  }
}

// 🏠 ログイン後に遷移するホーム画面（投稿・投票）
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final List<Map<String, Map<String, bool>>> _posts = [];
  final List<bool> _isVoted = [];

  void _addPost(String title, String option1, String option2, String option3) {
    setState(() {
      _posts.add({
        title: {option1: false, option2: false, option3: false},
      });
      _isVoted.add(false);
    });
  }

  void _toggleVote(int postIndex, String optionKey) {
    if (_isVoted[postIndex]) return;
    setState(() {
      String title = _posts[postIndex].keys.first;
      _posts[postIndex][title]!.updateAll((key, value) => false);
      _posts[postIndex][title]![optionKey] = true;
    });
  }

  void _confirmVote(int postIndex) {
    setState(() {
      _isVoted[postIndex] = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIndex == 0 ? '投稿' : '投票'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              // ✅ ログアウト後は勝手にLoginPageに切り替わるので何も書かなくてOK！
            },
          ),
        ],
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
