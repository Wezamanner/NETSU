import 'package:material_ui/material_ui.dart';

class AppTheme {
  const AppTheme._();

  static const _brand = Color(0xFF0F6B4C);
  static const _font = 'Noto Sans Ethiopic';

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final scheme = ColorScheme.fromSeed(seedColor: _brand, brightness: brightness);
    final scaffoldBg = isLight ? const Color(0xFFF4F6F5) : const Color(0xFF1A2220);
    final cardBg = isLight ? Colors.white : const Color(0xFF222C29);
    final base = ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      fontFamily: _font,
      scaffoldBackgroundColor: scaffoldBg,
    );
    final text = base.textTheme.apply(fontFamily: _font, bodyColor: scheme.onSurface, displayColor: scheme.onSurface).copyWith(
      bodyLarge: base.textTheme.bodyLarge?.copyWith(fontSize: 16, height: 1.45, color: scheme.onSurface),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(fontSize: 16, height: 1.4, color: scheme.onSurface),
      titleLarge: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: scheme.onSurface),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, color: scheme.onSurface),
    );
    final radius = BorderRadius.circular(16);
    final button = FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(48),
      shape: RoundedRectangleBorder(borderRadius: radius),
    );
    return base.copyWith(
      textTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: base.scaffoldBackgroundColor,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: cardBg,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(style: button),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: radius),
        ),
      ),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(minimumSize: const Size(48, 48))),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        border: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: scheme.outlineVariant)),
        enabledBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: scheme.outlineVariant)),
        focusedBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: scheme.primary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primary.withValues(alpha: 0.14),
        labelTextStyle: WidgetStateProperty.all(const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
  }
}
