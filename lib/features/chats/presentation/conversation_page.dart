import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/app_user.dart';
import '../../../core/models/chat_model.dart';
import '../../../core/models/message_model.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/empty_state.dart';
import '../data/chat_repository.dart';

class ConversationPage extends ConsumerStatefulWidget {
  const ConversationPage({super.key, required this.chatId});

  final String chatId;

  @override
  ConsumerState<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends ConsumerState<ConversationPage> {
  final _textController = TextEditingController();
  final _picker = ImagePicker();
  bool _hasText = false;
  bool _markingRead = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      final hasText = _textController.text.trim().isNotEmpty;
      if (hasText != _hasText && mounted) setState(() => _hasText = hasText);
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _toast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _sendText(ChatModel? chat, String userId) async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    if (ref.read(demoModeProvider)) {
      _textController.clear();
      _toast(
        'Mode démo : connectez Firebase pour envoyer et synchroniser vos messages.',
      );
      return;
    }
    if (chat == null) return;
    try {
      final sendFuture = ChatRepository().sendText(
        chatId: widget.chatId,
        senderId: userId,
        text: text,
      );
      // Vider immédiatement le champ : l’écriture Firestore peut rester en attente hors ligne.
      _textController.clear();
      await sendFuture;
    } catch (_) {
      _toast(
        'Le message n’a pas pu être envoyé. Vérifiez votre connexion ou vos autorisations.',
      );
    }
  }

  Future<void> _pickImage(
    ImageSource source,
    ChatModel? chat,
    String userId,
  ) async {
    try {
      final image = await _picker.pickImage(
        source: source,
        imageQuality: 84,
        maxWidth: 1800,
      );
      if (image == null) return;
      if (ref.read(demoModeProvider)) {
        _toast('L’envoi d’images nécessite une configuration Firebase.');
        return;
      }
      if (chat == null) return;
      await ChatRepository().sendImage(
        chatId: widget.chatId,
        senderId: userId,
        image: image,
      );
    } catch (_) {
      _toast(
        'Impossible d’envoyer cette image. Vérifiez votre connexion et l’accès au stockage.',
      );
    }
  }

