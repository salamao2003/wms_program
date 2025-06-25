import 'package:flutter/material.dart';
import 'package:warehouse_management_system/screens/products_screen.dart';
import 'package:warehouse_management_system/screens/stock_in_screen.dart';
import 'package:warehouse_management_system/screens/stock_out_screen.dart';
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
    switch (role) {
      case 'admin':
        return [
          NavigationItem(Icons.home, 'الرئيسية', _buildHomeScreen()),
          NavigationItem(Icons.inventory, 'المنتجات', ProductsScreen()),
          NavigationItem(Icons.warehouse, 'المخازن', WarehousesScreen()),
          NavigationItem(Icons.input, 'إدخال مخزون', StockInScreen()),
          NavigationItem(Icons.output, 'إخراج مخزون', StockOutScreen()),
          NavigationItem(Icons.history, 'المعاملات', _buildPlaceholderScreen('المعاملات', 'تاريخ جميع المعاملات')),
          NavigationItem(Icons.inventory_2, 'جرد المخزون', _buildPlaceholderScreen('جرد المخزون', 'عمليات الجرد')),
          NavigationItem(Icons.assessment, 'التقارير', _buildPlaceholderScreen('التقارير', 'تقارير النظام')),
          NavigationItem(Icons.business, 'الموردين', _buildPlaceholderScreen('الموردين', 'إدارة الموردين')),
          NavigationItem(Icons.people, 'العملاء', _buildPlaceholderScreen('العملاء', 'إدارة العملاء')),
          NavigationItem(Icons.admin_panel_settings, 'المستخدمين', _buildPlaceholderScreen('المستخدمين والأدوار', 'إدارة المستخدمين')),
          NavigationItem(Icons.settings, 'الإعدادات', _buildPlaceholderScreen('الإعدادات', 'إعدادات النظام')),
          NavigationItem(Icons.mail, 'إدارة الدعوات', const InvitationsManagementScreen()),
        ];
        
      case 'warehouse_manager':
        return [
          NavigationItem(Icons.home, 'الرئيسية', _buildHomeScreen()),
          NavigationItem(Icons.input, 'إدخال مخزون', _buildPlaceholderScreen('إدخال مخزون', 'إضافة مخزون جديد')),
          NavigationItem(Icons.output, 'إخراج مخزون', _buildPlaceholderScreen('إخراج مخزون', 'سحب مخزون')),
          NavigationItem(Icons.inventory_2, 'جرد المخزون', _buildPlaceholderScreen('جرد المخزون', 'عمليات الجرد')),
          NavigationItem(Icons.history, 'المعاملات', _buildPlaceholderScreen('المعاملات', 'عرض المعاملات (قراءة فقط)', isReadOnly: true)),
          NavigationItem(Icons.assessment, 'التقارير', _buildPlaceholderScreen('التقارير', 'عرض التقارير (قراءة فقط)', isReadOnly: true)),
        ];
        
      case 'project_manager':
        return [
          NavigationItem(Icons.home, 'الرئيسية', _buildHomeScreen()),
          NavigationItem(Icons.history, 'المعاملات', _buildPlaceholderScreen('المعاملات', 'عرض المعاملات (قراءة فقط)', isReadOnly: true)),
          NavigationItem(Icons.assessment, 'التقارير', _buildPlaceholderScreen('التقارير', 'عرض التقارير (قراءة فقط)', isReadOnly: true)),
          NavigationItem(Icons.inventory_2, 'جرد المخزون', _buildPlaceholderScreen('جرد المخزون', 'عرض نتائج الجرد (قراءة فقط)', isReadOnly: true)),
        ];
        
      default:
        return [
          NavigationItem(Icons.home, 'الرئيسية', _buildHomeScreen()),
        ];
    }
  }

  Widget _buildHomeScreen() {
    final roleDisplayName = _getRoleDisplayName(_userRole ?? '');
    final roleColor = _getRoleColor(_userRole ?? '');

    return Scaffold(
      appBar: AppBar(
        title: const Text('الصفحة الرئيسية'),
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
            ),
            
            const SizedBox(height: 30),
            
            // رسالة الترحيب
            Text(
              'مرحباً بك في نظام إدارة المخازن',
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
                          const Text(
                            'مستخدم النظام',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'الدور: $roleDisplayName',
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
                    'استخدم القائمة الجانبية للتنقل بين الصفحات',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'يمكنك الوصول للصفحات المسموح لك بها حسب دورك في النظام',
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
    switch (role) {
      case 'admin':
        return ['إدارة كاملة', 'جميع الصلاحيات', 'إدارة المستخدمين', 'التقارير المتقدمة'];
      case 'warehouse_manager':
        return ['إدارة المخزون', 'إدخال وإخراج', 'عمليات الجرد', 'تقارير المخزون'];
      case 'project_manager':
        return ['عرض التقارير', 'متابعة المعاملات', 'نتائج الجرد'];
      default:
        return ['صلاحيات محدودة'];
    }
  }

  Widget _buildPlaceholderScreen(String title, String description, {bool isReadOnly = false}) {
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
              child: const Text(
                'قراءة فقط',
                style: TextStyle(
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
                    ? 'يمكنك عرض البيانات فقط حسب صلاحياتك'
                    : 'هذه الصفحة قيد التطوير',
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
                label: const Text('العودة للصفحة الرئيسية'),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.all(8),
      child: Column(
        children: [
          CircleAvatar(
            radius: _isRailExtended ? 24 : 16,
            backgroundColor: roleColor,
            child: Text(
              'U',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: _isRailExtended ? 18 : 14,
              ),
            ),
          ),
          if (_isRailExtended) ...[
            const SizedBox(height: 8),
            Text(
              'مستخدم النظام',
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
        ],
      ),
    );
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'admin':
        return 'مدير النظام';
      case 'warehouse_manager':
        return 'مدير المخزن';
      case 'project_manager':
        return 'مدير المشروع';
      default:
        return role;
    }
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
    // شاشة التحميل
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('جاري تحميل البيانات...'),
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
              Text('خطأ: $_errorMessage'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                ),
                child: const Text('العودة للدخول'),
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
                child: const Text('نظام إدارة المخازن'),
              ),
            const SizedBox(height: 8),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('تسجيل الخروج'),
                    content: const Text('هل أنت متأكد؟'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('إلغاء'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('خروج'),
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
                ? const Center(child: Text('لا توجد صفحات متاحة'))
                : _navigationItems[_selectedIndex < _navigationItems.length ? _selectedIndex : 0].screen,
          ),
        ],
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