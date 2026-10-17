import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/ongea_mark.dart';
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
    } on AccountProfileSetupException {
      _message(
        'Votre compte a été créé, mais votre profil n’a pas pu être enregistré. Vérifiez les règles Firestore, puis réessayez de vous connecter.',
      );
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

  Future<void> _signInWithGoogle() async {
    if (!ref.read(firebaseReadyProvider)) {
      _message('Configurez Firebase pour vous connecter avec Google.');
      return;
    }
    setState(() => _busy = true);
    try {
      await AuthRepository().signInWithGoogle();
      ref.read(demoModeProvider.notifier).state = false;
      if (mounted) context.go('/chats');
    } on GoogleSignInException catch (error) {
      if (error.code.name == 'canceled') return;
      if (error.code.name == 'clientConfigurationError' ||
          error.code.name == 'providerConfigurationError') {
        _message(
          'La connexion Google est mal configurée. Vérifiez le fournisseur Firebase, le fichier google-services.json et les empreintes SHA.',
        );
      } else {
        _message('La connexion Google a échoué. Réessayez dans un instant.');
      }
    } on FirebaseAuthException catch (error) {
      if (error.code == 'invalid-credential') {
        _message(
          'Le jeton Google est invalide. Vérifiez que google-services.json est à jour.',
        );
      } else {
        _message(authErrorMessage(error));
      }
    } catch (_) {
      _message(
        'Impossible de terminer la connexion Google. Vérifiez votre réseau et la configuration Firebase.',
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
      backgroundColor: context.ongea.background,
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
                      decoration: BoxDecoration(
                        color: context.ongea.primary,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Center(
                        child: OngeaMark(
                          size: 44,
                          color: context.ongea.onPrimary,
                          accentColor: context.ongea.accent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ongea',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.1,
                      color: context.ongea.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isRegister
                        ? 'Créez votre compte et rapprochez-vous.'
                        : 'Les liens se créent en parlant.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: context.ongea.secondaryText,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 30),
                  if (!firebaseReady) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: context.ongea.noticeBackground,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: context.ongea.noticeBorder),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: context.ongea.noticeForeground,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Firebase n’est pas encore configuré. Vous pouvez parcourir Ongea en mode démo, ou suivre le README pour activer les comptes et la synchronisation.',
                              style: TextStyle(
                                height: 1.4,
                                color: context.ongea.noticeForeground,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                  if (firebaseReady)
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
                            autofillHints:
                                _isRegister
                                    ? const [AutofillHints.newPassword]
                                    : const [AutofillHints.password],
                            onFieldSubmitted: (_) => _submit(),
                            decoration: InputDecoration(
                              labelText: 'Mot de passe',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                tooltip:
                                    _obscurePassword
                                        ? 'Afficher le mot de passe'
                                        : 'Masquer le mot de passe',
                                onPressed:
                                    () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
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
                  if (firebaseReady) const SizedBox(height: 22),
                  if (firebaseReady)
                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        onPressed: _busy ? null : _submit,
                        child:
                            _busy
                                ? SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: context.ongea.onPrimary,
                                  ),
                                )
                                : Text(
                                  _isRegister
                                      ? 'Créer mon compte'
                                      : 'Se connecter',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                      ),
                    ),
                  if (firebaseReady) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: Divider(color: context.ongea.border)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'OU',
                            style: TextStyle(
                              color: context.ongea.secondaryText,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: context.ongea.border)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: _busy ? null : _signInWithGoogle,
                        icon: const Text(
                          'G',
                          style: TextStyle(
                            color: Color(0xFF4285F4),
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        label: const Text('Continuer avec Google'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: context.ongea.text,
                          side: BorderSide(color: context.ongea.border),
                          minimumSize: const Size.fromHeight(52),
                        ),
                      ),
                    ),
                  ],
                  if (firebaseReady) const SizedBox(height: 12),
                  if (firebaseReady)
                    TextButton(
                      onPressed:
                          _busy
                              ? null
                              : () =>
                                  setState(() => _isRegister = !_isRegister),
                      style: TextButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: Text(
                        _isRegister
                            ? 'Déjà inscrit·e ? Se connecter'
                            : 'Nouveau sur Ongea ? Créer un compte',
                        style: TextStyle(
                          color: context.ongea.primary,
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
                        foregroundColor: context.ongea.primary,
                        side: BorderSide(color: context.ongea.primary),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    'Lorsque Firebase est configuré, les données synchronisées sont protégées par les règles de sécurité.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.ongea.secondaryText,
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
