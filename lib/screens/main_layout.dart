import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:warehouse_management_system/l10n/app_localizations.dart';
import 'package:warehouse_management_system/services/language_service.dart';
import 'package:warehouse_management_system/screens/customers_screen.dart';
import 'package:warehouse_management_system/screens/inventory_count_screen.dart';
import 'package:warehouse_management_system/screens/products_screen.dart';
import 'package:warehouse_management_system/screens/reports_screen.dart';
import 'package:warehouse_management_system/screens/settings_screen.dart';
import 'package:warehouse_management_system/screens/stock_in_screen.dart';
import 'package:warehouse_management_system/screens/stock_out_screen.dart';
import 'package:warehouse_management_system/screens/suppliers_screen.dart';
import 'package:warehouse_management_system/screens/transactions_screen.dart';
import 'package:warehouse_management_system/screens/users_roles_screen.dart';
import 'package:warehouse_management_system/screens/warehouses_screen.dart';
import '../backend/main_layout_logic.dart';
import 'login_screen.dart';
import 'package:warehouse_management_system/backend/invitations_management_screen.dart';
class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  final MainLayoutLogic _layoutLogic = MainLayoutLogic();
  bool _isLoading = true;
  String? _userRole;
  String? _errorMessage;
  int _selectedIndex = 0;
  bool _isRailExtended = true;

  // قائمة مبسطة للصفحات حسب الدور
  List<NavigationItem> _navigationItems = [];

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // إعادة بناء القائمة عند تغيير اللغة
    if (_userRole != null) {
      setState(() {
        _navigationItems = _getNavigationItems(_userRole!);
      });
    }
  }

  Future<void> _loadUserRole() async {
    try {
      final role = await _layoutLogic.getCurrentUserRole();
      setState(() {
        _userRole = role;
        _navigationItems = _getNavigationItems(role ?? '');
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  List<NavigationItem> _getNavigationItems(String role) {
    final localizations = AppLocalizations.of(context);
    
    switch (role) {
      case 'admin':
        return [
          NavigationItem(Icons.home, localizations?.dashboard ?? 'الرئيسية', _buildHomeScreen()),
          NavigationItem(Icons.inventory, localizations?.products ?? 'المنتجات', ProductsScreen()),
          NavigationItem(Icons.warehouse, localizations?.warehouses ?? 'المخازن', WarehousesScreen()),
          NavigationItem(Icons.input, localizations?.stockIn ?? 'إدخال مخزون', StockInScreen()),
          NavigationItem(Icons.output, localizations?.stockOut ?? 'إخراج مخزون', StockOutScreen()),
          NavigationItem(Icons.business, localizations?.suppliers ?? 'الموردين', SuppliersScreen()),
         NavigationItem(Icons.mail, localizations?.invitations ?? 'إدارة الدعوات', const InvitationsManagementScreen()),
        ];
        
      case 'warehouse_manager':
        return [
          NavigationItem(Icons.home, localizations?.dashboard ?? 'الرئيسية', _buildHomeScreen()),
          NavigationItem(Icons.warehouse, localizations?.warehouses ?? 'المخازن', WarehousesScreen()),
          NavigationItem(Icons.input, localizations?.stockIn ?? 'إدخال مخزون', StockInScreen()),
          NavigationItem(Icons.output, localizations?.stockOut ?? 'إخراج مخزون', StockOutScreen()),
          NavigationItem(Icons.business, localizations?.suppliers ?? 'الموردين', SuppliersScreen()),
 
                ];
        
      case 'project_manager':
        return [
         NavigationItem(Icons.home, localizations?.dashboard ?? 'الرئيسية', _buildHomeScreen()),
          NavigationItem(Icons.warehouse, localizations?.warehouses ?? 'المخازن', WarehousesScreen()),
          NavigationItem(Icons.input, localizations?.stockIn ?? 'إدخال مخزون', StockInScreen()),
          NavigationItem(Icons.output, localizations?.stockOut ?? 'إخراج مخزون', StockOutScreen()),
          NavigationItem(Icons.business, localizations?.suppliers ?? 'الموردين', SuppliersScreen()),
 ];
        
      default:
        return [
          NavigationItem(Icons.home, localizations?.dashboard ?? 'الرئيسية', _buildHomeScreen()),
        ];
    }
  }

  Widget _buildHomeScreen() {
    final localizations = AppLocalizations.of(context);
    final roleDisplayName = _getRoleDisplayName(_userRole ?? '');
    final roleColor = _getRoleColor(_userRole ?? '');

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations?.dashboard ?? 'الصفحة الرئيسية'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserRole,
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // شعار النظام
            Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/logo2.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback to the original icon if image doesn't load
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: roleColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.warehouse,
                        size: 80,
                        color: roleColor,
                      ),
                    );
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 30),
            
            // رسالة الترحيب
            Text(
              localizations?.appTitle ?? 'مرحباً بك في نظام إدارة المخازن',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            // معلومات المستخدم
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: roleColor.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        backgroundColor: roleColor,
                        radius: 20,
                        child: const Text(
                          'U',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            localizations?.users ?? 'مستخدم النظام',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '${_getRoleLabel(localizations)}: $roleDisplayName',
                            style: TextStyle(
                              color: roleColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // إرشادات الاستخدام
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 32,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _getNavigationGuideText(localizations),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getPermissionText(localizations),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // معلومات إضافية
            _buildInfoCards(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCards() {
    final rolePermissions = _getRolePermissions(_userRole ?? '');
    
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: rolePermissions.map((permission) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _getRoleColor(_userRole ?? '').withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _getRoleColor(_userRole ?? '').withOpacity(0.3),
            ),
          ),
          child: Text(
            permission,
            style: TextStyle(
              color: _getRoleColor(_userRole ?? ''),
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        );
      }).toList(),
    );
  }

  List<String> _getRolePermissions(String role) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    
    switch (role) {
      case 'admin':
        return isEnglish 
            ? ['Full Management', 'All Permissions', 'User Management', 'Advanced Reports']
            : ['إدارة كاملة', 'جميع الصلاحيات', 'إدارة المستخدمين', 'التقارير المتقدمة'];
      case 'warehouse_manager':
        return isEnglish
            ? ['Warehouse Management', 'Stock In/Out']
            : ['إدارة المخزون', 'إدخال وإخراج'];
      case 'project_manager':
        return isEnglish
            ? ['View Reports', 'Transaction Monitoring', 'Inventory Results']
            : ['عرض التقارير', 'متابعة المعاملات', 'نتائج الجرد'];
      default:
        return isEnglish ? ['Limited Permissions'] : ['صلاحيات محدودة'];
    }
  }

  Widget _buildPlaceholderScreen(String title, String description, {bool isReadOnly = false}) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        automaticallyImplyLeading: false,
        actions: [
          if (isReadOnly)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isEnglish ? 'Read Only' : 'قراءة فقط',
                style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isReadOnly ? Icons.visibility : Icons.construction,
                size: 80,
                color: isReadOnly ? Colors.orange : Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 20),
              Text(
                description,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                isReadOnly 
                    ? (isEnglish ? 'You can only view data according to your permissions' : 'يمكنك عرض البيانات فقط حسب صلاحياتك')
                    : (isEnglish ? 'This page is under development' : 'هذه الصفحة قيد التطوير'),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedIndex = 0; // العودة للصفحة الرئيسية
                  });
                },
                icon: const Icon(Icons.home),
                label: Text(isEnglish ? 'Back to Home' : 'العودة للصفحة الرئيسية'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserHeader() {
    final roleDisplayName = _getRoleDisplayName(_userRole ?? '');
    final roleColor = _getRoleColor(_userRole ?? '');

    return Container(
      margin: const EdgeInsets.all(8),
      child: _isRailExtended
          ? Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/images/logo2.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback to original design if logo doesn't load
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: roleColor,
                            child: Text(
                              'U',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getUserDisplayName(),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            roleDisplayName,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: roleColor,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            )
          : Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/images/logo2.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback for collapsed state
                    return CircleAvatar(
                      radius: 16,
                      backgroundColor: roleColor,
                      child: Text(
                        'U',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
    );
  }

  String _getRoleDisplayName(String role) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    
    switch (role) {
      case 'admin':
        return isEnglish ? 'System Admin' : 'مدير النظام';
      case 'warehouse_manager':
        return isEnglish ? 'Warehouse Manager' : 'مدير المخزن';
      case 'project_manager':
        return isEnglish ? 'Project Manager' : 'مدير المشروع';
      default:
        return role;
    }
  }

  String _getRoleLabel(AppLocalizations? localizations) {
    return localizations?.settings ?? 'الدور';
  }

  String _getNavigationGuideText(AppLocalizations? localizations) {
    if (localizations != null && Localizations.localeOf(context).languageCode == 'en') {
      return 'Use the sidebar to navigate between pages';
    }
    return 'استخدم القائمة الجانبية للتنقل بين الصفحات';
  }

  String _getPermissionText(AppLocalizations? localizations) {
    if (localizations != null && Localizations.localeOf(context).languageCode == 'en') {
      return 'You can access pages according to your role permissions';
    }
    return 'يمكنك الوصول للصفحات المسموح لك بها حسب دورك في النظام';
  }

  String _getUserDisplayName() {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    return isEnglish ? 'System User' : 'مستخدم النظام';
  }

  String _getNoPageText() {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    return isEnglish ? 'No pages available' : 'لا توجد صفحات متاحة';
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.red;
      case 'warehouse_manager':
        return Colors.blue;
      case 'project_manager':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    
    // شاشة التحميل
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(isEnglish ? 'Loading data...' : 'جاري تحميل البيانات...'),
            ],
          ),
        ),
      );
    }

    // شاشة الخطأ
    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('${isEnglish ? 'Error' : 'خطأ'}: $_errorMessage'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                ),
                child: Text(isEnglish ? 'Back to Login' : 'العودة للدخول'),
              ),
            ],
          ),
        ),
      );
    }

    // الواجهة الرئيسية مع Navigation Rail
    return Scaffold(
      body: Row(
        children: [
          // Navigation Rail
          // ابحث عن NavigationRail وامسحه واستبدله بالكود ده:
Container(
  width: 250,
  color: Theme.of(context).colorScheme.surfaceVariant,
  child: Column(
    children: [
      // Header
      Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                setState(() {
                  _isRailExtended = !_isRailExtended;
                });
              },
            ),
            if (_isRailExtended) ...[
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadUserRole,
              ),
            ],
          ],
        ),
      ),
      
      // User Info
      _buildUserHeader(),
      
      const SizedBox(height: 20),
      
      // Navigation Items
      Expanded(
        child: ListView.builder(
          itemCount: _navigationItems.length,
          itemBuilder: (context, index) {
            final item = _navigationItems[index];
            return ListTile(
              leading: Icon(item.icon),
              title: Text(item.label),
              selected: _selectedIndex == index,
              onTap: () {
                setState(() {
                  _selectedIndex = index;
                });
              },
            );
          },
        ),
      ),
      
      // Footer
      Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_isRailExtended)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  AppLocalizations.of(context)?.appTitle ?? 'نظام إدارة المخازن',
                ),
              ),
            const SizedBox(height: 8),
            
            // Language Change Button
            _buildLanguageButton(),
            const SizedBox(height: 8),
            
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                final isEnglish = Localizations.localeOf(context).languageCode == 'en';
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(isEnglish ? 'Logout' : 'تسجيل الخروج'),
                    content: Text(isEnglish ? 'Are you sure?' : 'هل أنت متأكد؟'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(isEnglish ? 'Cancel' : 'إلغاء'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(isEnglish ? 'Logout' : 'خروج'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  await _layoutLogic.handleSignOut();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                }
              },
            ),
          ],
        ),
      ),
    ],
  ),
),
          
          // Vertical Divider
          const VerticalDivider(thickness: 1, width: 1),
          
          // Main Content Area
          Expanded(
            child: _navigationItems.isEmpty 
                ? Center(child: Text(_getNoPageText()))
                : _navigationItems[_selectedIndex < _navigationItems.length ? _selectedIndex : 0].screen,
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageButton() {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return InkWell(
          onTap: () => _showLanguageDialog(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 24,
                  height: 18,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 1,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: Image.asset(
                      languageService.isArabic 
                          ? 'assets/images/Palestine flag.jpg'
                          : 'assets/images/USA flag.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            color: languageService.isArabic ? Colors.green : Colors.blue,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Center(
                            child: Text(
                              languageService.isArabic ? 'AR' : 'EN',
                              style: const TextStyle(color: Colors.white, fontSize: 8),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                if (_isRailExtended) ...[
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)?.changeLanguage ?? 'تغيير اللغة',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLanguageDialog() {
    final languageService = Provider.of<LanguageService>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocalizations.of(context)?.selectLanguage ?? 'اختر اللغة',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            
            // Arabic Option
            ListTile(
              leading: Container(
                width: 32,
                height: 24,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.asset(
                    'assets/images/Palestine flag.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Center(
                          child: Text('AR', style: TextStyle(color: Colors.white, fontSize: 10)),
                        ),
                      );
                    },
                  ),
                ),
              ),
              title: Text(AppLocalizations.of(context)?.arabic ?? 'العربية'),
              trailing: languageService.isArabic 
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : null,
              onTap: () {
                languageService.setArabic();
                Navigator.pop(context);
              },
            ),
            
            // English Option
            ListTile(
              leading: Container(
                width: 32,
                height: 24,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.asset(
                    'assets/images/USA flag.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Center(
                          child: Text('EN', style: TextStyle(color: Colors.white, fontSize: 10)),
                        ),
                      );
                    },
                  ),
                ),
              ),
              title: Text(AppLocalizations.of(context)?.english ?? 'English'),
              trailing: languageService.isEnglish 
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : null,
              onTap: () {
                languageService.setEnglish();
                Navigator.pop(context);
              },
            ),
            
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)?.close ?? 'إغلاق'),
            ),
          ],
        ),
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final String label;
  final Widget screen;

  NavigationItem(this.icon, this.label, this.screen);
}