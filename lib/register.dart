import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login.dart'; // LoginPage への遷移に使用
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

  // String _getDefaultNickname(String email) {
  //   return email.split('@')[0];
  // }

  Future<void> _register() async {
    try {
      debugPrint('=== アカウント作成開始 ===');
      debugPrint('メールアドレス: ${_emailController.text.trim()}');
      debugPrint('パスワード長: ${_passwordController.text.length}');
      // debugPrint('ニックネーム: ${_nicknameController.text.trim()}');
      debugPrint('ユーザーID: $_userId');

      // ユーザー認証の作成
      debugPrint('Firebase Authでユーザー作成中...');
      User? user;
      debugPrint('Firebase Auth作成中try前');
      try {
        final credential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            );
        user = credential.user;
        debugPrint('Firebase Auth作成成功: ${user!.uid}');
      } catch (authError) {
        // Firebase内部エラーの詳細ログ
        if (authError.toString().contains('PigeonUserDetails')) {
          debugPrint('=== Firebase内部型変換エラー（既知の問題） ===');
          debugPrint('エラー詳細: $authError');
          debugPrint('原因: Firebase Flutter SDK内部のPigeon型変換の不整合');
          debugPrint('影響: なし（実際の処理は正常完了）');
          debugPrint('対応: 不要（Firebase SDK側の問題のため対応不可）');
          debugPrint('参考: https://github.com/firebase/flutterfire/issues');
          debugPrint('=== エラーログ終了 ===');
        } else {
          debugPrint('Firebase Auth作成エラー: $authError');
          debugPrint('エラーの型: ${authError.runtimeType}');
        }
        
        // 実際のユーザー作成状況を確認
        user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          debugPrint('✅ 結果確認: ユーザー作成は正常完了 (UID: ${user.uid})');
        } else {
          debugPrint('❌ 結果確認: ユーザー作成に失敗');
          rethrow; // 実際に失敗した場合はエラーを再スロー
        }
      }

      // ユーザープロフィール情報をFirestoreに保存
      debugPrint('Firestoreにユーザー情報保存中...');
      
      // userがnullでないことを確認
      // ignore: unnecessary_null_comparison
      if (user == null) {
        throw Exception('ユーザー情報が取得できませんでした');
      }
      
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'userId': _userId,
        'email': _emailController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('Firestore保存成功');

      if (!mounted) return;

      // メッセージを表示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('アカウント作成が完了しました。')),
      );

      // 少し待ってから遷移
      await Future.delayed(const Duration(seconds: 1));

      // ここでサインアウト
      debugPrint('サインアウト中...');
      await FirebaseAuth.instance.signOut();
      debugPrint('サインアウト完了');

      // すべてのルートを消してLoginPageだけにする（カスタムアニメーション）
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const LoginPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(-1.0, 0.0); // 左から右
            const end = Offset.zero;
            const curve = Curves.ease;
            final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        ),
        (Route<dynamic> route) => false,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('=== Firebase Auth エラー ===');
      debugPrint('エラーコード: ${e.code}');
      debugPrint('エラーメッセージ: ${e.message}');
      debugPrint('エラー詳細: $e');
      
      setState(() {
        _errorMessage = e.code;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('認証エラー: ${e.code} - ${e.message ?? "詳細不明"}')),
      );
    } catch (e, stackTrace) {
      debugPrint('=== 予期しないエラー ===');
      debugPrint('エラー: $e');
      debugPrint('スタックトレース: $stackTrace');
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('登録に失敗しました: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("アカウント作成"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => const LoginPage(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  const begin = Offset(-1.0, 0.0); // 左から右
                  const end = Offset.zero;
                  const curve = Curves.ease;
                  final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                  return SlideTransition(
                    position: animation.drive(tween),
                    child: child,
                  );
                },
              ),
              (Route<dynamic> route) => false,
            );
          },
        ),
      ),
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
