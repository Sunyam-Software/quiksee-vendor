import 'package:flutter/material.dart';
import 'package:quiksee_vendor_app/utill/images.dart';
import 'package:quiksee_vendor_app/utill/quiksee_brand_colors.dart';

class QuikseeSplashWidget extends StatefulWidget {
  const QuikseeSplashWidget({super.key});

  @override
  State<QuikseeSplashWidget> createState() => _QuikseeSplashWidgetState();
}

class _QuikseeSplashWidgetState extends State<QuikseeSplashWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loadingController;

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            Images.quikseeSplashBg,
            fit: BoxFit.cover,
            width: size.width,
            height: size.height,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.15),
                radius: 1.1,
                colors: [
                  Colors.transparent,
                  QuikseeBrandColors.forestGreen.withValues(alpha: 0.35),
                ],
              ),
            ),
          ),
          Positioned(
            left: 40,
            right: 40,
            bottom: MediaQuery.paddingOf(context).bottom + 36,
            child: AnimatedBuilder(
              animation: _loadingController,
              builder: (context, child) {
                final progress = 0.15 + (_loadingController.value * 0.7);
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: SizedBox(
                        height: 5,
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: QuikseeBrandColors.progressInactive,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            QuikseeBrandColors.gold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          QuikseeBrandColors.gold,
                          QuikseeBrandColors.goldDark,
                        ],
                      ).createShader(bounds),
                      child: const Text(
                        'Loading...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
