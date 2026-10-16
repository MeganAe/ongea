import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/app_user.dart';
import '../../../core/models/chat_model.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/empty_state.dart';
import '../data/chat_repository.dart';

class ContactInfoPage extends ConsumerStatefulWidget {
  const ContactInfoPage({super.key, required this.userId, this.chatId});

  final String userId;
  final String? chatId;

  @override
  ConsumerState<ContactInfoPage> createState() => _ContactInfoPageState();
}

class _ContactInfoPageState extends ConsumerState<ContactInfoPage> {
  bool? _demoMuted;
  bool? _demoLocked;

  void _toast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _setPreference(String key, bool value) async {
    final chatId = widget.chatId;
    final uid = ref.read(currentUserProvider)?.uid ?? DemoData.meId;
    if (chatId == null) return;
    if (ref.read(demoModeProvider)) {
      setState(() {
        if (key == 'muted') _demoMuted = value;
        if (key == 'locked') _demoLocked = value;
      });
      return;
    }
    try {
      await ChatRepository().setPreference(chatId, uid, key, value);
    } catch (_) {
      _toast('Impossible d’enregistrer ce réglage. Réessayez.');
    }
  }

  Future<void> _block(String otherId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bloquer ce contact ?'),
        content: const Text(
          'Ce contact sera ajouté à votre liste de blocage. La gestion complète de cette liste sera ajoutée dans une prochaine version.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Bloquer'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    if (ref.read(demoModeProvider)) {
      _toast('Le blocage est disponible après configuration Firebase.');
      return;
    }
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) return;
    try {
      await ChatRepository().blockUser(uid, otherId);
      if (mounted) {
        _toast('Contact bloqué.');
        context.pop();
      }
    } catch (_) {
      _toast('Le contact n’a pas pu être bloqué.');
    }
  }

  Future<void> _report(String otherId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Signaler ce contact ?'),
        content: const Text(
          'Un signalement sera envoyé à l’équipe Ongea pour examen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Signaler'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    if (ref.read(demoModeProvider)) {
      _toast('Le signalement est disponible après configuration Firebase.');
      return;
    }
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) return;
    try {
      await ChatRepository().reportUser(reporterId: uid, reportedId: otherId);
      _toast('Merci. Votre signalement a été transmis.');
    } catch (_) {
      _toast('Le signalement n’a pas pu être transmis.');
    }
  }

