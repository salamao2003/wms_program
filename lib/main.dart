import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:warehouse_management_system/l10n/app_localizations.dart';
import 'package:warehouse_management_system/screens/login_screen.dart';
import 'package:warehouse_management_system/screens/main_layout.dart';
import 'package:warehouse_management_system/screens/splash_screen.dart';
import 'package:warehouse_management_system/services/language_service.dart';
import 'package:warehouse_management_system/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: "https://yiqegbzhuxyjygqkaehz.supabase.co",
    anonKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlpcWVnYnpodXh5anlncWthZWh6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTAyNDc3NTksImV4cCI6MjA2NTgyMzc1OX0.ePivHHvtLExB-B8a5F12AzLQd5j7jmHu-LrDt3viGWk",
  );
  
  // Initialize language service
  final languageService = LanguageService();
  await languageService.initialize();
  
  runApp(WMSApp(languageService: languageService));
}

class WMSApp extends StatelessWidget {
  final LanguageService languageService;
  
  const WMSApp({super.key, required this.languageService});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: languageService,
      child: Consumer<LanguageService>(
        builder: (context, languageService, child) {
          return MaterialApp(
            title: 'Warehouse Management System',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            debugShowCheckedModeBanner: false,
            locale: languageService.currentLocale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const SplashScreen(),
            routes: {
              '/login': (context) => const LoginScreen(),
              '/main': (context) => const MainLayout(),
            },
          );
        },
      ),
    );
  }
}