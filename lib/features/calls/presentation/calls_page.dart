import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/call_record.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_avatar.dart';

class CallsPage extends ConsumerWidget {
  const CallsPage({super.key});

  void _showCallNotice(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Les appels audio et vidéo ne sont pas encore connectés dans cette version.',
        ),
      ),
    );
  }

  Future<void> _createLink(BuildContext context) async {
    final code = const Uuid().v4().split('-').first;
    final link = 'https://ongea.app/appel/$code';
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.link, color: AppColors.primary, size: 32),
        title: const Text('Lien d’appel créé'),
        content: SelectableText(link, textAlign: TextAlign.center),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          FilledButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: link));
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Lien copié. Les appels ne sont pas encore actifs.',
                    ),
                  ),
                );
              }
            },
            icon: const Icon(Icons.copy_outlined),
            label: const Text('Copier'),
          ),
        ],
      ),
    );
  }

  void _newCall(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Démarrer un appel',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'L’interface des appels est prête. La voix et la vidéo ne sont pas encore intégrées.',
                style: TextStyle(color: AppColors.secondaryText),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _showCallNotice(context);
                      },
                      icon: const Icon(Icons.call_outlined),
                      label: const Text('Appel audio'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _showCallNotice(context);
                      },
                      icon: const Icon(Icons.videocam_outlined),
                      label: const Text('Appel vidéo'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calls = ref.watch(callLogProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appels'),
        actions: [
          IconButton(
            tooltip: 'Créer un lien d’appel',
            onPressed: () => _createLink(context),
            icon: const Icon(Icons.link),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          Card(
            color: AppColors.softSurface,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: ListTile(
              minVerticalPadding: 12,
              leading: Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  color: AppColors.activeChip,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add_link, color: AppColors.primary),
              ),
              title: const Text(
                'Créer un lien d’appel',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text('Partagez un lien pour démarrer un appel'),
              trailing: const Icon(
                Icons.chevron_right,
                color: AppColors.primary,
              ),
              onTap: () => _createLink(context),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 26, 4, 10),
            child: Text(
              'Récents',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
          if (calls.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 42),
              child: Column(
                children: [
                  Icon(
                    Icons.call_outlined,
                    size: 42,
                    color: AppColors.secondaryText,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Aucun appel récent',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Vos appels apparaîtront ici.',
                    style: TextStyle(color: AppColors.secondaryText),
                  ),
                ],
              ),
            )
          else
            ...calls.map(
              (call) =>
                  _CallTile(call: call, onCall: () => _showCallNotice(context)),
            ),
          const SizedBox(height: 10),
          const Text(
            'Appels audio et vidéo : interface de démonstration uniquement.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Nouvel appel',
        onPressed: () => _newCall(context),
        child: const Icon(Icons.add_call),
      ),
    );
  }
}

class _CallTile extends StatelessWidget {
  const _CallTile({required this.call, required this.onCall});
  final CallRecord call;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    final missed = call.missed;
    final directionIcon = missed
        ? Icons.call_missed_outgoing
        : call.direction == 'incoming'
        ? Icons.call_received
        : Icons.call_made;
    final time = formatChatTime(call.createdAt);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      leading: AppAvatar(name: call.contactName, size: 50),
      title: Text(
        call.contactName,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: missed ? AppColors.danger : AppColors.text,
        ),
      ),
      subtitle: Row(
        children: [
          Icon(
            directionIcon,
            size: 16,
            color: missed ? AppColors.danger : AppColors.primary,
          ),
          const SizedBox(width: 5),
          Text('${call.video ? 'Vidéo' : 'Audio'} · $time'),
        ],
      ),
      trailing: IconButton(
        tooltip: call.video ? 'Rappeler en vidéo' : 'Rappeler',
        onPressed: onCall,
        icon: Icon(
          call.video ? Icons.videocam_outlined : Icons.call_outlined,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
