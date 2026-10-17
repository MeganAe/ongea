import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/models/app_user.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/ongea_skeleton.dart';
import '../data/chat_repository.dart';

class NewChatPage extends ConsumerStatefulWidget {
  const NewChatPage({super.key});

  @override
  ConsumerState<NewChatPage> createState() => _NewChatPageState();
}

class _NewChatPageState extends ConsumerState<NewChatPage> {
  final _searchController = TextEditingController();
  bool _opening = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openChat(AppUser contact, String currentUid) async {
    if (_opening || ref.read(demoModeProvider)) return;
    setState(() => _opening = true);
    try {
      final chatId = await ChatRepository().createOrGetDirectChat(
        currentUid,
        contact.id,
      );
      if (mounted) context.go('/chat/$chatId');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d’ouvrir la discussion. Réessayez.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final demo = ref.watch(demoModeProvider);
    final usersAsync = ref.watch(usersProvider);
    final current = ref.watch(currentUserProvider);
    final currentUid = current?.uid ?? DemoData.meId;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Nouvelle discussion'),
      ),
      body:
          demo
              ? const EmptyState(
                icon: Icons.chat_bubble_outline,
                title: 'Mode démo',
                message:
                    'La création de nouvelles discussions nécessite Firebase. Les discussions d’exemple restent consultables depuis l’accueil.',
              )
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'Rechercher un nom',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  ),
                  Expanded(
                    child: usersAsync.when(
                      loading: () => OngeaListSkeleton(itemCount: 6),
                      error:
                          (error, stack) => const EmptyState(
                            icon: Icons.people_outline,
                            title: 'Utilisateurs indisponibles',
                            message:
                                'Impossible de charger vos contacts pour le moment.',
                          ),
                      data: (users) {
                        final query =
                            _searchController.text.trim().toLowerCase();
                        final filtered =
                            users.where((user) {
                              if (user.id == currentUid) return false;
                              if (query.isEmpty) return true;
                              return user.name.toLowerCase().contains(query) ||
                                  user.email.toLowerCase().contains(query);
                            }).toList();
                        if (filtered.isEmpty) {
                          return EmptyState(
                            icon: Icons.person_search_outlined,
                            title:
                                query.isEmpty
                                    ? 'Aucun contact pour le moment'
                                    : 'Aucun résultat',
                            message:
                                query.isEmpty
                                    ? 'Les personnes inscrites sur Ongea apparaîtront ici.'
                                    : 'Essayez une autre recherche.',
                          );
                        }
                        return ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder:
                              (_, __) => const Divider(height: 1, indent: 82),
                          itemBuilder: (context, index) {
                            final contact = filtered[index];
                            return ListTile(
                              minVerticalPadding: 10,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 3,
                              ),
                              leading: AppAvatar(
                                name: contact.name,
                                photoUrl: contact.photoUrl,
                                size: 52,
                              ),
                              title: Text(
                                contact.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                contact.email.isEmpty
                                    ? 'Sur Ongea'
                                    : contact.email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing:
                                  _opening
                                      ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : Icon(
                                        Icons.chat_bubble_outline,
                                        color: context.ongea.primary,
                                      ),
                              onTap: () => _openChat(contact, currentUid),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
    );
  }
}
