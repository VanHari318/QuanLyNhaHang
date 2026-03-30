import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ADMIN DESIGN SYSTEM – Vị Lai Quán Premium Dark
// Inspired by: Haidilao brand × Linear / Stripe / Vercel dashboard aesthetics
// ─────────────────────────────────────────────────────────────────────────────

abstract class AdminColors {
  // ── Backgrounds ────────────────────────────────────────────────────────────
  static const Color bgPrimary  = Color(0xFF0D0D0F);   // Main screen background
  static const Color bgCard     = Color(0xFF16161A);   // Card / sheet surface
  static const Color bgElevated = Color(0xFF21212A);   // Modal, hover, elevated
  static const Color bgOverlay  = Color(0xCC000000);   // Scrim

  // ── Haidilao Crimson ───────────────────────────────────────────────────────
  static const Color crimson       = Color(0xFFC41230);
  static const Color crimsonBright = Color(0xFFE5172E);
  static const Color crimsonDeep   = Color(0xFF8B0D22);
  static const Color crimsonSubtle = Color(0xFF2D0711);
  static const Color crimsonGlow   = Color(0x33C41230);

  // ── Gold Accent ────────────────────────────────────────────────────────────
  static const Color gold       = Color(0xFFD4A832);
  static const Color goldLight  = Color(0xFFF0C84A);
  static const Color goldSubtle = Color(0xFF261D05);

  // ── Text ───────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFF0F0F2);
  static const Color textSecondary = Color(0xFF8A8A9A);
  static const Color textMuted     = Color(0xFF48485A);

  // ── Borders ────────────────────────────────────────────────────────────────
  static const Color borderDefault = Color(0xFF2A2A35);
  static const Color borderMuted   = Color(0xFF1C1C24);

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

  static TextStyle get displayLarge => GoogleFonts.plusJakartaSans(
    fontSize: 32, fontWeight: FontWeight.w800,
    color: AdminColors.textPrimary, letterSpacing: -1.0,
  );

  static TextStyle get h1 => GoogleFonts.plusJakartaSans(
    fontSize: 22, fontWeight: FontWeight.w800,
    color: AdminColors.textPrimary, letterSpacing: -0.4,
  );

  static TextStyle get h2 => GoogleFonts.plusJakartaSans(
    fontSize: 17, fontWeight: FontWeight.w700,
    color: AdminColors.textPrimary, letterSpacing: -0.3,
  );

  static TextStyle get h3 => GoogleFonts.inter(
    fontSize: 14, fontWeight: FontWeight.w700,
    color: AdminColors.textPrimary,
  );

  /// Gold KPI number – large
  static TextStyle get kpiLarge => GoogleFonts.plusJakartaSans(
    fontSize: 26, fontWeight: FontWeight.w800,
    color: AdminColors.gold, letterSpacing: -0.5,
  );

  /// Crimson KPI variant
  static TextStyle get kpiCrimson => GoogleFonts.plusJakartaSans(
    fontSize: 26, fontWeight: FontWeight.w800,
    color: AdminColors.crimsonBright, letterSpacing: -0.5,
  );

  static TextStyle get bodyMedium => GoogleFonts.inter(
    fontSize: 14, fontWeight: FontWeight.w500,
    color: AdminColors.textPrimary,
  );

  static TextStyle get body => GoogleFonts.inter(
    fontSize: 13, fontWeight: FontWeight.w400,
    color: AdminColors.textSecondary,
  );

  static TextStyle get caption => GoogleFonts.inter(
    fontSize: 12, fontWeight: FontWeight.w400,
    color: AdminColors.textSecondary,
  );

  /// ALL-CAPS label for section headers
  static TextStyle get sectionLabel => GoogleFonts.inter(
    fontSize: 11, fontWeight: FontWeight.w700,
    color: AdminColors.textMuted, letterSpacing: 1.2,
  );

  static TextStyle get chip => GoogleFonts.inter(
    fontSize: 12, fontWeight: FontWeight.w600,
    color: AdminColors.textPrimary, letterSpacing: 0.1,
  );

  static TextStyle get chipActive => GoogleFonts.inter(
    fontSize: 12, fontWeight: FontWeight.w700,
    color: Colors.white, letterSpacing: 0.1,
  );

  static TextStyle get priceMedium => GoogleFonts.inter(
    fontSize: 14, fontWeight: FontWeight.w700,
    color: AdminColors.gold,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// DECORATION HELPERS
// ─────────────────────────────────────────────────────────────────────────────
abstract class AdminDeco {
  static BoxDecoration get card => BoxDecoration(
    color: AdminColors.bgCard,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: AdminColors.borderDefault, width: 1),
  );

  static BoxDecoration get cardElevated => BoxDecoration(
    color: AdminColors.bgElevated,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: AdminColors.borderDefault, width: 1),
  );

