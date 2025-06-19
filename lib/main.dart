import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:warehouse_management_system/backend/supabase_service.dart';
import 'package:warehouse_management_system/screens/login_screen.dart';
import 'package:warehouse_management_system/screens/main_layout.dart';
import 'package:warehouse_management_system/theme/app_theme.dart';

Future<void> main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  

  // Initialize Supabase
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
    // Get the Supabase client instance
    final supabase = Supabase.instance.client;

    return MaterialApp(
      title: 'Warehouse Management System',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      // Use StreamBuilder to listen to auth state changes
      home: StreamBuilder<AuthState>(
        stream: supabase.auth.onAuthStateChange,
        builder: (context, snapshot) {
          // Check connection state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // Get the current session
          final session = supabase.auth.currentSession;

          // If user is authenticated, show main layout
          if (session != null) {
            return const MainLayout();
          }

          // Otherwise, show login screen
          return const LoginScreen();
        },
      ),
      // Define routes
      routes: {
        '/login': (context) => const LoginScreen(),
        '/main': (context) => const MainLayout(),
      },
    );
  }
}