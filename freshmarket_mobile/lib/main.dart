import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'features/main/presentation/pages/main_layout.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/catalog/presentation/pages/admin_product_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Cek memori HP apakah ada user yang masih login
  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  final role = prefs.getString('role') ?? 'customer';

  // Tentukan halaman pertama
  Widget initialPage = const LoginPage();
  if (isLoggedIn) {
    if (role == 'admin') {
      initialPage = const AdminProductPage();
    } else {
      initialPage = const MainLayout();
    }
  }

  runApp(MyApp(initialPage: initialPage));
}

class MyApp extends StatelessWidget {
  final Widget initialPage;
  const MyApp({super.key, required this.initialPage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FreshMarket Mobile',
      theme: AppTheme.lightTheme,
      home: initialPage, // Langsung masuk tanpa login jika sudah ada sesi
      debugShowCheckedModeBanner: false,
    );
  }
}