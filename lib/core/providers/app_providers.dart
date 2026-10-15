import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../models/call_record.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../models/status_model.dart';

final firebaseReadyProvider = Provider<bool>((ref) => false);
final demoModeProvider = StateProvider<bool>((ref) => false);

final authStateProvider = StreamProvider<User?>((ref) {
  if (!ref.watch(firebaseReadyProvider)) return Stream<User?>.value(null);
  return FirebaseAuth.instance.authStateChanges();
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).asData?.value;
});

final currentProfileProvider = StreamProvider<AppUser?>((ref) {
  if (ref.watch(demoModeProvider)) {
    return Stream.value(
      const AppUser(
        id: DemoData.meId,
        name: 'Aline Mukendi',
        email: 'aline@example.com',
      ),
    );
  }
  final user = ref.watch(currentUserProvider);
  if (!ref.watch(firebaseReadyProvider) || user == null)
    return Stream.value(null);
  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((doc) => doc.exists ? AppUser.fromDocument(doc) : null);
});

final usersProvider = StreamProvider<List<AppUser>>((ref) {
  if (ref.watch(demoModeProvider)) return Stream.value(DemoData.users());
  final user = ref.watch(currentUserProvider);
  if (!ref.watch(firebaseReadyProvider) || user == null) {
    return Stream.value(const <AppUser>[]);
  }
  return FirebaseFirestore.instance
      .collection('profiles')
      .limit(150)
      .snapshots()
      .map((snapshot) {
        final users = snapshot.docs.map(AppUser.fromDocument).toList();
        users.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        return users;
      });
});

final contactProvider = StreamProvider.family<AppUser?, String>((ref, uid) {
  if (ref.watch(demoModeProvider)) {
    for (final user in DemoData.users()) {
      if (user.id == uid) return Stream.value(user);
    }
    return Stream.value(null);
  }
  if (!ref.watch(firebaseReadyProvider)) return Stream.value(null);
  return FirebaseFirestore.instance
      .collection('profiles')
      .doc(uid)
      .snapshots()
      .map((doc) => doc.exists ? AppUser.fromDocument(doc) : null);
});

final chatListProvider = StreamProvider<List<ChatModel>>((ref) {
  if (ref.watch(demoModeProvider)) return Stream.value(DemoData.chats());
  final user = ref.watch(currentUserProvider);
  if (!ref.watch(firebaseReadyProvider) || user == null) {
    return Stream.value(const <ChatModel>[]);
  }
  return FirebaseFirestore.instance
      .collection('chats')
      .where('participants', arrayContains: user.uid)
      .orderBy('lastMessageAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(ChatModel.fromDocument).toList());
});

final chatProvider = StreamProvider.family<ChatModel?, String>((ref, chatId) {
  if (ref.watch(demoModeProvider)) {
    for (final chat in DemoData.chats()) {
      if (chat.id == chatId) return Stream.value(chat);
    }
    return Stream.value(null);
  }
  final user = ref.watch(currentUserProvider);
  if (!ref.watch(firebaseReadyProvider) || user == null)
    return Stream.value(null);
  return FirebaseFirestore.instance
      .collection('chats')
      .doc(chatId)
      .snapshots()
      .map((doc) => doc.exists ? ChatModel.fromDocument(doc) : null);
});

final messagesProvider = StreamProvider.family<List<MessageModel>, String>((
  ref,
  chatId,
) {
  if (ref.watch(demoModeProvider))
    return Stream.value(DemoData.messages(chatId));
  final user = ref.watch(currentUserProvider);
  if (!ref.watch(firebaseReadyProvider) || user == null) {
    return Stream.value(const <MessageModel>[]);
  }
  return FirebaseFirestore.instance
      .collection('chats')
      .doc(chatId)
      .collection('messages')
      .orderBy('createdAt')
      .limitToLast(200)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(MessageModel.fromDocument).toList());
});

final statusListProvider = StreamProvider<List<StatusModel>>((ref) {
  if (ref.watch(demoModeProvider)) return Stream.value(DemoData.statuses());
  final user = ref.watch(currentUserProvider);
  if (!ref.watch(firebaseReadyProvider) || user == null) {
    return Stream.value(const <StatusModel>[]);
  }
  return FirebaseFirestore.instance
      .collection('statuses')
      .where('expiresAt', isGreaterThan: Timestamp.now())
      .orderBy('expiresAt')
      .snapshots()
      .map((snapshot) => snapshot.docs.map(StatusModel.fromDocument).toList());
});

