import 'package:flutter/material.dart';

import 'supabase_service.dart';



class MainLayoutLogic {

  final SupabaseService _supabaseService = SupabaseService();

  

  // Cache للدور عشان نقلل استعلامات قاعدة البيانات

  String? _cachedUserRole;

  DateTime? _cacheTime;

  static const Duration _cacheTimeout = Duration(minutes: 10);



  /// الحصول على دور المستخدم (مع Cache)

  Future<String?> getCurrentUserRole({bool forceRefresh = false}) async {

    try {

      // استخدام Cache إذا كان متاح وحديث

      if (!forceRefresh && 

          _cachedUserRole != null && 

          _cacheTime != null && 

          DateTime.now().difference(_cacheTime!).inMinutes < _cacheTimeout.inMinutes) {

        return _cachedUserRole;

      }



      // جلب الدور من قاعدة البيانات

      final role = await _supabaseService.getCurrentUserRole();

      

      // حفظ في Cache

      _cachedUserRole = role;

      _cacheTime = DateTime.now();

      

      return role;

    } catch (e) {

      print('Error getting user role in MainLayoutLogic: $e');

      return null;

    }

  }



  /// التحقق من الصلاحيات لصفحة معينة

  Future<bool> hasPagePermission(String pageRoute) async {

    final userRole = await getCurrentUserRole();

    if (userRole == null) return false;



    return _getPagePermissions(userRole).contains(pageRoute);

  }



  /// الحصول على قائمة الصفحات المسموحة حسب الدور

  List<String> _getPagePermissions(String role) {

    switch (role) {

      case SupabaseService.ROLE_ADMIN:

        return [

          '/dashboard',

          '/products',

          '/warehouses', 

          '/stock_in',

          '/stock_out',

          '/transactions',

          '/inventory_count',

          '/reports',

          '/suppliers',

          '/customers',

          '/users_roles',

          '/settings',

        ];

        

      case SupabaseService.ROLE_WAREHOUSE_MANAGER:

        return [

          '/dashboard',

          '/stock_in',      // يقدر يضيف مخزون

          '/stock_out',     // يقدر يحذف مخزون

          '/inventory_count', // يقدر يعمل جرد

          '/transactions',  // يشاهد المعاملات فقط

          '/reports',       // يشاهد التقارير فقط

        ];

        

      case SupabaseService.ROLE_PROJECT_MANAGER:

        return [

          '/dashboard',     // يشاهد لوحة المعلومات

          '/transactions',  // يشاهد المعاملات فقط

          '/reports',       // يشاهد التقارير فقط

          '/inventory_count', // يشاهد نتائج الجرد فقط

        ];

        

      default:

        return ['/dashboard']; // دور غير معروف - Dashboard فقط

    }

  }



  /// الحصول على العناصر المسموحة في Navigation Rail

  Future<List<NavigationItemData>> getAllowedNavigationItems() async {

    final userRole = await getCurrentUserRole();

    if (userRole == null) return [];



    final allItems = _getAllNavigationItems();

    final allowedPages = _getPagePermissions(userRole);

    

    return allItems.where((item) => allowedPages.contains(item.route)).toList();

  }



  /// جميع عناصر التنقل المتاحة