  static BoxDecoration get cardSheet => BoxDecoration(
    color: AdminColors.bgCard,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: AdminColors.borderDefault, width: 1),
  );

  static BoxDecoration iconContainer(Color color, {double radius = 12}) =>
      BoxDecoration(
        color: color.withValues(alpha: 0.14),
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

  static List<BoxShadow> get crimsonGlow => [
        BoxShadow(
          color: AdminColors.crimson.withValues(alpha: 0.22),
          blurRadius: 18, spreadRadius: -3, offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.35),
          blurRadius: 12, offset: const Offset(0, 4),
        ),
      ];
}

// ─────────────────────────────────────────────────────────────────────────────
// ADMIN THEME DATA (dark, non-MD3 feel but with M3 ColorScheme for compat)
// ─────────────────────────────────────────────────────────────────────────────
class AdminTheme {
  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: AdminColors.bgPrimary,
      primaryColor: AdminColors.crimson,

      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        // Primary – Crimson
        primary: AdminColors.crimson,
        onPrimary: Colors.white,
        primaryContainer: AdminColors.crimsonSubtle,
        onPrimaryContainer: AdminColors.textPrimary,
        // Secondary – Gold
        secondary: AdminColors.gold,
        onSecondary: Colors.black,
        secondaryContainer: AdminColors.goldSubtle,
        onSecondaryContainer: AdminColors.gold,
        // Tertiary – Teal
        tertiary: AdminColors.teal,
        onTertiary: Colors.black,
        tertiaryContainer: Color(0xFF092621),
        onTertiaryContainer: AdminColors.teal,
        // Error
        error: AdminColors.error,
        onError: Colors.white,
        errorContainer: Color(0xFF3B0A0A),
        onErrorContainer: AdminColors.error,
        // Surface
        surface: AdminColors.bgCard,
        onSurface: AdminColors.textPrimary,
        onSurfaceVariant: AdminColors.textSecondary,
        // Outline
        outline: AdminColors.borderDefault,
        outlineVariant: AdminColors.borderMuted,
        // Misc
        shadow: Colors.black,
        scrim: Colors.black,
        inverseSurface: AdminColors.textPrimary,
        onInverseSurface: AdminColors.bgPrimary,
        inversePrimary: AdminColors.crimsonBright,
        surfaceTint: Colors.transparent,
        // Surface containers
        surfaceContainerHighest: AdminColors.bgElevated,
        surfaceContainerHigh: Color(0xFF1E1E28),
        surfaceContainer: AdminColors.bgCard,
        surfaceContainerLow: AdminColors.bgCard,
        surfaceContainerLowest: AdminColors.bgPrimary,
      ),

      // Typography
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        displayLarge: AdminText.displayLarge,
        headlineLarge: AdminText.h1,
        headlineMedium: AdminText.h2,
        titleLarge: AdminText.h3,
        bodyLarge: AdminText.bodyMedium,
        bodyMedium: AdminText.body,
        bodySmall: AdminText.caption,
        labelSmall: AdminText.sectionLabel,
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: AdminColors.bgPrimary,
        foregroundColor: AdminColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AdminText.h2,
        iconTheme: const IconThemeData(color: AdminColors.textSecondary, size: 22),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),

      // Card
      cardTheme: CardThemeData(
        color: AdminColors.bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AdminColors.borderDefault, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        surfaceTintColor: Colors.transparent,
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AdminColors.borderDefault,
        thickness: 1,
        space: 1,
      ),

      // Input
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AdminColors.bgElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AdminColors.borderDefault),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AdminColors.borderDefault),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AdminColors.crimson, width: 1.5),
        ),
        hintStyle: AdminText.body,
        labelStyle: AdminText.caption,
        prefixIconColor: AdminColors.textMuted,
        suffixIconColor: AdminColors.textMuted,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      // Icon
      iconTheme: const IconThemeData(color: AdminColors.textSecondary),

      // ListTile
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        textColor: AdminColors.textPrimary,
        iconColor: AdminColors.textSecondary,
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: AdminColors.bgElevated,
        selectedColor: AdminColors.crimsonSubtle,
        disabledColor: AdminColors.bgElevated,
        labelStyle: AdminText.chip,
        secondaryLabelStyle: AdminText.chipActive.copyWith(color: AdminColors.crimson),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: const BorderSide(color: AdminColors.borderDefault),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        brightness: Brightness.dark,
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: AdminColors.bgElevated,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AdminColors.borderDefault),
        ),
        titleTextStyle: AdminText.h2,
        contentTextStyle: AdminText.body,
        elevation: 8,
      ),

      // BottomSheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AdminColors.bgCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        dragHandleColor: AdminColors.borderDefault,
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AdminColors.bgElevated,
        contentTextStyle: AdminText.bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AdminColors.borderDefault),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 8,
      ),

      // FAB
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AdminColors.crimson,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
      ),

      // PopupMenu
      popupMenuTheme: PopupMenuThemeData(
        color: AdminColors.bgElevated,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AdminColors.borderDefault),
        ),
        textStyle: AdminText.body,
        elevation: 8,
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AdminColors.crimsonBright;
          return AdminColors.textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AdminColors.crimsonSubtle;
          return AdminColors.bgElevated;
        }),
      ),

      // ProgressIndicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AdminColors.crimson,
      ),
    );
  }
}
