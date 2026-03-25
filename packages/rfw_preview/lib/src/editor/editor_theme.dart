import 'package:flutter/material.dart';

/// Mystique design system tokens for the RFW Editor.
abstract final class EditorColors {
  // Accent
  static const szsBlue55 = Color(0xFF237AF2);

  // Text
  static const szsGray100 = Color(0xFF141618);
  static const szsGray70 = Color(0xFF49515A);
  static const szsGray50 = Color(0xFF8E949A);

  // Surfaces
  static const pageBg = Color(0xFFFAFBFC);
  static const cardBg = Color(0xFFFFFFFF);
  static const sectionBg = Color(0xFFF5F6F8);

  // Status
  static const szsRed50 = Color(0xFFE53935);

  // Divider & toast
  static const divider = Color(0xFFE8EBED);
  static const szsGray90 = Color(0xFF2B2F34);

  // Dark theme
  static const darkBg = Color(0xFF1E1E1E);
  static const darkSurface = Color(0xFF252526);
  static const darkBorder = Color(0xFF3C3C3C);
  static const darkText = Color(0xFFD4D4D4);
  static const darkTextDim = Color(0xFF8E949A);
}

/// Corner radius tokens.
abstract final class EditorRadius {
  static const button = 12.0;
  static const card = 16.0;
  static const input = 8.0;
}

/// Syntax highlighting colors for the editor.
abstract final class SyntaxColors {
  // Dark theme syntax
  static const keyword = Color(0xFFC586C0); // purple — import, widget
  static const widgetName = Color(0xFF4EC9B0); // teal — Widget names
  static const string = Color(0xFFCE9178); // orange-brown — strings
  static const number = Color(0xFFB5CEA8); // green — numbers
  static const comment = Color(0xFF6A9955); // green — comments
  static const property = Color(0xFF9CDCFE); // light blue — property names
  static const punctuation = Color(0xFFD4D4D4); // gray — braces, colons
  static const plain = Color(0xFFD4D4D4); // default text

  // Light theme syntax
  static const lightKeyword = Color(0xFF7B30D0);
  static const lightWidgetName = Color(0xFF267F99);
  static const lightString = Color(0xFFA31515);
  static const lightNumber = Color(0xFF098658);
  static const lightComment = Color(0xFF6A9955);
  static const lightProperty = Color(0xFF001080);
  static const lightPunctuation = Color(0xFF393A34);
  static const lightPlain = Color(0xFF393A34);
}

/// Creates the light theme for the editor.
ThemeData editorLightTheme() {
  return ThemeData(
    brightness: Brightness.light,
    colorSchemeSeed: EditorColors.szsBlue55,
    useMaterial3: true,
    scaffoldBackgroundColor: EditorColors.pageBg,
    cardColor: EditorColors.cardBg,
    fontFamily: null, // system default
    appBarTheme: const AppBarTheme(
      backgroundColor: EditorColors.cardBg,
      foregroundColor: EditorColors.szsGray100,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    dividerTheme: const DividerThemeData(
      color: EditorColors.sectionBg,
      thickness: 1,
      space: 1,
    ),
  );
}

/// Creates the dark theme for the editor.
ThemeData editorDarkTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    colorSchemeSeed: EditorColors.szsBlue55,
    useMaterial3: true,
    scaffoldBackgroundColor: EditorColors.darkBg,
    cardColor: EditorColors.darkSurface,
    fontFamily: null,
    appBarTheme: const AppBarTheme(
      backgroundColor: EditorColors.darkSurface,
      foregroundColor: EditorColors.darkText,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    dividerTheme: const DividerThemeData(
      color: EditorColors.darkBorder,
      thickness: 1,
      space: 1,
    ),
  );
}
