import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../backend/stock_out_logic.dart';
import '../backend/main_layout_logic.dart';
import '../theme/app_theme.dart';
import 'print_stock_out_screen.dart';

class StockOutScreen extends StatefulWidget {
  const StockOutScreen({super.key});

  @override
  State<StockOutScreen> createState() => _StockOutScreenState();
}

class _StockOutScreenState extends State<StockOutScreen> {
  // ===========================
  // Controllers & Variables
  // ===========================
  
  final StockOutLogic _stockOutLogic = StockOutLogic();
  final MainLayoutLogic _layoutLogic = MainLayoutLogic();
  
  // قائمة البيانات
  List<StockOut> _stockOuts = [];
  List<StockOut> _filteredStockOuts = [];
  List<Map<String, dynamic>> _warehouses = [];
  
  // Loading & Error States
  bool _isLoading = true;
  String? _errorMessage;
  String? _userRole;
  
  // Search & Filter Controllers
  final TextEditingController _searchController = TextEditingController();
  String? _selectedType;
  String? _selectedWarehouse;
  DateTime? _startDate;
  DateTime? _endDate;
  
  // Add/Edit Dialog Controllers
  final List<ProductItemController> _productControllers = [];
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _usageLocationController = TextEditingController();
  
  String? _selectedDialogWarehouse;
  String? _selectedFromWarehouse;
  String? _selectedToWarehouse;
  String _selectedDialogType = 'used';
  DateTime _selectedDate = DateTime.now();
  
