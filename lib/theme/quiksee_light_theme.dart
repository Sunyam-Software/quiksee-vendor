import 'package:flutter/material.dart';


Color _primaryColor = const Color(0xFF0F6B2D);
Color _secondaryColor = const Color(0xFFA36A00);

ThemeData light = ThemeData(
  fontFamily: 'Rubik',
  brightness: Brightness.light,
  primaryColor: _primaryColor,
  hintColor: const Color(0xFF9E9E9E),
  shadowColor: const Color(0xfffcf9f4),
  cardColor: const Color(0xFFFFFFFF),
  canvasColor: const Color(0xFFFFFFFF),
  highlightColor: Colors.white,
  dividerColor: const Color(0xFF2A2A2A),
  primaryColorDark: const Color(0xFF1F1F1F),
  scaffoldBackgroundColor: const Color(0xFFF7F8FA),


  colorScheme: ColorScheme.light(
    primary: _primaryColor,
    secondary: _secondaryColor,
    tertiary: const Color(0xFFFFBB38),  // Warning Color
    error: const Color(0xFFFF5A5A), // Danger Color
    tertiaryContainer: const Color(0xFFA7D3B3),
    onTertiaryContainer: const Color(0xFF04BB7B), // Success Color
    outline: const Color(0xFF4E9A63), // Info Color / Pending color
    surface: const Color(0xFFFFFFFF),
    surfaceTint: const Color(0xFF0B5824),
    primaryContainer: const Color(0xFF84C39A),
    secondaryContainer: const Color(0xFFF2F2F2)
  ),


  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Color(0xFF222324)),  // Text color primary
    bodyMedium: TextStyle(color: Color(0xFF656566)), // Text color Secondary
    bodySmall: TextStyle(color: Color(0xFFA7A7A7)),  // Text color Light grey
    titleMedium: TextStyle(color: Color(0xFFA0A0A0)),
    labelLarge: TextStyle(color: Color(0xFFFFFFFF)),
  ),

);

