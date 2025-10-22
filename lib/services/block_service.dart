import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BlockService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// ユーザーをブロックする
  Future<void> blockUser(String blockedUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('ログインが必要です');
    }

    if (currentUser.uid == blockedUserId) {
      throw Exception('自分自身をブロックすることはできません');
    }

    await _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('blockedUsers')
        .doc(blockedUserId)
        .set({
      'blockedAt': FieldValue.serverTimestamp(),
    });
  }

  /// ユーザーのブロックを解除する
  Future<void> unblockUser(String blockedUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('ログインが必要です');
    }

    await _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('blockedUsers')
        .doc(blockedUserId)
        .delete();
  }

  /// 特定のユーザーをブロックしているか確認
  Future<bool> isUserBlocked(String userId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    final doc = await _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('blockedUsers')
        .doc(userId)
        .get();

    return doc.exists;
  }

  /// ブロックしているユーザーIDのリストを取得
  Future<Set<String>> getBlockedUserIds() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return {};

    final snapshot = await _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('blockedUsers')
        .get();

    return snapshot.docs.map((doc) => doc.id).toSet();
  }

  /// ブロックしているユーザーのリストをストリームで取得
  Stream<Set<String>> getBlockedUserIdsStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value({});

    return _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('blockedUsers')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toSet());
  }
}

