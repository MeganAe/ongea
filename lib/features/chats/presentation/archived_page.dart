import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/models/app_user.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/ongea_skeleton.dart';
import '../data/chat_repository.dart';

class ArchivedPage extends ConsumerWidget {
  const ArchivedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsAsync = ref.watch(chatListProvider);
    final users = {
      for (final user
          in ref.watch(usersProvider).asData?.value ?? const <AppUser>[])
        user.id: user,
    };
    final userId = ref.watch(currentUserProvider)?.uid ?? DemoData.meId;
    final demo = ref.watch(demoModeProvider);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text(
          'Discussions archivées',
          style: TextStyle(fontSize: 21),
        ),
      ),
      body: chatsAsync.when(
        loading: () => OngeaListSkeleton(itemCount: 5),
        error:
            (error, stack) => const EmptyState(
              icon: Icons.archive_outlined,
              title: 'Impossible de charger',
              message: 'Réessayez lorsque votre connexion sera rétablie.',
            ),
        data: (allChats) {
          final chats =
              allChats.where((chat) => chat.isArchivedFor(userId)).toList();
          if (chats.isEmpty) {
            return EmptyState(
              icon: Icons.archive_outlined,
              title:
                  demo
                      ? 'Aucune archive de démonstration'
                      : 'Aucune discussion archivée',
              message:
                  demo
                      ? 'Les exemples du mode démo sont en lecture seule.'
                      : 'Les discussions que vous archivez apparaîtront ici.',
            );
          }
          return ListView.separated(
            itemCount: chats.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 84),
            itemBuilder: (context, index) {
              final chat = chats[index];
              final otherIds =
                  chat.participants.where((id) => id != userId).toList();
              final otherId = otherIds.isEmpty ? '' : otherIds.first;
              final contact = users[otherId];
              final name =
                  chat.isGroup ? 'Groupe Ongea' : (contact?.name ?? 'Contact');
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 5,
                ),
                leading: AppAvatar(name: name, photoUrl: contact?.photoUrl),
                title: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  chat.lastMessage.isEmpty ? 'Aucun message' : chat.lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      formatChatTime(chat.lastMessageAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: context.ongea.secondaryText,
                      ),
                    ),
                    if (!demo) ...[
                      const SizedBox(height: 4),
                      IconButton(
                        tooltip: 'Désarchiver',
                        visualDensity: VisualDensity.compact,
                        onPressed: () async {
                          try {
                            await ChatRepository().setPreference(
                              chat.id,
                              userId,
                              'archived',
                              false,
                            );
                          } catch (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Impossible de désarchiver cette discussion.',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                        icon: Icon(
                          Icons.unarchive_outlined,
                          size: 20,
                          color: context.ongea.primary,
                        ),
                      ),
                    ],
                  ],
                ),
                onTap: () => context.push('/chat/${chat.id}'),
              );
            },
          );
        },
      ),
    );
  }
}
