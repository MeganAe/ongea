import 'package:flutter/material.dart';

/// Signe Ongea : une bulle de conversation dessinée sur mesure, ponctuée de
/// trois points corail. Le fond et les couleurs sont fournis par l’écran.
class OngeaMark extends StatelessWidget {
  const OngeaMark({
    super.key,
    required this.color,
    required this.accentColor,
    this.size = 42,
  });

  final Color color;
  final Color accentColor;
  final double size;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(size),
    painter: _OngeaMarkPainter(color: color, accentColor: accentColor),
  );
}

class _OngeaMarkPainter extends CustomPainter {
  const _OngeaMarkPainter({required this.color, required this.accentColor});

  final Color color;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 48, size.height / 48);

    final outline =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
    final bubble = RRect.fromRectAndRadius(
      const Rect.fromLTWH(5, 5, 38, 29),
      const Radius.circular(8),
    );
    canvas.drawRRect(bubble, outline);

    final tail =
        Path()
          ..moveTo(15, 34)
          ..lineTo(12, 42)
          ..lineTo(24, 34);
    canvas.drawPath(tail, outline);

    final dots = Paint()..color = accentColor;
    for (final x in const [16.5, 24, 31.5]) {
      canvas.drawCircle(Offset(x, 19.5), 2.15, dots);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _OngeaMarkPainter oldDelegate) =>
      color != oldDelegate.color || accentColor != oldDelegate.accentColor;
}
