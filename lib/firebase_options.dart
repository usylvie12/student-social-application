import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA0zORTMG3FhcsMuqsKB1TfVj2v5LrSQWo',
    appId: '1:749236566005:web:c9d415a973fa811aa192bc',
    messagingSenderId: '749236566005',
    projectId: 'studentconnect-e2cad',
    authDomain: 'studentconnect-e2cad.firebaseapp.com',
    storageBucket: 'studentconnect-e2cad.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDUdv98Crxtgdxy8ZtDx65cw9q9c0NR7CA',
    appId: '1:749236566005:android:86a1c73ea40c31bfa192bc',
    messagingSenderId: '749236566005',
    projectId: 'studentconnect-e2cad',
    storageBucket: 'studentconnect-e2cad.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA7ilP4CXPFddA7Q57g9WpB7kkCqz8om4I',
    appId: '1:749236566005:ios:f21816edf8e24d3ba192bc',
    messagingSenderId: '749236566005',
    projectId: 'studentconnect-e2cad',
    storageBucket: 'studentconnect-e2cad.firebasestorage.app',
    iosBundleId: 'com.example.studentSocialApp',
  );
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyA7ilP4CXPFddA7Q57g9WpB7kkCqz8om4I',
    appId: '1:749236566005:ios:f21816edf8e24d3ba192bc',
    messagingSenderId: '749236566005',
    projectId: 'studentconnect-e2cad',
    storageBucket: 'studentconnect-e2cad.firebasestorage.app',
    iosBundleId: 'com.example.studentSocialApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyA0zORTMG3FhcsMuqsKB1TfVj2v5LrSQWo',
    appId: '1:749236566005:web:a348591d038d6ddba192bc',
    messagingSenderId: '749236566005',
    projectId: 'studentconnect-e2cad',
    authDomain: 'studentconnect-e2cad.firebaseapp.com',
    storageBucket: 'studentconnect-e2cad.firebasestorage.app',
  );
}
