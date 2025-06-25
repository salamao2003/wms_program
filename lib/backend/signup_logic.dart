import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class SignUpLogic {
  final SupabaseClient _supabase = Supabase.instance.client;
  final SupabaseService _supabaseService = SupabaseService();

  /// التحقق من صحة كود الدعوة
  Future<Map<String, dynamic>?> validateInviteCode({
  required String inviteCode,
  required String email,
}) async {
  try {
    print('Validating invite code: $inviteCode for email: $email'); // أضف هذا
    
    final invitation = await _supabaseService.validateInvitation(inviteCode, email);
    
    print('Invitation result: $invitation'); // أضف هذا
    
    return invitation;
  } catch (e) {
    print('Error validating invite code: $e'); // أضف هذا
    return null;
  }
}

  /// تسجيل مستخدم جديد بكود دعوة
  Future<void> handleSignUpWithInvite({
    required String email,
    required String password,
    required String fullName,
    required String inviteCode,
    required BuildContext context,
    required Function(bool) setLoading,
    required Function(String?) setError,
    required Function() onSuccess,
  }) async {
    setLoading(true);
    setError(null);

    try {
      // خطوة 1: التحقق من صحة البيانات
      final validationError = _validateSignUpData(email, password, fullName, inviteCode);
      if (validationError != null) {
        setError(validationError);
        return;
      }

      // خطوة 2: التحقق من كود الدعوة
      final invitation = await validateInviteCode(
        inviteCode: inviteCode,
        email: email,
      );

      if (invitation == null) {
        setError('كود الدعوة غير صحيح أو منتهي الصلاحية');
        return;
      }

      // خطوة 3: تسجيل المستخدم مع الدور
      final assignedRole = await _supabaseService.registerWithInvitation(
        email: email,
        password: password,
        fullName: fullName,
        inviteCode: inviteCode,
      );

      // خطوة 4: عرض رسالة نجاح
      if (context.mounted) {
        _showSuccessMessage(context, assignedRole);
        onSuccess();
      }

    } on AuthException catch (e) {
      setError(_getFriendlyAuthError(e.message));
    } catch (e) {
      setError(_getFriendlyError(e.toString()));
    } finally {
      setLoading(false);
    }
  }

  /// التحقق من صحة البيانات
  String? _validateSignUpData(String email, String password, String fullName, String inviteCode) {
    if (fullName.trim().isEmpty) {
      return 'يرجى إدخال الاسم الكامل';
    }
    
    if (fullName.trim().length < 2) {
      return 'الاسم يجب أن يكون حرفين على الأقل';
    }

    if (email.trim().isEmpty) {
      return 'يرجى إدخال البريد الإلكتروني';
    }

    if (!_isValidEmail(email)) {
      return 'يرجى إدخال بريد إلكتروني صحيح';
    }

    if (password.isEmpty) {
      return 'يرجى إدخال كلمة المرور';
    }

    if (password.length < 6) {
      return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
    }

    if (!_isStrongPassword(password)) {
      return 'كلمة المرور ضعيفة. يجب أن تحتوي على أرقام وحروف';
    }

    if (inviteCode.trim().isEmpty) {
      return 'يرجى إدخال كود الدعوة';
    }

    return null;
  }

  /// التحقق من صحة البريد الإلكتروني
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// التحقق من قوة كلمة المرور
  bool _isStrongPassword(String password) {
    // يجب أن تحتوي على حروف وأرقام على الأقل
    return password.contains(RegExp(r'[A-Za-z]')) && 
           password.contains(RegExp(r'[0-9]'));
  }

  /// ترجمة أخطاء المصادقة
  String _getFriendlyAuthError(String error) {
    if (error.contains('User already registered')) {
      return 'هذا البريد الإلكتروني مسجل بالفعل';
    } else if (error.contains('Password should be at least 6 characters')) {
      return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
    } else if (error.contains('Invalid email')) {
      return 'البريد الإلكتروني غير صحيح';
    } else if (error.contains('Email rate limit exceeded')) {
      return 'تم تجاوز حد الإرسال. حاول مرة أخرى لاحقاً';
    }
    return error;
  }

  /// ترجمة الأخطاء العامة
  String _getFriendlyError(String error) {
    if (error.contains('Invalid or expired invitation')) {
      return 'كود الدعوة غير صحيح أو منتهي الصلاحية';
    } else if (error.contains('Registration failed')) {
      return 'فشل في إنشاء الحساب. حاول مرة أخرى';
    } else if (error.contains('Failed to create invitation')) {
      return 'خطأ في معالجة الدعوة';
    }
    return 'حدث خطأ غير متوقع. حاول مرة أخرى';
  }

  /// عرض رسالة النجاح
  void _showSuccessMessage(BuildContext context, String role) {
    final String roleDisplayName = SupabaseService.getRoleDisplayName(role);
    
    IconData roleIcon;
    Color roleColor;
    
    switch (role) {
      case SupabaseService.ROLE_ADMIN:
        roleIcon = Icons.admin_panel_settings;
        roleColor = Colors.red;
        break;
      case SupabaseService.ROLE_WAREHOUSE_MANAGER:
        roleIcon = Icons.warehouse;
        roleColor = Colors.blue;
        break;
      case SupabaseService.ROLE_PROJECT_MANAGER:
        roleIcon = Icons.analytics;
        roleColor = Colors.green;
        break;
      default:
        roleIcon = Icons.person;
        roleColor = Colors.grey;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(roleIcon, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'تم إنشاء الحساب بنجاح!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'دورك في النظام: $roleDisplayName',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: roleColor,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// معاينة معلومات الدعوة (للتأكد قبل التسجيل)
  Future<Map<String, dynamic>?> previewInvitation({
    required String inviteCode,
    required String email,
  }) async {
    try {
      final invitation = await validateInviteCode(
        inviteCode: inviteCode,
        email: email,
      );

      if (invitation == null) return null;

      // حساب الوقت المتبقي
      final expiresAt = DateTime.parse(invitation['expires_at']);
      final now = DateTime.now();
      final timeLeft = expiresAt.difference(now);

      return {
        'role': invitation['role'],
        'role_display_name': SupabaseService.getRoleDisplayName(invitation['role']),
        'expires_at': expiresAt,
        'time_left_hours': timeLeft.inHours,
        'time_left_days': timeLeft.inDays,
        'is_valid': timeLeft.inMinutes > 0,
      };
    } catch (e) {
      print('Error previewing invitation: $e');
      return null;
    }
  }

  /// التحقق من توفر البريد الإلكتروني
  Future<bool> isEmailAvailable(String email) async {
    try {
      // محاولة تسجيل دخول بكلمة مرور خاطئة للتحقق من وجود الحساب
      await _supabase.auth.signInWithPassword(
        email: email,
        password: 'invalid_password_check_123',
      );
      // إذا لم يحدث خطأ، فالحساب موجود
      return false;
    } on AuthException catch (e) {
      if (e.message.contains('Invalid login credentials')) {
        // الحساب موجود لكن كلمة المرور خاطئة
        return false;
      } else if (e.message.contains('User not found')) {
        // الحساب غير موجود - متاح
        return true;
      }
      // خطأ آخر
      return false;
    } catch (e) {
      // خطأ في الشبكة أو غيره
      return false;
    }
  }

  /// اقتراح أسماء مستخدمين بديلة
  List<String> suggestEmailAlternatives(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return [];

    final username = parts[0];
    final domain = parts[1];

    return [
      '${username}1@$domain',
      '${username}2@$domain',
      '${username}.work@$domain',
      '${username}.official@$domain',
    ];
  }

  /// الحصول على معلومات قوة كلمة المرور
  Map<String, dynamic> getPasswordStrength(String password) {
    int strength = 0;
    List<String> requirements = [];
    List<String> missing = [];

    // طول كلمة المرور
    if (password.length >= 6) {
      strength += 20;
      requirements.add('طول مناسب (6+ أحرف)');
    } else {
      missing.add('6 أحرف على الأقل');
    }

    // وجود أحرف
    if (password.contains(RegExp(r'[A-Za-z]'))) {
      strength += 20;
      requirements.add('يحتوي على حروف');
    } else {
      missing.add('حروف انجليزية');
    }

    // وجود أرقام
    if (password.contains(RegExp(r'[0-9]'))) {
      strength += 20;
      requirements.add('يحتوي على أرقام');
    } else {
      missing.add('أرقام');
    }

    // وجود رموز خاصة
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      strength += 20;
      requirements.add('يحتوي على رموز خاصة');
    } else {
      missing.add('رموز خاصة (!@#\$...)');
    }

    // أحرف كبيرة وصغيرة
    if (password.contains(RegExp(r'[A-Z]')) && password.contains(RegExp(r'[a-z]'))) {
      strength += 20;
      requirements.add('أحرف كبيرة وصغيرة');
    } else {
      missing.add('أحرف كبيرة وصغيرة');
    }

    String strengthLabel;
    Color strengthColor;

    if (strength >= 80) {
      strengthLabel = 'قوية جداً';
      strengthColor = Colors.green;
    } else if (strength >= 60) {
      strengthLabel = 'قوية';
      strengthColor = Colors.lightGreen;
    } else if (strength >= 40) {
      strengthLabel = 'متوسطة';
      strengthColor = Colors.orange;
    } else {
      strengthLabel = 'ضعيفة';
      strengthColor = Colors.red;
    }

    return {
      'strength': strength,
      'label': strengthLabel,
      'color': strengthColor,
      'requirements': requirements,
      'missing': missing,
      'is_strong': strength >= 40,
    };
  }
}