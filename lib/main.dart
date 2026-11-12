import 'package:flutter/material.dart';
import 'package:get/get.dart'; // 👈 Import Get
import 'core/constant/app_color.dart';
import 'core/router/app_binding.dart';
import 'feature/auth/screen/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp( // 👈 MaterialApp ko GetMaterialApp me badla
      title: 'NGO Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColor.primary,
        scaffoldBackgroundColor: AppColor.background,
      ),
      initialBinding: AppBindings(), // 👈 Initial Binding lagayi
      home: const SplashScreen(),
    );
  }
}