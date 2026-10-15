import 'package:cloud_firestore/cloud_firestore.dart';

class StatusModel {
  const StatusModel({
    required this.id,
    required this.ownerId,
    required this.viewedBy,
    this.text,
    this.imageUrl,
    this.imagePublicId,
    this.createdAt,
    this.expiresAt,
  });

  final String id;
  final String ownerId;
  final String? text;
  final String? imageUrl;
  final String? imagePublicId;
  final DateTime? createdAt;
  final DateTime? expiresAt;
  final List<String> viewedBy;

  bool get isImage => imageUrl != null && imageUrl!.isNotEmpty;

  factory StatusModel.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    final rawCreated = data['createdAt'];
    final rawExpires = data['expiresAt'];
    return StatusModel(
      id: doc.id,
      ownerId: data['ownerId'] as String? ?? '',
      text: data['text'] as String?,
      imageUrl: data['imageUrl'] as String?,
      imagePublicId: data['imagePublicId'] as String?,
      createdAt: rawCreated is Timestamp ? rawCreated.toDate() : null,
      expiresAt: rawExpires is Timestamp ? rawExpires.toDate() : null,
      viewedBy: List<String>.from(data['viewedBy'] as List? ?? const []),
    );
  }
}
