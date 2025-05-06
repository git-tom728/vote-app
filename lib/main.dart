import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'login.dart';
// import 'register.dart';
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
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AuthGate(),
    );
  }
}

/// 🔐 ログイン状態によって画面を分ける
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // ローディング中
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        // 未ログイン
        if (!snapshot.hasData) {
          return const LoginPage();
        }
        // ログイン済み
        return const HomeScreen();
      },
    );
  }
}

/// 🏠 投稿＆投票のメイン画面
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  // final List<Map<String, Map<String, bool>>> _posts = [];
  // final List<bool> _isVoted = [];

  // void _addPost(String title, String option1, String option2, String option3) {
  //   setState(() {
  //     _posts.add({
  //       title: {option1: false, option2: false, option3: false},
  //     });
  //     _isVoted.add(false);
  //   });
  // }

  // void _toggleVote(int postIndex, String optionKey) {
  //   if (_isVoted[postIndex]) return;
  //   setState(() {
  //     String title = _posts[postIndex].keys.first;
  //     _posts[postIndex][title]!.updateAll((key, value) => false);
  //     _posts[postIndex][title]![optionKey] = true;
  //   });
  // }

  // void _confirmVote(int postIndex) {
  //   setState(() {
  //     _isVoted[postIndex] = true;
  //   });
  // }

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
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          const PostScreen(),
          const VoteScreen(),//
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.post_add), label: '投稿'),
          BottomNavigationBarItem(icon: Icon(Icons.how_to_vote), label: '投票'),
        ],
      ),
    );
  }
}
