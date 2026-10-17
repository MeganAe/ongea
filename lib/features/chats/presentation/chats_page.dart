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

enum _ChatAction { pin, favorite, mute, archive }

class ChatsPage extends ConsumerStatefulWidget {
  const ChatsPage({super.key});

  @override
  ConsumerState<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends ConsumerState<ChatsPage> {
  final _searchController = TextEditingController();
  bool _searching = false;
  String _filter = 'Toutes';
  static const _filters = ['Toutes', 'Non lues', 'Favoris', 'Groupes'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _displayName(
    ChatModel chat,
    String userId,
    Map<String, AppUser> users,
  ) {
    final others =
        chat.participants
            .where((id) => id != userId)
            .map((id) => users[id]?.name)
            .whereType<String>()
            .toList();
    if (chat.isGroup)
      return chat.id == 'demo-chat-groupe'
          ? 'Les amis du quartier'
          : (others.isEmpty ? 'Groupe Ongea' : others.take(2).join(', '));
    if (others.isNotEmpty) return others.first;
    return chat.participants.firstWhere(
      (id) => id != userId,
      orElse: () => 'Contact',
    );
  }

  String? _photoUrl(ChatModel chat, String userId, Map<String, AppUser> users) {
    if (chat.isGroup) return null;
    final otherId = chat.participants.firstWhere(
      (id) => id != userId,
      orElse: () => '',
    );
    return users[otherId]?.photoUrl;
  }

  Future<void> _applyAction(
    ChatModel chat,
    String userId,
    _ChatAction action,
  ) async {
    final preferences = switch (action) {
      _ChatAction.pin => ('pinned', !chat.isPinnedFor(userId)),
      _ChatAction.favorite => ('favorite', !chat.isFavoriteFor(userId)),
      _ChatAction.mute => ('muted', !chat.isMutedFor(userId)),
      _ChatAction.archive => ('archived', true),
    };
    if (ref.read(demoModeProvider)) {
      _showMessage(
        'Les préférences seront enregistrées après la configuration Firebase.',
      );
      return;
    }
    try {
      await ChatRepository().setPreference(
        chat.id,
        userId,
        preferences.$1,
        preferences.$2,
      );
      if (mounted && action == _ChatAction.archive)
        _showMessage('Discussion archivée.');
    } catch (_) {
      if (mounted)
        _showMessage('Impossible de modifier cette discussion. Réessayez.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatsAsync = ref.watch(chatListProvider);
    final usersAsync = ref.watch(usersProvider);
    final user = ref.watch(currentUserProvider);
    final demo = ref.watch(demoModeProvider);
    final userId = user?.uid ?? DemoData.meId;
    final users = {
      for (final item in usersAsync.asData?.value ?? const <AppUser>[])
        item.id: item,
    };

    return Scaffold(
      appBar: AppBar(
        title:
            _searching
                ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Rechercher une discussion',
                    border: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (_) => setState(() {}),
                )
                : const Text('Ongea'),
        actions: [
          IconButton(
            tooltip: 'Actus et appareil photo',
            onPressed: () => context.go('/status'),
            icon: const Icon(Icons.camera_alt_outlined),
          ),
          IconButton(
            tooltip: _searching ? 'Fermer la recherche' : 'Rechercher',
            onPressed: () {
              setState(() {
                _searching = !_searching;
                if (!_searching) _searchController.clear();
              });
            },
            icon: Icon(_searching ? Icons.close : Icons.search),
          ),
          PopupMenuButton<String>(
            tooltip: 'Plus d’options',
            onSelected: (value) {
              if (value == 'new' && !demo) context.push('/new-chat');
              if (value == 'archive') context.push('/archived');
              if (value == 'settings') context.go('/settings');
            },
            itemBuilder:
                (context) => [
                  if (!demo)
                    const PopupMenuItem(
                      value: 'new',
                      child: Text('Nouvelle discussion'),
                    ),
                  const PopupMenuItem(
                    value: 'archive',
                    child: Text('Discussions archivées'),
                  ),
                  const PopupMenuItem(
                    value: 'settings',
                    child: Text('Paramètres'),
                  ),
                ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        top: false,
        child: chatsAsync.when(
          loading: () => OngeaListSkeleton(itemCount: 6),
          error:
              (error, stack) => const EmptyState(
                icon: Icons.cloud_off_outlined,
                title: 'Connexion indisponible',
                message:
                    'Impossible de charger les discussions. Vérifiez votre connexion et les règles Firebase.',
              ),
          data: (allChats) {
            final archivedCount =
                allChats.where((chat) => chat.isArchivedFor(userId)).length;
            var chats =
                allChats.where((chat) => !chat.isArchivedFor(userId)).toList();
            switch (_filter) {
              case 'Non lues':
                chats =
                    chats.where((chat) => chat.unreadFor(userId) > 0).toList();
                break;
              case 'Favoris':
                chats =
                    chats.where((chat) => chat.isFavoriteFor(userId)).toList();
                break;
              case 'Groupes':
                chats = chats.where((chat) => chat.isGroup).toList();
                break;
            }
            final query = _searchController.text.trim().toLowerCase();
            if (query.isNotEmpty) {
              chats =
                  chats.where((chat) {
                    final name =
                        _displayName(chat, userId, users).toLowerCase();
                    return name.contains(query) ||
                        chat.lastMessage.toLowerCase().contains(query);
                  }).toList();
            }
            chats.sort((a, b) {
              final pinOrder = (b.isPinnedFor(userId) ? 1 : 0).compareTo(
                a.isPinnedFor(userId) ? 1 : 0,
              );
              if (pinOrder != 0) return pinOrder;
              return (b.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0))
                  .compareTo(
                    a.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0),
                  );
            });

            return Column(
              children: [
                if (demo)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: context.ongea.softSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.ongea.border),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: context.ongea.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Mode démo · exemples locaux en lecture seule.',
                              style: TextStyle(
                                color: context.ongea.secondaryText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                SizedBox(
                  height: 54,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 7,
                    ),
                    scrollDirection: Axis.horizontal,
                    itemCount: _filters.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final label = _filters[index];
                      final selected = label == _filter;
                      return ChoiceChip(
                        label: Text(label),
                        selected: selected,
                        showCheckmark: false,
                        onSelected: (_) => setState(() => _filter = label),
                        selectedColor: context.ongea.activeChip,
                        backgroundColor: context.ongea.surface,
                        side: BorderSide(
                          color:
                              selected
                                  ? context.ongea.activeChip
                                  : context.ongea.border,
                        ),
                        labelStyle: TextStyle(
                          color:
                              selected
                                  ? context.ongea.primary
                                  : context.ongea.secondaryText,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                        ),
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(horizontal: 7),
                      );
                    },
                  ),
                ),
                if (archivedCount > 0)
                  ListTile(
                    minLeadingWidth: 32,
                    leading: Icon(
                      Icons.archive_outlined,
                      color: context.ongea.secondaryText,
                    ),
                    title: const Text(
                      'Archivées',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '$archivedCount discussion${archivedCount > 1 ? 's' : ''}',
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: context.ongea.secondaryText,
                    ),
                    onTap: () => context.push('/archived'),
                  ),
                Expanded(
                  child:
                      chats.isEmpty
                          ? EmptyState(
                            icon:
                                _filter == 'Non lues'
                                    ? Icons.done_all
                                    : Icons.chat_bubble_outline,
                            title:
                                _searchController.text.isNotEmpty
                                    ? 'Aucun résultat'
                                    : 'Aucune discussion ici',
                            message:
                                _searchController.text.isNotEmpty
                                    ? 'Essayez un autre nom ou mot-clé.'
                                    : demo
                                    ? 'Aucune discussion de démonstration ne correspond à ce filtre.'
                                    : _filter == 'Groupes'
                                    ? 'Les discussions de groupe apparaîtront ici.'
                                    : _filter == 'Favoris'
                                    ? 'Ajoutez une discussion à vos favoris depuis son menu.'
                                    : 'Lancez une nouvelle discussion pour commencer à échanger.',
                            action:
                                demo
                                    ? null
                                    : TextButton.icon(
                                      onPressed:
                                          () => context.push('/new-chat'),
                                      icon: const Icon(Icons.edit_outlined),
                                      label: const Text('Nouvelle discussion'),
                                    ),
                          )
                          : ListView.separated(
                            padding: const EdgeInsets.only(bottom: 96, top: 2),
                            itemCount: chats.length,
                            separatorBuilder:
                                (_, __) => const Divider(height: 1, indent: 84),
                            itemBuilder: (context, index) {
                              final chat = chats[index];
                              final name = _displayName(chat, userId, users);
                              final unread = chat.unreadFor(userId);
                              return ListTile(
                                minVerticalPadding: 10,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 2,
                                ),
                                leading: AppAvatar(
                                  name: chat.isGroup ? 'Groupe' : name,
                                  photoUrl: _photoUrl(chat, userId, users),
                                  size: 54,
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight:
                                              unread > 0
                                                  ? FontWeight.w700
                                                  : FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      formatChatTime(chat.lastMessageAt),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color:
                                            unread > 0
                                                ? context.ongea.primary
                                                : context.ongea.secondaryText,
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 5),
                                  child: Row(
                                    children: [
                                      if (chat.lastMessageSenderId ==
                                          userId) ...[
                                        _MessageTicks(
                                          status:
                                              chat.lastMessageStatus ?? 'sent',
                                        ),
                                        const SizedBox(width: 4),
                                      ],
                                      Expanded(
                                        child: Text(
                                          chat.lastMessage.isEmpty
                                              ? 'Commencez la conversation'
                                              : chat.lastMessage,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color:
                                                unread > 0
                                                    ? context.ongea.text
                                                    : context
                                                        .ongea
                                                        .secondaryText,
                                            fontWeight:
                                                unread > 0
                                                    ? FontWeight.w600
                                                    : FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                      if (unread > 0)
                                        Container(
                                          constraints: const BoxConstraints(
                                            minWidth: 21,
                                            minHeight: 21,
                                          ),
                                          alignment: Alignment.center,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: context.ongea.primary,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            unread > 99 ? '99+' : '$unread',
                                            style: TextStyle(
                                              color: context.ongea.onPrimary,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        )
                                      else if (chat.isPinnedFor(userId))
                                        Padding(
                                          padding: EdgeInsets.only(left: 4),
                                          child: Icon(
                                            Icons.push_pin_outlined,
                                            size: 17,
                                            color: context.ongea.secondaryText,
                                          ),
                                        )
                                      else if (chat.isMutedFor(userId))
                                        Padding(
                                          padding: EdgeInsets.only(left: 4),
                                          child: Icon(
                                            Icons.notifications_off_outlined,
                                            size: 17,
                                            color: context.ongea.secondaryText,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                trailing:
                                    demo
                                        ? null
                                        : PopupMenuButton<_ChatAction>(
                                          tooltip: 'Options de la discussion',
                                          icon: Icon(
                                            Icons.more_vert,
                                            color: context.ongea.secondaryText,
                                          ),
                                          onSelected:
                                              (action) => _applyAction(
                                                chat,
                                                userId,
                                                action,
                                              ),
                                          itemBuilder:
                                              (context) => [
                                                PopupMenuItem(
                                                  value: _ChatAction.pin,
                                                  child: Text(
                                                    chat.isPinnedFor(userId)
                                                        ? 'Désépingler'
                                                        : 'Épingler',
                                                  ),
                                                ),
                                                PopupMenuItem(
                                                  value: _ChatAction.favorite,
                                                  child: Text(
                                                    chat.isFavoriteFor(userId)
                                                        ? 'Retirer des favoris'
                                                        : 'Ajouter aux favoris',
                                                  ),
                                                ),
                                                PopupMenuItem(
                                                  value: _ChatAction.mute,
                                                  child: Text(
                                                    chat.isMutedFor(userId)
                                                        ? 'Réactiver les notifications'
                                                        : 'Mettre en sourdine',
                                                  ),
                                                ),
                                                const PopupMenuItem(
                                                  value: _ChatAction.archive,
                                                  child: Text('Archiver'),
                                                ),
                                              ],
                                        ),
                                onTap: () => context.push('/chat/${chat.id}'),
                              );
                            },
                          ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton:
          demo
              ? null
              : FloatingActionButton.extended(
                onPressed: () => context.push('/new-chat'),
                icon: const Icon(Icons.edit_outlined),
                label: const Text(
                  'Nouvelle discussion',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
    );
  }
}

class _MessageTicks extends StatelessWidget {
  const _MessageTicks({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    if (status == 'read')
      return Icon(Icons.done_all, size: 17, color: context.ongea.readTick);
    if (status == 'delivered')
      return Icon(Icons.done_all, size: 17, color: context.ongea.receivedTick);
    return Icon(Icons.done, size: 17, color: context.ongea.receivedTick);
  }
}
