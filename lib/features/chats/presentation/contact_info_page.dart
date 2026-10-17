import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/models/app_user.dart';
import '../../../core/models/chat_model.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/ongea_skeleton.dart';
import '../data/chat_repository.dart';

class ContactInfoPage extends ConsumerStatefulWidget {
  const ContactInfoPage({super.key, required this.userId, this.chatId});

  final String userId;
  final String? chatId;

  @override
  ConsumerState<ContactInfoPage> createState() => _ContactInfoPageState();
}

class _ContactInfoPageState extends ConsumerState<ContactInfoPage> {
  void _toast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _setMuted(bool value) async {
    final chatId = widget.chatId;
    final uid = ref.read(currentUserProvider)?.uid;
    if (chatId == null || uid == null || ref.read(demoModeProvider)) return;
    try {
      await ChatRepository().setPreference(chatId, uid, 'muted', value);
    } catch (_) {
      _toast('Impossible d’enregistrer la sourdine. Réessayez.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(contactProvider(widget.userId));
    final chatId = widget.chatId;
    final chat =
        chatId == null ? null : ref.watch(chatProvider(chatId)).asData?.value;
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
        loading: () => const OngeaProfileSkeleton(),
        error:
            (error, stack) => const EmptyState(
              icon: Icons.person_off_outlined,
              title: 'Contact indisponible',
              message: 'Impossible de charger les informations de ce contact.',
            ),
        data:
            (contact) =>
                contact == null
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
    final muted = chat?.isMutedFor(currentUid) ?? false;
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
          style: TextStyle(color: context.ongea.secondaryText),
        ),
        if (demo) ...[
          const SizedBox(height: 8),
          Text(
            'Mode démo · profil d’exemple',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.ongea.secondaryText, fontSize: 12),
          ),
        ],
        if (!demo && chatId != null) ...[
          const SizedBox(height: 24),
          const _SectionHeading('Discussion'),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            secondary: Icon(
              Icons.notifications_off_outlined,
              color: context.ongea.secondaryText,
            ),
            title: const Text('Sourdine'),
            value: muted,
            activeTrackColor: context.ongea.primary,
            onChanged: _setMuted,
          ),
        ],
        const SizedBox(height: 18),
        const _SectionHeading('Sécurité'),
        _InfoTile(
          icon: Icons.verified_user_outlined,
          title: 'Sécurité des échanges',
          subtitle:
              demo
                  ? 'Profil d’exemple; aucun échange réseau.'
                  : 'Connexion protégée par TLS. Le chiffrement de bout en bout n’est pas activé.',
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
      style: TextStyle(
        color: context.ongea.primary,
        fontWeight: FontWeight.w700,
        fontSize: 14,
      ),
    ),
  );
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.icon, required this.title, this.subtitle});

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    minLeadingWidth: 34,
    leading: Icon(icon, color: context.ongea.secondaryText),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
    subtitle: subtitle == null ? null : Text(subtitle!),
  );
}
