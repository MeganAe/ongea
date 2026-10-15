import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/providers/app_providers.dart';
import '../data/auth_repository.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegister = false;
  bool _obscurePassword = true;
  bool _busy = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!ref.read(firebaseReadyProvider)) {
      _message('Configurez Firebase pour créer un compte ou vous connecter.');
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    try {
      final repository = AuthRepository();
      if (_isRegister) {
        await repository.signUp(
          name: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
        );
      } else {
        await repository.signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
      }
      ref.read(demoModeProvider.notifier).state = false;
      if (mounted) context.go('/chats');
    } on FirebaseAuthException catch (error) {
      _message(authErrorMessage(error));
    } catch (_) {
      _message(
        'Impossible de terminer cette opération. Vérifiez votre connexion et la configuration Firebase.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Saisissez votre adresse e-mail.';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return 'Saisissez une adresse e-mail valide.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Saisissez votre mot de passe.';
    if (_isRegister && password.length < 8) {
      return '8 caractères minimum pour votre sécurité.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final firebaseReady = ref.watch(firebaseReadyProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(26, 36, 26, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: const BoxDecoration(
                        color: AppColors.activeChip,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.forum_outlined,
                        size: 37,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Ongea',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isRegister
                        ? 'Créez votre compte et rapprochez-vous.'
                        : 'Vos conversations, simplement.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 30),
                  if (!firebaseReady) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7E6),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFFE2A8)),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, color: Color(0xFF9A6700)),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Firebase n’est pas encore configuré. Vous pouvez parcourir Ongea en mode démo, ou suivre le README pour activer les comptes et la synchronisation.',
                              style: TextStyle(
                                height: 1.4,
                                color: Color(0xFF694F00),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        if (_isRegister) ...[
                          TextFormField(
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Nom complet',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (value) {
                              if ((value ?? '').trim().length < 2)
                                return 'Saisissez votre nom.';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                        ],
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          decoration: const InputDecoration(
                            labelText: 'Adresse e-mail',
                            prefixIcon: Icon(Icons.alternate_email),
                          ),
                          validator: _validateEmail,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          autofillHints: _isRegister
                              ? const [AutofillHints.newPassword]
                              : const [AutofillHints.password],
                          onFieldSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            labelText: 'Mot de passe',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              tooltip: _obscurePassword
                                  ? 'Afficher le mot de passe'
                                  : 'Masquer le mot de passe',
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: _validatePassword,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _isRegister ? 'Créer mon compte' : 'Se connecter',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() => _isRegister = !_isRegister),
                    style: TextButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: Text(
                      _isRegister
                          ? 'Déjà inscrit·e ? Se connecter'
                          : 'Nouveau sur Ongea ? Créer un compte',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (!firebaseReady) ...[
                    const SizedBox(height: 6),
                    OutlinedButton.icon(
                      onPressed: () {
                        ref.read(demoModeProvider.notifier).state = true;
                        if (mounted) context.go('/chats');
                      },
                      icon: const Icon(Icons.explore_outlined),
                      label: const Text('Explorer la démo'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const Text(
                    'Vos messages restent privés et sont protégés par les règles de sécurité Firebase.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.secondaryText,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
