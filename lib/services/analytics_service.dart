import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  static Future<void> setUserId(String uid) async {
    await _analytics.setUserId(id: uid);
  }

  static Future<void> clearUserId() async {
    await _analytics.setUserId(id: null);
  }

  static Future<void> logLogin() async {
    await _analytics.logLogin(loginMethod: 'email');
  }

  static Future<void> logProfileCompleted() async {
    await _analytics.logEvent(name: 'profile_completed');
  }

  static Future<void> logConnectionCreated() async {
    await _analytics.logEvent(name: 'connection_created');
  }

  static Future<void> logMessageSent() async {
    await _analytics.logEvent(name: 'message_sent');
  }

  static Future<void> logEventCreated() async {
    await _analytics.logEvent(name: 'event_created');
  }

  static Future<void> logEventJoined() async {
    await _analytics.logEvent(name: 'event_joined');
  }
}
