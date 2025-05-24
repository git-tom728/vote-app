import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main.dart'; // HomeScreen への遷移に使用
import 'utils/user_id_generator.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nicknameController = TextEditingController();
  String? _errorMessage;
  late String _userId;

  @override
  void initState() {
    super.initState();
    _userId = UserIdGenerator.generate();
  }

  String _getDefaultNickname(String email) {
    return email.split('@')[0];
  }

  Future<void> _register() async {
    try {
      // ユーザーIDの重複チェック
      final userIdQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('userId', isEqualTo: _userId)
          .get();

      if (userIdQuery.docs.isNotEmpty) {
        // 重複している場合は新しいIDを生成
        _userId = UserIdGenerator.generate();
        // 再帰的に登録処理を実行
        await _register();
        return;
      }

      // ユーザー認証の作成
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      // ニックネームが未入力の場合はメールアドレスの@より前の部分を使用
      final nickname = _nicknameController.text.trim().isEmpty
          ? _getDefaultNickname(_emailController.text.trim())
          : _nicknameController.text.trim();

      // ユーザープロフィール情報をFirestoreに保存
      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .set({
        'userId': _userId,
        'nickname': nickname,
        'email': _emailController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? "登録に失敗しました";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("アカウント作成")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _nicknameController,
              decoration: const InputDecoration(
                labelText: "ニックネーム（任意）",
              ),
            ),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "メールアドレス"),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: "パスワード"),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _register,
              child: const Text("登録"),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
    );
  }
}
