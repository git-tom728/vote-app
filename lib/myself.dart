import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/user_service.dart';
import 'services/support_service.dart';

class MyselfPage extends StatefulWidget {
  const MyselfPage({super.key});

  @override
  State<MyselfPage> createState() => _MyselfPageState();
}

class _MyselfPageState extends State<MyselfPage> with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();
  final SupportService _supportService = SupportService();
  int postCount = 0;
  int voteCount = 0;
  Map<String, dynamic>? userProfile;
  final _usernameController = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = false;
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _animation;
  String _inquiryContent = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _loadUserData();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // エラーメッセージを表示
  void _showError(String message, {bool isWarning = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isWarning ? Icons.warning_amber_rounded : Icons.error_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isWarning ? Colors.orange : Colors.red,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  // 成功メッセージを表示
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = _auth.currentUser;
      if (user != null) {
        final profile = await _userService.getUserProfile();
        final postCount = await _userService.getPostCount();
        final voteCount = await _userService.getVoteCount();
        
        if (!mounted) return;
        setState(() {
          userProfile = profile;
          _usernameController.text = profile?['username'] ?? '';
          this.postCount = postCount;
          this.voteCount = voteCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'データの読み込みに失敗しました。再読み込みをお試しください。';
        _isLoading = false;
      });
      _showError(_errorMessage!);
    }
  }

  Future<void> _updateUsername() async {
    final newUsername = _usernameController.text.trim();
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // バリデーション
      if (!_userService.isValidUsername(newUsername)) {
        setState(() {
          _errorMessage = 'ユーザー名は3〜20文字の英数字とアンダースコアのみ使用可能です';
          _isLoading = false;
        });
        _showError(_errorMessage!, isWarning: true);
        return;
      }

      // 更新頻度のチェック
      if (!_userService.canUpdateUsername()) {
        setState(() {
          _errorMessage = '更新は5秒に1回までです。しばらくお待ちください。';
          _isLoading = false;
        });
        _showError(_errorMessage!, isWarning: true);
        return;
      }

      final success = await _userService.updateUsername(newUsername);
      if (success) {
        setState(() {
          userProfile = {
            ...userProfile!,
            'username': newUsername,
          };
          _isEditing = false;
        });

        if (!mounted) return;
        _showSuccess('ユーザー名を更新しました');
      } else {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'ユーザー名の更新に失敗しました。もう一度お試しください。';
        });
        _showError(_errorMessage!);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '更新中にエラーが発生しました。時間をおいて再度お試しください。';
      });
      _showError(_errorMessage!);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // カードの更新アニメーション
  Future<void> _refreshCard() async {
    _animationController.forward(from: 0.0);
    await _loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    final User? user = _auth.currentUser;
    
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('マイページ'),
      // ),
      body: user == null
          ? const Center(child: Text('ログインが必要です'))
          : Stack(
              children: [
                RefreshIndicator(
                  onRefresh: _loadUserData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_errorMessage != null)
                            Card(
                              color: Colors.red.shade50,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline, color: Colors.red),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: const TextStyle(color: Colors.red),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, color: Colors.red),
                                      onPressed: () {
                                        setState(() {
                                          _errorMessage = null;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          AnimatedBuilder(
                            animation: _animation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: 1.0 - (_animation.value * 0.05),
                                child: Opacity(
                                  opacity: 1.0 - (_animation.value * 0.3),
                                  child: child,
                                ),
                              );
                            },
                            child: Card(
                              child: Stack(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'アカウント情報',
                                              style: Theme.of(context).textTheme.titleLarge,
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.refresh),
                                              onPressed: _isLoading ? null : _refreshCard,
                                              tooltip: '再読み込み',
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        if (userProfile != null) ...[
                                          Row(
                                            children: [
                                              const Text('ユーザー名: '),
                                              if (!_isEditing) ...[
                                                Text(userProfile!['username']),
                                                const SizedBox(width: 4),
                                                GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      _isEditing = true;
                                                      _errorMessage = null;
                                                    });
                                                  },
                                                  child: const Icon(
                                                    Icons.edit,
                                                    size: 16,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ] else ...[
                                                Expanded(
                                                  child: TextField(
                                                    controller: _usernameController,
                                                    decoration: const InputDecoration(
                                                      isDense: true,
                                                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                                      border: OutlineInputBorder(),
                                                      hintText: '3〜20文字の英数字とアンダースコア',
                                                      helperText: '変更を保存するにはチェックマークをタップしてください',
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                GestureDetector(
                                                  onTap: _updateUsername,
                                                  child: const Icon(
                                                    Icons.check,
                                                    size: 16,
                                                    color: Colors.green,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      _usernameController.text = userProfile!['username'];
                                                      _isEditing = false;
                                                      _errorMessage = null;
                                                    });
                                                  },
                                                  child: const Icon(
                                                    Icons.close,
                                                    size: 16,
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                        ],
                                        Text('メールアドレス: ${user.email}'),
                                        const SizedBox(height: 8),
                                        Text('投稿数: $postCount'),
                                        const SizedBox(height: 8),
                                        Text('投票数: $voteCount'),
                                      ],
                                    ),
                                  ),
                                  if (_isLoading)
                                    Positioned.fill(
                                      child: Container(
                                        // ignore: deprecated_member_use
                                        color: Colors.black.withOpacity(0.3),
                                        child: const Center(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              CircularProgressIndicator(),
                                              SizedBox(height: 16),
                                              Text(
                                                '処理中...',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton(
                                onPressed: () async {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('ログアウト'),
                                      content: const Text('ログアウトしますか？'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: const Text('キャンセル'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          child: const Text('ログアウト'),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirmed == true) {
                                    await FirebaseAuth.instance.signOut();
                                    if (mounted) {
                                      // ignore: use_build_context_synchronously
                                      Navigator.pushReplacementNamed(context, '/login');
                                    }
                                  }
                                },
                                child: const Text('ログアウト'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('アカウント削除'),
                                      content: const Text('アカウントを削除すると、すべてのデータが完全に削除され、復元できません。本当に削除しますか？'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('キャンセル'),
                                        ),
                                        TextButton(
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.red,
                                          ),
                                          onPressed: () async {
                                            try {
                                              // Firebase Authenticationからアカウント削除
                                              User? user = _auth.currentUser;
                                              if (user != null) {
                                                await user.delete();
                                                
                                                if (mounted) {
                                                  // ignore: use_build_context_synchronously
                                                  Navigator.pop(context);
                                                  // ignore: use_build_context_synchronously
                                                  Navigator.pushReplacementNamed(context, '/login');
                                                  // ignore: use_build_context_synchronously
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(
                                                      content: Text('アカウントが削除されました'),
                                                      backgroundColor: Colors.green,
                                                    ),
                                                  );
                                                }
                                              }
                                            } catch (e) {
                                              if (mounted) {
                                                // ignore: use_build_context_synchronously
                                                Navigator.pop(context);
                                                // ignore: use_build_context_synchronously
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('アカウント削除に失敗しました: ${e.toString()}'),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                          child: const Text('削除'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                child: const Text('アカウント削除'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('お問い合わせ'),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text('お問い合わせ内容を入力してください'),
                                          const SizedBox(height: 16),
                                          TextField(
                                            maxLines: 5,
                                            decoration: const InputDecoration(
                                              hintText: 'お問い合わせ内容',
                                              border: OutlineInputBorder(),
                                            ),
                                            onChanged: (value) {
                                              _inquiryContent = value;
                                            },
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('キャンセル'),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            if (_inquiryContent.isEmpty) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('お問い合わせ内容を入力してください'),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                              return;
                                            }

                                            try {
                                              await _supportService.submitInquiry(_inquiryContent);
                                              if (mounted) {
                                                // ignore: use_build_context_synchronously
                                                // ignore: use_build_context_synchronously
                                                Navigator.pop(context);
                                                // ignore: use_build_context_synchronously
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Text('お問い合わせを受け付けました'),
                                                    backgroundColor: Colors.green,
                                                  ),
                                                );
                                              }
                                            } catch (e) {
                                              if (mounted) {
                                                // ignore: use_build_context_synchronously
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Text('お問い合わせの送信に失敗しました'),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                          child: const Text('送信'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                child: const Text('お問い合わせ'),
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[600],
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('利用規約'),
                                      content: const SingleChildScrollView(
                                        child: Text(
                                          '【Vote アプリ利用規約】\n\n'
                                          '第1条（適用）\n'
                                          '本利用規約は、Vote アプリの利用に関する条件を定めるものです。\n\n'
                                          '第2条（禁止事項）\n'
                                          '・法令に違反する行為\n'
                                          '・他者を誹謗中傷、脅迫する行為\n'
                                          '・わいせつ、暴力的、差別的なコンテンツの投稿\n'
                                          '・スパム行為や営利目的の宣伝\n'
                                          '・虚偽情報の拡散\n'
                                          '・知的財産権を侵害する行為\n\n'
                                          '第3条（コンテンツ管理）\n'
                                          '不適切なコンテンツは削除され、違反ユーザーはアカウント停止となる場合があります。\n\n'
                                          '詳細な利用規約は以下をご確認ください：\n'
                                          'https://git-tom728.github.io/vote-app/terms_of_service.html',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('閉じる'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                child: const Text('利用規約'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
} 