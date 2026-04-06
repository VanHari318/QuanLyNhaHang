import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
<<<<<<< HEAD
=======
import 'dart:ui';
>>>>>>> 6690387 (sua loi)

import 'providers/auth_provider.dart';
import 'providers/menu_provider.dart';
import 'providers/order_provider.dart';
import 'providers/table_provider.dart';
import 'providers/inventory_provider.dart';
import 'providers/chatbot_provider.dart';
import 'providers/cart_provider.dart';
import 'models/user_model.dart';
import 'screens/auth/login_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/waiter/waiter_screen.dart';
import 'screens/kitchen/kitchen_screen.dart';
import 'screens/cashier/cashier_screen.dart';
import 'screens/customer/customer_menu_page.dart';
import 'screens/customer/customer_main_screen.dart';
import 'utils/logout_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
<<<<<<< HEAD
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
=======
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
>>>>>>> 6690387 (sua loi)
  await dotenv.load(fileName: ".env.local");
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MenuProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => TableProvider()),
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
        ChangeNotifierProvider(create: (_) => ChatbotProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
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
<<<<<<< HEAD
      seedColor: const Color(0xFFD32F2F), // Đỏ – Vị Lai Quán primary
=======
      seedColor: const Color(0xFFB71C1C), // Đỏ sâu – Vị Lai Quán primary
>>>>>>> 6690387 (sua loi)
      brightness: Brightness.light,
    );

    return MaterialApp(
<<<<<<< HEAD
=======
      scrollBehavior: MyCustomScrollBehavior(),
>>>>>>> 6690387 (sua loi)
      title: 'Vị Lai Quán – Quản Lý',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        textTheme: GoogleFonts.montserratTextTheme(),

        // AppBar – MD3 uses surface as default background
        appBarTheme: AppBarTheme(
<<<<<<< HEAD
          centerTitle: false,
=======
          centerTitle: true,
>>>>>>> 6690387 (sua loi)
          elevation: 0,
          scrolledUnderElevation: 3,
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.onSurface,
          surfaceTintColor: colorScheme.surfaceTint,
        ),

        // Card – Haidilao Style: High rounded corners
        cardTheme: CardThemeData(
          elevation: 2,
<<<<<<< HEAD
          shadowColor: colorScheme.shadow.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          clipBehavior: Clip.antiAlias,
          color: colorScheme.surface,
          surfaceTintColor: Colors.transparent, // Disable surface tint for cleaner red-white look
=======
          shadowColor: colorScheme.shadow.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          color: colorScheme.surface,
          surfaceTintColor: Colors.transparent,
>>>>>>> 6690387 (sua loi)
        ),

        // FilledButton (primary action)
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 54), // Larger buttons
<<<<<<< HEAD
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
=======
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
>>>>>>> 6690387 (sua loi)
          ),
        ),

        // OutlinedButton (secondary)
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 54),
<<<<<<< HEAD
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
=======
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
>>>>>>> 6690387 (sua loi)
            side: BorderSide(color: colorScheme.primary, width: 1.5),
          ),
        ),

        // ElevatedButton
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(0, 54),
<<<<<<< HEAD
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
=======
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
>>>>>>> 6690387 (sua loi)
            elevation: 2,
            shadowColor: colorScheme.shadow.withValues(alpha: 0.2),
          ),
        ),

        // InputDecoration – Premium Rounded style
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
          ),
<<<<<<< HEAD
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
=======
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 18,
          ),
>>>>>>> 6690387 (sua loi)
        ),

        // FAB
        floatingActionButtonTheme: FloatingActionButtonThemeData(
<<<<<<< HEAD
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
=======
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
>>>>>>> 6690387 (sua loi)
          elevation: 4,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
        ),

<<<<<<< HEAD
        // ListTile
        listTileTheme: ListTileThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          selectedTileColor: colorScheme.secondaryContainer,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
=======
        // Make scaffold background slightly off-white for contrast
        scaffoldBackgroundColor: colorScheme.background,

        // ListTile
        listTileTheme: ListTileThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          selectedTileColor: colorScheme.secondaryContainer,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 8,
          ),
>>>>>>> 6690387 (sua loi)
        ),

        // Chip
        chipTheme: ChipThemeData(
<<<<<<< HEAD
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          side: BorderSide.none,
          selectedColor: colorScheme.primary,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
=======
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: BorderSide.none,
          selectedColor: colorScheme.primary,
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
>>>>>>> 6690387 (sua loi)
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),

        // Dialog – Haidilao Style: extra rounded
        dialogTheme: DialogThemeData(
<<<<<<< HEAD
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
=======
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
>>>>>>> 6690387 (sua loi)
          elevation: 12,
        ),

        // SnackBar
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
<<<<<<< HEAD
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
=======
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
>>>>>>> 6690387 (sua loi)
          backgroundColor: Colors.black87,
        ),

        // Divider
        dividerTheme: DividerThemeData(
<<<<<<< HEAD
          space: 24, 
          thickness: 1, 
=======
          space: 24,
          thickness: 1,
>>>>>>> 6690387 (sua loi)
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
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
      case UserRole.customer:
        return const CustomerMainScreen();
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
<<<<<<< HEAD
              Text('Truy cập bị từ chối',
                  style: Theme.of(context).textTheme.headlineSmall),
=======
              Text(
                'Truy cập bị từ chối',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
>>>>>>> 6690387 (sua loi)
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
<<<<<<< HEAD
=======

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.unknown,
  };
}
>>>>>>> 6690387 (sua loi)