  List<NavigationItemData> _getAllNavigationItems() {

    return [

      NavigationItemData(

        route: '/dashboard',

        icon: Icons.dashboard,

        label: 'لوحة المعلومات',

        permissions: [SupabaseService.ROLE_ADMIN, SupabaseService.ROLE_WAREHOUSE_MANAGER, SupabaseService.ROLE_PROJECT_MANAGER],

        accessLevel: AccessLevel.readWrite,

      ),

      NavigationItemData(

        route: '/products',

        icon: Icons.inventory,

        label: 'المنتجات',

        permissions: [SupabaseService.ROLE_ADMIN],

        accessLevel: AccessLevel.readWrite,

      ),

      NavigationItemData(

        route: '/warehouses',

        icon: Icons.warehouse,

        label: 'المخازن',

        permissions: [SupabaseService.ROLE_ADMIN],

        accessLevel: AccessLevel.readWrite,

      ),

      NavigationItemData(

        route: '/stock_in',

        icon: Icons.input,

        label: 'إدخال مخزون',

        permissions: [SupabaseService.ROLE_ADMIN, SupabaseService.ROLE_WAREHOUSE_MANAGER],

        accessLevel: AccessLevel.readWrite,

      ),

      NavigationItemData(

        route: '/stock_out',

        icon: Icons.output,

        label: 'إخراج مخزون',

        permissions: [SupabaseService.ROLE_ADMIN, SupabaseService.ROLE_WAREHOUSE_MANAGER],

        accessLevel: AccessLevel.readWrite,

      ),

      NavigationItemData(

        route: '/transactions',

        icon: Icons.history,

        label: 'المعاملات',

        permissions: [SupabaseService.ROLE_ADMIN, SupabaseService.ROLE_WAREHOUSE_MANAGER, SupabaseService.ROLE_PROJECT_MANAGER],

        accessLevel: AccessLevel.readOnly,

      ),

      NavigationItemData(

        route: '/inventory_count',

        icon: Icons.inventory_2,

        label: 'جرد المخزون',

        permissions: [SupabaseService.ROLE_ADMIN, SupabaseService.ROLE_WAREHOUSE_MANAGER, SupabaseService.ROLE_PROJECT_MANAGER],

        accessLevel: AccessLevel.mixed, // Admin و Warehouse Manager = ReadWrite, Project Manager = ReadOnly

      ),

      NavigationItemData(

        route: '/reports',

        icon: Icons.assessment,

        label: 'التقارير',

        permissions: [SupabaseService.ROLE_ADMIN, SupabaseService.ROLE_WAREHOUSE_MANAGER, SupabaseService.ROLE_PROJECT_MANAGER],

        accessLevel: AccessLevel.readOnly,

      ),

      NavigationItemData(

        route: '/suppliers',

        icon: Icons.business,

        label: 'الموردين',

        permissions: [SupabaseService.ROLE_ADMIN],

        accessLevel: AccessLevel.readWrite,

      ),

      NavigationItemData(

        route: '/customers',

        icon: Icons.people,

        label: 'العملاء',

        permissions: [SupabaseService.ROLE_ADMIN],

        accessLevel: AccessLevel.readWrite,

      ),

      NavigationItemData(

        route: '/users_roles',

        icon: Icons.admin_panel_settings,

        label: 'المستخدمين والأدوار',

        permissions: [SupabaseService.ROLE_ADMIN],

        accessLevel: AccessLevel.readWrite,

      ),

      NavigationItemData(

        route: '/settings',

        icon: Icons.settings,

        label: 'الإعدادات',

        permissions: [SupabaseService.ROLE_ADMIN],

        accessLevel: AccessLevel.readWrite,

      ),

    ];

  }



  /// التحقق من نوع الوصول للصفحة (قراءة/كتابة/قراءة فقط)

  Future<AccessLevel> getPageAccessLevel(String pageRoute) async {

    final userRole = await getCurrentUserRole();

    if (userRole == null) return AccessLevel.denied;



    final item = _getAllNavigationItems()

        .firstWhere((item) => item.route == pageRoute, orElse: () => NavigationItemData.empty());

    

    if (!item.permissions.contains(userRole)) {

      return AccessLevel.denied;

    }



    // حالات خاصة حسب الدور

    switch (pageRoute) {

      case '/inventory_count':

        if (userRole == SupabaseService.ROLE_PROJECT_MANAGER) {

          return AccessLevel.readOnly;

        }

        return AccessLevel.readWrite;

        

      case '/transactions':

      case '/reports':

        if (userRole == SupabaseService.ROLE_ADMIN) {

          return AccessLevel.readWrite;

        }

        return AccessLevel.readOnly;

        

      default:

        return item.accessLevel;

    }

  }



