import 'package:flutter/material.dart';

abstract final class QuikseeBrandColors {
  static const Color forestGreen = Color(0xFF0B3D24);
  static const Color forestGreenMid = Color(0xFF134D2E);
  static const Color forestGreenLight = Color(0xFF1A5C38);
  static const Color seeTextGreen = Color(0xFF1E7A3F);
  static const Color featuredSectionBackground = Color(0xFFE8F4EC);
  static const Color headerBackgroundGreen = Color(0xFFCDE5D5);
  static const Color flashDealTextGreen = forestGreen;
  static const Color gold = Color(0xFFF0B020);
  static const Color goldDark = Color(0xFFB87A08);
  static const Color logoGoldLight = Color(0xFFFFE45C);
  static const Color progressInactive = Color(0xFF1A4D32);
  static const Color buttonText = Color(0xFF1A1A1A);

  static const LinearGradient flashDealGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [gold, goldDark, Color(0xFFE6B800)],
  );
}
