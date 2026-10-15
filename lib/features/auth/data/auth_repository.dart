import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
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
    await user.updateDisplayName(name.trim());
    await _firestore.collection('users').doc(user.uid).set({
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'photoUrl': null,
      'lastSeen': FieldValue.serverTimestamp(),
      'fcmToken': null,
      'blockedUsers': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _firestore.collection('profiles').doc(user.uid).set({
      'name': name.trim(),
      'photoUrl': null,
      'lastSeen': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });
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
    await _auth.signOut();
  }
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
      return 'La connexion par e-mail n’est pas activée dans Firebase.';
    default:
      return 'Une erreur est survenue. Vérifiez vos informations puis réessayez.';
  }
}
