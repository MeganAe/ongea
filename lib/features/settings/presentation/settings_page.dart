import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/media/cloudinary_media_service.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../auth/data/auth_repository.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final demo = ref.read(demoModeProvider);
    try {
      if (!demo && ref.read(firebaseReadyProvider))
        await AuthRepository().signOut();
      ref.read(demoModeProvider.notifier).state = false;
      if (context.mounted) context.go('/auth');
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('La déconnexion a échoué. Réessayez.')),
        );
      }
    }
  }

  void _showSetting(BuildContext context, String title, String description) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(description),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Future<void> _invite(BuildContext context) async {
    final code = const Uuid().v4().split('-').first.toUpperCase();
    await Clipboard.setData(
      ClipboardData(text: 'Rejoins-moi sur Ongea ! Code d’invitation : $code'),
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invitation copiée dans le presse-papiers.'),
        ),
      );
    }
  }

  Future<void> _changeProfilePhoto(BuildContext context, WidgetRef ref) async {
    final user = ref.read(currentUserProvider);
    if (ref.read(demoModeProvider) || user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Connectez Firebase pour modifier votre photo de profil.',
          ),
        ),
      );
      return;
    }
    final media = CloudinaryMediaService();
    if (!media.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Configurez Cloudinary pour ajouter une photo de profil.',
          ),
        ),
      );
      return;
    }
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 84,
      maxWidth: 1200,
      maxHeight: 1200,
    );
    if (image == null || !context.mounted) return;
    try {
      final asset = await media.uploadImage(image);
      await AuthRepository().updateProfilePhoto(
        uid: user.uid,
        photoUrl: asset.secureUrl,
        photoPublicId: asset.publicId,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo de profil mise à jour.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'La photo n’a pas pu être enregistrée. Vérifiez Cloudinary et votre connexion.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).asData?.value;
    final authUser = ref.watch(currentUserProvider);
    final name = profile?.name ?? authUser?.displayName ?? 'Utilisateur Ongea';
    final email = profile?.email ?? authUser?.email ?? '';
    final demo = ref.watch(demoModeProvider);
    final options = <_SettingOption>[
      _SettingOption(
        Icons.key_outlined,
        'Compte',
        'Sécurité, informations personnelles',
        'Gérez votre adresse e-mail, votre mot de passe et vos informations de compte.',
      ),
      _SettingOption(
        Icons.lock_outline,
        'Confidentialité',
        'Bloqués, visibilité, confirmations de lecture',
        'Contrôlez qui peut voir votre présence et vos informations. Les réglages avancés seront ajoutés progressivement.',
      ),
      _SettingOption(
        Icons.chat_bubble_outline,
        'Discussions',
        'Thème, fond d’écran, historique',
        'Personnalisez l’apparence de vos conversations et la sauvegarde de vos messages.',
      ),
      _SettingOption(
        Icons.notifications_none_outlined,
        'Notifications',
        'Sons des messages et des groupes',
        'Les notifications push sont envoyées via Firebase Cloud Messaging après déploiement des fonctions.',
      ),
      _SettingOption(
        Icons.data_usage_outlined,
        'Stockage et données',
        'Utilisation du réseau',
        'Les messages texte sont mis en attente hors ligne. Les photos de discussion passent par Firebase Storage; les statuts et photos de profil par Cloudinary.',
      ),
      _SettingOption(
        Icons.language_outlined,
        'Langue de l’application',
        'Français',
        'Ongea est actuellement disponible en français.',
      ),
      _SettingOption(
        Icons.help_outline,
        'Aide',
        'FAQ, contact, conditions',
        'Consultez le README du projet pour l’installation, la configuration Firebase et le dépannage.',
      ),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
        children: [
          Material(
            color: AppColors.softSurface,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => _showSetting(
                context,
                'Profil Ongea',
                'Votre profil est visible par les personnes avec lesquelles vous discutez.',
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    AppAvatar(
                      name: name,
                      photoUrl: profile?.photoUrl,
                      size: 58,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            email.isNotEmpty ? email : 'Disponible',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.secondaryText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Row(
                            children: [
                              Icon(
                                Icons.circle,
                                color: AppColors.primary,
                                size: 9,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Disponible',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Changer la photo de profil',
                      onPressed: () => _changeProfilePhoto(context, ref),
                      icon: const Icon(
                        Icons.photo_camera_outlined,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          for (final option in options)
            _SettingsTile(
              option: option,
              onTap: () =>
                  _showSetting(context, option.title, option.description),
            ),
          _SettingsTile(
            option: const _SettingOption(
              Icons.person_add_alt_1_outlined,
              'Inviter un ami',
              'Partager Ongea',
            ),
            onTap: () => _invite(context),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _logout(context, ref),
            icon: const Icon(Icons.logout, color: AppColors.danger),
            label: const Text(
              'Se déconnecter',
              style: TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              side: const BorderSide(color: Color(0x33B91C1C)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            demo ? 'Ongea · Mode démo' : 'Ongea · Version 1.0.0',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.secondaryText,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingOption {
  const _SettingOption(
    this.icon,
    this.title,
    this.subtitle, [
    this.description = 'Cette rubrique sera bientôt disponible.',
  ]);
  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.option, required this.onTap});
  final _SettingOption option;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    minLeadingWidth: 30,
    leading: Icon(option.icon, color: AppColors.secondaryText),
    title: Text(
      option.title,
      style: const TextStyle(fontWeight: FontWeight.w600),
    ),
    subtitle: Text(option.subtitle, style: const TextStyle(fontSize: 12)),
    trailing: const Icon(Icons.chevron_right, color: AppColors.secondaryText),
    onTap: onTap,
  );
}
