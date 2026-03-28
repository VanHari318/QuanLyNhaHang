import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/menu_provider.dart';
import 'providers/order_provider.dart';
import 'providers/table_provider.dart';
import 'providers/inventory_provider.dart';
import 'providers/chatbot_provider.dart';
import 'models/user_model.dart';
import 'screens/login_screen.dart';
import 'screens/admin_dashboard.dart';
import 'screens/waiter_screen.dart';
import 'screens/kitchen_screen.dart';
import 'screens/cashier_screen.dart';
import 'screens/customer_menu_page.dart';
import 'utils/logout_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MenuProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => TableProvider()),
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
        ChangeNotifierProvider(create: (_) => ChatbotProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Material Design 3 – full theme configuration
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFD32F2F), // Đỏ – Vị Lai Quán primary
      brightness: Brightness.light,
    );

    return MaterialApp(
      title: 'Vị Lai Quán – Quản Lý',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        fontFamily: 'Roboto',

        // AppBar – MD3 uses surface as default background
        appBarTheme: AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 3,
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.onSurface,
          surfaceTintColor: colorScheme.surfaceTint,
        ),

        // Card – MD3 elevated card
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
          color: colorScheme.surface,
          surfaceTintColor: colorScheme.surfaceTint,
        ),

        // FilledButton (primary action)
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),

        // OutlinedButton (secondary)
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),

        // ElevatedButton
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(0, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 1,
          ),
        ),

        // InputDecoration – MD3 filled style
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),

        // FAB
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: colorScheme.primaryContainer,
          foregroundColor: colorScheme.onPrimaryContainer,
        ),

        // ListTile
        listTileTheme: ListTileThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          selectedTileColor: colorScheme.secondaryContainer,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        ),

        // Chip
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          side: BorderSide.none,
          selectedColor: colorScheme.primaryContainer,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),

        // Dialog – MD3 rounded 28px
        dialogTheme: DialogThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          elevation: 6,
        ),

        // SnackBar
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),

        // Divider
        dividerTheme: const DividerThemeData(space: 1, thickness: 1),
      ),
      home: const _RouterEntry(),
    );
  }
}

/// Entry point: kiểm tra URL query để quyết định mở trang nào
class _RouterEntry extends StatelessWidget {
  const _RouterEntry();

  @override
  Widget build(BuildContext context) {
    // Đọc URL params (Flutter Web)
    final uri = Uri.base;
    final tableId = uri.queryParameters['tableId'];
    final sessionIdParam = uri.queryParameters['sessionId'];

    if (tableId != null && tableId.isNotEmpty) {
      // Khách quét QR → mở trang menu không cần đăng nhập
      final sessionId = (sessionIdParam != null && sessionIdParam.isNotEmpty)
          ? sessionIdParam
          : _buildSessionId(tableId);
      return CustomerMenuPage(tableId: tableId, sessionId: sessionId);
    }

    // Nhân viên → auth flow bình thường
    return const AuthWrapper();
  }

  String _buildSessionId(String tableId) {
    final now = DateTime.now();
    final d = now.day.toString().padLeft(2, '0');
    final mo = now.month.toString().padLeft(2, '0');
    final h = now.hour.toString().padLeft(2, '0');
    final mi = now.minute.toString().padLeft(2, '0');
    return '${tableId}_${now.year}$mo${d}_$h$mi';
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.user == null) {
      return const LoginScreen();
    }

    switch (authProvider.user!.role) {
      case UserRole.admin:
        return const AdminDashboard();
      case UserRole.waiter:
        return const WaiterScreen();
      case UserRole.chef:
        return const KitchenScreen();
      case UserRole.cashier:
        return const CashierScreen();
      default:
        return _AccessDeniedScreen();
    }
  }
}

class _AccessDeniedScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline_rounded, size: 72, color: cs.error),
              const SizedBox(height: 24),
              Text('Truy cập bị từ chối',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              const Text(
                'Tài khoản đang chờ Admin phê duyệt.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Đăng xuất'),
                onPressed: () => LogoutHelper.showLogoutDialog(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
