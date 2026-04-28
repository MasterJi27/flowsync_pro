import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get light => _theme(Brightness.light);
  static ThemeData get dark => _theme(Brightness.dark);

  static ThemeData _theme(Brightness brightness) {
    final baseScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0B6E8A),
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    );
    final scheme = baseScheme.copyWith(
      primary: brightness == Brightness.light
          ? const Color(0xFF0B6E8A)
          : const Color(0xFF62D7E8),
      secondary: brightness == Brightness.light
          ? const Color(0xFFC86B2D)
          : const Color(0xFFFFC38A),
      tertiary: brightness == Brightness.light
          ? const Color(0xFF5D3DF0)
          : const Color(0xFFB9A7FF),
      surface: brightness == Brightness.light
          ? const Color(0xFFF7FAFB)
          : const Color(0xFF091417),
      surfaceContainerHighest: brightness == Brightness.light
          ? const Color(0xFFE4EEF1)
          : const Color(0xFF162228),
      onSurfaceVariant: brightness == Brightness.light
          ? const Color(0xFF526468)
          : const Color(0xFFA4BCC2),
    );

    final baseText = GoogleFonts.dmSansTextTheme(
      brightness == Brightness.light
          ? ThemeData.light().textTheme
          : ThemeData.dark().textTheme,
    );
    final displayText = GoogleFonts.spaceGroteskTextTheme(baseText);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: displayText,
      scaffoldBackgroundColor: brightness == Brightness.light
          ? const Color(0xFFEFF6F8)
          : const Color(0xFF061015),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        titleTextStyle: displayText.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: brightness == Brightness.light ? 1.5 : 0,
        shadowColor: scheme.primary.withValues(alpha: 0.18),
        color: brightness == Brightness.light
            ? Colors.white
            : const Color(0xFF12212A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.32),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: displayText.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(46),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.65),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.35)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        labelStyle: displayText.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brightness == Brightness.light
            ? Colors.white
            : const Color(0xFF18252C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: brightness == Brightness.light
            ? Colors.white
            : const Color(0xFF12212A),
        indicatorColor: scheme.primaryContainer.withValues(alpha: 0.65),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontWeight: FontWeight.w700, color: scheme.onSurface),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: brightness == Brightness.light
            ? Colors.white
            : const Color(0xFF13222B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: displayText.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.32),
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: brightness == Brightness.light
            ? const Color(0xFF0A2430)
            : const Color(0xFF16313B),
        contentTextStyle: displayText.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
