import 'package:firebase_auth/firebase_auth.dart';

import 'analytics_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> signOut() async {
    await logout();
  }

  Future<User?> register(String email, String password) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      return result.user;
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<User?> login(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = result.user;

      if (user != null) {
        await AnalyticsService.setUserId(user.uid);

        await AnalyticsService.logLogin();
      }

      return user;
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<void> logout() async {
    await AnalyticsService.clearUserId();

    await _auth.signOut();
  }
}
