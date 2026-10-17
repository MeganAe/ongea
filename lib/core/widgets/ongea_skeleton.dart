import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

/// Placeholder neutre utilisé pendant les chargements de contenu.
class OngeaSkeleton extends StatelessWidget {
  const OngeaSkeleton({
    super.key,
    this.width,
    this.height = 14,
    this.radius = 8,
    this.circle = false,
  });

  final double? width;
  final double height;
  final double radius;
  final bool circle;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration:
        circle
            ? BoxDecoration(
              color: context.ongea.softSurface,
              shape: BoxShape.circle,
            )
            : BoxDecoration(
              color: context.ongea.softSurface,
              borderRadius: BorderRadius.circular(radius),
            ),
  );
}

/// Lignes d’aperçu stables pour les listes de contacts et de discussions.
class OngeaListSkeleton extends StatelessWidget {
  const OngeaListSkeleton({super.key, this.itemCount = 6});

  final int itemCount;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    label: 'Chargement du contenu',
    child: ListView.separated(
      itemCount: itemCount,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      separatorBuilder: (context, index) => const SizedBox(height: 2),
      itemBuilder:
          (context, index) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const OngeaSkeleton(width: 52, height: 52, circle: true),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(child: OngeaSkeleton(height: 14)),
                          const SizedBox(width: 24),
                          OngeaSkeleton(
                            width: index.isEven ? 32 : 44,
                            height: 10,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      FractionallySizedBox(
                        widthFactor: index.isEven ? 0.68 : 0.48,
                        alignment: Alignment.centerLeft,
                        child: const OngeaSkeleton(height: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
    ),
  );
}

/// Silhouettes de bulles qui reprennent l’alternance d’une conversation.
class OngeaMessageSkeleton extends StatelessWidget {
  const OngeaMessageSkeleton({super.key, this.itemCount = 8});

  final int itemCount;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    label: 'Chargement des messages',
    child: ListView.builder(
      reverse: true,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        final isMine = index.isEven;
        final maxBubbleWidth = MediaQuery.sizeOf(context).width * 0.74;
        final bubbleWidth =
            (168.0 + (index % 3) * 28).clamp(128.0, maxBubbleWidth).toDouble();
        return Align(
          alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: bubbleWidth,
            height: index % 3 == 0 ? 58 : 46,
            margin: const EdgeInsets.symmetric(vertical: 5),
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            decoration: BoxDecoration(
              color: context.ongea.softSurface,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMine ? 16 : 4),
                bottomRight: Radius.circular(isMine ? 4 : 16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FractionallySizedBox(
                  widthFactor: index % 3 == 0 ? 0.72 : 0.9,
                  child: const OngeaSkeleton(height: 10, radius: 6),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: const OngeaSkeleton(width: 30, height: 8, radius: 5),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

/// État d’attente pour une fiche contact, avec les mêmes proportions que son contenu.
class OngeaProfileSkeleton extends StatelessWidget {
  const OngeaProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    label: 'Chargement de la fiche contact',
    child: ListView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
      children: [
        const SizedBox(height: 12),
        const Center(child: OngeaSkeleton(width: 92, height: 92, circle: true)),
        const SizedBox(height: 18),
        const Center(child: OngeaSkeleton(width: 168, height: 18)),
        const SizedBox(height: 9),
        const Center(child: OngeaSkeleton(width: 116, height: 13)),
        const SizedBox(height: 30),
        for (var index = 0; index < 4; index++) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: OngeaSkeleton(height: 42, radius: 12),
          ),
          if (index < 3) const Divider(height: 1),
        ],
      ],
    ),
  );
}
