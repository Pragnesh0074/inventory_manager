import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:inventory_manager/providers/auth_provider.dart' as ap;
import 'package:inventory_manager/providers/shop_provider.dart';
import 'package:inventory_manager/ui/screens/auth/login_screen.dart';
import 'package:inventory_manager/ui/screens/shop_list_screen.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  await ScreenUtil.ensureScreenSize();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ap.AuthProvider()),
        ChangeNotifierProvider(
          create: (_) {
            final provider = ShopProvider();
            return provider;
          },
        ),
      ],
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Inventory Management',
            home: child,
          );
        },
        child: const AuthGate(),
      ),
    );
  }
}

/// Listens to [AuthProvider] status and routes to [LoginScreen] or [ShopListScreen].
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    // When auth status changes, load shops if authenticated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleAuthChange();
    });
    context.read<ap.AuthProvider>().addListener(_handleAuthChange);
  }

  @override
  void dispose() {
    context.read<ap.AuthProvider>().removeListener(_handleAuthChange);
    super.dispose();
  }

  void _handleAuthChange() {
    final authProvider = context.read<ap.AuthProvider>();
    if (authProvider.status == ap.AuthStatus.authenticated) {
      // Reload shops when user logs in
      context.read<ShopProvider>().initializeData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ap.AuthProvider>(
      builder: (context, authProvider, _) {
        switch (authProvider.status) {
          case ap.AuthStatus.loading:
            // Splash / loading state
            return const Scaffold(
              backgroundColor: Color(0xFFF5F6FA),
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFFFDB462)),
              ),
            );
          case ap.AuthStatus.unauthenticated:
            return const LoginScreen();
          case ap.AuthStatus.authenticated:
            return const ShopListScreen();
        }
      },
    );
  }
}
