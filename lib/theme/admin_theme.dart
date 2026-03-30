import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ADMIN DESIGN SYSTEM – Vị Lai Quán Premium (Light & Dark)
// ─────────────────────────────────────────────────────────────────────────────

abstract class AdminColors {
  // ── Core Brand ─────────────────────────────────────────────────────────────
  static const Color crimson      = Color(0xFFC41230);
  static const Color crimsonBright = Color(0xFFE5172E);
  static const Color crimsonDeep  = Color(0xFF8B0D22);
  static Color crimsonSubtle(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2D0711) : const Color(0xFFFFF1F2);
  static const Color gold         = Color(0xFFD4A832);
  static const Color goldLight     = Color(0xFFF0C84A);
  static Color goldSubtle(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? const Color(0xFF261D05) : const Color(0xFFFEF9C3);

  // ── Dynamic Backgrounds (helper getters) ───────────────────────────────────
  static Color bgPrimary(BuildContext context) => Theme.of(context).scaffoldBackgroundColor;
  static Color bgCard(BuildContext context) => Theme.of(context).cardTheme.color ?? Colors.white;
  static Color bgElevated(BuildContext context) => Theme.of(context).colorScheme.surfaceContainerHighest;
  
  static Color textPrimary(BuildContext context) => Theme.of(context).colorScheme.onSurface;
  static Color textSecondary(BuildContext context) => Theme.of(context).colorScheme.onSurfaceVariant;
  static Color textMuted(BuildContext context) => Theme.of(context).disabledColor;

  static Color borderDefault(BuildContext context) => Theme.of(context).colorScheme.outline;
  static Color borderMuted(BuildContext context) => Theme.of(context).colorScheme.outlineVariant;

  // ── Status Colors ──────────────────────────────────────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFEAB308);
  static const Color error   = Color(0xFFEF4444);
  static const Color info    = Color(0xFF3B82F6);
  static const Color orange  = Color(0xFFF97316);
  static const Color purple  = Color(0xFFA855F7);
  static const Color teal    = Color(0xFF14B8A6);
  static const Color indigo  = Color(0xFF818CF8);
}

// ─────────────────────────────────────────────────────────────────────────────
// TYPE SCALE
// ─────────────────────────────────────────────────────────────────────────────
abstract class AdminText {
  static TextStyle get brandName => GoogleFonts.plusJakartaSans(
    fontSize: 16, fontWeight: FontWeight.w800,
    color: AdminColors.gold, letterSpacing: 2.5,
  );

  static TextStyle displayLarge(BuildContext context) => GoogleFonts.plusJakartaSans(
    fontSize: 32, fontWeight: FontWeight.w800,
    color: Theme.of(context).colorScheme.onSurface, letterSpacing: -1.0,
  );

  static TextStyle h1(BuildContext context) => GoogleFonts.plusJakartaSans(
    fontSize: 22, fontWeight: FontWeight.w800,
    color: Theme.of(context).colorScheme.onSurface, letterSpacing: -0.4,
  );

  static TextStyle h2(BuildContext context) => GoogleFonts.plusJakartaSans(
    fontSize: 17, fontWeight: FontWeight.w700,
    color: Theme.of(context).colorScheme.onSurface, letterSpacing: -0.3,
  );

  static TextStyle h3(BuildContext context) => GoogleFonts.inter(
    fontSize: 14, fontWeight: FontWeight.w700,
    color: Theme.of(context).colorScheme.onSurface,
  );

  static TextStyle kpiLarge(BuildContext context) => GoogleFonts.plusJakartaSans(
    fontSize: 26, fontWeight: FontWeight.w800,
    color: AdminColors.gold, letterSpacing: -0.5,
  );

  static TextStyle kpiCrimson(BuildContext context) => GoogleFonts.plusJakartaSans(
    fontSize: 26, fontWeight: FontWeight.w800,
    color: AdminColors.crimsonBright, letterSpacing: -0.5,
  );

  static TextStyle bodyMedium(BuildContext context) => GoogleFonts.inter(
    fontSize: 14, fontWeight: FontWeight.w500,
    color: Theme.of(context).colorScheme.onSurface,
  );

  static TextStyle body(BuildContext context) => GoogleFonts.inter(
    fontSize: 13, fontWeight: FontWeight.w400,
    color: Theme.of(context).colorScheme.onSurfaceVariant,
  );

  static TextStyle caption(BuildContext context) => GoogleFonts.inter(
    fontSize: 12, fontWeight: FontWeight.w400,
    color: Theme.of(context).colorScheme.onSurfaceVariant,
  );

  static TextStyle sectionLabel(BuildContext context) => GoogleFonts.inter(
    fontSize: 11, fontWeight: FontWeight.w700,
    color: Theme.of(context).disabledColor, letterSpacing: 1.2,
  );

