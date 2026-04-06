import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'theme/app_theme.dart';

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
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
    return MaterialApp(
      scrollBehavior: MyCustomScrollBehavior(),
      title: 'Vị Lai Quán – Quản Lý',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.waiterTheme(),
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
              Text(
                'Truy cập bị từ chối',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
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

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.unknown,
  };
}
