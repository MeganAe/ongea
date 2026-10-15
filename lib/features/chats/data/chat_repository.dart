import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class ChatRepository {
  ChatRepository({FirebaseFirestore? firestore, FirebaseStorage? storage})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _chats =>
      _firestore.collection('chats');

  Future<String> createOrGetDirectChat(
    String currentUid,
    String otherUid,
  ) async {
    if (currentUid == otherUid)
      throw ArgumentError('Un utilisateur ne peut pas discuter avec lui-même.');
    final existing = await _chats
        .where('participants', arrayContains: currentUid)
        .get();
    for (final doc in existing.docs) {
      final participants = List<String>.from(
        doc.data()['participants'] as List? ?? const [],
      );
      if (participants.length == 2 && participants.contains(otherUid)) {
        final archived = Map<String, dynamic>.from(
          doc.data()['archived'] as Map? ?? const {},
        );
        if (archived[currentUid] == true) {
          await setPreference(doc.id, currentUid, 'archived', false);
        }
        return doc.id;
      }
    }

    final chatRef = _chats.doc();
    await chatRef.set({
      'participants': [currentUid, otherUid],
      'lastMessage': '',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'unreadCount': {currentUid: 0, otherUid: 0},
      'pinned': {currentUid: false},
      'muted': {currentUid: false},
      'archived': {currentUid: false},
      'favorite': {currentUid: false},
      'locked': {currentUid: false},
      'createdAt': FieldValue.serverTimestamp(),
    });
    return chatRef.id;
  }

  Future<void> sendText({
    required String chatId,
    required String senderId,
    required String text,
  }) async {
    final cleaned = text.trim();
    if (cleaned.isEmpty) return;
    await _chats.doc(chatId).collection('messages').add({
      'senderId': senderId,
      'text': cleaned,
      'imageUrl': null,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'sent',
    });
    // Le déclencheur Cloud Function met à jour lastMessage, les non-lus et envoie le push.
    // Firestore conserve cette écriture localement si l’app est hors ligne.
  }

  Future<void> sendImage({
    required String chatId,
    required String senderId,
    required XFile image,
  }) async {
    final bytes = await image.readAsBytes();
    final name = '${const Uuid().v4()}.jpg';
    final ref = _storage.ref('chats/$chatId/$senderId/$name');
    await ref.putData(
      bytes,
      SettableMetadata(
        contentType: image.mimeType ?? 'image/jpeg',
        customMetadata: {'uploadedBy': senderId},
      ),
    );
    final imageUrl = await ref.getDownloadURL();
    await _chats.doc(chatId).collection('messages').add({
      'senderId': senderId,
      'text': '',
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'sent',
    });
  }

  Future<void> setPreference(
    String chatId,
    String userId,
    String preference,
    bool value,
  ) async {
    const allowed = {'pinned', 'muted', 'archived', 'favorite', 'locked'};
    if (!allowed.contains(preference))
      throw ArgumentError('Préférence inconnue.');
    await _chats.doc(chatId).update({
      FieldPath([preference, userId]): value,
    });
  }

  Future<void> markDelivered(String chatId, String messageId) async {
    final ref = _chats.doc(chatId).collection('messages').doc(messageId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists) return;
      final status = snapshot.data()?['status'];
      if (status == 'sent') transaction.update(ref, {'status': 'delivered'});
    });
  }

  Future<void> markRead(String chatId, String userId) async {
    final messages = await _chats
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(200)
        .get();
    final batch = _firestore.batch();
    var hasWrites = false;
    for (final message in messages.docs) {
      final data = message.data();
      if (data['senderId'] != userId && data['status'] != 'read') {
        batch.update(message.reference, {'status': 'read'});
        hasWrites = true;
      }
    }
    // Les UID Firebase générés sont des segments sûrs pour la notation pointée.
    batch.update(_chats.doc(chatId), {'unreadCount.$userId': 0});
    hasWrites = true;
    if (hasWrites) await batch.commit();
  }

  Future<void> blockUser(String currentUid, String otherUid) async {
    await _firestore.collection('users').doc(currentUid).update({
      'blockedUsers': FieldValue.arrayUnion([otherUid]),
    });
  }

  Future<void> reportUser({
    required String reporterId,
    required String reportedId,
  }) async {
    await _firestore.collection('reports').add({
      'reporterId': reporterId,
      'reportedId': reportedId,
      'reason': 'signalement depuis les informations du contact',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
