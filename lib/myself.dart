import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/user_service.dart';
import 'login.dart';
import 'constants/regions.dart';
import 'config/environment.dart';

class MyselfPage extends StatefulWidget {
  const MyselfPage({super.key});

  @override
  State<MyselfPage> createState() => _MyselfPageState();
}

class _MyselfPageState extends State<MyselfPage> with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();
  int postCount = 0;
  int voteCount = 0;
  Map<String, dynamic>? userProfile;
  final _usernameController = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = false;
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _animation;
  String _selectedRegion = Regions.defaultPrefecture;

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
          _selectedRegion = profile?['region'] ?? Regions.defaultPrefecture;
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

  // 地域の更新
  Future<void> _updateRegion(String newRegion) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final success = await _userService.updateRegion(newRegion);
      if (success) {
        setState(() {
          _selectedRegion = newRegion;
          userProfile = {
            ...userProfile!,
            'region': newRegion,
          };
        });

        if (!mounted) return;
        _showSuccess('地域を更新しました');
      } else {
        if (!mounted) return;
        setState(() {
          _errorMessage = '地域の更新に失敗しました。もう一度お試しください。';
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

  // アカウント削除ダイアログを表示
  void _showAccountDeletionDialog() {
    final TextEditingController passwordController = TextEditingController();
    bool isPasswordVisible = false;
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.red.shade600),
              const SizedBox(width: 8),
              const Text('アカウント削除'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'アカウントを削除すると、すべてのデータが完全に削除され、復元できません。',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('確認のため、パスワードを入力してください：'),
              const SizedBox(height: 8),
              Text(
                'メールアドレス: ${_auth.currentUser?.email ?? ''}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: !isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'パスワード',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        isPasswordVisible = !isPasswordVisible;
                      });
                    },
                  ),
                ),
                enabled: !isLoading,
              ),
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 8),
                        Text('削除処理中...'),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () {
                passwordController.dispose();
                Navigator.pop(context);
              },
              child: Text('キャンセル', style: TextStyle(color: Colors.grey.shade600)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: isLoading ? null : () async {
                final password = passwordController.text.trim();
                if (password.isEmpty) {
                  _showError('パスワードを入力してください');
                  return;
                }

                setState(() {
                  isLoading = true;
                });

                try {
                  final user = _auth.currentUser;
                  if (user != null && user.email != null) {
                    // パスワードで再認証
                    final credential = EmailAuthProvider.credential(
                      email: user.email!,
                      password: password,
                    );
                    
                    await user.reauthenticateWithCredential(credential);
                    
                    // 最終確認ダイアログを表示
                    Navigator.pop(context);
                    passwordController.dispose();
                    _showFinalConfirmationDialog();
                  }
                } catch (e) {
                  setState(() {
                    isLoading = false;
                  });
                  
                  String errorMessage = 'パスワードが間違っています';
                  if (e.toString().contains('wrong-password')) {
                    errorMessage = 'パスワードが間違っています';
                  } else if (e.toString().contains('too-many-requests')) {
                    errorMessage = 'ログイン試行回数が多すぎます。しばらく待ってから再試行してください';
                  }
                  
                  _showError(errorMessage);
                }
              },
              child: const Text('確認', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // AuthState変化を定期的にチェック
  void _startAuthStatePolling() {
    int attempts = 0;
    const maxAttempts = 10; // 最大10回（10秒間）チェック
    
    Timer.periodic(const Duration(seconds: 1), (timer) {
      attempts++;
      
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      final currentUser = _auth.currentUser;
      
      if (currentUser == null) {
        timer.cancel();
        
        // 手動で画面を更新してAuthState変化を促す
        if (mounted) {
          setState(() {}); // 画面更新
          
          // 少し待ってから手動遷移
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
              );
            }
          });
        }
        return;
      }
      
      if (attempts >= maxAttempts) {
        timer.cancel();
        
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
          );
        }
      }
    });
  }

  // 最終確認ダイアログを表示
  void _showFinalConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange.shade600),
            const SizedBox(width: 8),
            const Text('最終確認'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '本当にアカウントを削除しますか？',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              'この操作は取り消すことができません。\nすべてのデータが完全に削除されます。',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('キャンセル', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              try {
                final user = _auth.currentUser;
                
                if (user != null) {
                  await user.delete();
                  
                  // 削除後のユーザー状態を確認
                  
                  if (mounted) {
                    Navigator.pop(context);
                    _showSuccess('アカウントが削除されました');
                    
                    // 定期的にAuthState変化をチェック
                    _startAuthStatePolling();
                  } else {
                  }
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  _showError('アカウント削除に失敗しました: ${e.toString()}');
                }
              }
            },
            child: const Text('アカウントを削除する', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? user = _auth.currentUser;
    
    return Scaffold(
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
                              elevation: 8,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.blue.shade50,
                                      Colors.white,
                                      Colors.blue.shade100,
                                    ],
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(20.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.all(12),
                                                    decoration: BoxDecoration(
                                                      color: Colors.blue.shade100,
                                                      borderRadius: BorderRadius.circular(16),
                                                    ),
                                                    child: Icon(
                                                      Icons.account_circle,
                                                      color: Colors.blue.shade700,
                                                      size: 28,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 16),
                                                  Text(
                                                    'アカウント情報',
                                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.grey.shade800,
                                                      fontSize: 22,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(12),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.grey.shade200,
                                                      blurRadius: 8,
                                                      offset: const Offset(0, 4),
                                                    ),
                                                  ],
                                                ),
                                                child: IconButton(
                                                  icon: Icon(
                                                    Icons.refresh_rounded,
                                                    color: Colors.blue.shade600,
                                                    size: 24,
                                                  ),
                                                  onPressed: _isLoading ? null : _refreshCard,
                                                  tooltip: '再読み込み',
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          if (userProfile != null) ...[
                                            Row(
                                              children: [
                                                const Text('ユーザー名: '),
                                                if (!_isEditing) ...[
                                                  Text(userProfile!['username'] ?? 'ユーザー名未設定'),
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
                                                        _usernameController.text = userProfile!['username'] ?? '';
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
                                          const SizedBox(height: 16),
                                          // 地域選択プルダウン
                                          Row(
                                            children: [
                                              const Text('地域: '),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius: BorderRadius.circular(8),
                                                    border: Border.all(color: Colors.grey.shade300),
                                                  ),
                                                  child: DropdownButtonHideUnderline(
                                                    child: DropdownButton<String>(
                                                      value: _selectedRegion,
                                                      isExpanded: true,
                                                      icon: Icon(Icons.arrow_drop_down, color: Colors.blue.shade600),
                                                      style: TextStyle(
                                                        color: Colors.grey.shade800,
                                                        fontSize: 14,
                                                      ),
                                                      items: Regions.prefectures.map((String prefecture) {
                                                        return DropdownMenuItem<String>(
                                                          value: prefecture,
                                                          child: Text(prefecture),
                                                        );
                                                      }).toList(),
                                                      onChanged: _isLoading ? null : (String? newValue) {
                                                        if (newValue != null && newValue != _selectedRegion) {
                                                          _updateRegion(newValue);
                                                        }
                                                      },
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
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
                                          color: Colors.black.withValues(alpha: 0.3),
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
                          ),
                          // 環境情報の表示（開発環境のみ）
                          if (EnvironmentConfig.isDevelopment)
                            Container(
                              margin: const EdgeInsets.only(top: 20),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Color(EnvironmentConfig.environmentColor).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Color(EnvironmentConfig.environmentColor),
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: Color(EnvironmentConfig.environmentColor),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '環境情報',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(EnvironmentConfig.environmentColor),
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '現在の環境: ${EnvironmentConfig.environmentName}',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'このデータはテスト用です',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Container(
                            margin: const EdgeInsets.only(top: 20),
                            width: double.infinity,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  colors: [Colors.red.shade400, Colors.red.shade600],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.shade200,
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  minimumSize: const Size(double.infinity, 50),
                                ),
                                icon: const Icon(Icons.delete_forever_rounded, size: 20),
                                label: const Text('アカウント削除', style: TextStyle(fontWeight: FontWeight.w600)),
                                onPressed: () => _showAccountDeletionDialog(),
                              ),
                            ),
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