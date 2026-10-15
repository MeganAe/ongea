import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/status_model.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_avatar.dart';
import '../data/status_repository.dart';

class StatusViewerPage extends ConsumerStatefulWidget {
  const StatusViewerPage({super.key, required this.statusId});
  final String statusId;

  @override
  ConsumerState<StatusViewerPage> createState() => _StatusViewerPageState();
}

class _StatusViewerPageState extends ConsumerState<StatusViewerPage> {
  bool _viewRecorded = false;

  void _recordView(StatusModel status, String uid) {
    if (_viewRecorded || ref.read(demoModeProvider) || status.ownerId == uid)
      return;
    _viewRecorded = true;
    StatusRepository().markViewed(status.id, uid).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final statusesAsync = ref.watch(statusListProvider);
    final users = {
      for (final user in ref.watch(usersProvider).asData?.value ?? const [])
        user.id: user,
    };
    final uid = ref.watch(currentUserProvider)?.uid ?? DemoData.meId;
    return Scaffold(
      backgroundColor: const Color(0xFF101414),
      body: statusesAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (error, stack) => _error(context),
        data: (statuses) {
          StatusModel? status;
          for (final item in statuses) {
            if (item.id == widget.statusId) {
              status = item;
              break;
            }
          }
          if (status == null) return _error(context);
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _recordView(status!, uid),
          );
          final owner = users[status.ownerId];
          return Stack(
            fit: StackFit.expand,
            children: [
              if (status.isImage)
                Image.network(
                  status.imageUrl!,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white,
                      size: 54,
                    ),
                  ),
                )
              else
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0F766E), Color(0xFF174A45)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Text(
                    status.text ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 27,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ),
              SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 8, 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                minHeight: 3,
                                value: 1,
                                backgroundColor: Colors.white38,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          AppAvatar(
                            name: owner?.name ?? 'Contact',
                            photoUrl: owner?.photoUrl,
                            size: 35,
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            flex: 5,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  owner?.name ?? 'Contact Ongea',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  formatChatTime(status.createdAt),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => context.pop(),
                            tooltip: 'Fermer',
                            icon: const Icon(Icons.close, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (status.isImage && (status.text?.isNotEmpty ?? false))
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        color: Colors.black45,
                        child: Text(
                          status.text!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _error(BuildContext context) => SafeArea(
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.hourglass_disabled_outlined,
            color: Colors.white70,
            size: 48,
          ),
          const SizedBox(height: 16),
          const Text(
            'Ce statut n’est plus disponible.',
            style: TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Retour'),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
          ),
        ],
      ),
    ),
  );
}
