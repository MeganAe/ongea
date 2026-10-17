import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'core/notifications/notification_service.dart';
import 'core/providers/app_providers.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR');
  Intl.defaultLocale = 'fr_FR';
  var firebaseReady = false;
  if (DefaultFirebaseOptions.isConfigured) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
      );
      firebaseReady = true;
    } catch (error) {
      debugPrint('Initialisation Firebase impossible : $error');
    }
  }
  runApp(
    ProviderScope(
      overrides: [firebaseReadyProvider.overrideWithValue(firebaseReady)],
      child: const OngeaApp(),
    ),
  );
}

class OngeaApp extends ConsumerStatefulWidget {
  const OngeaApp({super.key});

  @override
  ConsumerState<OngeaApp> createState() => _OngeaAppState();
}

class _OngeaAppState extends ConsumerState<OngeaApp>
    with WidgetsBindingObserver {
  bool _notificationsStarted = false;
  bool _presenceStarted = false;
  Timer? _presenceTimer;
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _startServicesIfReady();
  }

  void _startServicesIfReady() {
    if (!ref.read(firebaseReadyProvider)) return;
    if (!_notificationsStarted) {
      _notificationsStarted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(NotificationService.instance.initialize());
      });
    }
    if (!_presenceStarted) {
      _presenceStarted = true;
      _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
        (_) => _refreshPresence(),
      );
      _refreshPresence();
    }
  }

  void _refreshPresence() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _presenceTimer?.cancel();
      _presenceTimer = null;
      return;
    }
    unawaited(_writePresence(user.uid));
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
      _presenceTimer ??= Timer.periodic(
        const Duration(minutes: 1),
        (_) => unawaited(_writePresence(user.uid)),
      );
    } else {
      _presenceTimer?.cancel();
      _presenceTimer = null;
    }
  }

  Future<void> _writePresence(String uid) async {
    try {
      await Future.wait([
        FirebaseFirestore.instance.collection('users').doc(uid).update({
          'lastSeen': FieldValue.serverTimestamp(),
        }),
        FirebaseFirestore.instance.collection('profiles').doc(uid).update({
          'lastSeen': FieldValue.serverTimestamp(),
        }),
      ]);
    } catch (_) {
      // La présence reste indicative si le réseau est momentanément indisponible.
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!ref.read(firebaseReadyProvider) || !_presenceStarted) return;
    if (state == AppLifecycleState.resumed) {
      _refreshPresence();
    } else {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      _presenceTimer?.cancel();
      _presenceTimer = null;
      if (uid != null) unawaited(_writePresence(uid));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _presenceTimer?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Ongea',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: ref.watch(appRouterProvider),
      scaffoldMessengerKey: rootMessengerKey,
      locale: const Locale('fr', 'FR'),
      supportedLocales: const [Locale('fr', 'FR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
    );
  }
}