  void _showAttachmentOptions(ChatModel? chat, String userId) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 22),
          child: Row(
            children: [
              _AttachmentOption(
                icon: Icons.photo_library_outlined,
                label: 'Galerie',
                color: const Color(0xFF7C4DFF),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery, chat, userId);
                },
              ),
              const SizedBox(width: 24),
              _AttachmentOption(
                icon: Icons.camera_alt_outlined,
                label: 'Appareil photo',
                color: AppColors.primary,
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera, chat, userId);
                },
              ),
              const SizedBox(width: 24),
              _AttachmentOption(
                icon: Icons.insert_drive_file_outlined,
                label: 'Document',
                color: const Color(0xFF188038),
                onTap: () {
                  Navigator.pop(context);
                  _toast(
                    'L’envoi de documents sera ajouté dans une prochaine version.',
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEmojiPicker() {
    const emojis = [
      '😀',
      '😂',
      '🥰',
      '😊',
      '😍',
      '🙏',
      '👍',
      '❤️',
      '🎉',
      '🌍',
      '✨',
      '👋',
    ];
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: emojis
                .map(
                  (emoji) => InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      final value = _textController.value;
                      final selection = value.selection;
                      final start = selection.isValid
                          ? selection.start
                          : value.text.length;
                      final end = selection.isValid
                          ? selection.end
                          : value.text.length;
                      final text = value.text.replaceRange(start, end, emoji);
                      _textController.value = TextEditingValue(
                        text: text,
                        selection: TextSelection.collapsed(
                          offset: start + emoji.length,
                        ),
                      );
                      Navigator.pop(context);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(emoji, style: const TextStyle(fontSize: 28)),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  void _syncReadStatus(List<MessageModel> messages, String userId) {
    if (_markingRead || ref.read(demoModeProvider)) return;
    final hasUnreadIncoming = messages.any(
      (message) => message.senderId != userId && message.status != 'read',
    );
    if (!hasUnreadIncoming) return;
    _markingRead = true;
    unawaited(
      ChatRepository()
          .markRead(widget.chatId, userId)
          .catchError((_) {})
          .whenComplete(() => _markingRead = false),
    );
  }

  String _title(ChatModel chat, String userId, Map<String, AppUser> users) {
    if (chat.isGroup)
      return chat.id == 'demo-chat-groupe'
          ? 'Les amis du quartier'
          : 'Groupe Ongea';
    final otherId = chat.participants.firstWhere(
      (id) => id != userId,
      orElse: () => '',
    );
    return users[otherId]?.name ?? 'Discussion';
  }

  String _peerId(ChatModel chat, String userId) =>
      chat.participants.firstWhere((id) => id != userId, orElse: () => '');

  @override
  Widget build(BuildContext context) {
    final chatAsync = ref.watch(chatProvider(widget.chatId));
    final messagesAsync = ref.watch(messagesProvider(widget.chatId));
    final user = ref.watch(currentUserProvider);
    final demo = ref.watch(demoModeProvider);
    final userId = user?.uid ?? DemoData.meId;
    final users = {
      for (final item
          in ref.watch(usersProvider).asData?.value ?? const <AppUser>[])
        item.id: item,
    };

    ref.listen<AsyncValue<List<MessageModel>>>(
      messagesProvider(widget.chatId),
      (previous, next) {
        final messages = next.asData?.value;
        if (messages != null) _syncReadStatus(messages, userId);
      },
    );

    final chat = chatAsync.asData?.value;
    final peerId = chat == null ? '' : _peerId(chat, userId);
    final contact = peerId.isEmpty ? null : users[peerId];
    final title = chat == null ? 'Discussion' : _title(chat, userId, users);
    final onlineLabel = demo ? 'en ligne' : formatLastSeen(contact?.lastSeen);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 68,
        leading: IconButton(
          tooltip: 'Retour',
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        titleSpacing: 0,
        title: chat == null
            ? const Text(
                'Discussion',
                style: TextStyle(fontSize: 19, color: AppColors.text),
              )
            : InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: peerId.isEmpty
                    ? null
                    : () => context.push(
                        '/contact/$peerId?chatId=${widget.chatId}',
                      ),
                child: Row(
                  children: [
                    AppAvatar(
                      name: title,
                      photoUrl: contact?.photoUrl,
                      size: 40,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            onlineLabel,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
        actions: [
          IconButton(
            tooltip: 'Appel vidéo',
            onPressed: () =>
                _toast('Les appels vidéo ne sont pas encore disponibles.'),
            icon: const Icon(Icons.videocam_outlined),
          ),
          IconButton(
            tooltip: 'Appel audio',
            onPressed: () =>
                _toast('Les appels audio ne sont pas encore disponibles.'),
            icon: const Icon(Icons.call_outlined),
          ),
          PopupMenuButton<String>(
            tooltip: 'Options',
            onSelected: (value) {
              if (value == 'info' && peerId.isNotEmpty)
                context.push('/contact/$peerId?chatId=${widget.chatId}');
              if (value == 'search')
                _toast(
                  'La recherche dans cette conversation sera bientôt disponible.',
                );
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'info', child: Text('Infos du contact')),
              PopupMenuItem(value: 'search', child: Text('Rechercher')),
            ],
          ),
          const SizedBox(width: 2),
        ],
      ),
      body: ColoredBox(
        color: AppColors.chatBackground,
        child: Column(
          children: [
            Expanded(
              child: messagesAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (error, stack) => const EmptyState(
                  icon: Icons.cloud_off_outlined,
                  title: 'Messages indisponibles',
                  message: 'Vérifiez votre connexion et les règles de sécurité Firebase.',
                ),
                data: (messages) => messages.isEmpty
                    ? const EmptyState(
                        icon: Icons.waving_hand_outlined,
                        title: 'Dites bonjour',
                        message: 'Vos messages sont chiffrés en transit et synchronisés en temps réel.',
                      )
                    : _MessagesList(messages: messages, currentUserId: userId),
              ),
            ),
            _Composer(
              controller: _textController,
              hasText: _hasText,
              onEmoji: _showEmojiPicker,
              onAttachment: () => _showAttachmentOptions(chat, userId),
              onCamera: () => _pickImage(ImageSource.camera, chat, userId),
              onMic: () =>
                  _toast('L’enregistrement vocal n’est pas encore disponible.'),
              onSend: () => _sendText(chat, userId),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessagesList extends StatelessWidget {
  const _MessagesList({required this.messages, required this.currentUserId});

  final List<MessageModel> messages;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    final chronological = <Widget>[];
    DateTime? previousDate;
    for (final message in messages) {
      final date = message.createdAt;
      final isNewDay =
          previousDate == null ||
          date == null ||
          previousDate.year != date.year ||
          previousDate.month != date.month ||
          previousDate.day != date.day;
      if (isNewDay)
        chronological.add(_DateSeparator(label: formatDateLabel(date)));
      chronological.add(
        _MessageBubble(
          message: message,
          isMine: message.senderId == currentUserId,
        ),
      );
      previousDate = date;
    }
    final reversed = chronological.reversed.toList(growable: false);
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      itemCount: reversed.length,
      itemBuilder: (context, index) => reversed[index],
    );
  }
}

class _DateSeparator extends StatelessWidget {
  const _DateSeparator({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.secondaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ),
  );
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMine});
  final MessageModel message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: Radius.circular(isMine ? 16 : 4),
      bottomRight: Radius.circular(isMine ? 4 : 16),
    );
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.80,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.fromLTRB(11, 8, 10, 6),
          decoration: BoxDecoration(
            color: isMine ? AppColors.bubbleOutgoing : AppColors.bubbleIncoming,
            borderRadius: radius,
            boxShadow: const [
              BoxShadow(
                color: Color(0x0C000000),
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (message.isImage)
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      message.imageUrl!,
                      width: 236,
                      height: 210,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) =>
                          progress == null
                          ? child
                          : const SizedBox(
                              width: 236,
                              height: 160,
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                      errorBuilder: (context, error, stack) => const SizedBox(
                        width: 236,
                        height: 120,
                        child: Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: AppColors.secondaryText,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (message.text.isNotEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    message.text,
                    style: const TextStyle(fontSize: 15, height: 1.32),
                  ),
                ),
              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formatMessageTime(message.createdAt),
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.secondaryText,
                    ),
                  ),
                  if (isMine) ...[
                    const SizedBox(width: 4),
                    Icon(
                      message.status == 'read'
                          ? Icons.done_all
                          : message.status == 'delivered'
                          ? Icons.done_all
                          : Icons.done,
                      size: 16,
                      color: message.status == 'read'
                          ? AppColors.readTick
                          : AppColors.receivedTick,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.hasText,
    required this.onEmoji,
    required this.onAttachment,
    required this.onCamera,
    required this.onMic,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool hasText;
  final VoidCallback onEmoji;
  final VoidCallback onAttachment;
  final VoidCallback onCamera;
  final VoidCallback onMic;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(7, 8, 8, 8),
        color: AppColors.chatBackground,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              tooltip: 'Émojis',
              onPressed: onEmoji,
              icon: const Icon(
                Icons.emoji_emotions_outlined,
                color: AppColors.secondaryText,
              ),
            ),
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Écrire un message',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Joindre un fichier',
              onPressed: onAttachment,
              icon: const Icon(
                Icons.attach_file,
                color: AppColors.secondaryText,
              ),
            ),
            if (!hasText)
              IconButton(
                tooltip: 'Appareil photo',
                onPressed: onCamera,
                icon: const Icon(
                  Icons.camera_alt_outlined,
                  color: AppColors.secondaryText,
                ),
              ),
            Container(
              width: 48,
              height: 48,
              margin: const EdgeInsets.only(left: 2, bottom: 2),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                tooltip: hasText ? 'Envoyer' : 'Message vocal',
                onPressed: hasText ? onSend : onMic,
                icon: Icon(
                  hasText ? Icons.send_rounded : Icons.mic_none_rounded,
                  color: Colors.white,
                  size: 21,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachmentOption extends StatelessWidget {
  const _AttachmentOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 27,
              backgroundColor: color.withOpacity(0.12),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    ),
  );
}