  /// الحصول على معلومات المستخدم للعرض في Header

  Future<Map<String, dynamic>?> getUserDisplayInfo() async {

    try {

      final userWithRole = await _supabaseService.getCurrentUserWithRole();

      if (userWithRole == null) return null;



      return {

        'name': userWithRole['full_name'] ?? 'مستخدم',

        'email': userWithRole['email'] ?? '',

        'role': userWithRole['role'] ?? '',

        'role_display': SupabaseService.getRoleDisplayName(userWithRole['role'] ?? ''),

        'avatar_color': _getAvatarColor(userWithRole['role'] ?? ''),

      };

    } catch (e) {

      print('Error getting user display info: $e');

      return null;

    }

  }



  /// الحصول على لون الأفاتار حسب الدور

  Color _getAvatarColor(String role) {

    switch (role) {

      case SupabaseService.ROLE_ADMIN:

        return Colors.red;

      case SupabaseService.ROLE_WAREHOUSE_MANAGER:

        return Colors.blue;

      case SupabaseService.ROLE_PROJECT_MANAGER:

        return Colors.green;

      default:

        return Colors.grey;

    }

  }



  /// تسجيل الخروج

  Future<void> handleSignOut() async {

    try {

      await _supabaseService.signOut();

      _clearCache();

    } catch (e) {

      print('Error in handleSignOut: $e');

      throw Exception('خطأ في تسجيل الخروج');

    }

  }



  /// مسح Cache

  void _clearCache() {

    _cachedUserRole = null;

    _cacheTime = null;

  }



  /// فرض تحديث Cache

  Future<void> refreshUserRole() async {

    await getCurrentUserRole(forceRefresh: true);

  }



  /// التحقق من انتهاء صلاحية الجلسة

  bool get isSessionExpired {

    return !_supabaseService.isAuthenticated;

  }



  /// الحصول على إحصائيات سريعة للمستخدم (للDashboard)

  Future<Map<String, dynamic>> getUserStats() async {

    final userRole = await getCurrentUserRole();

    if (userRole == null) return {};



    // إحصائيات مختلفة حسب الدور

    switch (userRole) {

      case SupabaseService.ROLE_ADMIN:

        return {

          'title': 'إحصائيات المدير',

          'show_all_stats': true,

          'accessible_features': [

            'إدارة المستخدمين',

            'إدارة المنتجات',

            'إدارة المخازن',

            'جميع التقارير',

          ],

        };

        

      case SupabaseService.ROLE_WAREHOUSE_MANAGER:

        return {

          'title': 'إحصائيات مدير المخزن',

          'show_stock_stats': true,

          'accessible_features': [

            'إدخال وإخراج مخزون',

            'جرد المخزون',

            'تقارير المخزون',

          ],

        };

        

      case SupabaseService.ROLE_PROJECT_MANAGER:

        return {

          'title': 'إحصائيات مدير المشروع',

          'show_reports_only': true,

          'accessible_features': [

            'عرض التقارير',

            'متابعة المعاملات',

            'نتائج الجرد',

          ],

        };

        

      default:

        return {};

    }

  }

}



/// بيانات عنصر التنقل

class NavigationItemData {

  final String route;

  final IconData icon;

  final String label;

  final List<String> permissions;

  final AccessLevel accessLevel;



  NavigationItemData({

    required this.route,

    required this.icon,

    required this.label,

    required this.permissions,

    required this.accessLevel,

  });



  factory NavigationItemData.empty() {

    return NavigationItemData(

      route: '',

      icon: Icons.error,

      label: '',

      permissions: [],

      accessLevel: AccessLevel.denied,

    );

  }

}



/// مستويات الوصول

enum AccessLevel {

  denied,      // ممنوع

  readOnly,    // قراءة فقط

  readWrite,   // قراءة وكتابة

  mixed,       // مختلط حسب الدور

}