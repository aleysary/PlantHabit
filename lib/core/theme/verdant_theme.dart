import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'verdant_colors.dart';

/// Design tokens that don't map neatly onto [ColorScheme].
@immutable
class VerdantTokens extends ThemeExtension<VerdantTokens> {
  const VerdantTokens({
    required this.card,
    required this.raised,
    required this.line,
    required this.muted,
    required this.text,
    required this.highlight,
    required this.onHighlight,
    required this.hero,
    required this.onHero,
    required this.isDark,
  });

  final Color card;
  final Color raised;
  final Color line;
  final Color muted;
  final Color text;
  final Color highlight;
  final Color onHighlight;
  final Color hero;
  final Color onHero;
  final bool isDark;

  List<Color> backdropFor(String potId) =>
      (isDark ? VerdantColors.potBackdropsDark : VerdantColors.potBackdrops)[potId] ??
      [card, raised];

  @override
  VerdantTokens copyWith({
    Color? card,
    Color? raised,
    Color? line,
    Color? muted,
    Color? text,
    Color? highlight,
    Color? onHighlight,
    Color? hero,
    Color? onHero,
    bool? isDark,
  }) {
    return VerdantTokens(
      card: card ?? this.card,
      raised: raised ?? this.raised,
      line: line ?? this.line,
      muted: muted ?? this.muted,
      text: text ?? this.text,
      highlight: highlight ?? this.highlight,
      onHighlight: onHighlight ?? this.onHighlight,
      hero: hero ?? this.hero,
      onHero: onHero ?? this.onHero,
      isDark: isDark ?? this.isDark,
    );
  }

  @override
  VerdantTokens lerp(ThemeExtension<VerdantTokens>? other, double t) {
    if (other is! VerdantTokens) return this;
    return VerdantTokens(
      card: Color.lerp(card, other.card, t)!,
      raised: Color.lerp(raised, other.raised, t)!,
      line: Color.lerp(line, other.line, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      text: Color.lerp(text, other.text, t)!,
      highlight: Color.lerp(highlight, other.highlight, t)!,
      onHighlight: Color.lerp(onHighlight, other.onHighlight, t)!,
      hero: Color.lerp(hero, other.hero, t)!,
      onHero: Color.lerp(onHero, other.onHero, t)!,
      isDark: t < 0.5 ? isDark : other.isDark,
    );
  }
}

extension VerdantContext on BuildContext {
  VerdantTokens get v => Theme.of(this).extension<VerdantTokens>()!;
  TextTheme get text => Theme.of(this).textTheme;
  ColorScheme get colors => Theme.of(this).colorScheme;
}

class VerdantTheme {
  VerdantTheme._();

  static const radiusLg = 24.0;
  static const radiusMd = 16.0;
  static const radiusSm = 10.0;

  static ThemeData build({
    required Brightness brightness,
    AccentOption accent = AccentOption.moss,
    bool compact = false,
  }) {
    final dark = brightness == Brightness.dark;
    final bg = dark ? VerdantColors.night : VerdantColors.paper;
    final card = dark ? VerdantColors.nightCard : VerdantColors.card;
    final raised = dark ? VerdantColors.nightRaised : VerdantColors.paperDeep;
    final text = dark ? VerdantColors.mist : VerdantColors.ink;
    final muted = dark ? VerdantColors.mistMuted : VerdantColors.muted;
    final line = dark ? VerdantColors.nightLine : VerdantColors.line;
    // In dark mode the primary needs to be brighter to read on the night bg.
    final primary = dark ? Color.lerp(accent.primary, accent.highlight, 0.55)! : accent.primary;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: dark ? VerdantColors.ink : Colors.white,
      secondary: accent.highlight,
      onSecondary: VerdantColors.ink,
      tertiary: VerdantColors.terracotta,
      onTertiary: Colors.white,
      error: VerdantColors.danger,
      onError: Colors.white,
      surface: bg,
      onSurface: text,
      surfaceContainerHighest: raised,
      outline: line,
      outlineVariant: line,
    );

