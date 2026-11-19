import 'package:flutter/material.dart';

const ttuScarlet = Color(0xFFCC0000);

ThemeData buildTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: ttuScarlet,
    brightness: brightness,
    primary: brightness == Brightness.light ? ttuScarlet : null,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
    ),
  );
}
