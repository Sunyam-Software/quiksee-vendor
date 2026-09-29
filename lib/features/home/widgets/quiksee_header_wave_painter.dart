import 'package:flutter/material.dart';
import 'package:quiksee_vendor_app/utill/quiksee_brand_colors.dart';

class QuikseeHeaderWavePainter extends CustomPainter {
  const QuikseeHeaderWavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    void drawWave({
      required List<Offset> anchors,
      required Color color,
      required double opacity,
    }) {
      if (anchors.length < 3) return;
      final path = Path()..moveTo(anchors.first.dx, anchors.first.dy);
      for (var i = 0; i < anchors.length - 1; i++) {
        final current = anchors[i];
        final next = anchors[i + 1];
        final control = Offset(
          (current.dx + next.dx) / 2,
          (current.dy + next.dy) / 2 - 8,
        );
        path.quadraticBezierTo(current.dx, current.dy, control.dx, control.dy);
      }
      path.lineTo(anchors.last.dx, anchors.last.dy);
      path.lineTo(w, h);
      path.lineTo(w * 0.15, h);
      path.close();
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: opacity)
          ..style = PaintingStyle.fill,
      );
    }

    drawWave(
      color: QuikseeBrandColors.seeTextGreen,
      opacity: 0.16,
      anchors: [
        Offset(w * 0.28, h * 0.15),
        Offset(w * 0.55, h * 0.05),
        Offset(w * 0.88, h * 0.12),
        Offset(w * 0.98, h * 0.45),
        Offset(w * 0.72, h * 0.82),
        Offset(w * 0.38, h * 0.72),
      ],
    );

    drawWave(
      color: QuikseeBrandColors.forestGreenLight,
      opacity: 0.10,
      anchors: [
        Offset(w * 0.42, h * 0.25),
        Offset(w * 0.68, h * 0.18),
        Offset(w * 0.92, h * 0.35),
        Offset(w * 0.85, h * 0.65),
        Offset(w * 0.52, h * 0.78),
      ],
    );

    drawWave(
      color: QuikseeBrandColors.gold,
      opacity: 0.06,
      anchors: [
        Offset(w * 0.48, h * 0.35),
        Offset(w * 0.62, h * 0.28),
        Offset(w * 0.78, h * 0.42),
        Offset(w * 0.70, h * 0.58),
        Offset(w * 0.50, h * 0.55),
      ],
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
