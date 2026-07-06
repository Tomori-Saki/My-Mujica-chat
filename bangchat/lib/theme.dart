import 'package:flutter/material.dart';

/// BanGchat 暗金色主题。
///
/// 对应原 Vue 前端 style.css 中的 CSS 变量：
/// - 金色强调: #D8C076
/// - 文字: #EFE7D4
/// - 弱化文字: #A59B86
/// - 背景: 深海军蓝 / 深红渐变
class AppTheme {
  AppTheme._();

  // ---- 颜色常量 ----
  static const Color gold = Color(0xFFD8C076);
  static const Color goldSoft = Color(0xFF9F8B4C);
  static const Color text = Color(0xFFEFE7D4);
  static const Color muted = Color(0xFFA59B86);
  static const Color panel = Color(0xFF121110);
  static const Color panelStrong = Color(0xFF161511);
  static const Color line = Color(0x2DD9C276);
  static const Color danger = Color(0xFFC46B6B);
  static const Color bgDark = Color(0xFF0A0A06);
  static const Color accent = Color(0xFFC8AD5E);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDark,
      colorScheme: const ColorScheme.dark(
        primary: gold,
        secondary: goldSoft,
        surface: panel,
        error: danger,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: panelStrong,
        elevation: 0,
        centerTitle: true,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xE6080806),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0x33D9C276)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0x33D9C276)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: gold),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        hintStyle: const TextStyle(color: muted, fontSize: 13),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: const Color(0xFF1A160C),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          side: const BorderSide(color: line),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: text, fontSize: 14),
        bodySmall: TextStyle(color: muted, fontSize: 12),
        titleMedium: TextStyle(color: text, fontSize: 16),
      ),
      fontFamily: 'Noto Sans SC',
    );
  }
}