  void _showInfo(String title, String body) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(contactProvider(widget.userId));
    final chatId = widget.chatId;
    final chat = chatId == null
        ? null
        : ref.watch(chatProvider(chatId)).asData?.value;
    final currentUid = ref.watch(currentUserProvider)?.uid ?? DemoData.meId;
    final demo = ref.watch(demoModeProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Infos du contact', style: TextStyle(fontSize: 21)),
      ),
      body: userAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, stack) => const EmptyState(
          icon: Icons.person_off_outlined,
          title: 'Contact indisponible',
          message: 'Impossible de charger les informations de ce contact.',
        ),
        data: (contact) => contact == null
            ? const EmptyState(
                icon: Icons.person_off_outlined,
                title: 'Contact introuvable',
                message: 'Ce compte n’est plus accessible.',
              )
            : _buildInfo(contact, chat, currentUid, demo),
      ),
    );
  }

  Widget _buildInfo(
    AppUser contact,
    ChatModel? chat,
    String currentUid,
    bool demo,
  ) {
    final chatId = widget.chatId;
    final muted = demo
        ? (_demoMuted ?? chat?.isMutedFor(currentUid) ?? false)
        : (chat?.isMutedFor(currentUid) ?? false);
    final locked = demo
        ? (_demoLocked ?? chat?.isLockedFor(currentUid) ?? false)
        : (chat?.isLockedFor(currentUid) ?? false);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
      children: [
        Center(
          child: AppAvatar(
            name: contact.name,
            photoUrl: contact.photoUrl,
            size: 112,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          contact.name,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          contact.email.isEmpty
              ? formatLastSeen(contact.lastSeen)
              : contact.email,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.secondaryText),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: _ContactAction(
                icon: Icons.call_outlined,
                label: 'Appel',
                onTap: () =>
                    _toast('Les appels réels ne sont pas encore disponibles.'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ContactAction(
                icon: Icons.videocam_outlined,
                label: 'Vidéo',
                onTap: () =>
                    _toast('Les appels vidéo ne sont pas encore disponibles.'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ContactAction(
                icon: Icons.search,
                label: 'Recherche',
                onTap: () => _toast(
                  'La recherche dans la conversation sera bientôt disponible.',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const _SectionHeading('Discussion'),
        _InfoTile(
          icon: Icons.photo_library_outlined,
          title: 'Médias, liens et documents',
          trailing: const Icon(
            Icons.chevron_right,
            color: AppColors.secondaryText,
          ),
          onTap: () => _showInfo(
            'Médias, liens et documents',
            'Les photos partagées dans cette conversation apparaîtront ici.',
          ),
        ),
        _InfoTile(
          icon: Icons.star_border_rounded,
          title: 'Messages importants',
          trailing: const Icon(
            Icons.chevron_right,
            color: AppColors.secondaryText,
          ),
          onTap: () => _showInfo(
            'Messages importants',
            'Appuyez longuement sur un message pour le retrouver ici (fonctionnalité à venir).',
          ),
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(
            Icons.notifications_off_outlined,
            color: AppColors.secondaryText,
          ),
          title: const Text('Sourdine'),
          value: muted,
          activeTrackColor: AppColors.primary,
          onChanged: chatId == null
              ? null
              : (value) => _setPreference('muted', value),
        ),
        _InfoTile(
          icon: Icons.music_note_outlined,
          title: 'Sons et notifications',
          subtitle: 'Par défaut',
          onTap: () => _showInfo(
            'Sons et notifications',
            'Les alertes utilisent les réglages de notification de votre appareil.',
          ),
        ),
        _InfoTile(
          icon: Icons.timer_outlined,
          title: 'Messages éphémères',
          subtitle: 'Désactivés',
          onTap: () => _showInfo(
            'Messages éphémères',
            'La suppression automatique des messages sera ajoutée dans une prochaine version.',
          ),
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(
            Icons.lock_outline,
            color: AppColors.secondaryText,
          ),
          title: const Text('Verrouiller la discussion'),
          subtitle: const Text(
            'Le verrouillage local sera activé dans une prochaine version',
          ),
          value: locked,
          activeTrackColor: AppColors.primary,
          onChanged: chatId == null
              ? null
              : (value) => _setPreference('locked', value),
        ),
        _InfoTile(
          icon: Icons.verified_user_outlined,
          title: 'Chiffrement',
          subtitle: 'Connexion sécurisée par Firebase',
          onTap: () => _showInfo(
            'Chiffrement',
            'Les échanges avec les services Ongea sont protégés par TLS. Le chiffrement de bout en bout n’est pas encore implémenté.',
          ),
        ),
        const SizedBox(height: 18),
        _InfoTile(
          icon: Icons.block_outlined,
          title: 'Bloquer ${contact.name}',
          color: AppColors.danger,
          onTap: () => _block(contact.id),
        ),
        _InfoTile(
          icon: Icons.flag_outlined,
          title: 'Signaler ${contact.name}',
          color: AppColors.danger,
          onTap: () => _report(contact.id),
        ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        color: AppColors.primary,
        fontWeight: FontWeight.w700,
        fontSize: 14,
      ),
    ),
  );
}

class _ContactAction extends StatelessWidget {
  const _ContactAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(64, 68),
      foregroundColor: AppColors.primary,
      side: const BorderSide(color: AppColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    ),
  );
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.color,
    this.onTap,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Color? color;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    minLeadingWidth: 34,
    leading: Icon(icon, color: color ?? AppColors.secondaryText),
    title: Text(
      title,
      style: TextStyle(
        color: color ?? AppColors.text,
        fontWeight: FontWeight.w500,
      ),
    ),
    subtitle: subtitle == null ? null : Text(subtitle!),
    trailing:
        trailing ??
        (onTap == null
            ? null
            : const Icon(Icons.chevron_right, color: AppColors.secondaryText)),
    onTap: onTap,
  );
}