  // Edit Mode
  StockOut? _editingStockOut;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _notesController.dispose();
    _usageLocationController.dispose();
    for (var controller in _productControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // ===========================
  // Data Loading
  // ===========================
  
  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // جلب دور المستخدم
      _userRole = await _layoutLogic.getCurrentUserRole();

      // جلب المخازن
      _warehouses = await _stockOutLogic.getWarehouses();
      
      // جلب سجلات الصرف
      await _loadStockOuts();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _loadStockOuts() async {
    try {
      final filter = StockOutFilter(
        searchQuery: _searchController.text,
        type: _selectedType,
        warehouseId: _selectedWarehouse,
        startDate: _startDate,
        endDate: _endDate,
      );

      _stockOuts = await _stockOutLogic.getStockOuts(filter: filter);
      
      
      
      _filteredStockOuts = _stockOuts;
      setState(() {});
    } catch (e) {
      throw e;
    }
  }

  // ===========================
  // Filter Functions
  // ===========================
  
  void _applyFilters() {
    _loadStockOuts();
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedType = null;
      _selectedWarehouse = null;
      _startDate = null;
      _endDate = null;
    });
    _applyFilters();
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      locale: Localizations.localeOf(context),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _applyFilters();
    }
  }

  // ===========================
  // Build UI
  // ===========================

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isRTL = Localizations.localeOf(context).languageCode == 'ar';
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.grey[50],
      body: Column(
        children: [
          // Header Section
          _buildHeader(localizations, isDarkMode, isRTL),
          
          // Main Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? _buildErrorWidget(localizations)
                    : _filteredStockOuts.isEmpty
                        ? _buildEmptyWidget(localizations, isDarkMode)
                        : _buildDataTable(localizations, isDarkMode, isRTL),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AppLocalizations localizations, bool isDarkMode, bool isRTL) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Title and Add Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isRTL ? 'إخراج المخزون' : 'Stock Out',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              // Hide Add button for project_manager
              if (_userRole != 'project_manager')
                ElevatedButton.icon(
                  onPressed: () => _showAddEditDialog(),
                  icon: const Icon(Icons.add, size: 20, color: Colors.white),
                  label: Text(isRTL ? 'تسجيل صرف' : 'Record Stock Out'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Search and Filters
          Row(
            children: [
              // Search Field
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: isRTL 
                        ? 'بحث برقم الصرف أو رقم السجل أو كود المنتج...'
                        : 'Search by Exchange No, Record ID , or Product ID...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (value) {
                    if (value.isEmpty || value.length >= 2) {
                      _applyFilters();
                    }
                  },
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Type Filter
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String?>(
                  value: _selectedType,
                  decoration: InputDecoration(
                    labelText: isRTL ? 'النوع' : 'Type',
                    filled: true,
                    fillColor: isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: <DropdownMenuItem<String?>>[
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(isRTL ? 'الكل' : 'All'),
                    ),
                    const DropdownMenuItem<String?>(
                      value: 'used',
                      child: Text('Used'),
                    ),
                    const DropdownMenuItem<String?>(
                      value: 'transfer',
                      child: Text('Transfer'),
                    ),
                    const DropdownMenuItem<String?>(
                      value: 'return',
                      child: Text('Return'),
                    ),
                    const DropdownMenuItem<String?>(
                      value: 'damage',
                      child: Text('Damage'),
                    ),
                  ].map((item) {
                    // Localize static labels
                    if (item.value == 'used') {
                      return DropdownMenuItem<String?>(
                        value: 'used',
                        child: Text(isRTL ? 'استخدام' : 'Used'),
                      );
                    } else if (item.value == 'transfer') {
                      return DropdownMenuItem<String?>(
                        value: 'transfer',
                        child: Text(isRTL ? 'تحويل' : 'Transfer'),
                      );
                    } else if (item.value == 'return') {
                      return DropdownMenuItem<String?>(
                        value: 'return',
                        child: Text(isRTL ? 'إرجاع' : 'Return'),
                      );
                    } else if (item.value == 'damage') {
                      return DropdownMenuItem<String?>(
                        value: 'damage',
                        child: Text(isRTL ? 'تالف' : 'Damage'),
                      );
                    }
                    return item; // 'All'
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value;
                    });
                    _applyFilters();
                  },
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Warehouse Filter
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String?>(
                  value: _selectedWarehouse,
                  decoration: InputDecoration(
                    labelText: isRTL ? 'المخزن' : 'Warehouse',
                    filled: true,
                    fillColor: isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: <DropdownMenuItem<String?>>[
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(isRTL ? 'الكل' : 'All'),
                    ),
                    ..._warehouses.map<DropdownMenuItem<String?>>(
                      (warehouse) => DropdownMenuItem<String?>(
                        value: warehouse['id']?.toString(),
                        child: Text((warehouse['name'] ?? '').toString()),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedWarehouse = value;
                    });
                    _applyFilters();
                  },
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Date Range Button
              ElevatedButton.icon(
                onPressed: _selectDateRange,
                icon: const Icon(Icons.date_range, size: 18),
                label: Text(
                  _startDate != null && _endDate != null
                      ? '${DateFormat('dd/MM').format(_startDate!)} - ${DateFormat('dd/MM').format(_endDate!)}'
                      : isRTL ? 'التاريخ' : 'Date',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey[100],
                  foregroundColor: isDarkMode ? Colors.white70 : Colors.black87,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Clear Filters Button
              if (_searchController.text.isNotEmpty ||
                  _selectedType != null ||
                  _selectedWarehouse != null ||
                  _startDate != null)
                IconButton(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.clear),
                  tooltip: isRTL ? 'مسح الفلاتر' : 'Clear Filters',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable(AppLocalizations localizations, bool isDarkMode, bool isRTL) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey[50],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                _buildTableHeader(isRTL ? 'رقم الصرف' : 'Exchange #', 1),
                _buildTableHeader(isRTL ? 'رقم السجل' : 'Record ID', 1),
                _buildTableHeader(isRTL ? 'التاريخ' : 'Date', 1),
               _buildTableHeader(isRTL ? 'كود المنتج' : 'Product ID', 1),
                _buildTableHeader(isRTL ? 'اسم المنتج' : 'Product Name', 2),
                _buildTableHeader(isRTL ? 'الكمية' : 'Quantity', 1),
                _buildTableHeader(isRTL ? 'الوحدة' : 'Unit', 1),
                _buildTableHeader(isRTL ? 'المخزن' : 'Warehouse', 1),
                _buildTableHeader(isRTL ? 'موقع الاستخدام' : 'Usage Location', 1),
                _buildTableHeader(isRTL ? 'النوع' : 'Type', 1),
                _buildTableHeader(isRTL ? 'من' : 'From', 1),
                _buildTableHeader(isRTL ? 'إلى' : 'To', 1),
                _buildTableHeader(isRTL ? 'ملاحظات' : 'Notes', 2),
                _buildTableHeader(isRTL ? 'الإجراءات' : 'Actions', 1),
              ],
            ),
          ),
          
          // Table Body
          Expanded(
            child: ListView.builder(
              itemCount: _filteredStockOuts.length,
              itemBuilder: (context, index) {
                final stockOut = _filteredStockOuts[index];
                return _buildTableRow(stockOut, index, isDarkMode, isRTL);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String text, int flex) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildTableRow(StockOut stockOut, int index, bool isDarkMode, bool isRTL) {
    final isEven = index % 2 == 0;
    final rowColor = isEven
        ? (isDarkMode ? const Color(0xFF252525) : Colors.grey[50])
        : (isDarkMode ? const Color(0xFF1E1E1E) : Colors.white);

    
    // تحديد لون النوع
    Color typeColor;
    switch (stockOut.type) {
      case 'used':
        typeColor = Colors.blue;
        break;
      case 'transfer':
        typeColor = Colors.orange;
        break;
      case 'return':
        typeColor = Colors.green;
        break;
      case 'damage':
        typeColor = Colors.red;
        break;
      default:
        typeColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: rowColor,
        border: Border(
          bottom: BorderSide(
            color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Exchange Number
          Expanded(
            flex: 1,
            child: Text(
              stockOut.exchangeNumber,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          
          // Record ID
          // عرض record_id لكل item
Expanded(
  flex: 1,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: stockOut.items.map((item) => Text(
      item.recordId ?? 'N/A',
      style: const TextStyle(fontSize: 11),
      overflow: TextOverflow.ellipsis,
    )).toList(),
  ),
),
          
          // Date
          Expanded(
            flex: 1,
            child: Text(
              DateFormat('dd/MM/yyyy').format(stockOut.date),
              style: const TextStyle(fontSize: 12),
            ),
          ),
          
          // Product ID
Expanded(
  flex: 1,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: stockOut.items.map((item) => Text(
      item.productId,
      style: const TextStyle(fontSize: 11),
      overflow: TextOverflow.ellipsis,
    )).toList(),
  ),
),

// Product Name
Expanded(
  flex: 2,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: stockOut.items.map((item) => Text(
      item.productName,
      style: const TextStyle(fontSize: 11),
      overflow: TextOverflow.ellipsis,
    )).toList(),
  ),
),
          
          // Total Quantity
          // Quantity - عرض كمية كل منتج منفصلة
Expanded(
  flex: 1,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: stockOut.items.map((item) => Text(
      item.quantity.toStringAsFixed(2),
      style: const TextStyle(fontSize: 11),
    )).toList(),
  ),
),

          // Unit
Expanded(
  flex: 1,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: stockOut.items.map((item) => Text(
      item.unit,
      style: const TextStyle(fontSize: 11),
    )).toList(),
  ),
),
          
          // Warehouse
          Expanded(
            flex: 1,
            child: Text(
              stockOut.type == 'transfer' 
                  ? '-'
                  : stockOut.warehouseName,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          
          // Usage Location
          Expanded(
            flex: 1,
            child: Text(
              stockOut.usageLocation ?? '-',
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          // Type
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _getTypeText(stockOut.type, isRTL),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: typeColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          
          // From
          Expanded(
            flex: 1,
            child: Text(
              stockOut.type == 'transfer' 
                  ? stockOut.fromWarehouseName ?? '-'
                  : 'N/A',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          
          // To
          Expanded(
            flex: 1,
            child: Text(
              stockOut.type == 'transfer' 
                  ? stockOut.toWarehouseName ?? '-'
                  : 'N/A',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          
          // Notes
          Expanded(
            flex: 2,
            child: Text(
              stockOut.notes ?? '-',
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          // Actions
          Expanded(
            flex: 1,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Edit button - hide for warehouse_manager and project_manager
                if (_userRole != 'warehouse_manager' && _userRole != 'project_manager')
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: () => _showAddEditDialog(stockOut: stockOut),
                    tooltip: isRTL ? 'تعديل' : 'Edit',
                    color: Colors.blue,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                  ),
                // Delete button - hide for project_manager
                if (_userRole != 'project_manager')
                  IconButton(
                    icon: const Icon(Icons.delete, size: 18),
                    onPressed: () => _confirmDelete(stockOut),
                    tooltip: isRTL ? 'حذف' : 'Delete',
                    color: Colors.red,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                  ),
                IconButton(
                  icon: const Icon(Icons.print, size: 18),
                  onPressed: () => _printStockOut(stockOut),
                  tooltip: isRTL ? 'طباعة' : 'Print',
                  color: Colors.green,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTypeText(String type, bool isRTL) {
    switch (type) {
      case 'used':
        return isRTL ? 'استخدام' : 'Used';
      case 'transfer':
        return isRTL ? 'تحويل' : 'Transfer';
      case 'return':
        return isRTL ? 'إرجاع' : 'Return';
      case 'damage':
        return isRTL ? 'تالف' : 'Damage';
      default:
        return type;
    }
  }

  Widget _buildEmptyWidget(AppLocalizations localizations, bool isDarkMode) {
    final isRTL = Localizations.localeOf(context).languageCode == 'ar';
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            isRTL ? 'لا توجد سجلات صرف' : 'No stock out records',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isRTL ? 'ابدأ بإضافة سجل صرف جديد' : 'Start by adding a new stock out record',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(AppLocalizations localizations) {
    final isRTL = Localizations.localeOf(context).languageCode == 'ar';
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 60,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            isRTL ? 'حدث خطأ' : 'An error occurred',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: Text(isRTL ? 'إعادة المحاولة' : 'Retry'),
          ),
        ],
      ),
    );
  }

  // ===========================
  // Add/Edit Dialog
  // ===========================

  void _showAddEditDialog({StockOut? stockOut}) {
    final isRTL = Localizations.localeOf(context).languageCode == 'ar';
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    setState(() {
      _isEditMode = stockOut != null;
      _editingStockOut = stockOut;
      
      // Reset controllers
      _productControllers.clear();
      _notesController.clear();
      _usageLocationController.clear();
      
      if (stockOut != null) {
        // Fill data for edit mode
        _selectedDialogType = stockOut.type;
        _selectedDate = stockOut.date;
        _notesController.text = stockOut.notes ?? '';
        _usageLocationController.text = stockOut.usageLocation ?? '';
        
        if (stockOut.type == 'transfer') {
          _selectedFromWarehouse = stockOut.fromWarehouseId;
          _selectedToWarehouse = stockOut.toWarehouseId;
        } else {
          _selectedDialogWarehouse = stockOut.warehouseId;
        }
        
        // Add product controllers
        for (var item in stockOut.items) {
          final controller = ProductItemController();
          controller.productIdController.text = item.productId;
          controller.productNameController.text = item.productName;
          controller.quantityController.text = item.quantity.toString();
          controller.unitController.text = item.unit;
          _productControllers.add(controller);
        }
      } else {
        // Add mode - start with one empty product
        _selectedDialogType = 'used';
        _selectedDate = DateTime.now();
        _selectedDialogWarehouse = null;
        _selectedFromWarehouse = null;
        _selectedToWarehouse = null;
        _productControllers.add(ProductItemController());
      }
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.height * 0.85,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dialog Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _isEditMode
                              ? (isRTL ? 'تعديل سجل الصرف' : 'Edit Stock Out')
                              : (isRTL ? 'تسجيل صرف جديد' : 'Record Stock Out'),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    
                    const Divider(),
                    
                    // Dialog Body
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Products Section
                            _buildProductsSection(setDialogState, isRTL, isDarkMode),
                            
                            const SizedBox(height: 24),
                            
                            // General Information Section
                            _buildGeneralInfoSection(setDialogState, isRTL, isDarkMode),
                          ],
                        ),
                      ),
                    ),
                    
                    // Dialog Actions
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(isRTL ? 'إلغاء' : 'Cancel'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () => _saveStockOut(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          child: Text(
                            _isEditMode
                                ? (isRTL ? 'حفظ التغييرات' : 'Save Changes')
                                : (isRTL ? 'إضافة' : 'Add'),
                          ),
                        ),
                      ],
                    ),
                    ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProductsSection(StateSetter setDialogState, bool isRTL, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isRTL ? 'المنتجات' : 'Products',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              onPressed: () {
                setDialogState(() {
                  _productControllers.add(ProductItemController());
                });
              },
              icon: const Icon(Icons.add_circle_outline),
              color: AppTheme.primaryColor,
              tooltip: isRTL ? 'إضافة منتج' : 'Add Product',
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Products List
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _productControllers.length,
          itemBuilder: (context, index) {
            return _buildProductItem(index, setDialogState, isRTL, isDarkMode);
          },
        ),
      ],
    );
  }

  Widget _buildProductItem(int index, StateSetter setDialogState, bool isRTL, bool isDarkMode) {
    final controller = _productControllers[index];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          // Product ID Field
          Expanded(
            flex: 2,
            child: TextField(
              controller: controller.productIdController,
              decoration: InputDecoration(
                labelText: isRTL ? 'كود المنتج' : 'Product ID',
                filled: true,
                fillColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onChanged: (value) async {
                if (value.isNotEmpty) {
                  final product = await _stockOutLogic.getProductById(value);
                  if (product != null) {
                    setDialogState(() {
                      controller.productNameController.text = product['name'] ?? '';
                      controller.unitController.text = product['unit'] ?? '';
                    });
                  }
                }
              },
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Product Name Field with Autocomplete
          Expanded(
            flex: 3,
            child: Autocomplete<Map<String, dynamic>>(
              optionsBuilder: (TextEditingValue textEditingValue) async {
                if (textEditingValue.text.isEmpty) {
                  return const Iterable<Map<String, dynamic>>.empty();
                }
                final products = await _stockOutLogic.searchProducts(textEditingValue.text);
                return products;
              },
              displayStringForOption: (Map<String, dynamic> option) => option['name'],
              fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                textEditingController.text = controller.productNameController.text;
                return TextField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    labelText: isRTL ? 'اسم المنتج' : 'Product Name',
                    filled: true,
                    fillColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (value) {
                    controller.productNameController.text = value;
                  },
                );
              },
              onSelected: (Map<String, dynamic> selection) {
                setDialogState(() {
                  controller.productIdController.text = selection['id'];
                  controller.productNameController.text = selection['name'];
                  controller.unitController.text = selection['unit'] ?? '';
                });
              },
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Quantity Field
          Expanded(
            flex: 2,
            child: TextField(
              controller: controller.quantityController,
              decoration: InputDecoration(
                labelText: isRTL ? 'الكمية' : 'Quantity',
                filled: true,
                fillColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Unit Field
          Expanded(
            flex: 1,
            child: TextField(
              controller: controller.unitController,
              decoration: InputDecoration(
                labelText: isRTL ? 'الوحدة' : 'Unit',
                filled: true,
                fillColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              readOnly: true,
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Remove Button
          if (_productControllers.length > 1)
            IconButton(
              onPressed: () {
                setDialogState(() {
                  controller.dispose();
                  _productControllers.removeAt(index);
                });
              },
              icon: const Icon(Icons.remove_circle_outline),
              color: Colors.red,
              tooltip: isRTL ? 'حذف' : 'Remove',
            ),
        ],
      ),
    );
  }

  Widget _buildGeneralInfoSection(StateSetter setDialogState, bool isRTL, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Text(
          isRTL ? 'معلومات عامة' : 'General Information',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Fields Grid
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            // Type Dropdown
            SizedBox(
              width: 200,
              child: DropdownButtonFormField<String>(
                value: _selectedDialogType,
                decoration: InputDecoration(
                  labelText: isRTL ? 'النوع' : 'Type',
                  filled: true,
                  fillColor: isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'used',
                    child: Text(isRTL ? 'استخدام' : 'Used'),
                  ),
                  DropdownMenuItem(
                    value: 'transfer',
                    child: Text(isRTL ? 'تحويل' : 'Transfer'),
                  ),
                  DropdownMenuItem(
                    value: 'return',
                    child: Text(isRTL ? 'إرجاع' : 'Return'),
                  ),
                  DropdownMenuItem(
                    value: 'damage',
                    child: Text(isRTL ? 'تالف' : 'Damage'),
                  ),
                ],
                onChanged: (value) {
                  setDialogState(() {
                    _selectedDialogType = value!;
                    // Reset warehouse selections
                    _selectedDialogWarehouse = null;
                    _selectedFromWarehouse = null;
                    _selectedToWarehouse = null;
                  });
                },
              ),
            ),
            
            // Warehouse/From-To Fields based on Type
            if (_selectedDialogType != 'transfer') ...[
              // Single Warehouse for non-transfer types
              SizedBox(
                width: 250,
                child: DropdownButtonFormField<String?>(
                  value: _selectedDialogWarehouse,
                  decoration: InputDecoration(
                    labelText: isRTL ? 'المخزن' : 'Warehouse',
                    filled: true,
                    fillColor: isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: _warehouses.map<DropdownMenuItem<String?>>(
                    (warehouse) => DropdownMenuItem<String?>(
                      value: warehouse['id']?.toString(),
                      child: Text((warehouse['name'] ?? '').toString()),
                    ),
                  ).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      _selectedDialogWarehouse = value;
                    });
                  },
                ),
              ),
            ] else ...[
              // From and To Warehouses for transfer type
              SizedBox(
                width: 250,
                child: DropdownButtonFormField<String?>(
                  value: _selectedFromWarehouse,
                  decoration: InputDecoration(
                    labelText: isRTL ? 'من مخزن' : 'From Warehouse',
                    filled: true,
                    fillColor: _isEditMode 
                        ? (isDarkMode ? const Color(0xFF3C3C3C) : Colors.grey[200])
                        : (isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey[50]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: _warehouses.map<DropdownMenuItem<String?>>(
                    (warehouse) => DropdownMenuItem<String?>(
                      value: warehouse['id']?.toString(),
                      child: Text((warehouse['name'] ?? '').toString()),
                    ),
                  ).toList(),
                  onChanged: _isEditMode ? null : (value) {
                    setDialogState(() {
                      _selectedFromWarehouse = value;
                    });
                  },
                ),
              ),
              
              SizedBox(
                width: 250,
                child: DropdownButtonFormField<String?>(
                  value: _selectedToWarehouse,
                  decoration: InputDecoration(
                    labelText: isRTL ? 'إلى مخزن' : 'To Warehouse',
                    filled: true,
                    fillColor: isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: _warehouses
                      .where((w) => (w['id']?.toString()) != _selectedFromWarehouse)
                      .map<DropdownMenuItem<String?>>((warehouse) => DropdownMenuItem<String?> (
                        value: warehouse['id']?.toString(),
                        child: Text((warehouse['name'] ?? '').toString()),
                      )).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      _selectedToWarehouse = value;
                    });
                  },
                ),
              ),
            ],
            
            // Usage Location Field
            SizedBox(
              width: 250,
              child: TextField(
                controller: _usageLocationController,
                decoration: InputDecoration(
                  labelText: isRTL ? 'موقع الاستخدام' : 'Usage Location',
                  filled: true,
                  fillColor: isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            
            // Date Field
            SizedBox(
              width: 200,
              child: InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    locale: Localizations.localeOf(context),
                  );
                  if (picked != null) {
                    setDialogState(() {
                      _selectedDate = picked;
                    });
                  }
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: isRTL ? 'التاريخ' : 'Date',
                    filled: true,
                    fillColor: isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    DateFormat('dd/MM/yyyy').format(_selectedDate),
                  ),
                ),
              ),
            ),
            
            // Notes Field
            SizedBox(
              width: double.infinity,
              child: TextField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: isRTL ? 'ملاحظات' : 'Notes',
                  filled: true,
                  fillColor: isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                maxLines: 3,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _saveStockOut() async {
    final isRTL = Localizations.localeOf(context).languageCode == 'ar';
    
    // Validation
    if (_productControllers.isEmpty) {
      _showSnackBar(
        isRTL ? 'يجب إضافة منتج واحد على الأقل' : 'Please add at least one product',
        isError: true,
      );
      return;
    }
    
    // Validate products
    for (var controller in _productControllers) {
      if (controller.productIdController.text.isEmpty ||
          controller.quantityController.text.isEmpty) {
        _showSnackBar(
          isRTL ? 'يرجى ملء جميع حقول المنتجات' : 'Please fill all product fields',
          isError: true,
        );
        return;
      }
    }
    
    // Validate warehouse selection
    if (_selectedDialogType == 'transfer') {
      if (_selectedFromWarehouse == null || _selectedToWarehouse == null) {
        _showSnackBar(
          isRTL ? 'يرجى اختيار المخازن للتحويل' : 'Please select warehouses for transfer',
          isError: true,
        );
        return;
      }
    } else {
      if (_selectedDialogWarehouse == null) {
        _showSnackBar(
          isRTL ? 'يرجى اختيار المخزن' : 'Please select a warehouse',
          isError: true,
        );
        return;
      }
    }
    
    // Check stock availability
    for (var controller in _productControllers) {
      final quantity = double.tryParse(controller.quantityController.text) ?? 0;
      final warehouseId = _selectedDialogType == 'transfer' 
          ? _selectedFromWarehouse! 
          : _selectedDialogWarehouse!;
      
      final available = await _stockOutLogic.checkStockAvailability(
        warehouseId,
        controller.productIdController.text,
        quantity,
      );
      
      if (!available) {
        final availableQty = await _stockOutLogic.getAvailableQuantity(
          warehouseId,
          controller.productIdController.text,
        );
        
        _showSnackBar(
          isRTL 
              ? 'الكمية المتاحة من ${controller.productNameController.text}: $availableQty'
              : 'Available quantity of ${controller.productNameController.text}: $availableQty',
          isError: true,
        );
        return;
      }
    }
    
    // Prepare items
    final items = _productControllers.map((controller) => StockOutItem(
      productId: controller.productIdController.text,
      productName: controller.productNameController.text,
      quantity: double.parse(controller.quantityController.text),
      unit: controller.unitController.text,
    )).toList();
    
    // Get warehouse names
    String warehouseName = '';
    String? fromWarehouseName;
    String? toWarehouseName;
    
    if (_selectedDialogType == 'transfer') {
      fromWarehouseName = _warehouses.firstWhere(
  (w) => (w['id']?.toString()) == _selectedFromWarehouse,
      )['name'];
      toWarehouseName = _warehouses.firstWhere(
  (w) => (w['id']?.toString()) == _selectedToWarehouse,
      )['name'];
    } else {
      warehouseName = _warehouses.firstWhere(
  (w) => (w['id']?.toString()) == _selectedDialogWarehouse,
      )['name'];
    }
    
    // Create StockOut object
final stockOut = StockOut(
  id: _isEditMode ? _editingStockOut!.id : null,
  recordId: _isEditMode ? _editingStockOut!.recordId : '',
  exchangeNumber: _isEditMode ? _editingStockOut!.exchangeNumber : '',
  warehouseId: _selectedDialogType == 'transfer' 
      ? _selectedFromWarehouse ?? ''  // في حالة transfer استخدم from_warehouse
      : _selectedDialogWarehouse ?? '',
      warehouseName: warehouseName,
      type: _selectedDialogType,
      usageLocation: _usageLocationController.text.isEmpty 
          ? null 
          : _usageLocationController.text,
      fromWarehouseId: _selectedFromWarehouse,
      fromWarehouseName: fromWarehouseName,
      toWarehouseId: _selectedToWarehouse,
      toWarehouseName: toWarehouseName,
      date: _selectedDate,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      items: items,
    );
    
    try {
      // Show loading
      Navigator.of(context).pop();
      _showLoadingDialog();
      
      if (_isEditMode) {
        await _stockOutLogic.updateStockOut(stockOut);
        _showSnackBar(
          isRTL ? 'تم تحديث السجل بنجاح' : 'Record updated successfully',
        );
      } else {
        await _stockOutLogic.addStockOut(stockOut);
        _showSnackBar(
          isRTL ? 'تم إضافة السجل بنجاح' : 'Record added successfully',
        );
      }
      
      Navigator.of(context).pop(); // Close loading dialog
      await _loadData();
      
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      _showSnackBar(
        isRTL ? 'حدث خطأ: $e' : 'Error: $e',
        isError: true,
      );
    }
  }

  Future<void> _confirmDelete(StockOut stockOut) async {
    final isRTL = Localizations.localeOf(context).languageCode == 'ar';
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isRTL ? 'تأكيد الحذف' : 'Confirm Delete'),
        content: Text(
          isRTL 
              ? 'هل أنت متأكد من حذف سجل الصرف ${stockOut.recordId}؟'
              : 'Are you sure you want to delete stock out record ${stockOut.recordId}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(isRTL ? 'إلغاء' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(isRTL ? 'حذف' : 'Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed == true && stockOut.id != null) {
      try {
        _showLoadingDialog();
        await _stockOutLogic.deleteStockOut(stockOut.id!);
        Navigator.of(context).pop();
        _showSnackBar(
          isRTL ? 'تم حذف السجل بنجاح' : 'Record deleted successfully',
        );
        await _loadData();
      } catch (e) {
        Navigator.of(context).pop();
        _showSnackBar(
          isRTL ? 'حدث خطأ في الحذف: $e' : 'Error deleting: $e',
          isError: true,
        );
      }
    }
  }

  void _printStockOut(StockOut stockOut) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => PrintStockOutScreen(stockOut: stockOut),
    ),
  );
}

  // ===========================
  // Helper Methods
  // ===========================

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

// ===========================
// Helper Classes
// ===========================

class ProductItemController {
  final TextEditingController productIdController = TextEditingController();
  final TextEditingController productNameController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController unitController = TextEditingController();

  void dispose() {
    productIdController.dispose();
    productNameController.dispose();
    quantityController.dispose();
    unitController.dispose();
  }
}