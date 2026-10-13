import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'analytics_service.dart';

class ConnectionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<bool> connectToStudent(String otherUserId) async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw Exception('Please log in first.');
    }

    if (currentUser.uid == otherUserId) {
      throw Exception('You cannot connect with yourself.');
    }

    final ids = [currentUser.uid, otherUserId]..sort();
    final connectionId = '${ids[0]}_${ids[1]}';

    final connectionRef = _firestore
        .collection('connections')
        .doc(connectionId);

    final created = await _firestore.runTransaction<bool>((transaction) async {
      final existing = await transaction.get(connectionRef);

      if (existing.exists) {
        return false;
      }

      transaction.set(connectionRef, {
        'user1Id': ids[0],
        'user2Id': ids[1],
        'createdBy': currentUser.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'connected',
      });

      return true;
    });

    if (created) {
      await AnalyticsService.logConnectionCreated();
    }

    return created;
  }
}
