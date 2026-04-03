import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOMER — Café-Lifestyle  |  Warm Coral + Cream
// ─────────────────────────────────────────────────────────────────────────────
abstract class CustomerTheme {
  static const Color primary = Color(0xFFFF6B6B);
  static const Color secondary = Color(0xFFFF8E53);
  static const Color background = Color(0xFFFFF8F0);
  static const Color surface = Colors.white;
  static const Color onPrimary = Colors.white;

  static const LinearGradient appBarGradient = LinearGradient(
    colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFF6B6B), Color(0xFFFF4E4E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static BoxDecoration get navBarDecoration => BoxDecoration(
        color: const Color(0xFFFFF8F0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      );

  static TextStyle get appBarTitle => const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w800,
        fontSize: 20,
        letterSpacing: 0.3,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// CASHIER — FinTech Clean  |  Emerald + Mint White
// ─────────────────────────────────────────────────────────────────────────────
abstract class CashierTheme {
  static const Color primary = Color(0xFF00B894);
  static const Color primaryLight = Color(0xFF00CBA8);
  static const Color background = Color(0xFFF0FFF4);
  static const Color cardAccent = Color(0xFF00B894);
  static const Color surface = Colors.white;

  static const LinearGradient payButtonGradient = LinearGradient(
    colors: [Color(0xFF00B894), Color(0xFF00CBA8)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static BoxDecoration cardDecoration(BuildContext context) => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00B894).withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border(
          left: const BorderSide(color: Color(0xFF00B894), width: 4),
        ),
      );

  static TextStyle get amountStyle => const TextStyle(
        color: Color(0xFF00B894),
        fontWeight: FontWeight.w800,
        fontSize: 18,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// KITCHEN — Dark Command  |  Deep Orange + Charcoal
// ─────────────────────────────────────────────────────────────────────────────
abstract class KitchenTheme {
  static const Color background = Color(0xFF1C1C1E);
  static const Color surface = Color(0xFF2C2C2E);
  static const Color surfaceVariant = Color(0xFF3A3A3C);
  static const Color primary = Color(0xFFFF7043);
  static const Color primaryLight = Color(0xFFFF8A65);
  static const Color onBackground = Color(0xFFF5F5F5);
  static const Color onSurface = Color(0xFFE0E0E0);
  static const Color onSurfaceDim = Color(0xFF9E9E9E);

  static const LinearGradient appBarGradient = LinearGradient(
    colors: [Color(0xFF2C2C2E), Color(0xFF1C1C1E)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient ticketTopAccent = LinearGradient(
    colors: [Color(0xFFFF7043), Color(0xFFFF5722)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static BoxDecoration get ticketDecoration => BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );

  static Color statusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFFFB300);
      case 'preparing':
        return const Color(0xFF42A5F5);
      default:
        return const Color(0xFF9E9E9E);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WAITER — Sky-Fresh  |  Electric Blue + Light Sky
// ─────────────────────────────────────────────────────────────────────────────
abstract class WaiterTheme {
  static const Color primary = Color(0xFF0984E3);
  static const Color primaryLight = Color(0xFF74B9FF);
  static const Color background = Color(0xFFEBF8FF);
  static const Color surface = Colors.white;

  static const LinearGradient appBarGradient = LinearGradient(
    colors: [Color(0xFF0984E3), Color(0xFF74B9FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient summaryBarGradient = LinearGradient(
    colors: [Color(0xFF0984E3), Color(0xFF6C5CE7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static BoxDecoration tableCardDecoration({
    required Color statusColor,
    required bool isSelected,
  }) =>
      BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withValues(alpha: 0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );

  static Color tableStatusColor(String status) {
    switch (status) {
      case 'available':
        return const Color(0xFF00B894);
      case 'occupied':
        return const Color(0xFFFF7675);
      case 'reserved':
        return const Color(0xFFFDAB00);
      default:
        return const Color(0xFF636E72);
    }
  }
}
