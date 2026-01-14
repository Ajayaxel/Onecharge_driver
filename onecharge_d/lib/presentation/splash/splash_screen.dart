import 'package:flutter/material.dart';
import 'package:onecharge_d/core/storage/token_storage.dart';
import 'package:onecharge_d/presentation/main_navigation_screen.dart';
import 'package:onecharge_d/presentation/login/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // Wait a bit for smooth transition (optional)
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Check if user is logged in
    final isLoggedIn = await TokenStorage.isLoggedIn();
    
    if (!mounted) return;
    
    // Navigate based on auth status
    if (isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'images/logo/onechargelogo.png',
          height: 102,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
