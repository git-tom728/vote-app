import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'config/firebase_options_dev.dart';
import 'config/environment.dart';
import 'login.dart';
import 'post.dart';
import 'vote.dart';
import 'myself.dart';
import 'config/debug_config.dart';
import 'services/version_service.dart';
import 'widgets/update_dialog.dart';

/// メインエントリーポイント（本番環境）
void main() => mainWithEnvironment(Environment.production);

/// 開発環境用エントリーポイント
void mainDev() => mainWithEnvironment(Environment.development);

/// 環境を指定してアプリを起動
Future<void> mainWithEnvironment(Environment environment) async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 環境を設定
  EnvironmentConfig.setEnvironment(environment);
  DebugConfig.debugLog('環境設定', data: {
    'environment': EnvironmentConfig.environmentName,
    'isDevelopment': EnvironmentConfig.isDevelopment,
  });
  
  // 環境に応じたFirebase設定を使用
  final firebaseOptions = EnvironmentConfig.isDevelopment
      ? DevelopmentFirebaseOptions.currentPlatform
      : DefaultFirebaseOptions.currentPlatform;
  
  await Firebase.initializeApp(options: firebaseOptions);
  DebugConfig.debugSuccess('Firebase初期化完了', data: {
    'projectId': firebaseOptions.projectId,
    'environment': EnvironmentConfig.environmentName,
  });
  
  // バージョンサービスの初期化
  try {
    await VersionService().initialize();
    DebugConfig.debugSuccess('VersionService初期化完了');
  } catch (e) {
    DebugConfig.debugError('VersionService初期化エラー（アプリは続行）', error: e);
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vote App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AuthGate(),
      // 開発環境の場合はバナーを表示
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        if (EnvironmentConfig.isDevelopment) {
          return Banner(
            message: EnvironmentConfig.environmentShortName,
            location: BannerLocation.topEnd,
            color: Color(EnvironmentConfig.environmentColor),
            child: child!,
          );
        }
        return child!;
      },
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
        DebugConfig.debugLog('AuthState変化検知', data: {
          'connectionState': snapshot.connectionState.toString(),
          'hasData': snapshot.hasData,
          'user': snapshot.data?.uid,
        });
        
        // ローディング中
        if (snapshot.connectionState == ConnectionState.waiting) {
          DebugConfig.debugLog('AuthState: ローディング中');
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        // 未ログイン
        if (!snapshot.hasData) {
          DebugConfig.debugLog('AuthState: 未ログイン → LoginPageへ');
          return const LoginPage();
        }
        // ログイン済み
        DebugConfig.debugSuccess('AuthState: ログイン済み → HomeScreenへ', data: {
          'uid': snapshot.data?.uid,
          'email': snapshot.data?.email,
        });
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
  
  @override
  void initState() {
    super.initState();
    // アプリ起動時にバージョンチェック
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdates();
    });
  }
  
  /// バージョンチェックを実行
  Future<void> _checkForUpdates() async {
    if (!mounted) return;
    
    try {
      DebugConfig.debugLog('バージョンチェック開始');
      await UpdateDialog.checkAndShowIfNeeded(context);
    } catch (e) {
      DebugConfig.debugError('バージョンチェックエラー', error: e);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIndex == 0 ? '投稿' : _selectedIndex == 1 ? '投票' : 'マイページ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              try {
                DebugConfig.debugLog('ログアウト開始');
                
                // ローディング表示
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );

                await FirebaseAuth.instance.signOut();
                DebugConfig.debugSuccess('Firebase.signOut()完了');
                
                // Firebase AuthStateの変化を5秒間監視
                DebugConfig.debugLog('Firebase AuthState変化を5秒間監視開始');
                
                bool logoutSuccess = false;
                late StreamSubscription<User?> authSubscription;
                
                // タイムアウト用のCompleter
                final completer = Completer<bool>();
                
                // AuthState変化を監視
                authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
                  DebugConfig.debugLog('AuthState変化検知', data: {
                    'user': user?.uid ?? 'null',
                    'logoutSuccess': user == null,
                  });
                  
                  if (user == null && !completer.isCompleted) {
                    DebugConfig.debugSuccess('Firebase AuthState: ログアウト成功');
                    logoutSuccess = true;
                    completer.complete(true);
                  }
                });
                
                // 5秒のタイムアウト
                Timer(const Duration(seconds: 5), () {
                  if (!completer.isCompleted) {
                    DebugConfig.debugWarning('Firebase AuthState: 5秒タイムアウト');
                    completer.complete(false);
                  }
                });
                
                // 結果を待機
                logoutSuccess = await completer.future;
                authSubscription.cancel();
                
                // ローディング閉じる
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
                
                if (logoutSuccess) {
                  // 成功: ログイン画面に遷移
                  DebugConfig.debugSuccess('ログアウト成功 - LoginPageに遷移');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('ログアウトしました'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const LoginPage()),
                      (route) => false,
                    );
                  }
                } else {
                  // 失敗: エラーメッセージ表示
                  DebugConfig.debugError('ログアウト失敗: Firebase AuthStateが変化しませんでした');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('ログアウトに失敗しました。もう一度お試しください。'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
                
                DebugConfig.debugSuccess('ログアウト処理完了');
              } catch (e) {
                DebugConfig.debugError('ログアウトエラー', error: e, stackTrace: StackTrace.current);
                
                // エラー時はローディングを閉じる
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('ログアウトエラー: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          PostScreen(),
          VoteScreen(),
          MyselfPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.post_add), label: '投稿'),
          BottomNavigationBarItem(icon: Icon(Icons.how_to_vote), label: '投票'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'マイページ'),
        ],
      ),
    );
  }
}
