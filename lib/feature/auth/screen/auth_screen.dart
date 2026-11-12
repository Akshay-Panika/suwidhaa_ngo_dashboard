import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constant/app_color.dart';
import '../../../core/widget/flutter_toast.dart';
import '../../main/screen/main_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _emailController = TextEditingController(text: "admin@ngo.com");
  final TextEditingController _passwordController = TextEditingController(text: "admin@123");
  bool _isLoading = false;

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      FlutterToast.error("Please enter email and password");
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));

    if (email == "admin@ngo.com" && password == "admin@123") {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);

      if (!mounted) return;
      FlutterToast.success("Login Successful!");

      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainScreen()));
    } else {
      setState(() => _isLoading = false);
      FlutterToast.error("Invalid Credentials! Use admin@ngo.com / admin@123");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 800) return _buildLoginForm();

          return Row(
            children: [
              Expanded(
                flex: 1,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColor.primary, Color(0xFF004D40)],
                    ),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.volunteer_activism, size: 100, color: Colors.white),
                      SizedBox(height: 24),
                      Text("NGO Admin Panel", style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2)),
                      SizedBox(height: 12),
                      Text("Manage your organization efficiently", style: TextStyle(fontSize: 16, color: Colors.white70)),
                    ],
                  ),
                ),
              ),
              Expanded(flex: 1, child: _buildLoginForm()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoginForm() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(32.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Welcome Back", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColor.textDark)),
              const SizedBox(height: 8),
              const Text("Please sign in to continue.", style: TextStyle(fontSize: 14, color: AppColor.textGrey)),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColor.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColor.primary.withOpacity(0.3)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Demo Credentials:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColor.primary)),
                    SizedBox(height: 4),
                    Text("Email: admin@ngo.com\nPassword: admin@123", style: TextStyle(fontSize: 12, color: AppColor.primary)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text("Email Address", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.email_outlined, color: AppColor.primary),
                  filled: true, fillColor: AppColor.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              const Text("Password", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline, color: AppColor.primary),
                  filled: true, fillColor: AppColor.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("LOGIN", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}