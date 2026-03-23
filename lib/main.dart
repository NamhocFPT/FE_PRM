import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/main_wrapper.dart';
import 'screens/onboarding_screen.dart';

import 'screens/income_setup_screen.dart';
import 'services/auth_service.dart';
import 'services/jarprofile_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '6 Jars App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // Sử dụng màn hình splash để check token
      home: const SplashScreen(),
      routes: {
        '/login': (context) => LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const MainWrapper(),
        '/onboarding': (context) => const OnboardingScreen(),
      },
    );
  }
}

// Màn hình splash để kiểm tra token khi khởi động
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();
  final JarProfileService _jarProfileService = JarProfileService();

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // Đợi một chút để tránh flicker
    await Future.delayed(const Duration(milliseconds: 500));

    // Kiểm tra có token không
    final isLoggedIn = await _authService.isLoggedIn();
    print('DEBUG: isLoggedIn = $isLoggedIn');

    if (!mounted) return;

    if (isLoggedIn) {
      // Đã đăng nhập -> check jar profile
      final userProfile = await _authService.getUserProfile();
      if (userProfile == null) {
        // Token tồn tại nhưng fetch profile fail -> có thể token hết hạn/sai
        // Chuyển về login để user đăng nhập lại
        print('DEBUG: userProfile is null, redirecting to login');
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      final currency = userProfile['currency'] ?? '';
      print('DEBUG: currency = "$currency"');

      if (!mounted) return;

      // Kiểm tra xem đã có Jar Profile chưa để quyết định vào trang chủ hay setup
      final hasActiveProfile = await _jarProfileService.hasActiveProfile();

      if (!mounted) return;

      if (hasActiveProfile) {
        // Đã thiết lập xong -> vào trang chủ
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        // Chưa thiết lập xong -> vào màn hình thiết lập thu nhập
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const IncomeSetupScreen(),
          ),
        );
      }
    } else {
      // Chưa đăng nhập -> vào onboarding
      Navigator.pushReplacementNamed(context, '/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
//