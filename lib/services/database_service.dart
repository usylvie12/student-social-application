import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> createUserProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    await _db.collection('users').doc(userId).set(data);
  }

  Future<void> createPublicProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    await _db.collection('publicProfiles').doc(userId).set(data);
  }
}
