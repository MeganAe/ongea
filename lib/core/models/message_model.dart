import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  const MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    required this.status,
    this.imageUrl,
    this.createdAt,
  });

  final String id;
  final String senderId;
  final String text;
  final String? imageUrl;
  final DateTime? createdAt;
  final String status;

  bool get isImage => imageUrl != null && imageUrl!.isNotEmpty;

  factory MessageModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    final rawDate = data['createdAt'];
    return MessageModel(
      id: doc.id,
      senderId: data['senderId'] as String? ?? '',
      text: data['text'] as String? ?? '',
      imageUrl: data['imageUrl'] as String?,
      createdAt: rawDate is Timestamp ? rawDate.toDate() : null,
      status: data['status'] as String? ?? 'sent',
    );
  }
}
