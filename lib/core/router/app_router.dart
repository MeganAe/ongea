import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../widgets/auth_gate.dart';
import '../../features/auth/presentation/auth_page.dart';
import '../../features/chats/presentation/archived_page.dart';
import '../../features/chats/presentation/chats_page.dart';
import '../../features/chats/presentation/contact_info_page.dart';
import '../../features/chats/presentation/conversation_page.dart';
import '../../features/chats/presentation/new_chat_page.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../../features/status/presentation/status_page.dart';
import '../../features/status/presentation/status_viewer_page.dart';

GoRouter? appRouterInstance;

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/chats',
    routes: [
      GoRoute(path: '/auth', builder: (context, state) => const AuthPage()),
      ShellRoute(
        builder:
            (context, state, child) => AuthGate(
              child: _MainScaffold(location: state.uri.path, child: child),
            ),
        routes: [
          GoRoute(
            path: '/chats',
            builder: (context, state) => const ChatsPage(),
          ),
          GoRoute(
            path: '/status',
            builder: (context, state) => const StatusPage(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsPage(),
          ),
        ],
      ),
      GoRoute(
        path: '/new-chat',
        builder: (context, state) => const AuthGate(child: NewChatPage()),
      ),
      GoRoute(
        path: '/chat/:chatId',
        builder:
            (context, state) => AuthGate(
              child: ConversationPage(chatId: state.pathParameters['chatId']!),
            ),
      ),
      GoRoute(
        path: '/contact/:userId',
        builder:
            (context, state) => AuthGate(
              child: ContactInfoPage(
                userId: state.pathParameters['userId']!,
                chatId: state.uri.queryParameters['chatId'],
              ),
            ),
      ),
      GoRoute(
        path: '/archived',
        builder: (context, state) => const AuthGate(child: ArchivedPage()),
      ),
      GoRoute(
        path: '/status/view/:statusId',
        builder:
            (context, state) => AuthGate(
              child: StatusViewerPage(
                statusId: state.pathParameters['statusId']!,
              ),
            ),
      ),
    ],
  );
  appRouterInstance = router;
  ref.onDispose(() {
    if (identical(appRouterInstance, router)) appRouterInstance = null;
    router.dispose();
  });
  return router;
});

class _MainScaffold extends StatelessWidget {
  const _MainScaffold({required this.location, required this.child});

  final String location;
  final Widget child;

  int get _selectedIndex {
    if (location.startsWith('/status')) return 1;
    if (location.startsWith('/settings')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          const routes = ['/chats', '/status', '/settings'];
          context.go(routes[index]);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Discussions',
          ),
          NavigationDestination(
            icon: Icon(Icons.circle_outlined),
            selectedIcon: Icon(Icons.circle),
            label: 'Actus',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Paramètres',
          ),
        ],
      ),
    );
  }
}
