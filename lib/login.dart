import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'register.dart';
import 'main.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String errorMessage = '';

  Future<void> loginUser() async {
    try {
      debugPrint('=== ログイン開始 ===');
      debugPrint('メールアドレス: ${emailController.text.trim()}');
      
      User? user;
      try {
        final credential = await _auth.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
        user = credential.user;
        debugPrint('ログイン成功: ${user!.uid}');
      } catch (authError) {
        debugPrint('Firebase Authログインエラー: $authError');
        // 型エラーの場合は、ユーザーが実際にログインされているかチェック
        user = _auth.currentUser;
        if (user != null) {
          debugPrint('ユーザーはログイン済み: ${user.uid}');
        } else {
          rethrow; // ユーザーがログインされていない場合はエラーを再スロー
        }
      }

      // ログイン成功後の処理
      if (!mounted) return;
      
      // メインページに遷移
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ログインに成功しました')),
      );
      
      // HomeScreenに遷移
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
      
    } on FirebaseAuthException catch (e) {
      debugPrint('=== Firebase Auth エラー ===');
      debugPrint('エラーコード: ${e.code}');
      debugPrint('エラーメッセージ: ${e.message}');
      
      setState(() {
        errorMessage = 'ログインに失敗しました: ${e.code}';
      });
    } catch (e) {
      debugPrint('=== 予期しないエラー ===');
      debugPrint('エラー: $e');
      
      setState(() {
        errorMessage = 'ログインに失敗しました: $e';
      });
    }
  }

  Future<void> _resetPassword() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        errorMessage = 'メールアドレスを入力してください';
      });
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('パスワードリセット用のメールを送信しました'),
        ),
      );
    } catch (e) {
      setState(() {
        errorMessage = 'パスワードリセットメールの送信に失敗しました: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ログイン')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'メールアドレス'),
            ),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'パスワード'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loginUser,
              child: const Text('ログイン'),
            ),
            TextButton(
              onPressed: _resetPassword,
              child: const Text('パスワードをお忘れですか？'),
            ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterPage()),
                  );
                },
              child: const Text("アカウント作成はこちら"),
              ),
            const SizedBox(height: 20),
            Text(errorMessage, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}
