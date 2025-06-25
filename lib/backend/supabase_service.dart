import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  SupabaseClient get client => _client;

  Future<void> initialize() async {
    await Supabase.initialize(
      url: 'https://yiqegbzhuxyjygqkaehz.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlpcWVnYnpodXh5anlncWthZWh6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTAyNDc3NTksImV4cCI6MjA2NTgyMzc1OX0.ePivHHvtLExB-B8a5F12AzLQd5j7jmHu-LrDt3viGWk',
    );
  }

  // ====================== USER ROLES ======================

  /// الحصول على دور المستخدم الحالي
  Future<String?> getCurrentUserRole() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;

      final response = await _client
          .from('user_roles')
          .select('role')
          .eq('user_id', user.id)
          .single();

      return response['role'];
    } catch (e) {
      print('Error getting user role: $e');
      return null;
    }
  }

  /// التحقق من وجود صلاحيات معينة
  Future<bool> hasPermission(List<String> allowedRoles) async {
    final userRole = await getCurrentUserRole();
    return userRole != null && allowedRoles.contains(userRole);
  }

  /// التحقق إذا كان المستخدم Admin
  Future<bool> isAdmin() async {
    return await hasPermission(['admin']);
  }

  /// التحقق إذا كان المستخدم Warehouse Manager
  Future<bool> isWarehouseManager() async {
    return await hasPermission(['warehouse_manager']);
  }

  /// التحقق إذا كان المستخدم Project Manager
  Future<bool> isProjectManager() async {
    return await hasPermission(['project_manager']);
  }

  /// الحصول على معلومات المستخدم مع الدور
  Future<Map<String, dynamic>?> getCurrentUserWithRole() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;

      final roleResponse = await _client
          .from('user_roles')
          .select('role, created_at')
          .eq('user_id', user.id)
          .single();

      return {
        'id': user.id,
        'email': user.email,
        'full_name': user.userMetadata?['full_name'],
        'role': roleResponse['role'],
        'role_created_at': roleResponse['created_at'],
        'auth_created_at': user.createdAt,
      };
    } catch (e) {
      print('Error getting user with role: $e');
      return null;
    }
  }

  // ====================== INVITATIONS ======================

  /// إنشاء دعوة جديدة (Admin فقط)
  Future<String?> createInvitation({
    required String email,
    required String role,
  }) async {
    try {
      // التحقق من أن المستخدم admin
      if (!await isAdmin()) {
        throw Exception('Only admins can create invitations');
      }

      final response = await _client.rpc('invite_user', params: {
        'target_email': email,
        'target_role': role,
      });

      return response['invite_code'];
    } catch (e) {
      print('Error creating invitation: $e');
      throw Exception('Failed to create invitation: ${e.toString()}');
    }
  }

  /// التحقق من صحة كود الدعوة
  /// التحقق من صحة كود الدعوة
