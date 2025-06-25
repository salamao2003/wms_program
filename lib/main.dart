import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:warehouse_management_system/screens/login_screen.dart';
import 'package:warehouse_management_system/screens/main_layout.dart';
import 'package:warehouse_management_system/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: "https://yiqegbzhuxyjygqkaehz.supabase.co",
    anonKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlpcWVnYnpodXh5anlncWthZWh6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTAyNDc3NTksImV4cCI6MjA2NTgyMzc1OX0.ePivHHvtLExB-B8a5F12AzLQd5j7jmHu-LrDt3viGWk",
  );
  runApp(const WMSApp());
}

class WMSApp extends StatelessWidget {
  const WMSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Warehouse Management System',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: const LoginScreen(), // تعيين الشاشة الرئيسية كـ LoginScreen
      routes: {
        '/login': (context) => const LoginScreen(),
        '/main': (context) => const MainLayout(),
      },
    );
  }
}