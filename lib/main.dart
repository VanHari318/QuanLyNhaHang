import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

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
import 'theme/admin_theme.dart';
import 'providers/admin_theme_provider.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
        ChangeNotifierProvider(create: (_) => AdminThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final adminTheme = context.watch<AdminThemeProvider>();

    // ── DEFAULT THEME (Vị Lai Quán Red) ──────────────────────────────────────
    final defaultColorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFD32F2F),
      brightness: Brightness.light,
    );
    final defaultTheme = ThemeData(
      useMaterial3: true,
      colorScheme: defaultColorScheme,
      textTheme: GoogleFonts.interTextTheme(),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 3,
        backgroundColor: defaultColorScheme.surface,
        foregroundColor: defaultColorScheme.onSurface,
        surfaceTintColor: defaultColorScheme.surfaceTint,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: defaultColorScheme.shadow.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        clipBehavior: Clip.antiAlias,
        color: defaultColorScheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          side: BorderSide(color: defaultColorScheme.primary, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(0, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          elevation: 2,
          shadowColor: defaultColorScheme.shadow.withValues(alpha: 0.2),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: defaultColorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
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
          borderSide: BorderSide(color: defaultColorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 4,
        backgroundColor: defaultColorScheme.primary,
        foregroundColor: defaultColorScheme.onPrimary,
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        selectedTileColor: defaultColorScheme.secondaryContainer,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        side: BorderSide.none,
        selectedColor: defaultColorScheme.primary,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        elevation: 12,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.black87,
      ),
      dividerTheme: DividerThemeData(
        space: 24,
        thickness: 1,
        color: defaultColorScheme.outlineVariant.withValues(alpha: 0.3),
      ),
    );

    final bool isAdmin = auth.user?.role == UserRole.admin;

    return MaterialApp(
      title: 'Vị Lai Quán – Quản Lý',
      debugShowCheckedModeBanner: false,
      theme: isAdmin ? AdminTheme.lightTheme : defaultTheme,
      darkTheme: isAdmin ? AdminTheme.darkTheme : null,
      themeMode: isAdmin ? adminTheme.themeMode : ThemeMode.light,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('vi', 'VN'),
        Locale('en', 'US'),
      ],
      locale: const Locale('vi', 'VN'),
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