    final display = GoogleFonts.frauncesTextTheme();
    final body = GoogleFonts.manropeTextTheme();

    TextStyle d(TextStyle? s, double size, {FontWeight w = FontWeight.w500, double ls = -0.8}) =>
        (s ?? const TextStyle()).copyWith(fontSize: size, fontWeight: w, letterSpacing: ls, color: text, height: 1.05);
    TextStyle b(TextStyle? s, double size, {FontWeight w = FontWeight.w500, double ls = 0, Color? c, double h = 1.35}) =>
        (s ?? const TextStyle()).copyWith(fontSize: size, fontWeight: w, letterSpacing: ls, color: c ?? text, height: h);

    final textTheme = TextTheme(
      displayLarge: d(display.displayLarge, 56, ls: -2),
      displayMedium: d(display.displayMedium, 44, ls: -1.6),
      displaySmall: d(display.displaySmall, 36, ls: -1.2),
      headlineLarge: d(display.headlineLarge, 32, ls: -1),
      headlineMedium: d(display.headlineMedium, 28, ls: -0.8),
      headlineSmall: d(display.headlineSmall, 24, ls: -0.6),
      titleLarge: b(body.titleLarge, 18, w: FontWeight.w700, ls: -0.3),
      titleMedium: b(body.titleMedium, 16, w: FontWeight.w700, ls: -0.2),
      titleSmall: b(body.titleSmall, 14, w: FontWeight.w700),
      bodyLarge: b(body.bodyLarge, 16),
      bodyMedium: b(body.bodyMedium, 14),
      bodySmall: b(body.bodySmall, 12.5, c: muted),
      labelLarge: b(body.labelLarge, 14, w: FontWeight.w700, ls: 0.1),
      labelMedium: b(body.labelMedium, 12, w: FontWeight.w700, ls: 0.2),
      // Used for small-caps eyebrow labels.
      labelSmall: b(body.labelSmall, 10.5, w: FontWeight.w800, ls: 1.4, c: muted),
    );

    final tokens = VerdantTokens(
      card: card,
      raised: raised,
      line: line,
      muted: muted,
      text: text,
      highlight: accent.highlight,
      onHighlight: VerdantColors.ink,
      hero: dark ? VerdantColors.nightRaised : VerdantColors.ink,
      onHero: VerdantColors.mist,
      isDark: dark,
    );

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusMd),
      borderSide: BorderSide(color: line),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      textTheme: textTheme,
      visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
      splashFactory: InkRipple.splashFactory,
      extensions: [tokens],
      dividerTheme: DividerThemeData(color: line, thickness: 1, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: text,
        titleTextStyle: textTheme.titleLarge,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(borderSide: BorderSide(color: primary, width: 1.6)),
        errorBorder: border.copyWith(borderSide: const BorderSide(color: VerdantColors.danger)),
        focusedErrorBorder: border.copyWith(borderSide: const BorderSide(color: VerdantColors.danger, width: 1.6)),
        labelStyle: textTheme.bodyMedium?.copyWith(color: muted),
        hintStyle: textTheme.bodyMedium?.copyWith(color: muted),
        floatingLabelStyle: textTheme.labelMedium?.copyWith(color: primary),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          backgroundColor: dark ? accent.highlight : VerdantColors.ink,
          foregroundColor: dark ? VerdantColors.ink : VerdantColors.mist,
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          foregroundColor: text,
          side: BorderSide(color: line, width: 1.2),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primary, textStyle: textTheme.labelLarge),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: dark ? VerdantColors.mist : VerdantColors.ink,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: dark ? VerdantColors.ink : VerdantColors.mist),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: line,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? VerdantColors.ink : null),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? accent.highlight : null),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      }),
    );
  }
}
