import 'package:flutter/material.dart';
import 'package:quiksee_vendor_app/utill/images.dart';

class QuikseeGlobalPageBackground extends StatelessWidget {
  const QuikseeGlobalPageBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ColoredBox(
      color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F9F6),
    );
  }
}

class QuikseeWatermarkOverlay extends StatelessWidget {
  const QuikseeWatermarkOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IgnorePointer(
      child: QuikseeBackgroundWatermark(
        opacity: isDark ? 0.04 : 0.06,
        alignment: Alignment.center,
        widthFactor: 0.6,
      ),
    );
  }
}

class QuikseeBackgroundWatermark extends StatelessWidget {
  const QuikseeBackgroundWatermark({
    super.key,
    this.opacity = 0.06,
    this.alignment = Alignment.center,
    this.widthFactor = 0.55,
  });

  final double opacity;
  final Alignment alignment;
  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return IgnorePointer(
      child: Align(
        alignment: alignment,
        child: Opacity(
          opacity: opacity,
          child: Image.asset(
            Images.quikseeLogo,
            width: size.width * widthFactor,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          ),
        ),
      ),
    );
  }
}
