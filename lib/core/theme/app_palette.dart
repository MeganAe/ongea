import 'package:flutter/material.dart';

/// Jetons de couleur Ongea. Chaque widget lit la palette active depuis le thème,
/// afin que les mêmes écrans restent lisibles en mode clair et sombre.
@immutable
final class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.primary,
    required this.onPrimary,
    required this.accent,
    required this.onAccent,
    required this.background,
    required this.surface,
    required this.text,
    required this.secondaryText,
    required this.border,
    required this.activeChip,
    required this.chatBackground,
    required this.danger,
    required this.readTick,
    required this.receivedTick,
    required this.bubbleOutgoing,
    required this.bubbleIncoming,
    required this.softSurface,
    required this.noticeBackground,
    required this.noticeBorder,
    required this.noticeForeground,
  });

  static const light = AppPalette(
    primary: Color(0xFF135B60),
    onPrimary: Color(0xFFF7F7F2),
    accent: Color(0xFFC9674B),
    onAccent: Color(0xFFFFFFFF),
    background: Color(0xFFF8FAF9),
    surface: Color(0xFFFFFFFF),
    text: Color(0xFF172829),
    secondaryText: Color(0xFF586A6B),
    border: Color(0xFFD9E3E1),
    activeChip: Color(0xFFDCEAE7),
    chatBackground: Color(0xFFF1F5F3),
    danger: Color(0xFFB43E37),
    readTick: Color(0xFF1D746D),
    receivedTick: Color(0xFF6E8082),
    bubbleOutgoing: Color(0xFFF0DDD1),
    bubbleIncoming: Color(0xFFFFFFFF),
    softSurface: Color(0xFFEEF3F1),
    noticeBackground: Color(0xFFFFF2DE),
    noticeBorder: Color(0xFFF0D8A7),
    noticeForeground: Color(0xFF704B16),
  );

  static const dark = AppPalette(
    primary: Color(0xFF82CDC2),
    onPrimary: Color(0xFF082F31),
    accent: Color(0xFFF2A183),
    onAccent: Color(0xFF351A12),
    background: Color(0xFF101A1B),
    surface: Color(0xFF152223),
    text: Color(0xFFE9F2F0),
    secondaryText: Color(0xFFA5B5B3),
    border: Color(0xFF2C4140),
    activeChip: Color(0xFF24413F),
    chatBackground: Color(0xFF0E1819),
    danger: Color(0xFFFF9389),
    readTick: Color(0xFF7BD0C4),
    receivedTick: Color(0xFF92A4A2),
    bubbleOutgoing: Color(0xFF29413F),
    bubbleIncoming: Color(0xFF1A2A2B),
    softSurface: Color(0xFF1B2B2C),
    noticeBackground: Color(0xFF3A3020),
    noticeBorder: Color(0xFF655034),
    noticeForeground: Color(0xFFF4D3A2),
  );

  final Color primary;
  final Color onPrimary;
  final Color accent;
  final Color onAccent;
  final Color background;
  final Color surface;
  final Color text;
  final Color secondaryText;
  final Color border;
  final Color activeChip;
  final Color chatBackground;
  final Color danger;
  final Color readTick;
  final Color receivedTick;
  final Color bubbleOutgoing;
  final Color bubbleIncoming;
  final Color softSurface;
  final Color noticeBackground;
  final Color noticeBorder;
  final Color noticeForeground;

  @override
  AppPalette copyWith({
    Color? primary,
    Color? onPrimary,
    Color? accent,
    Color? onAccent,
    Color? background,
    Color? surface,
    Color? text,
    Color? secondaryText,
    Color? border,
    Color? activeChip,
    Color? chatBackground,
    Color? danger,
    Color? readTick,
    Color? receivedTick,
    Color? bubbleOutgoing,
    Color? bubbleIncoming,
    Color? softSurface,
    Color? noticeBackground,
    Color? noticeBorder,
    Color? noticeForeground,
  }) => AppPalette(
    primary: primary ?? this.primary,
    onPrimary: onPrimary ?? this.onPrimary,
    accent: accent ?? this.accent,
    onAccent: onAccent ?? this.onAccent,
    background: background ?? this.background,
    surface: surface ?? this.surface,
    text: text ?? this.text,
    secondaryText: secondaryText ?? this.secondaryText,
    border: border ?? this.border,
    activeChip: activeChip ?? this.activeChip,
    chatBackground: chatBackground ?? this.chatBackground,
    danger: danger ?? this.danger,
    readTick: readTick ?? this.readTick,
    receivedTick: receivedTick ?? this.receivedTick,
    bubbleOutgoing: bubbleOutgoing ?? this.bubbleOutgoing,
    bubbleIncoming: bubbleIncoming ?? this.bubbleIncoming,
    softSurface: softSurface ?? this.softSurface,
    noticeBackground: noticeBackground ?? this.noticeBackground,
    noticeBorder: noticeBorder ?? this.noticeBorder,
    noticeForeground: noticeForeground ?? this.noticeForeground,
  );

  @override
  AppPalette lerp(covariant AppPalette? other, double t) {
    if (other == null) return this;
    return AppPalette(
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      text: Color.lerp(text, other.text, t)!,
      secondaryText: Color.lerp(secondaryText, other.secondaryText, t)!,
      border: Color.lerp(border, other.border, t)!,
      activeChip: Color.lerp(activeChip, other.activeChip, t)!,
      chatBackground: Color.lerp(chatBackground, other.chatBackground, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      readTick: Color.lerp(readTick, other.readTick, t)!,
      receivedTick: Color.lerp(receivedTick, other.receivedTick, t)!,
      bubbleOutgoing: Color.lerp(bubbleOutgoing, other.bubbleOutgoing, t)!,
      bubbleIncoming: Color.lerp(bubbleIncoming, other.bubbleIncoming, t)!,
      softSurface: Color.lerp(softSurface, other.softSurface, t)!,
      noticeBackground:
          Color.lerp(noticeBackground, other.noticeBackground, t)!,
      noticeBorder: Color.lerp(noticeBorder, other.noticeBorder, t)!,
      noticeForeground:
          Color.lerp(noticeForeground, other.noticeForeground, t)!,
    );
  }
}

extension OngeaPaletteContext on BuildContext {
  AppPalette get ongea => Theme.of(this).extension<AppPalette>()!;
}
