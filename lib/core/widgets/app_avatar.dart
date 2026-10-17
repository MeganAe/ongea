import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.size = 52,
    this.ringColor,
    this.ringWidth = 0,
  });

  final String name;
  final String? photoUrl;
  final double size;
  final Color? ringColor;
  final double ringWidth;

  String get _initials {
    final parts =
        name
            .trim()
            .split(RegExp(r'\s+'))
            .where((part) => part.isNotEmpty)
            .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final image = CircleAvatar(
      radius: size / 2,
      backgroundColor: context.ongea.activeChip,
      foregroundColor: context.ongea.primary,
      backgroundImage:
          photoUrl != null && photoUrl!.isNotEmpty
              ? NetworkImage(photoUrl!)
              : null,
      child:
          photoUrl == null || photoUrl!.isEmpty
              ? Text(
                _initials,
                style: TextStyle(
                  fontSize: size * 0.29,
                  fontWeight: FontWeight.w700,
                ),
              )
              : null,
    );
    if (ringWidth <= 0 || ringColor == null) return image;
    return Container(
      width: size + ringWidth * 2 + 4,
      height: size + ringWidth * 2 + 4,
      padding: EdgeInsets.all(ringWidth),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ringColor!, width: ringWidth),
      ),
      child: image,
    );
  }
}
