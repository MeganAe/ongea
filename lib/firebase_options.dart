import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.g.dart' as generated;

/// Façade conservée séparément des options Android générées/configurées par FlutterFire.
/// Relancez `flutterfire configure --out=lib/firebase_options.g.dart` après toute
/// modification de l'application Firebase ou de ses clients OAuth.
abstract final class DefaultFirebaseOptions {
  static bool get isConfigured =>
      generated.DefaultFirebaseOptions.currentPlatform.projectId !=
      'YOUR_FIREBASE_PROJECT_ID';

  static FirebaseOptions get currentPlatform =>
      generated.DefaultFirebaseOptions.currentPlatform;
}
