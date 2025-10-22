import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 投稿を通報する
  Future<void> reportPost({
    required String postId,
    required String reportedUserId,
    required String reason,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('ログインが必要です');
    }

    await _firestore.collection('reports').add({
      'postId': postId,
      'reportedUserId': reportedUserId,
      'reportedBy': currentUser.uid,
      'reportedByEmail': currentUser.email,
      'reason': reason,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'pending', // pending, reviewed, resolved
    });
  }

  /// ユーザーが特定の投稿を既に通報しているか確認
  Future<bool> hasReportedPost(String postId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    final snapshot = await _firestore
        .collection('reports')
        .where('postId', isEqualTo: postId)
        .where('reportedBy', isEqualTo: currentUser.uid)
        .get();

    return snapshot.docs.isNotEmpty;
  }
}