Future<Map<String, dynamic>?> validateInvitation(String inviteCode, String email) async {
  try {
    print('Checking invitation with code: $inviteCode, email: $email');
    
    final response = await _client
        .from('invitations')
        .select('role, expires_at')
        .eq('code', inviteCode)
        .eq('email', email)
        .gt('expires_at', DateTime.now().toIso8601String())
        .isFilter('used_at', null);
        // أزلنا .single() من هنا!
    
    print('Database response: $response');
    print('Response type: ${response.runtimeType}');
    print('Response length: ${response.length}');
    
    // التحقق من وجود نتائج
    if (response == null || response.isEmpty) {
      print('No matching invitation found');
      return null;
    }
    
    // أخذ أول نتيجة
    final invitation = response.first;
    print('Found invitation: $invitation');
    
    return {
      'role': invitation['role'],
      'expires_at': invitation['expires_at'],
    };
  } catch (e) {
    print('Error validating invitation: $e');
    return null;
  }
}

  /// تسجيل مستخدم بكود دعوة
  Future<String> registerWithInvitation({
    required String email,
    required String password,
    required String fullName,
    required String inviteCode,
  }) async {
    try {
      // التحقق من الدعوة أولاً
      final invitation = await validateInvitation(inviteCode, email);
      if (invitation == null) {
        throw Exception('Invalid or expired invitation code');
      }

      // تسجيل المستخدم
      final authResponse = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );

      if (authResponse.user == null) {
        throw Exception('Failed to create user account');
      }

      // إضافة الدور للمستخدم باستخدام الـ function
      await _client.rpc('register_with_invite', params: {
        'invite_code': inviteCode,
        'user_email': email,
      });

      return invitation['role'];
    } catch (e) {
      print('Error registering with invitation: $e');
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  /// الحصول على جميع الدعوات المعلقة (Admin فقط)
  Future<List<Map<String, dynamic>>> getPendingInvitations() async {
    try {
      if (!await isAdmin()) {
        throw Exception('Only admins can view invitations');
      }

      final response = await _client
          .from('invitations')
          .select('id, email, role, expires_at, created_at')
          .isFilter('used_at', null)
          .gt('expires_at', DateTime.now().toIso8601String())
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting pending invitations: $e');
      throw Exception('Failed to get invitations: ${e.toString()}');
    }
  }

  /// حذف دعوة (Admin فقط)
  Future<void> deleteInvitation(int invitationId) async {
    try {
      if (!await isAdmin()) {
        throw Exception('Only admins can delete invitations');
      }

      await _client
          .from('invitations')
          .delete()
          .eq('id', invitationId);
    } catch (e) {
      print('Error deleting invitation: $e');
      throw Exception('Failed to delete invitation: ${e.toString()}');
    }
  }

  // ====================== USER MANAGEMENT ======================

  /// الحصول على جميع المستخدمين مع أدوارهم (Admin فقط)
  Future<List<Map<String, dynamic>>> getAllUsersWithRoles() async {
    try {
      if (!await isAdmin()) {
        throw Exception('Only admins can view all users');
      }

      final response = await _client
          .from('user_roles')
          .select('''
            *,
            users:user_id (
              email,
              created_at,
              last_sign_in_at
            )
          ''')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting users with roles: $e');
      throw Exception('Failed to get users: ${e.toString()}');
    }
  }

  /// تحديث دور المستخدم (Admin فقط)
  Future<void> updateUserRole({
    required String userId,
    required String newRole,
  }) async {
    try {
      if (!await isAdmin()) {
        throw Exception('Only admins can update user roles');
      }

      await _client
          .from('user_roles')
          .update({'role': newRole})
          .eq('user_id', userId);
    } catch (e) {
      print('Error updating user role: $e');
      throw Exception('Failed to update user role: ${e.toString()}');
    }
  }

  /// حذف مستخدم (Admin فقط)
  Future<void> deleteUser(String userId) async {
    try {
      if (!await isAdmin()) {
        throw Exception('Only admins can delete users');
      }

      // حذف الدور (سيحذف المستخدم تلقائياً بسبب CASCADE)
      await _client
          .from('user_roles')
          .delete()
          .eq('user_id', userId);
    } catch (e) {
      print('Error deleting user: $e');
      throw Exception('Failed to delete user: ${e.toString()}');
    }
  }

  // ====================== ROLE CONSTANTS ======================

  static const String ROLE_ADMIN = 'admin';
  static const String ROLE_WAREHOUSE_MANAGER = 'warehouse_manager';
  static const String ROLE_PROJECT_MANAGER = 'project_manager';

  static const List<String> ALL_ROLES = [
    ROLE_ADMIN,
    ROLE_WAREHOUSE_MANAGER,
    ROLE_PROJECT_MANAGER,
  ];

  /// الحصول على اسم الدور بالعربية
  static String getRoleDisplayName(String role) {
    switch (role) {
      case ROLE_ADMIN:
        return 'مدير النظام';
      case ROLE_WAREHOUSE_MANAGER:
        return 'مدير المخزن';
      case ROLE_PROJECT_MANAGER:
        return 'مدير المشروع';
      default:
        return role;
    }
  }

  /// الحصول على لون الدور
  static String getRoleColor(String role) {
    switch (role) {
      case ROLE_ADMIN:
        return 'red';
      case ROLE_WAREHOUSE_MANAGER:
        return 'blue';
      case ROLE_PROJECT_MANAGER:
        return 'green';
      default:
        return 'grey';
    }
  }

  // ====================== UTILITY METHODS ======================

  /// تسجيل الخروج
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// التحقق من أن المستخدم مسجل دخول
  bool get isAuthenticated => _client.auth.currentUser != null;

  /// الحصول على المستخدم الحالي
  User? get currentUser => _client.auth.currentUser;
}