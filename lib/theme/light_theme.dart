import 'package:flutter/material.dart';
import 'package:quiksee_vendor_app/utill/quiksee_brand_colors.dart';

Color _primaryColor = QuikseeBrandColors.seeTextGreen;
Color _secondaryColor = QuikseeBrandColors.gold;

ThemeData light = ThemeData(
  fontFamily: 'TitilliumWeb',
  primaryColor: _primaryColor,
  bottomSheetTheme: const BottomSheetThemeData(backgroundColor: Colors.transparent),
  brightness: Brightness.light,
  highlightColor: Colors.white,
  hintColor: const Color(0xFFA7A7A7),
  disabledColor:  const Color(0xFF343A40),
  canvasColor: const Color(0xFFFCFCFC),
  cardColor: const Color(0xFFFFFFFF),
  splashColor: Colors.transparent,
  scaffoldBackgroundColor: Colors.transparent,

  textTheme: TextTheme(
    bodyLarge: const TextStyle(color: Color(0xFF222324)),
    bodyMedium: TextStyle(color: _primaryColor),
    bodySmall: const TextStyle(color: Color(0xFFA7A7A7)),
    headlineMedium: const TextStyle(color: Color(0xFFA0A0A0)),
    headlineLarge : const TextStyle(color: Color(0xFF656566)),
  ),

  colorScheme: ColorScheme.light(
    primary:  _primaryColor,
    secondary:  _secondaryColor,
    error: const Color(0xFFFF5A5A),
    tertiary:  const Color(0xFFFFBB38),
    tertiaryContainer: const Color(0xFFADC9F3),
    onTertiaryContainer:  const Color(0xFF04BB7B),
    primaryContainer: const Color(0xFF9AECC6),
    secondaryContainer: const Color(0xFFF2F2F2),
    surface: const Color(0xFFFFFFFF),
    surfaceTint: QuikseeBrandColors.seeTextGreen,
    onPrimary: const Color(0xFF67AFFF),
    onSecondary: const Color(0xFFFC9926),
    outline: const Color(0xff5C8FFC),
  ),

  pageTransitionsTheme: const PageTransitionsTheme(builders: {
    TargetPlatform.android: ZoomPageTransitionsBuilder(),
    TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
    TargetPlatform.fuchsia: ZoomPageTransitionsBuilder(),
  }),
);