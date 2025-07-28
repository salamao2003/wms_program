import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../backend/products_logic.dart';
import '../l10n/app_localizations.dart';
import '../services/language_service.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final ProductsLogic _productsLogic = ProductsLogic();
  final TextEditingController _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _products = [];
  Map<String, int> _stats = {};
  
  bool _isLoading = true;
  String? _errorMessage;
  
  // للفلترة
  String _searchTerm = '';
  int? _selectedCategoryFilter;
 
  String _selectedSearchField = 'id'; // أو أي قيمة أخرى غير 'all'

final List<Map<String, String>> _searchFields = [
    {'value': 'id', 'label_ar': 'رقم المنتج (ID)', 'label_en': 'Product ID', 'icon': 'tag'},
    {'value': 'name', 'label_ar': 'اسم المنتج', 'label_en': 'Product Name', 'icon': 'inventory'},
    {'value': 'invoice', 'label_ar': 'رقم الفاتورة', 'label_en': 'Invoice Number', 'icon': 'receipt'},
    {'value': 'tax', 'label_ar': 'الرقم الضريبي', 'label_en': 'Tax Number', 'icon': 'account_balance'},
    {'value': 'po', 'label_ar': 'رقم PO', 'label_en': 'PO Number', 'icon': 'assignment'},
    {'value': 'supplier', 'label_ar': 'المورد', 'label_en': 'Supplier', 'icon': 'business'},
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _productsLogic.getProducts(),
        _productsLogic.getProductsStats(),
      ]);

      setState(() {
        _products = results[0] as List<Map<String, dynamic>>;
        _stats = results[1] as Map<String, int>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _searchProducts() async {
    try {
      List<Map<String, dynamic>> results;
      
      if (_selectedSearchField == 'all') {
        // البحث الشامل
        results = await _productsLogic.searchProducts(
          searchTerm: _searchTerm.isNotEmpty ? _searchTerm : null,
          categoryId: _selectedCategoryFilter,
         
          status: 'active',
        );
      } else {
        // البحث المتخصص
        results = await _productsLogic.searchProductsByField(
          searchTerm: _searchTerm.isNotEmpty ? _searchTerm : null,
          searchField: _selectedSearchField,
          categoryId: _selectedCategoryFilter,
          
          status: 'active',
        );
      }

      setState(() {
        _products = results;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل البحث: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations?.productsTitle ?? 'Products Management'),
        automaticallyImplyLeading: false,
        actions: [
          // إحصائيات سريعة
          if (_stats.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.inventory_2, size: 16),
                  const SizedBox(width: 4),
                  Text('${_stats['total_products']} ${localizations?.products ?? 'منتج'}'),
                ],
              ),
            ),
          ],
          ElevatedButton.icon(
            onPressed: () => _showProductDialog(),
            icon: const Icon(Icons.add),
            label: Text(localizations?.addProduct ?? 'Add Product'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorWidget()
              : _buildMainContent(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'خطأ في تحميل البيانات',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadInitialData,
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // شريط البحث والفلاتر
          _buildSearchAndFilters(),
          const SizedBox(height: 16),
          
          // جدول المنتجات
          Expanded(
            child: _products.isEmpty ? _buildEmptyState() : _buildProductsTable(),
          ),
        ],
      ),
    );
  }

   // شريط البحث والفلاتر المحدث
  Widget _buildSearchAndFilters() {
    final localizations = AppLocalizations.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // الصف الأول: نوع البحث وحقل البحث
            Row(
              children: [
                // اختيار نوع البحث
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    value: _selectedSearchField,
                    decoration: InputDecoration(
                      labelText: localizations?.searchText ?? 'نوع البحث',
                      border: const OutlineInputBorder(),
                      prefixIcon: Icon(_getSearchFieldIcon(_selectedSearchField)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: _searchFields.map((field) {
                      final isArabic = Localizations.localeOf(context).languageCode == 'ar';
                      final label = isArabic ? field['label_ar']! : field['label_en']!;
                      
                      return DropdownMenuItem<String>(
                        value: field['value'],
                        child: Row(
                          children: [
                            Icon(_getSearchFieldIcon(field['value']!), size: 18),
                            const SizedBox(width: 8),
                            Text(label, style: const TextStyle(fontSize: 14)),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedSearchField = value!;
                      });
                      if (_searchTerm.isNotEmpty) {
                        _searchProducts();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                
                // حقل البحث
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: _getSearchHint(_selectedSearchField, localizations),
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                      suffixIcon: _searchTerm.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchTerm = '';
                                });
                                _loadInitialData();
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchTerm = value;
                      });
                      // البحث التلقائي بعد كتابة 2 حروف
                      if (value.length >= 2 || value.isEmpty) {
                        _searchProducts();
                      }
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // الصف الثاني: فلاتر إضافية
            Row(
              children: [
                // فلتر المخزن
                
                const SizedBox(width: 12),
                
                // إحصائيات البحث
                if (_products.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.inventory_2, size: 18, color: Colors.blue),
                        const SizedBox(width: 6),
                        Text(
                          '${_products.length} ${localizations?.products ?? 'منتج'}',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),               
                const SizedBox(width: 12),               
              ],
            ),
          ],
        ),
      ),
    );
  }

  // الحصول على أيقونة نوع البحث
  IconData _getSearchFieldIcon(String field) {
    switch (field) {
      case 'all': return Icons.search;
      case 'id': return Icons.tag;
      case 'name': return Icons.inventory_2;
      case 'invoice': return Icons.receipt;
      case 'tax': return Icons.account_balance;
      case 'po': return Icons.assignment;
      case 'supplier': return Icons.business;
      default: return Icons.search;
    }
  }

  // الحصول على نص المساعدة للبحث
  String _getSearchHint(String field, AppLocalizations? localizations) {
    switch (field) {
      case 'all': return localizations?.searchAll ?? 'ابحث في جميع الحقول...';
      case 'id': return localizations?.searchById ?? 'ابحث برقم المنتج (مثل: 123)...';
      case 'name': return localizations?.searchByName ?? 'ابحث باسم المنتج...';
      case 'invoice': return localizations?.searchByInvoice ?? 'ابحث برقم الفاتورة...';
      case 'tax': return localizations?.searchByTax ?? 'ابحث بالرقم الضريبي...';
      case 'po': return localizations?.searchByPo ?? 'ابحث برقم PO...';
      case 'supplier': return localizations?.searchBySupplier ?? 'ابحث باسم المورد...';
      default: return localizations?.searchText ?? 'ابحث...';
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'لا توجد منتجات',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text('ابدأ بإضافة منتج جديد'),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showProductDialog(),
            icon: const Icon(Icons.add),
            label: const Text('إضافة أول منتج'),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsTable() {
    final localizations = AppLocalizations.of(context);
    
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            columnSpacing: 20,
            columns: [
              DataColumn(label: Text(localizations?.productId ?? 'ID')),
              DataColumn(label: Text(localizations?.productName ?? 'اسم المنتج')),
              DataColumn(label: Text(localizations?.category ?? 'الفئة')),
              DataColumn(label: Text(localizations?.supplier ?? 'المورد')),
              DataColumn(label: Text(localizations?.taxNumber ?? 'الرقم الضريبي')),
              DataColumn(label: Text(localizations?.invoiceNumber ?? 'رقم الفاتورة')),
              DataColumn(label: Text(localizations?.poNumber ?? 'رقم PO')),
              DataColumn(label: Text(localizations?.actions ?? 'الإجراءات')),
            ],
            rows: _products.map((product) {
              return DataRow(
                cells: [
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        product['id'].toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 150,
                      child: Text(
                        product['name'],
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 120,
                      child: Text(
                        product['category']?['name'] ?? (localizations?.category ?? 'غير محدد'),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: product['category'] != null ? null : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 100,
                      child: Text(
                        product['supplier'] ?? (localizations?.supplier ?? 'غير محدد'),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: product['supplier'] != null ? null : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      product['supplier_tax_number'] ?? 'غير محدد',
                      style: TextStyle(
                        color: product['supplier_tax_number'] != null ? null : Colors.grey,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      product['electronic_invoice_number'] ?? 'غير محدد',
                      style: TextStyle(
                        color: product['electronic_invoice_number'] != null ? null : Colors.grey,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      product['po_number'] ?? 'غير محدد',
                      style: TextStyle(
                        color: product['po_number'] != null ? null : Colors.grey,
                      ),
                    ),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.visibility, color: Colors.blue),
                          onPressed: () => _viewProduct(product),
                          tooltip: localizations?.view ?? 'عرض التفاصيل',
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.orange),
                          onPressed: () => _showProductDialog(product: product),
                          tooltip: localizations?.edit ?? 'تعديل',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteProduct(product),
                          tooltip: localizations?.delete ?? 'حذف',
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // ============== DIALOG METHODS ==============

  Future<void> _showProductDialog({Map<String, dynamic>? product}) async {
    await showDialog(
      context: context,
      builder: (context) => ProductFormDialog(
        product: product,
        productsLogic: _productsLogic,
        onSuccess: () {
          _loadInitialData();
        },
      ),
    );
  }

  void _viewProduct(Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (context) => ProductDetailsDialog(
        product: product,
        productsLogic: _productsLogic,
      ),
    );
  }

  Future<void> _deleteProduct(Map<String, dynamic> product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المنتج'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('هل أنت متأكد من حذف المنتج؟'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ID: ${product['id']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('الاسم: ${product['name']}'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'تحذير: هذا الإجراء لا يمكن التراجع عنه!',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _productsLogic.deleteProduct(product['id'].toString());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حذف المنتج بنجاح')),
          );
          _loadInitialData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('فشل في حذف المنتج: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

// ============== SEPARATE DIALOGS ==============

class ProductFormDialog extends StatefulWidget {
  final Map<String, dynamic>? product;
  final ProductsLogic productsLogic;
  final VoidCallback onSuccess;

  const ProductFormDialog({
    super.key,
    this.product,
    required this.productsLogic,
    required this.onSuccess,
  });

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  late final TextEditingController _idController;
  late final TextEditingController _nameController;
  late final TextEditingController _supplierController;
  late final TextEditingController _taxNumberController;
  late final TextEditingController _invoiceNumberController;
  late final TextEditingController _poNumberController;

  // للفئات الهرمية
  List<Map<String, dynamic>> _level1Categories = [];
  List<Map<String, dynamic>> _level2Categories = [];
  List<Map<String, dynamic>> _level3Categories = [];
  List<Map<String, dynamic>> _level4Categories = [];
  
  int? _selectedLevel1;
  int? _selectedLevel2;
  int? _selectedLevel3;
  int? _selectedLevel4;
  
  bool _isLoading = false;
  bool _isIdValid = true;

  @override
  void initState() {
    super.initState();
    
    _idController = TextEditingController(text: widget.product?['id']?.toString() ?? '');
    _nameController = TextEditingController(text: widget.product?['name']?.toString() ?? '');
    _supplierController = TextEditingController(text: widget.product?['supplier']?.toString() ?? '');
    _taxNumberController = TextEditingController(text: widget.product?['supplier_tax_number']?.toString() ?? '');
    _invoiceNumberController = TextEditingController(text: widget.product?['electronic_invoice_number']?.toString() ?? '');
    _poNumberController = TextEditingController(text: widget.product?['po_number']?.toString() ?? '');
    
    _loadRootCategories();
  }

  Future<void> _loadRootCategories() async {
    try {
      final categories = await widget.productsLogic.getRootCategories();
      setState(() {
        _level1Categories = categories;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load categories: $e')),
      );
    }
  }

  Future<void> _loadSubCategories(int parentId, int level) async {
    try {
      final categories = await widget.productsLogic.getSubCategories(parentId);
      
      if (mounted) {
        setState(() {
          switch (level) {
            case 2:
              _level2Categories = categories;
              _level3Categories.clear();
              _level4Categories.clear();
              _selectedLevel2 = null;
              _selectedLevel3 = null;
              _selectedLevel4 = null;
              break;
            case 3:
              _level3Categories = categories;
              _level4Categories.clear();
              _selectedLevel3 = null;
              _selectedLevel4 = null;
              break;
            case 4:
              _level4Categories = categories;
              _selectedLevel4 = null;
              break;
          }
        });
        
        // Debug: طباعة للتأكد
        print('Loaded ${categories.length} categories for level $level');
        print('Level 2 categories: ${_level2Categories.length}');
      }
    } catch (e) {
      print('Error loading subcategories: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load subcategories: $e')),
        );
      }
    }
  }

  int? get _finalCategoryId {
    return _selectedLevel4 ?? _selectedLevel3 ?? _selectedLevel2 ?? _selectedLevel1;
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;
    final localizations = AppLocalizations.of(context);
    
    return AlertDialog(
      title: Text(isEditing 
          ? (localizations?.editProduct ?? 'تعديل المنتج') 
          : (localizations?.addProduct ?? 'إضافة منتج جديد')),
      content: SizedBox(
        width: 700,
        height: 600,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product ID & Name
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _idController,
                      enabled: !isEditing,
                      decoration: InputDecoration(
                        labelText: '${localizations?.productId ?? 'Product ID'} *',
                        border: const OutlineInputBorder(),
                        errorText: _isIdValid ? null : (localizations?.productIdExists ?? 'ID already exists'),
                      ),
                      onChanged: _validateId,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: '${localizations?.productName ?? 'اسم المنتج'} *',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Categories Section
              _buildCategoriesSection(),
              const SizedBox(height: 16),
              
              // Supplier Info
              TextField(
                controller: _supplierController,
                decoration: InputDecoration(
                  labelText: localizations?.supplier ?? 'المورد',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.business),
                ),
              ),
              const SizedBox(height: 16),
              
              // Additional Info
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _taxNumberController,
                      decoration: InputDecoration(
                        labelText: localizations?.taxNumber ?? 'الرقم الضريبي للمورد',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.receipt_long),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _invoiceNumberController,
                      decoration: InputDecoration(
                        labelText: localizations?.invoiceNumber ?? 'رقم الفاتورة الإلكترونية',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.receipt),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              TextField(
                controller: _poNumberController,
                decoration: InputDecoration(
                  labelText: localizations?.poNumber ?? 'رقم أمر الشراء (PO)',
                  border: const OutlineInputBorder(),
                  prefixIcon: Icon(Icons.assignment),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(localizations?.cancel ?? 'إلغاء'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveProduct,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEditing 
                  ? (localizations?.edit ?? 'تحديث') 
                  : (localizations?.add ?? 'إضافة')),
        ),
      ],
    );
  }

  Widget _buildCategoriesSection() {
    final localizations = AppLocalizations.of(context);
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isEnglish ? 'Hierarchical Categories:' : 'الفئات الهرمية:',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        
        // Level 1 Categories (دايماً يظهر)
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int?>(
                value: _selectedLevel1,
                decoration: InputDecoration(
                  labelText: localizations?.mainCategory ?? 'الفئة الرئيسية',
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem<int?>(
                      value: null, 
                      child: Text(isEnglish ? 'Select Category' : 'اختر الفئة')
                  ),
                  ..._level1Categories.map((cat) {
                    return DropdownMenuItem<int?>(
                      value: cat['id'],
                      child: Text(cat['name']),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedLevel1 = value;
                    // مسح الفئات الفرعية عند تغيير الفئة الرئيسية
                    _level2Categories.clear();
                    _level3Categories.clear();
                    _level4Categories.clear();
                    _selectedLevel2 = null;
                    _selectedLevel3 = null;
                    _selectedLevel4 = null;
                  });
                  if (value != null) {
                    _loadSubCategories(value, 2);
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _showAddCategoryDialog(1, null),
              icon: const Icon(Icons.add_circle, color: Colors.green),
              tooltip: isEnglish ? 'Add Main Category' : 'إضافة فئة رئيسية',
            ),
          ],
        ),
        
        // Level 2 Categories (يظهر إذا تم اختيار فئة رئيسية)
        if (_selectedLevel1 != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int?>(
                  value: _selectedLevel2,
                  decoration: InputDecoration(
                    labelText: localizations?.subCategory1 ?? 'الفئة الفرعية الأولى',
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem<int?>(
                        value: null, 
                        child: Text(isEnglish ? 'Select Category' : 'اختر الفئة')
                    ),
                    ..._level2Categories.map((cat) {
                      return DropdownMenuItem<int?>(
                        value: cat['id'],
                        child: Text(cat['name']),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedLevel2 = value;
                      // مسح الفئات الأعمق عند تغيير الفئة الفرعية
                      _level3Categories.clear();
                      _level4Categories.clear();
                      _selectedLevel3 = null;
                      _selectedLevel4 = null;
                    });
                    if (value != null) {
                      _loadSubCategories(value, 3);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _showAddCategoryDialog(2, _selectedLevel1),
                icon: const Icon(Icons.add_circle, color: Colors.green),
                tooltip: isEnglish ? 'Add Subcategory' : 'إضافة فئة فرعية',
              ),
            ],
          ),
        ],
        
        // Level 3 Categories (يظهر إذا تم اختيار فئة فرعية أولى)
        if (_selectedLevel2 != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int?>(
                  value: _selectedLevel3,
                  decoration: InputDecoration(
                    labelText: localizations?.subCategory2 ?? 'الفئة الفرعية الثانية',
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem<int?>(
                        value: null, 
                        child: Text(isEnglish ? 'Select Category' : 'اختر الفئة')
                    ),
                    ..._level3Categories.map((cat) {
                      return DropdownMenuItem<int?>(
                        value: cat['id'],
                        child: Text(cat['name']),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedLevel3 = value;
                      // مسح الفئات الأعمق عند تغيير الفئة الفرعية
                      _level4Categories.clear();
                      _selectedLevel4 = null;
                    });
                    if (value != null) {
                      _loadSubCategories(value, 4);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _showAddCategoryDialog(3, _selectedLevel2),
                icon: const Icon(Icons.add_circle, color: Colors.green),
                tooltip: isEnglish ? 'Add Subcategory' : 'إضافة فئة فرعية',
              ),
            ],
          ),
        ],
        
        // Level 4 Categories (يظهر إذا تم اختيار فئة فرعية ثانية)
        if (_selectedLevel3 != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int?>(
                  value: _selectedLevel4,
                  decoration: InputDecoration(
                    labelText: localizations?.subCategory3 ?? 'الفئة الفرعية الثالثة',
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem<int?>(
                        value: null, 
                        child: Text(isEnglish ? 'Select Category' : 'اختر الفئة')
                    ),
                    ..._level4Categories.map((cat) {
                      return DropdownMenuItem<int?>(
                        value: cat['id'],
                        child: Text(cat['name']),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedLevel4 = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _showAddCategoryDialog(4, _selectedLevel3),
                icon: const Icon(Icons.add_circle, color: Colors.green),
                tooltip: isEnglish ? 'Add Subcategory' : 'إضافة فئة فرعية',
              ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _showAddCategoryDialog(int level, int? parentId) async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${isEnglish ? 'Add' : 'إضافة'} ${_getLevelName(level, isEnglish)}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: '${isEnglish ? 'Category Name' : 'اسم الفئة'} *',
                border: const OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: isEnglish ? 'Description (Optional)' : 'الوصف (اختياري)',
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(isEnglish ? 'Cancel' : 'إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            child: Text(isEnglish ? 'Add' : 'إضافة'),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.trim().isNotEmpty) {
      try {
        await widget.productsLogic.addCategory(
          name: nameController.text.trim(),
          parentId: parentId,
          description: descriptionController.text.trim().isNotEmpty 
              ? descriptionController.text.trim() 
              : null,
        );

        // إعادة تحميل الفئات
        if (level == 1) {
          _loadRootCategories();
        } else if (parentId != null) {
          _loadSubCategories(parentId, level);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إضافة الفئة بنجاح')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في إضافة الفئة: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getLevelName(int level, [bool isEnglish = false]) {
    switch (level) {
      case 1: return isEnglish ? 'Main Category' : 'فئة رئيسية';
      case 2: return isEnglish ? 'First Subcategory' : 'فئة فرعية أولى';
      case 3: return isEnglish ? 'Second Subcategory' : 'فئة فرعية ثانية';
      case 4: return isEnglish ? 'Third Subcategory' : 'فئة فرعية ثالثة';
      default: return isEnglish ? 'Subcategory' : 'فئة فرعية';
    }
  }

  Future<void> _validateId(String value) async {
    if (value.isEmpty || widget.product != null) return;

    try {
      final isAvailable = await widget.productsLogic.isProductIdAvailable(value);
      setState(() {
        _isIdValid = isAvailable;
      });
    } catch (e) {
      setState(() {
        _isIdValid = false;
      });
    }
  }

  Future<void> _saveProduct() async {
    // التحقق من البيانات
    final validation = widget.productsLogic.validateProductData(
      id: _idController.text.trim(),
      name: _nameController.text.trim(),
    );

    if (validation != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validation), backgroundColor: Colors.red),
      );
      return;
    }

    if (!_isIdValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product ID already exists'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final isEditing = widget.product != null;
      
      if (isEditing) {
        await widget.productsLogic.updateProduct(
          id: _idController.text.trim(),
          name: _nameController.text.trim(),
          categoryId: _finalCategoryId,
          supplier: _supplierController.text.trim().isNotEmpty ? _supplierController.text.trim() : null,
          supplierTaxNumber: _taxNumberController.text.trim().isNotEmpty ? _taxNumberController.text.trim() : null,
          electronicInvoiceNumber: _invoiceNumberController.text.trim().isNotEmpty ? _invoiceNumberController.text.trim() : null,
          poNumber: _poNumberController.text.trim().isNotEmpty ? _poNumberController.text.trim() : null,
        );
      } else {
        await widget.productsLogic.addProduct(
          id: _idController.text.trim(),
          name: _nameController.text.trim(),
          categoryId: _finalCategoryId,
          supplier: _supplierController.text.trim().isNotEmpty ? _supplierController.text.trim() : null,
          supplierTaxNumber: _taxNumberController.text.trim().isNotEmpty ? _taxNumberController.text.trim() : null,
          electronicInvoiceNumber: _invoiceNumberController.text.trim().isNotEmpty ? _invoiceNumberController.text.trim() : null,
          poNumber: _poNumberController.text.trim().isNotEmpty ? _poNumberController.text.trim() : null,
        );
      }

      widget.onSuccess();
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'تم تحديث المنتج بنجاح' : 'تم إضافة المنتج بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _supplierController.dispose();
    _taxNumberController.dispose();
    _invoiceNumberController.dispose();
    _poNumberController.dispose();
    super.dispose();
  }
}

// ============== PRODUCT DETAILS DIALOG ==============

class ProductDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> product;
  final ProductsLogic productsLogic;

  const ProductDetailsDialog({
    super.key,
    required this.product,
    required this.productsLogic,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.inventory_2, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'تفاصيل المنتج',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.withOpacity(0.1), Colors.blue.withOpacity(0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                             product['id'].toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(product['status']).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getStatusText(product['status']),
                            style: TextStyle(
                              color: _getStatusColor(product['status']),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      product['name'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Basic Info
              _buildInfoSection('المعلومات الأساسية', [
                _buildDetailRow('الاسم:', product['name']),
                _buildDetailRow('الفئة:', product['category']?['name'] ?? 'غير محدد'),
              ]),

              // Supplier Info
              if (_hasSupplierInfo()) ...[
                const SizedBox(height: 16),
                _buildInfoSection('معلومات المورد', [
                  _buildDetailRow('المورد:', product['supplier'] ?? 'غير محدد'),
                  _buildDetailRow('الرقم الضريبي:', product['supplier_tax_number'] ?? 'غير محدد'),
                  _buildDetailRow('رقم الفاتورة:', product['electronic_invoice_number'] ?? 'غير محدد'),
                  _buildDetailRow('رقم PO:', product['po_number'] ?? 'غير محدد'),
                ]),
              ],

              // Stock Info using FutureBuilder
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إغلاق'),
        ),
      ],
    );
  }

  bool _hasSupplierInfo() {
    return product['supplier'] != null ||
           product['supplier_tax_number'] != null ||
           product['electronic_invoice_number'] != null ||
           product['po_number'] != null;
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'active': return Colors.green;
      case 'inactive': return Colors.orange;
      case 'discontinued': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'active': return 'نشط';
      case 'inactive': return 'غير نشط';
      case 'discontinued': return 'متوقف';
      default: return 'غير محدد';
    }
  }
}