import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../../features/chats/data/chat_repository.dart';
import '../../firebase_options.dart';
import '../router/app_router.dart';

final rootMessengerKey = GlobalKey<ScaffoldMessengerState>();

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    try {
      await _messaging.requestPermission(alert: true, badge: true, sound: true);
      await _saveCurrentToken();
      FirebaseAuth.instance.authStateChanges().listen((user) {
        if (user != null) unawaited(_saveCurrentToken());
      });
      _messaging.onTokenRefresh.listen((_) {
        unawaited(_saveCurrentToken());
      });
      FirebaseMessaging.onMessage.listen((message) async {
        final chatId = message.data['chatId'] as String?;
        final messageId = message.data['messageId'] as String?;
        if (chatId != null && messageId != null) {
          try {
            await ChatRepository().markDelivered(chatId, messageId);
          } catch (_) {
            // Le statut sera mis à jour à la prochaine synchronisation.
          }
        }
        final title = message.notification?.title ?? 'Nouveau message';
        final body =
            message.notification?.body ??
            'Vous avez reçu un message sur Ongea.';
        rootMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('$title · $body'),
            duration: const Duration(seconds: 4),
          ),
        );
      });
      FirebaseMessaging.onMessageOpenedApp.listen(_openFromMessage);
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) _openFromMessage(initialMessage);
    } catch (error) {
      debugPrint('FCM indisponible : $error');
    }
  }

  Future<void> _saveCurrentToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final token = await _messaging.getToken();
      if (token == null) return;
      final profileRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      for (var attempt = 0; attempt < 4; attempt++) {
        final profile = await profileRef.get();
        if (profile.exists) {
          await profileRef.update({'fcmToken': token});
          return;
        }
        await Future<void>.delayed(const Duration(milliseconds: 400));
      }
    } catch (_) {
      // Les permissions ou le réseau peuvent ne pas être disponibles au démarrage.
    }
  }

  void _openFromMessage(RemoteMessage message) {
    final chatId = message.data['chatId'] as String?;
    if (chatId != null) appRouterInstance?.go('/chat/$chatId');
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (!DefaultFirebaseOptions.isConfigured) return;
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final chatId = message.data['chatId'] as String?;
  final messageId = message.data['messageId'] as String?;
  if (chatId == null || messageId == null) return;
  try {
    final ref = FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId);
    final snapshot = await ref.get();
    if (snapshot.exists && snapshot.data()?['status'] == 'sent') {
      await ref.update({'status': 'delivered'});
    }
  } catch (_) {
    // Le statut de livraison est indicatif et sera synchronisé à l’ouverture du chat.
  }
}
