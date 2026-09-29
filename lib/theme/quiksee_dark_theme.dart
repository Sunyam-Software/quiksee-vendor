import 'package:flutter/material.dart';


Color _primaryColor = const Color(0xFF0F6B2D);
Color _secondaryColor = const Color(0xFFA36A00);

ThemeData dark = ThemeData(
  fontFamily: 'Rubik',
  brightness: Brightness.dark,
  hintColor: const Color(0x80F9FAFA),
  shadowColor: const Color(0x80E8E8E8),
  primaryColor: _primaryColor,
  primaryColorLight: const Color(0x80F9FAFA),
  highlightColor: const Color(0xFF252525),
  focusColor: const Color(0xFF8D8D8D),
  dividerColor: const Color(0xFF2A2A2A),
  canvasColor: const Color(0xFF041524),
  cardColor: const Color(0xFF242424),
  scaffoldBackgroundColor: const Color(0xFF000000),

  colorScheme : ColorScheme.dark(
    primary: _primaryColor,
    secondary: _secondaryColor,
    error:const Color(0xFFFF4040), // Danger Color
    tertiary: const Color(0xFFFFBB38), // Warning Color
    tertiaryContainer: const Color(0xFF1E4A30),
    onTertiaryContainer: const Color(0xFF04BB7B), // Success Color
    primaryContainer: const Color(0xFF166C42),
    surface: const Color(0xFF2D2D2D),
    outline: const Color(0xFF4E9A63), // Info Color // Pending color
    secondaryContainer: const Color(0xFFF2F2F2),
  ),


  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Color(0x80F9FAFA)),  // Text color primary
    bodyMedium: TextStyle(color: Color(0x80F9FAFA)), // Text color Secondary
    bodySmall: TextStyle(color: Color(0xFFA7A7A7)),  // Text color Light grey
    titleMedium: TextStyle(color: Color(0xFFA0A0A0)),
    labelLarge: TextStyle(color: Color(0xFFFFFFFF)),
  ),

  dialogTheme: const DialogThemeData(
    surfaceTintColor: Color(0xFF02203A),
    shadowColor: Color(0x20454545),
  ),

);