import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    this.photoPublicId,
    this.lastSeen,
  });

  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final String? photoPublicId;
  final DateTime? lastSeen;

  factory AppUser.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    return AppUser.fromMap(doc.id, doc.data() ?? const {});
  }

  factory AppUser.fromMap(String id, Map<String, dynamic> data) {
    final rawLastSeen = data['lastSeen'];
    return AppUser(
      id: id,
      name: (data['name'] as String?)?.trim().isNotEmpty == true
          ? (data['name'] as String).trim()
          : 'Utilisateur Ongea',
      email: data['email'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      photoPublicId: data['photoPublicId'] as String?,
      lastSeen: rawLastSeen is Timestamp ? rawLastSeen.toDate() : null,
    );
  }
}
