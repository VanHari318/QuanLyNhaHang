import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/menu_provider.dart';
import 'providers/order_provider.dart';
import 'providers/table_provider.dart';
import 'models/user_model.dart';
import 'screens/login_screen.dart';
import 'screens/admin_dashboard.dart';
import 'screens/waiter_screen.dart';
import 'screens/kitchen_screen.dart';
import 'screens/cashier_screen.dart';
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
      title: 'Restaurant Management',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
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

    // Redirect based on role
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
        return Scaffold(
          appBar: AppBar(
            title: const Text('Access Denied'),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => LogoutHelper.showLogoutDialog(context),
              ),
            ],
          ),
          body: const Center(
            child: Text(
              'Your account is pending approval by Admin.\nPlease contact your manager.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ),
        );
    }
  }
}
