import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static bool get isConfigured => const String.fromEnvironment('FIREBASE_API_KEY').isNotEmpty;

  static FirebaseOptions get currentPlatform {
    // LƯU Ý: Ở môi trường thật, cấu hình được truyền qua --dart-define hoặc lệnh:
    // `flutterfire configure`
    return const FirebaseOptions(
      apiKey: String.fromEnvironment('FIREBASE_API_KEY', defaultValue: 'DUMMY_API_KEY'),
      appId: String.fromEnvironment('FIREBASE_APP_ID', defaultValue: '1:1234567890:android:abcdef'),
      messagingSenderId: String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID', defaultValue: '1234567890'),
      projectId: String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: 'wakeup-demo-proj'),
    );
  }
}
