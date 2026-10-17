import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/media/cloudinary_media_service.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../auth/data/auth_repository.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final demo = ref.read(demoModeProvider);
    try {
      if (!demo && ref.read(firebaseReadyProvider)) {
        await AuthRepository().signOut();
      }
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

  Future<void> _changeProfilePhoto(BuildContext context, WidgetRef ref) async {
    final user = ref.read(currentUserProvider);
    final media = CloudinaryMediaService();
    if (ref.read(demoModeProvider) || user == null || !media.isConfigured) {
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
    final demo = ref.watch(demoModeProvider);
    final name = profile?.name ?? authUser?.displayName ?? 'Utilisateur Ongea';
    final email = profile?.email ?? authUser?.email ?? '';
    final canChangePhoto =
        !demo && authUser != null && CloudinaryMediaService().isConfigured;

    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Material(
            color: context.ongea.softSurface,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  AppAvatar(name: name, photoUrl: profile?.photoUrl, size: 58),
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
                        const SizedBox(height: 4),
                        Text(
                          email.isNotEmpty
                              ? email
                              : demo
                              ? 'Profil de démonstration'
                              : 'Profil Ongea',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: context.ongea.secondaryText),
                        ),
                      ],
                    ),
                  ),
                  if (canChangePhoto)
                    IconButton(
                      tooltip: 'Changer la photo de profil',
                      onPressed: () => _changeProfilePhoto(context, ref),
                      icon: Icon(
                        Icons.photo_camera_outlined,
                        color: context.ongea.primary,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (demo) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.ongea.softSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.ongea.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: context.ongea.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Mode démo : les données affichées sont des exemples locaux.',
                      style: TextStyle(color: context.ongea.secondaryText),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => _logout(context, ref),
            icon: Icon(Icons.logout, color: context.ongea.danger),
            label: Text(
              'Se déconnecter',
              style: TextStyle(
                color: context.ongea.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              side: BorderSide(
                color: context.ongea.danger.withValues(alpha: 0.35),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Ongea',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.ongea.secondaryText, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
