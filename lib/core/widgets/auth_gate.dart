import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_colors.dart';
import '../providers/app_providers.dart';
import '../../features/auth/presentation/auth_page.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demoMode = ref.watch(demoModeProvider);
    final ready = ref.watch(firebaseReadyProvider);
    if (demoMode) return child;
    if (!ready) return const AuthPage();

    final auth = ref.watch(authStateProvider);
    return auth.when(
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (error, stack) => const AuthPage(),
      data: (user) => user == null ? const AuthPage() : child,
    );
  }
}
