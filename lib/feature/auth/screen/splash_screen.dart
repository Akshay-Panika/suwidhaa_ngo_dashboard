import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constant/app_color.dart';
import '../../main/screen/main_screen.dart';
import 'auth_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 2));
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (!mounted) return;

    if (isLoggedIn) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainScreen()));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AuthScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.volunteer_activism, size: 80, color: Colors.white),
            const SizedBox(height: 20),
            const Text("NGO Admin Panel", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 10),
            Text("Manage your NGO", style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8))),
            const SizedBox(height: 40),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}