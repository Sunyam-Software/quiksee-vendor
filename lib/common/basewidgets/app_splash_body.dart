import 'package:flutter/material.dart';
import 'package:quiksee/utill/images.dart';

class AppSplashBody extends StatelessWidget {
  const AppSplashBody({super.key});

  static const Color brandGreen = Color(0xFF0F6B2D);

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      Images.splashBackground,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      gaplessPlayback: true,
    );
  }
}
