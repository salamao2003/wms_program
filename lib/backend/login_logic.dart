import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/main_layout.dart';
import '../backend/supabase_service.dart';

class LoginLogic {
  final SupabaseClient _supabase = Supabase.instance.client;
  final SupabaseService _supabaseService = SupabaseService();

  Future<AuthResponse> signInWithPassword(String email, String password) async {
    return await _supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  Future<void> resetPasswordForEmail(String email) async {
    await _supabase.auth.resetPasswordForEmail(email.trim());
  }

  String getFriendlyError(String error) {
    if (error.contains('Invalid login credentials')) {
      return 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
    } else if (error.contains('Email not confirmed')) {
      return 'يرجى تأكيد البريد الإلكتروني أولاً';
    } else if (error.contains('Too many requests')) {
      return 'محاولات كثيرة. يرجى المحاولة لاحقاً';
    } else if (error.contains('User not found')) {
      return 'المستخدم غير موجود في النظام';
    } else if (error.contains('No role assigned')) {
      return 'لم يتم تعيين دور لهذا المستخدم. تواصل مع الإدارة';
    }
    return error;
  }

  Future<void> handleSignIn({
    required String email,
    required String password,
    required BuildContext context,
    required Function(bool) setLoading,
    required Function(String?) setError,
  }) async {
    if (email.isEmpty || password.isEmpty) return;

    setLoading(true);
    setError(null);

    try {
      // خطوة 1: تسجيل الدخول
      final response = await signInWithPassword(email, password);

      if (response.session != null && response.user != null) {
        
        // خطوة 2: التحقق من وجود دور للمستخدم
        final userRole = await _supabaseService.getCurrentUserRole();
        
        if (userRole == null) {
          // المستخدم ليس له دور - تسجيل خروج
          await _supabase.auth.signOut();
          setError('لم يتم تعيين دور لهذا المستخدم. تواصل مع الإدارة');
          return;
        }

        // خطوة 3: الحصول على معلومات المستخدم الكاملة
        final userWithRole = await _supabaseService.getCurrentUserWithRole();
        
        if (userWithRole == null) {
          await _supabase.auth.signOut();
          setError('خطأ في جلب بيانات المستخدم');
          return;
        }

        // خطوة 4: حفظ معلومات المستخدم محلياً (optional)
        await _saveUserDataLocally(userWithRole);

        // خطوة 5: عرض رسالة ترحيب
        if (context.mounted) {
          _showWelcomeMessage(context, userWithRole);
          
          // خطوة 6: التوجه للصفحة الرئيسية
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MainLayout()),
          );
        }
      } else {
        throw Exception('فشل تسجيل الدخول: لم يتم إنشاء جلسة');
      }
    } on AuthException catch (e) {
      setError(getFriendlyError(e.message));
    } catch (e) {
      setError(getFriendlyError(e.toString()));
    } finally {
      setLoading(false);
    }
  }

  Future<void> handleResetPassword({
    required String email,
    required BuildContext context,
  }) async {
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال بريد إلكتروني صحيح')),
      );
      return;
    }

    try {
      await resetPasswordForEmail(email);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم إرسال رابط إعادة تعيين كلمة المرور إلى $email'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إرسال الرابط: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// حفظ بيانات المستخدم محلياً
  Future<void> _saveUserDataLocally(Map<String, dynamic> userData) async {
    // يمكن استخدام SharedPreferences أو Hive لحفظ البيانات محلياً
    // هذا مفيد للوصول السريع للدور بدون استعلام قاعدة البيانات
    try {
      // مثال باستخدام SharedPreferences (يتطلب إضافة package)
      /*
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_role', userData['role']);
      await prefs.setString('user_name', userData['full_name'] ?? '');
      await prefs.setString('user_email', userData['email'] ?? '');
      */
      
      print('User data saved locally: ${userData['role']}');
    } catch (e) {
      print('Error saving user data locally: $e');
    }
  }

  /// عرض رسالة ترحيب حسب الدور
  void _showWelcomeMessage(BuildContext context, Map<String, dynamic> userData) {
    final String role = userData['role'];
    final String userName = userData['full_name'] ?? userData['email'] ?? '';
    
    String welcomeMessage;
    Color messageColor;
    IconData messageIcon;

    switch (role) {
      case SupabaseService.ROLE_ADMIN:
        welcomeMessage = 'مرحباً $userName\nأهلاً بك في لوحة الإدارة';
        messageColor = Colors.red;
        messageIcon = Icons.admin_panel_settings;
        break;
      case SupabaseService.ROLE_WAREHOUSE_MANAGER:
        welcomeMessage = 'مرحباً $userName\nأهلاً بك في إدارة المخازن';
        messageColor = Colors.blue;
        messageIcon = Icons.warehouse;
        break;
      case SupabaseService.ROLE_PROJECT_MANAGER:
        welcomeMessage = 'مرحباً $userName\nأهلاً بك في متابعة المشاريع';
        messageColor = Colors.green;
        messageIcon = Icons.analytics;
        break;
      default:
        welcomeMessage = 'مرحباً $userName';
        messageColor = Colors.grey;
        messageIcon = Icons.person;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(messageIcon, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                welcomeMessage,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: messageColor,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// التحقق من حالة تسجيل الدخول والدور
  Future<Map<String, dynamic>?> checkAuthStatus() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final userWithRole = await _supabaseService.getCurrentUserWithRole();
      return userWithRole;
    } catch (e) {
      print('Error checking auth status: $e');
      return null;
    }
  }

  /// تسجيل الخروج
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      // مسح البيانات المحلية
      await _clearLocalData();
    } catch (e) {
      print('Error signing out: $e');
      throw Exception('خطأ في تسجيل الخروج');
    }
  }

  /// مسح البيانات المحلية
  Future<void> _clearLocalData() async {
    try {
      // مسح SharedPreferences
      /*
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_role');
      await prefs.remove('user_name');
      await prefs.remove('user_email');
      */
      
      print('Local data cleared');
    } catch (e) {
      print('Error clearing local data: $e');
    }
  }

  /// التحقق من صحة البيانات
  bool validateLoginData(String email, String password) {
    if (email.isEmpty) return false;
    if (password.isEmpty) return false;
    if (!email.contains('@')) return false;
    if (password.length < 6) return false;
    return true;
  }

  /// الحصول على رسالة خطأ التحقق
  String? getValidationError(String email, String password) {
    if (email.isEmpty) return 'يرجى إدخال البريد الإلكتروني';
    if (!email.contains('@')) return 'يرجى إدخال بريد إلكتروني صحيح';
    if (password.isEmpty) return 'يرجى إدخال كلمة المرور';
    if (password.length < 6) return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
    return null;
  }

  /// التحقق من انتهاء جلسة المستخدم
  bool get isSessionValid {
    final session = _supabase.auth.currentSession;
    if (session == null) return false;
    
    final expiresAt = DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000);
    return DateTime.now().isBefore(expiresAt);
  }

  /// تجديد الجلسة
  Future<bool> refreshSession() async {
    try {
      final response = await _supabase.auth.refreshSession();
      return response.session != null;
    } catch (e) {
      print('Error refreshing session: $e');
      return false;
    }
  }
}