final callLogProvider = StateProvider<List<CallRecord>>(
  (ref) => DemoData.calls(),
);

abstract final class DemoData {
  static const meId = 'demo-me';
  static const ayaId = 'demo-aya';
  static const malickId = 'demo-malick';
  static const groupeId = 'demo-groupe';

  static List<AppUser> users() => const [
    AppUser(
      id: ayaId,
      name: 'Aya Mukendi',
      email: 'aya@example.com',
      photoUrl: null,
    ),
    AppUser(
      id: malickId,
      name: 'Malick Bahati',
      email: 'malick@example.com',
      photoUrl: null,
    ),
    AppUser(
      id: 'demo-lina',
      name: 'Lina Mbuyi',
      email: 'lina@example.com',
      photoUrl: null,
    ),
    AppUser(
      id: 'demo-jules',
      name: 'Jules Kasereka',
      email: 'jules@example.com',
      photoUrl: null,
    ),
  ];

  static List<ChatModel> chats() {
    final now = DateTime.now();
    return [
      ChatModel(
        id: 'demo-chat-aya',
        participants: const [meId, ayaId],
        lastMessage: 'Tu es bien rentré ? 😊',
        lastMessageSenderId: ayaId,
        lastMessageStatus: 'delivered',
        lastMessageAt: now.subtract(const Duration(minutes: 4)),
        unreadCount: const {meId: 2},
        pinned: const {meId: true},
        muted: const {},
        archived: const {},
        favorite: const {meId: true},
        locked: const {},
      ),
      ChatModel(
        id: 'demo-chat-malick',
        participants: const [meId, malickId],
        lastMessage: 'Merci beaucoup, à demain !',
        lastMessageAt: now.subtract(const Duration(hours: 1, minutes: 12)),
        unreadCount: const {},
        pinned: const {},
        muted: const {meId: true},
        archived: const {},
        favorite: const {},
        locked: const {},
      ),
      ChatModel(
        id: 'demo-chat-groupe',
        participants: const [meId, ayaId, malickId],
        lastMessage: 'Aya : On se retrouve à 18 h ?',
        lastMessageAt: now.subtract(const Duration(hours: 5)),
        unreadCount: const {},
        pinned: const {},
        muted: const {},
        archived: const {},
        favorite: const {},
        locked: const {},
      ),
    ];
  }

  static List<MessageModel> messages(String chatId) {
    final now = DateTime.now();
    final peer = chatId == 'demo-chat-malick' ? malickId : ayaId;
    return [
      MessageModel(
        id: 'demo-1',
        senderId: peer,
        text: 'Salut ! Comment s’est passée ta journée ?',
        status: 'read',
        createdAt: now.subtract(const Duration(hours: 1, minutes: 18)),
      ),
      MessageModel(
        id: 'demo-2',
        senderId: meId,
        text: 'Très bien, merci ! Je viens juste de rentrer.',
        status: 'read',
        createdAt: now.subtract(const Duration(hours: 1, minutes: 14)),
      ),
      MessageModel(
        id: 'demo-3',
        senderId: peer,
        text: 'Parfait 😊 Tu es bien rentré ?',
        status: 'delivered',
        createdAt: now.subtract(const Duration(minutes: 4)),
      ),
    ];
  }

  static List<StatusModel> statuses() {
    final now = DateTime.now();
    return [
      StatusModel(
        id: 'demo-status-aya',
        ownerId: ayaId,
        text: 'Une belle journée au bord du lac 🌅',
        createdAt: now.subtract(const Duration(minutes: 35)),
        expiresAt: now.add(const Duration(hours: 23)),
        viewedBy: const [],
      ),
      StatusModel(
        id: 'demo-status-malick',
        ownerId: malickId,
        text: 'Bon dimanche à tous !',
        createdAt: now.subtract(const Duration(hours: 2)),
        expiresAt: now.add(const Duration(hours: 22)),
        viewedBy: const [meId],
      ),
    ];
  }

  static List<CallRecord> calls() {
    final now = DateTime.now();
    return [
      CallRecord(
        contactName: 'Aya Mukendi',
        direction: 'outgoing',
        createdAt: now.subtract(const Duration(minutes: 18)),
        video: true,
      ),
      CallRecord(
        contactName: 'Malick Bahati',
        direction: 'incoming',
        createdAt: now.subtract(const Duration(hours: 2)),
        missed: true,
      ),
      CallRecord(
        contactName: 'Jules Kasereka',
        direction: 'outgoing',
        createdAt: now.subtract(const Duration(days: 1, hours: 3)),
      ),
    ];
  }
}
