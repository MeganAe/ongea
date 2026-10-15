import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../core/media/cloudinary_media_service.dart';

class StatusRepository {
  StatusRepository({
    FirebaseFirestore? firestore,
    CloudinaryMediaService? media,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _media = media ?? CloudinaryMediaService();

  final FirebaseFirestore _firestore;
  final CloudinaryMediaService _media;

  CollectionReference<Map<String, dynamic>> get _statuses =>
      _firestore.collection('statuses');

  Future<void> createText(String ownerId, String text) async {
    final cleaned = text.trim();
    if (cleaned.isEmpty) return;
    final now = DateTime.now();
    await _statuses.add({
      'ownerId': ownerId,
      'text': cleaned,
      'imageUrl': null,
      'imagePublicId': null,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(now.add(const Duration(hours: 24))),
      'viewedBy': <String>[],
    });
  }

  Future<void> createImage(String ownerId, XFile image) async {
    final id = const Uuid().v4();
    final asset = await _media.uploadImage(image);
    final now = DateTime.now();
    await _statuses.doc(id).set({
      'ownerId': ownerId,
      'text': null,
      'imageUrl': asset.secureUrl,
      'imagePublicId': asset.publicId,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(now.add(const Duration(hours: 24))),
      'viewedBy': <String>[],
    });
  }

  Future<void> markViewed(String statusId, String userId) async {
    await _statuses.doc(statusId).update({
      'viewedBy': FieldValue.arrayUnion([userId]),
    });
  }
}
