import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/app_user.dart';
import '../../../core/models/status_model.dart';
import '../../../core/media/cloudinary_media_service.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/empty_state.dart';
import '../data/status_repository.dart';

class StatusPage extends ConsumerWidget {
  const StatusPage({super.key});

  Future<void> _createStatus(BuildContext context, WidgetRef ref) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Écrire un statut'),
              onTap: () => Navigator.pop(context, 'text'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Partager une photo'),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Prendre une photo'),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (choice == null || !context.mounted) return;
    final uid = ref.read(currentUserProvider)?.uid;
    if (ref.read(demoModeProvider) || uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La publication des statuts nécessite Firebase.'),
        ),
      );
      return;
    }
    if (choice == 'text') {
      final controller = TextEditingController();
      final text = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Nouveau statut'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 500,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Que souhaitez-vous partager ?',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Publier'),
            ),
          ],
        ),
      );
      controller.dispose();
      if (text == null || text.trim().isEmpty) return;
      try {
        await StatusRepository().createText(uid, text);
      } catch (_) {
        if (context.mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Le statut n’a pas pu être publié.')),
          );
      }
      return;
    }
    if (!CloudinaryMediaService().isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configurez Cloudinary pour publier une photo.'),
        ),
      );
      return;
    }
    final source = choice == 'camera'
        ? ImageSource.camera
        : ImageSource.gallery;
    try {
      final image = await ImagePicker().pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1800,
      );
      if (image != null) await StatusRepository().createImage(uid, image);
    } catch (_) {
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'La photo n’a pas pu être publiée. Vérifiez la connexion et la configuration Cloudinary.',
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusesAsync = ref.watch(statusListProvider);
    final users = {
      for (final user
          in ref.watch(usersProvider).asData?.value ?? const <AppUser>[])
        user.id: user,
    };
    final uid = ref.watch(currentUserProvider)?.uid ?? DemoData.meId;
    final demo = ref.watch(demoModeProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Actus'),
        actions: [
          IconButton(
            tooltip: 'Créer un statut',
            onPressed: () => _createStatus(context, ref),
            icon: const Icon(Icons.add_circle_outline),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: statusesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, stack) => const EmptyState(
          icon: Icons.cloud_off_outlined,
          title: 'Actus indisponibles',
          message: 'Vérifiez votre connexion et réessayez.',
        ),
        data: (allStatuses) {
          final mine =
              allStatuses.where((status) => status.ownerId == uid).toList()
                ..sort(
                  (a, b) => (b.createdAt ?? DateTime(2000)).compareTo(
                    a.createdAt ?? DateTime(2000),
                  ),
                );
          final othersByOwner = <String, List<StatusModel>>{};
          for (final status in allStatuses.where(
            (status) => status.ownerId != uid,
          )) {
            othersByOwner.putIfAbsent(status.ownerId, () => []).add(status);
          }
          for (final statuses in othersByOwner.values) {
            statuses.sort(
              (a, b) => (b.createdAt ?? DateTime(2000)).compareTo(
                a.createdAt ?? DateTime(2000),
              ),
            );
          }
          final recent = <MapEntry<String, List<StatusModel>>>[];
          final viewed = <MapEntry<String, List<StatusModel>>>[];
          for (final entry in othersByOwner.entries) {
            final hasUnseen = entry.value.any(
              (status) => !status.viewedBy.contains(uid),
            );
            (hasUnseen ? recent : viewed).add(entry);
          }
          recent.sort(
            (a, b) => (b.value.first.createdAt ?? DateTime(2000)).compareTo(
              a.value.first.createdAt ?? DateTime(2000),
            ),
          );
          viewed.sort(
            (a, b) => (b.value.first.createdAt ?? DateTime(2000)).compareTo(
              a.value.first.createdAt ?? DateTime(2000),
            ),
          );
          final myProfile = users[uid];
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              _MyStatusTile(
                name: myProfile?.name ?? 'Mon statut',
                photoUrl: myProfile?.photoUrl,
                latest: mine.isEmpty ? null : mine.first,
                onTap: mine.isEmpty
                    ? () => _createStatus(context, ref)
                    : () => context.push('/status/view/${mine.first.id}'),
                onAdd: () => _createStatus(context, ref),
              ),
              if (recent.isNotEmpty) ...[
                const _StatusHeading('RÉCENTES'),
                for (final entry in recent)
                  _StatusContactTile(
                    user: users[entry.key],
                    status: entry.value.first,
                    viewed: false,
                    fallbackName: 'Contact Ongea',
                    onTap: () =>
                        context.push('/status/view/${entry.value.first.id}'),
                  ),
              ],
              if (viewed.isNotEmpty) ...[
                const _StatusHeading('VUES'),
                for (final entry in viewed)
                  _StatusContactTile(
                    user: users[entry.key],
                    status: entry.value.first,
                    viewed: true,
                    fallbackName: 'Contact Ongea',
                    onTap: () =>
                        context.push('/status/view/${entry.value.first.id}'),
                  ),
              ],
              if (recent.isEmpty && viewed.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 56),
                  child: EmptyState(
                    icon: Icons.circle_outlined,
                    title: 'Rien de nouveau',
                    message: 'Les statuts de vos contacts apparaîtront ici et disparaîtront après 24 heures.',
                  ),
                ),
              if (demo)
                const Padding(
                  padding: EdgeInsets.only(top: 18),
                  child: Text(
                    'Mode démo · Les statuts présentés sont des exemples.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Ajouter une photo ou un statut',
        onPressed: () => _createStatus(context, ref),
        child: const Icon(Icons.camera_alt_outlined),
      ),
    );
  }
}

class _MyStatusTile extends StatelessWidget {
  const _MyStatusTile({
    required this.name,
    required this.photoUrl,
    required this.latest,
    required this.onTap,
    required this.onAdd,
  });
  final String name;
  final String? photoUrl;
  final StatusModel? latest;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(vertical: 5),
    leading: Stack(
      clipBehavior: Clip.none,
      children: [
        AppAvatar(name: name, photoUrl: photoUrl, size: 54),
        Positioned(
          right: -11,
          bottom: -11,
          child: SizedBox(
            width: 44,
            height: 44,
            child: InkResponse(
              onTap: onAdd,
              radius: 22,
              child: Center(
                child: Container(
                  width: 23,
                  height: 23,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.add, size: 16, color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
    title: const Text(
      'Mon statut',
      style: TextStyle(fontWeight: FontWeight.w700),
    ),
    subtitle: Text(
      latest == null
          ? 'Touchez pour ajouter une actu'
          : 'Ma mise à jour · ${formatChatTime(latest!.createdAt)}',
      style: const TextStyle(color: AppColors.secondaryText),
    ),
    onTap: onTap,
  );
}

class _StatusHeading extends StatelessWidget {
  const _StatusHeading(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 23, bottom: 8),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
        color: AppColors.secondaryText,
      ),
    ),
  );
}

class _StatusContactTile extends StatelessWidget {
  const _StatusContactTile({
    required this.user,
    required this.status,
    required this.viewed,
    required this.fallbackName,
    required this.onTap,
  });
  final AppUser? user;
  final StatusModel status;
  final bool viewed;
  final String fallbackName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = user?.name ?? fallbackName;
    final preview = status.isImage
        ? 'Photo · ${formatChatTime(status.createdAt)}'
        : '${status.text ?? 'Statut'} · ${formatChatTime(status.createdAt)}';
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 2),
      leading: AppAvatar(
        name: name,
        photoUrl: user?.photoUrl,
        size: 50,
        ringColor: viewed ? AppColors.border : AppColors.primary,
        ringWidth: 2.3,
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        preview,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: AppColors.secondaryText),
      ),
      onTap: onTap,
    );
  }
}
