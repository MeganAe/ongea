import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  const ChatModel({
    required this.id,
    required this.participants,
    required this.lastMessage,
    required this.unreadCount,
    this.lastMessageSenderId,
    this.lastMessageStatus,
    required this.pinned,
    required this.muted,
    required this.archived,
    required this.favorite,
    required this.locked,
    this.lastMessageAt,
  });

  final String id;
  final List<String> participants;
  final String lastMessage;
  final String? lastMessageSenderId;
  final String? lastMessageStatus;
  final DateTime? lastMessageAt;
  final Map<String, int> unreadCount;
  final Map<String, bool> pinned;
  final Map<String, bool> muted;
  final Map<String, bool> archived;
  final Map<String, bool> favorite;
  final Map<String, bool> locked;

  bool get isGroup => participants.length > 2;
  int unreadFor(String userId) => unreadCount[userId] ?? 0;
  bool isPinnedFor(String userId) => pinned[userId] ?? false;
  bool isMutedFor(String userId) => muted[userId] ?? false;
  bool isArchivedFor(String userId) => archived[userId] ?? false;
  bool isFavoriteFor(String userId) => favorite[userId] ?? false;
  bool isLockedFor(String userId) => locked[userId] ?? false;

  factory ChatModel.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    final rawDate = data['lastMessageAt'];
    return ChatModel(
      id: doc.id,
      participants: List<String>.from(
        data['participants'] as List? ?? const [],
      ),
      lastMessage: data['lastMessage'] as String? ?? '',
      lastMessageSenderId: data['lastMessageSenderId'] as String?,
      lastMessageStatus: data['lastMessageStatus'] as String?,
      lastMessageAt: rawDate is Timestamp ? rawDate.toDate() : null,
      unreadCount: _intMap(data['unreadCount']),
      pinned: _boolMap(data['pinned']),
      muted: _boolMap(data['muted']),
      archived: _boolMap(data['archived']),
      favorite: _boolMap(data['favorite']),
      locked: _boolMap(data['locked']),
    );
  }

  static Map<String, int> _intMap(dynamic value) {
    if (value is! Map) return const {};
    return value.map(
      (key, value) =>
          MapEntry(key.toString(), value is num ? value.toInt() : 0),
    );
  }

  static Map<String, bool> _boolMap(dynamic value) {
    if (value is! Map) return const {};
    return value.map((key, value) => MapEntry(key.toString(), value == true));
  }
}
