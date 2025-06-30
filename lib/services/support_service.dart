import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SupportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> submitInquiry(String content) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('inquiries').add({
      'userId': user.uid,
      'email': user.email,
      'content': content,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
} 