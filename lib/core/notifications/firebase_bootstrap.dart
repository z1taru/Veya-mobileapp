import 'package:firebase_core/firebase_core.dart';

abstract final class FirebaseBootstrap {
  /// Pass generated FirebaseOptions after adding platform configuration.
  /// Sprint 1 intentionally skips initialization when project keys are absent.
  static Future<bool> initialize({FirebaseOptions? options}) async {
    if (options == null) return false;
    await Firebase.initializeApp(options: options);
    return true;
  }
}
