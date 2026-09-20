import 'package:cloud_firestore/cloud_firestore.dart';

class MatchingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> findMatches(String currentUserId) async {
    final currentUserDocument = await _firestore
        .collection('users')
        .doc(currentUserId)
        .get();

    if (!currentUserDocument.exists) {
      return [];
    }

    final currentUser = currentUserDocument.data()!;

    final String university = currentUser['university'] ?? '';

    final String country = currentUser['country'] ?? '';

    final List<String> languages = List<String>.from(
      currentUser['languages'] ?? [],
    );

    final List<String> interests = List<String>.from(
      currentUser['interests'] ?? [],
    );

    final usersSnapshot = await _firestore.collection('users').get();

    List<Map<String, dynamic>> matches = [];

    for (final document in usersSnapshot.docs) {
      if (document.id == currentUserId) {
        continue;
      }

      final otherUser = document.data();

      final String otherUniversity = otherUser['university'] ?? '';

      final String otherCountry = otherUser['country'] ?? '';

      final List<String> otherLanguages = List<String>.from(
        otherUser['languages'] ?? [],
      );

      final List<String> otherInterests = List<String>.from(
        otherUser['interests'] ?? [],
      );

      int score = 0;

      if (university.isNotEmpty && university == otherUniversity) {
        score += 3;
      }

      if (country.isNotEmpty && country == otherCountry) {
        score += 2;
      }

      for (final language in languages) {
        if (otherLanguages.contains(language)) {
          score += 1;
        }
      }

      for (final interest in interests) {
        if (otherInterests.contains(interest)) {
          score += 1;
        }
      }

      if (score > 0) {
        matches.add({
          'id': document.id,
          'name': otherUser['name'] ?? '',
          'university': otherUniversity,
          'country': otherCountry,
          'languages': otherLanguages,
          'interests': otherInterests,
          'score': score,
        });
      }
    }

    matches.sort((a, b) => b['score'].compareTo(a['score']));

    return matches;
  }
}
