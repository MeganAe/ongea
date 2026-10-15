// STUB DE DÉVELOPPEMENT — remplacé par `flutterfire configure`.
// Ces valeurs ne sont pas des secrets. Ne collez jamais de clé de compte de service ici.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

abstract class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
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
        return linux;
      case TargetPlatform.fuchsia:
        throw UnsupportedError('Firebase n’est pas configuré pour Fuchsia.');
    }
  }

  static const web = FirebaseOptions(
    apiKey: 'YOUR_FIREBASE_API_KEY',
    appId: '1:000000000000:web:0000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'YOUR_FIREBASE_PROJECT_ID',
    authDomain: 'YOUR_FIREBASE_PROJECT_ID.firebaseapp.com',
    storageBucket: 'YOUR_FIREBASE_PROJECT_ID.appspot.com',
  );
  static const android = FirebaseOptions(
    apiKey: 'YOUR_FIREBASE_API_KEY',
    appId: '1:000000000000:android:0000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'YOUR_FIREBASE_PROJECT_ID',
    storageBucket: 'YOUR_FIREBASE_PROJECT_ID.appspot.com',
  );
  static const ios = FirebaseOptions(
    apiKey: 'YOUR_FIREBASE_API_KEY',
    appId: '1:000000000000:ios:0000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'YOUR_FIREBASE_PROJECT_ID',
    storageBucket: 'YOUR_FIREBASE_PROJECT_ID.appspot.com',
    iosBundleId: 'com.ongea.app',
  );
  static const macos = FirebaseOptions(
    apiKey: 'YOUR_FIREBASE_API_KEY',
    appId: '1:000000000000:ios:0000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'YOUR_FIREBASE_PROJECT_ID',
    storageBucket: 'YOUR_FIREBASE_PROJECT_ID.appspot.com',
    iosBundleId: 'com.ongea.app',
  );
  static const windows = FirebaseOptions(
    apiKey: 'YOUR_FIREBASE_API_KEY',
    appId: '1:000000000000:web:0000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'YOUR_FIREBASE_PROJECT_ID',
    authDomain: 'YOUR_FIREBASE_PROJECT_ID.firebaseapp.com',
    storageBucket: 'YOUR_FIREBASE_PROJECT_ID.appspot.com',
  );
  static const linux = FirebaseOptions(
    apiKey: 'YOUR_FIREBASE_API_KEY',
    appId: '1:000000000000:web:0000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'YOUR_FIREBASE_PROJECT_ID',
    authDomain: 'YOUR_FIREBASE_PROJECT_ID.firebaseapp.com',
    storageBucket: 'YOUR_FIREBASE_PROJECT_ID.appspot.com',
  );
}
