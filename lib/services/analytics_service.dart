import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // 1. Login
  static Future<void> logLogin() async {
    await _analytics.logLogin(loginMethod: 'email');
  }

  // 2. Profile completed
  static Future<void> logProfileCompleted() async {
    await _analytics.logEvent(name: 'profile_completed');
  }

  // 3. Connection created
  static Future<void> logConnectionCreated() async {
    await _analytics.logEvent(name: 'connection_created');
  }

  // 4. Message sent
  static Future<void> logMessageSent() async {
    await _analytics.logEvent(name: 'message_sent');
  }

  // 5. Event created
  static Future<void> logEventCreated() async {
    await _analytics.logEvent(name: 'event_created');
  }

  // 6. Event joined
  static Future<void> logEventJoined() async {
    await _analytics.logEvent(name: 'event_joined');
  }
}
