import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vote/services/log_service.dart';

class AccountDeletionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LogService _logService = LogService();

  /// アカウントの完全削除
  /// 1. Firestoreのユーザーデータを削除
  /// 2. Firebase Authenticationのアカウントを削除
  Future<void> deleteUserAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('ユーザーがログインしていません');
    }

    final userId = user.uid;
    
    try {
      _logService.startTrace('delete_user_account');
      _logService.logInfo('アカウント削除開始', data: {'userId': userId});

      // Step 1: Firestoreのデータを削除
      await _deleteUserDataFromFirestore(userId);

      // Step 2: Firebase Authのアカウントを削除
      await user.delete();

      _logService.logInfo('アカウント削除完了', data: {'userId': userId});
      _logService.stopTrace('delete_user_account');
      
    } catch (e, stackTrace) {
      _logService.logError(
        e,
        stackTrace,
        reason: 'アカウント削除に失敗',
        parameters: {'userId': userId},
      );
      _logService.stopTrace('delete_user_account');
      rethrow;
    }
  }

  /// Firestoreからユーザー関連データを削除
  Future<void> _deleteUserDataFromFirestore(String userId) async {
    final batch = _firestore.batch();
    
    try {
      // 1. ユーザープロファイルを削除
      final userRef = _firestore.collection('users').doc(userId);
      batch.delete(userRef);
      _logService.logInfo('ユーザープロファイル削除をバッチに追加');

      // 2. ユーザーが作成した投稿を削除
      final postsQuery = await _firestore
          .collection('posts')
          .where('userId', isEqualTo: userId)
          .get();
      
      for (var doc in postsQuery.docs) {
        batch.delete(doc.reference);
      }
      _logService.logInfo('ユーザー投稿削除をバッチに追加', 
          data: {'postsCount': postsQuery.docs.length});

      // 3. ユーザーの投票履歴を削除
      final votesQuery = await _firestore
          .collection('votes')
          .where('userId', isEqualTo: userId)
          .get();
      
      for (var doc in votesQuery.docs) {
        batch.delete(doc.reference);
      }
      _logService.logInfo('ユーザー投票履歴削除をバッチに追加', 
          data: {'votesCount': votesQuery.docs.length});

      // 4. ユーザーが投票した投稿の投票数を調整
      await _adjustVoteCountsForDeletedUser(userId, votesQuery.docs);

      // バッチ実行
      await batch.commit();
      _logService.logInfo('Firestoreデータ削除完了');
      
    } catch (e, stackTrace) {
      _logService.logError(
        e,
        stackTrace,
        reason: 'Firestoreデータ削除に失敗',
        parameters: {'userId': userId},
      );
      rethrow;
    }
  }

  /// 削除されるユーザーの投票分を投稿の投票数から引く
  Future<void> _adjustVoteCountsForDeletedUser(
    String userId, 
    List<QueryDocumentSnapshot> userVotes
  ) async {
    for (var voteDoc in userVotes) {
      final voteData = voteDoc.data() as Map<String, dynamic>;
      final postId = voteData['postId'] as String;
      final selectedOption = voteData['selectedOption'] as String;

      try {
        await _firestore.runTransaction((transaction) async {
          final postRef = _firestore.collection('posts').doc(postId);
          final postDoc = await transaction.get(postRef);

          if (postDoc.exists) {
            final options = Map<String, dynamic>.from(postDoc.data()!['options']);
            if (options.containsKey(selectedOption) && options[selectedOption] > 0) {
              options[selectedOption] = options[selectedOption] - 1;
              transaction.update(postRef, {'options': options});
            }
          }
        });
      } catch (e) {
        // 投稿が既に削除されている場合などはスキップ
        _logService.logInfo('投票数調整をスキップ', 
            data: {'postId': postId, 'reason': e.toString()});
      }
    }
  }

  /// 再認証が必要かチェック
  bool isReauthenticationRequired() {
    final user = _auth.currentUser;
    if (user?.metadata.lastSignInTime == null) return true;
    
    final lastSignIn = user!.metadata.lastSignInTime!;
    final now = DateTime.now();
    final difference = now.difference(lastSignIn);
    
    // 5分以内にサインインしていれば再認証不要
    return difference.inMinutes > 5;
  }

  /// 再認証の実行
  Future<void> reauthenticateUser(String email, String password) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('ユーザーがログインしていません');
    }

    try {
      _logService.startTrace('reauthenticate_user');
      
      final credential = EmailAuthProvider.credential(
        email: email, 
        password: password
      );
      
      await user.reauthenticateWithCredential(credential);
      
      _logService.logInfo('再認証完了');
      _logService.stopTrace('reauthenticate_user');
      
    } catch (e, stackTrace) {
      _logService.logError(
        e,
        stackTrace,
        reason: '再認証に失敗',
      );
      _logService.stopTrace('reauthenticate_user');
      rethrow;
    }
  }
}
