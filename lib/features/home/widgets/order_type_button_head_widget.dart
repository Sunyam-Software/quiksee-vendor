import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_asset_image_widget.dart';
import 'package:quiksee_vendor_app/features/order/controllers/order_controller.dart';
import 'package:quiksee_vendor_app/utill/dimensions.dart';
import 'package:quiksee_vendor_app/utill/styles.dart';

class OrderTypeButtonHeadWidget extends StatelessWidget {
  final String? text;
  final String? subText;
  final Color? color;
  final Color? circleColor;
  final int index;
  final Function? callback;
  final int? numberOfOrder;
  final String? image;

  const OrderTypeButtonHeadWidget({
    super.key,
    required this.text,
    this.subText,
    this.color,
    required this.index,
    required this.callback,
    required this.numberOfOrder,
    required this.circleColor,
    required this.image,
  });

  String get _label {
    final main = text?.trim() ?? '';
    final sub = subText?.trim() ?? '';
    if (main.isEmpty) return sub;
    if (sub.isEmpty) return main;
    return '$main $sub';
  }

  static Color _lightSurface(Color accent, Color? override) {
    if (override != null) return override;
    return Color.lerp(Colors.white, accent, 0.07) ?? Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final accent = circleColor ?? Theme.of(context).primaryColor;
    final surface = _lightSurface(accent, color);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Provider.of<OrderController>(context, listen: false).setIndex(context, index);
          callback?.call();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
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
            border: Border.all(
              color: accent.withValues(alpha: 0.12),
            ),
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
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  right: -6,
                  bottom: -8,
                  child: CustomPaint(
                    size: const Size(80, 48),
                    painter: _AnalyticsCardWavePainter(
                      color: accent,
                      opacity: 0.09,
                    ),
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
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: accent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: QuikseeAssetImageWidget(
                              image ?? '',
                              color: Colors.white,
                              fit: BoxFit.contain,
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
                        '${numberOfOrder ?? 0}',
                        style: robotoBold.copyWith(
                          fontSize: 22,
                          height: 1,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _label,
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

class _AnalyticsCardWavePainter extends CustomPainter {
  final Color color;
  final double opacity;

  _AnalyticsCardWavePainter({
    required this.color,
    this.opacity = 0.07,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width * 0.05, size.height * 0.72)
      ..cubicTo(
        size.width * 0.35,
        size.height * 0.08,
        size.width * 0.62,
        size.height * 0.55,
        size.width * 0.88,
        size.height * 0.22,
      )
      ..quadraticBezierTo(
        size.width * 0.98,
        size.height * 0.42,
        size.width,
        size.height * 0.65,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(size.width * 0.15, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _AnalyticsCardWavePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.opacity != opacity;
  }
}
