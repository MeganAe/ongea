import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthRepository {
  static Future<void>? _googleSignInInitialization;

  AuthRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<UserCredential> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) throw StateError('Le compte n’a pas pu être créé.');
    try {
      await user.updateDisplayName(name.trim());
      final batch = _firestore.batch();
      batch.set(_firestore.collection('users').doc(user.uid), {
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'photoUrl': null,
        'lastSeen': FieldValue.serverTimestamp(),
        'fcmToken': null,
        'blockedUsers': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
      });
      batch.set(_firestore.collection('profiles').doc(user.uid), {
        'name': name.trim(),
        'photoUrl': null,
        'lastSeen': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();
    } catch (error) {
      throw AccountProfileSetupException(uid: user.uid, cause: error);
    }
    return credential;
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user != null) {
      final name = user.displayName ?? 'Utilisateur Ongea';
      await _firestore.collection('users').doc(user.uid).set({
        'email': user.email ?? email.trim().toLowerCase(),
        'name': name,
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await _firestore.collection('profiles').doc(user.uid).set({
        'name': name,
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    return credential;
  }

  Future<UserCredential> signInWithGoogle() async {
    final googleSignIn = GoogleSignIn.instance;
    await (_googleSignInInitialization ??= googleSignIn.initialize());
    if (!googleSignIn.supportsAuthenticate()) {
      throw UnsupportedError(
        'La connexion Google n’est pas disponible sur cette plateforme.',
      );
    }

    final googleUser = await googleSignIn.authenticate();
    final idToken = googleUser.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw StateError('Google n’a pas renvoyé de jeton d’identification.');
    }

    final credential = GoogleAuthProvider.credential(idToken: idToken);
    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;
    if (user == null) throw StateError('La connexion Google a échoué.');
    await _syncProviderProfile(user);
    return userCredential;
  }

  Future<void> _syncProviderProfile(User user) async {
    final userRef = _firestore.collection('users').doc(user.uid);
    final profileRef = _firestore.collection('profiles').doc(user.uid);
    final snapshots = await Future.wait([userRef.get(), profileRef.get()]);
    final userExists = snapshots[0].exists;
    final profileExists = snapshots[1].exists;
    final name = _socialDisplayName(user);

    final userData = <String, dynamic>{
      'name': name,
      'email': user.email?.trim().toLowerCase() ?? '',
      'lastSeen': FieldValue.serverTimestamp(),
    };
    if (!userExists) {
      userData.addAll({
        // Les avatars Ongea sont stockés sur Cloudinary, pas sur l’URL Google.
        'photoUrl': null,
        'fcmToken': null,
        'blockedUsers': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await userRef.set(userData, SetOptions(merge: true));

    final profileData = <String, dynamic>{
      'name': name,
      'lastSeen': FieldValue.serverTimestamp(),
    };
    if (!profileExists) {
      profileData.addAll({
        'photoUrl': null,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await profileRef.set(profileData, SetOptions(merge: true));
  }

  String _socialDisplayName(User user) {
    final displayName = user.displayName?.trim();
    if (displayName != null && displayName.length >= 2) return displayName;
    final emailName = (user.email ?? '').split('@').first.trim();
    return emailName.length >= 2 ? emailName : 'Utilisateur Ongea';
  }

  Future<void> updateProfilePhoto({
    required String uid,
    required String photoUrl,
    required String photoPublicId,
  }) async {
    final batch = _firestore.batch();
    batch.update(_firestore.collection('users').doc(uid), {
      'photoUrl': photoUrl,
      'photoPublicId': photoPublicId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.update(_firestore.collection('profiles').doc(uid), {
      'photoUrl': photoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> signOut() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await Future.wait([
          _firestore.collection('users').doc(user.uid).update({
            'lastSeen': FieldValue.serverTimestamp(),
            'fcmToken': FieldValue.delete(),
          }),
          _firestore.collection('profiles').doc(user.uid).update({
            'lastSeen': FieldValue.serverTimestamp(),
          }),
        ]).timeout(const Duration(seconds: 2));
      } catch (_) {
        // La déconnexion ne doit pas rester bloquée en cas de réseau indisponible.
      }
    }
    final googleInitialization = _googleSignInInitialization;
    if (googleInitialization != null) {
      try {
        await googleInitialization;
        await GoogleSignIn.instance.signOut();
      } catch (_) {
        // La session Firebase doit pouvoir se fermer même si Google est indisponible.
      }
    }
    await _auth.signOut();
  }
}

/// L'inscription Auth a réussi, mais le profil Firestore n'a pas été créé.
class AccountProfileSetupException implements Exception {
  const AccountProfileSetupException({required this.uid, required this.cause});

  final String uid;
  final Object cause;
}

String authErrorMessage(FirebaseAuthException error) {
  switch (error.code) {
    case 'email-already-in-use':
      return 'Cette adresse e-mail possède déjà un compte.';
    case 'invalid-email':
      return 'L’adresse e-mail n’est pas valide.';
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
      return 'Adresse e-mail ou mot de passe incorrect.';
    case 'weak-password':
      return 'Choisissez un mot de passe d’au moins 8 caractères.';
    case 'too-many-requests':
      return 'Trop de tentatives. Réessayez dans quelques minutes.';
    case 'network-request-failed':
      return 'Connexion impossible. Vérifiez votre accès à Internet.';
    case 'operation-not-allowed':
      return 'Cette méthode de connexion n’est pas activée dans Firebase.';
    case 'account-exists-with-different-credential':
      return 'Cette adresse e-mail utilise déjà une autre méthode de connexion.';
    case 'credential-already-in-use':
      return 'Ce compte Google est déjà associé à un autre compte Ongea.';
    default:
      return 'Une erreur est survenue. Vérifiez vos informations puis réessayez.';
  }
}
