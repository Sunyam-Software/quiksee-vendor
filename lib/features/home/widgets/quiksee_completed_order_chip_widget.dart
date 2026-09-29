import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiksee_vendor_app/features/order/controllers/order_controller.dart';
import 'package:quiksee_vendor_app/utill/dimensions.dart';
import 'package:quiksee_vendor_app/utill/styles.dart';

class QuikseeCompletedOrderChipWidget extends StatelessWidget {
  final String icon;
  final String label;
  final int? count;
  final Color primaryColor;
  final int index;
  final VoidCallback? onTap;
  final bool waveOnLeft;

  const QuikseeCompletedOrderChipWidget({
    super.key,
    required this.icon,
    required this.label,
    required this.count,
    required this.primaryColor,
    required this.index,
    this.onTap,
    this.waveOnLeft = true,
  });

  static Color _lightSurface(Color accent) {
    return Color.lerp(Colors.white, accent, 0.07) ?? Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final value = count ?? 0;
    final accent = primaryColor;
    final surface = _lightSurface(accent);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Provider.of<OrderController>(context, listen: false)
              .setIndex(context, index);
          onTap?.call();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 148,
          height: 128,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(Colors.white, surface, 0.35) ?? Colors.white,
                surface,
              ],
            ),
            border: Border.all(color: accent.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Positioned(
                  right: waveOnLeft ? null : -6,
                  left: waveOnLeft ? -6 : null,
                  bottom: -8,
                  child: CustomPaint(
                    size: const Size(80, 48),
                    painter: _WavePainter(color: accent, opacity: 0.09),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: accent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Image.asset(
                                icon,
                                width: 20,
                                height: 20,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.more_horiz_rounded,
                            size: 20,
                            color: Colors.grey.shade400,
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        '$value',
                        style: robotoBold.copyWith(
                          fontSize: 22,
                          height: 1,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: robotoBold.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          height: 1.15,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final Color color;
  final double opacity;

  _WavePainter({required this.color, this.opacity = 0.09});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width * 0.05, size.height * 0.72)
      ..cubicTo(
        size.width * 0.35, size.height * 0.08,
        size.width * 0.62, size.height * 0.55,
        size.width * 0.88, size.height * 0.22,
      )
      ..quadraticBezierTo(
        size.width * 0.98, size.height * 0.42,
        size.width, size.height * 0.65,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(size.width * 0.12, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WavePainter old) =>
      old.color != color || old.opacity != opacity;
}