  static TextStyle priceMedium(BuildContext context) => GoogleFonts.inter(
    fontSize: 14, fontWeight: FontWeight.w700,
    color: Theme.of(context).brightness == Brightness.dark ? AdminColors.gold : AdminColors.crimsonDeep,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// DECORATION HELPERS
// ─────────────────────────────────────────────────────────────────────────────
abstract class AdminDeco {
  static BoxDecoration card(BuildContext context) => BoxDecoration(
    color: AdminColors.bgCard(context),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: AdminColors.borderDefault(context), width: 1),
    boxShadow: Theme.of(context).brightness == Brightness.light ? [
      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
    ] : null,
  );

  static BoxDecoration cardElevated(BuildContext context) => BoxDecoration(
    color: AdminColors.bgElevated(context),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: AdminColors.borderDefault(context), width: 1),
  );

  static BoxDecoration cardSheet(BuildContext context) => BoxDecoration(
    color: AdminColors.bgCard(context),
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: AdminColors.borderDefault(context), width: 1),
  );

  static BoxDecoration iconContainer(Color color, {double radius = 12}) =>
      BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(radius),
      );

  static BoxDecoration iconGradient(Color color, {double radius = 14}) =>
      BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.65)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(radius),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// ADMIN THEME DATA
// ─────────────────────────────────────────────────────────────────────────────
class AdminTheme {
  
  // ── LIGHT THEME ─────────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);
    const primary = AdminColors.crimson;
    const scaffoldBg = Color(0xFFF8F9FA); // Off-white clean bg

    return base.copyWith(
      scaffoldBackgroundColor: scaffoldBg,
      primaryColor: primary,

      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: primary,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFFFFF1F2),
        onPrimaryContainer: primary,
        secondary: AdminColors.gold,
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFFFEF9C3),
        onSecondaryContainer: Color(0xFF713F12),
        tertiary: AdminColors.teal,
        onTertiary: Colors.white,
        tertiaryContainer: Color(0xFFF0FDFA),
        onTertiaryContainer: AdminColors.teal,
        error: AdminColors.error,
        onError: Colors.white,
        surface: Colors.white,
        onSurface: Color(0xFF1A1A1E),
        onSurfaceVariant: Color(0xFF64748B),
        outline: Color(0xFFE2E8F0),
        outlineVariant: Color(0xFFF1F5F9),
        surfaceContainerHighest: Color(0xFFF1F5F9),
      ),

      textTheme: GoogleFonts.interTextTheme(base.textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: scaffoldBg,
        foregroundColor: Color(0xFF1A1A1E),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1E)),
        iconTheme: IconThemeData(color: Color(0xFF64748B)),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),

      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
      ),
      
      chipTheme: ChipThemeData(
        backgroundColor: Color(0xFFF1F5F9),
        selectedColor: primary,
        labelStyle: const TextStyle(color: Color(0xFF1A1A1E), fontWeight: FontWeight.w600),
        secondaryLabelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  // ── DARK THEME ──────────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    const bgPrimary = Color(0xFF0D0D0F);
    const bgCard = Color(0xFF16161A);
    const bgElevated = Color(0xFF21212A);

    return base.copyWith(
      scaffoldBackgroundColor: bgPrimary,
      primaryColor: AdminColors.crimson,

      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: AdminColors.crimson,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFF2D0711),
        onPrimaryContainer: Colors.white,
        secondary: AdminColors.gold,
        onSecondary: Colors.black,
        secondaryContainer: Color(0xFF261D05),
        onSecondaryContainer: AdminColors.gold,
        tertiary: AdminColors.teal,
        onTertiary: Colors.black,
        error: AdminColors.error,
        onError: Colors.white,
        surface: bgCard,
        onSurface: Color(0xFFF0F0F2),
        onSurfaceVariant: Color(0xFF8A8A9A),
        outline: Color(0xFF2A2A35),
        outlineVariant: Color(0xFF1C1C24),
        surfaceContainerHighest: bgElevated,
      ),

      textTheme: GoogleFonts.interTextTheme(base.textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: bgPrimary,
        foregroundColor: Color(0xFFF0F0F2),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFFF0F0F2)),
        iconTheme: IconThemeData(color: Color(0xFF8A8A9A)),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),

      cardTheme: CardThemeData(
        color: bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF2A2A35), width: 1),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF2A2A35)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF2A2A35)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AdminColors.crimson, width: 1.5),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: bgElevated,
        selectedColor: AdminColors.crimson,
        labelStyle: const TextStyle(color: Color(0xFFF0F0F2), fontWeight: FontWeight.w600),
        secondaryLabelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AdminColors.crimson,
        foregroundColor: Colors.white,
      ),
    );
  }
}
