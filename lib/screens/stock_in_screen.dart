import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../backend/stock_in_logic.dart';

class StockInScreen extends StatefulWidget {
  const StockInScreen({super.key});

  @override
  State<StockInScreen> createState() => _StockInScreenState();
}

class _StockInScreenState extends State<StockInScreen> {
  // Backend services
  final StockInLogic _stockInLogic = StockInLogic();
  
  // Data lists
  List<StockInRecord> _stockInRecords = [];
  List<StockInRecord> _filteredRecords = [];
  
  // Controllers for search and filters
  final TextEditingController _searchController = TextEditingController();
  
  // Filter variables
  String? _selectedSupplierId;
  DateTime? _startDate;
  DateTime? _endDate;
  
  // State variables
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // تحميل جميع البيانات
  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final records = await _stockInLogic.getStockInRecords();

      if (mounted) {
        setState(() {
          _stockInRecords = records;
          _filteredRecords = records; // Initialize filtered records
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading data: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  // تطبيق الفلاتر والبحث
  void _applyFilters() {
    setState(() {
      _filteredRecords = _stockInRecords.where((record) {
        // Search filter
        final searchQuery = _searchController.text.toLowerCase();
        final matchesSearch = searchQuery.isEmpty ||
            record.recordId.toLowerCase().contains(searchQuery) ||
            record.additionNumber.toLowerCase().contains(searchQuery) ||
            record.productId.toLowerCase().contains(searchQuery) ||
            (record.productName?.toLowerCase() ?? '').contains(searchQuery) ||
            (record.supplierName?.toLowerCase() ?? '').contains(searchQuery);

        // Supplier filter
        final matchesSupplier = _selectedSupplierId == null ||
            record.supplierId == _selectedSupplierId;

        // Date range filter
        final matchesDateRange = (_startDate == null || _endDate == null) ||
            (record.createdAt != null &&
                record.createdAt!.isAfter(_startDate!) &&
                record.createdAt!.isBefore(_endDate!.add(const Duration(days: 1))));

        return matchesSearch && matchesSupplier && matchesDateRange;
      }).toList();
    });
  }

  // مسح الفلاتر
  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedSupplierId = null;
      _startDate = null;
      _endDate = null;
      _filteredRecords = _stockInRecords;
    });
  }

  // الحصول على قائمة الموردين الفريدة للفلتر
  List<DropdownMenuItem<String>> _getUniqueSuppliers() {
    final suppliers = <String, String>{};
    for (final record in _stockInRecords) {
      if (record.supplierId != null && record.supplierName != null) {
        suppliers[record.supplierId!] = record.supplierName!;
      }
    }
    
    final items = <DropdownMenuItem<String>>[
      const DropdownMenuItem<String>(
        value: null,
        child: Text('All Suppliers'),
      ),
    ];
    
    suppliers.forEach((id, name) {
      items.add(DropdownMenuItem<String>(
        value: id,
        child: Text(name),
      ));
    });
    
    return items;
  }

  // اختيار نطاق التواريخ
  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(1900), // تاريخ بعيد في الماضي
      lastDate: DateTime(2100),  // تاريخ بعيد في المستقبل
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _applyFilters();
    }
  }

  // مزامنة مخزون المخازن مع سجلات Stock In
  Future<void> _syncWarehouseStock() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sync Warehouse Stock'),
        content: const Text(
          'This will sync all warehouse stock data with Stock In records. '
          'This process will update warehouse inventory based on all Stock In entries. '
          'Are you sure you want to continue?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Sync'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        setState(() => _isLoading = true);
        
        // عرض رسالة المعالجة
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Text('Syncing warehouse stock...'),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );

        await _stockInLogic.syncExistingStockInRecords();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Warehouse stock synced successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error syncing warehouse stock: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  // تحميل الفاتورة الإلكترونية
  void _downloadRecord(StockInRecord record) async {
    // التحقق من وجود فاتورة إلكترونية
    if (record.electronicInvoiceUrl == null || record.electronicInvoiceUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا توجد فاتورة إلكترونية لهذا السجل'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    try {
      // عرض رسالة تحميل
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Text('جاري فتح الفاتورة: ${record.invoiceFileName ?? 'Invoice.pdf'}'),
            ],
          ),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 2),
        ),
      );

      // فتح الفاتورة باستخدام url_launcher
      final bool success = await _stockInLogic.downloadElectronicInvoice(
        invoiceUrl: record.electronicInvoiceUrl!,
        fileName: record.invoiceFileName ?? 'Invoice.pdf',
      );

      if (success) {
        // عرض رسالة نجاح
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم فتح الفاتورة: ${record.invoiceFileName ?? 'Invoice.pdf'}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('فشل في فتح الفاتورة: ${e.toString()}'),
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      // نسخ الرابط للحافظة كبديل
                      Clipboard.setData(ClipboardData(text: record.electronicInvoiceUrl!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تم نسخ رابط الفاتورة للحافظة'),
                          backgroundColor: Colors.blue,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: const Text('نسخ الرابط', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock In'),
        automaticallyImplyLeading: false,
        actions: [
          // Sync Button
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _syncWarehouseStock,
            icon: const Icon(Icons.sync),
            label: const Text('Sync Stock'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : () => _showStockInDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Record Stock In'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search and Filters Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by Record ID, Product, or Supplier...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _applyFilters();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) => _applyFilters(),
                  ),
                  const SizedBox(height: 16),
                  // Filters Row
                  Row(
                    children: [
                      // Supplier Filter
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Filter by Supplier',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          value: _selectedSupplierId,
                          items: _getUniqueSuppliers(),
                          onChanged: (value) {
                            setState(() {
                              _selectedSupplierId = value;
                            });
                            _applyFilters();
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Date Range Filter
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _selectDateRange(),
                                icon: const Icon(Icons.date_range),
                                label: Text(
                                  _startDate != null && _endDate != null
                                      ? '${_startDate!.day}/${_startDate!.month} - ${_endDate!.day}/${_endDate!.month}'
                                      : 'Select Date Range',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            if (_startDate != null || _endDate != null)
                              IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    _startDate = null;
                                    _endDate = null;
                                  });
                                  _applyFilters();
                                },
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Clear All Filters Button
                      ElevatedButton.icon(
                        onPressed: _clearFilters,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Clear All'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Stock In Records Table
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Stock In Records',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _filteredRecords.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.inbox,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _stockInRecords.isEmpty 
                                        ? 'No stock in records found'
                                        : 'No records match your filters',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : SingleChildScrollView(
                              child: DataTable(
                                columns: const [
                                  DataColumn(label: Text('Addition NO')),
                                  DataColumn(label: Text('Record ID')),
                                  DataColumn(label: Text('Date')),
                                  DataColumn(label: Text('Product Name')),
                                  DataColumn(label: Text('Quantity')),
                                  DataColumn(label: Text('Unit')),
                                  DataColumn(label: Text('Supplier')),
                                  DataColumn(label: Text('Supplier Tax NO')),
                                  DataColumn(label: Text('Warehouse Name')),
                                  DataColumn(label: Text('Notes')),
                                  DataColumn(label: Text('Actions')),
                                ],
                                rows: _filteredRecords.map((record) {
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(record.additionNumber)),
                                      DataCell(Text(record.recordId)),
                                      DataCell(Text(
                                        (record.invoiceDate ?? record.createdAt) != null
                                            ? '${(record.invoiceDate ?? record.createdAt)!.day}/${(record.invoiceDate ?? record.createdAt)!.month}/${(record.invoiceDate ?? record.createdAt)!.year}'
                                            : 'N/A'
                                      )),
                                      DataCell(Text(record.productName ?? 'N/A')),
                                      DataCell(Text('${record.quantity}')),
                                      DataCell(Text(record.unit)),
                                      DataCell(Text(record.supplierName ?? 'N/A')),
                                      DataCell(Text(record.supplierTaxNumber ?? 'N/A')),
                                      DataCell(Text(record.warehouseName ?? record.warehouseCode ?? 'N/A')),
                                      DataCell(Text(record.notes ?? 'N/A')),
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.visibility, color: Colors.blue),
                                              onPressed: () => _viewRecord(record),
                                              tooltip: 'View',
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.edit, color: Colors.orange),
                                              onPressed: () => _showStockInDialog(record: record),
                                              tooltip: 'Edit',
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete, color: Colors.red),
                                              onPressed: () => _deleteRecord(record),
                                              tooltip: 'Delete',
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                record.electronicInvoiceUrl != null && record.electronicInvoiceUrl!.isNotEmpty
                                                    ? Icons.file_download
                                                    : Icons.download_outlined,
                                                color: record.electronicInvoiceUrl != null && record.electronicInvoiceUrl!.isNotEmpty
                                                    ? Colors.green
                                                    : Colors.grey,
                                              ),
                                              onPressed: () => _downloadRecord(record),
                                              tooltip: record.electronicInvoiceUrl != null && record.electronicInvoiceUrl!.isNotEmpty
                                                  ? 'Download Invoice'
                                                  : 'No Invoice Available',
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
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // حذف سجل مع تأكيد
  Future<void> _deleteRecord(StockInRecord record) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete record ${record.recordId}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && record.id != null) {
      try {
        await _stockInLogic.deleteStockInRecordWithStock(record.id!, record);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Record deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData(); // إعادة تحميل البيانات
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting record: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // عرض حوار إضافة/تعديل
  void _showStockInDialog({StockInRecord? record}) {
    showDialog(
      context: context,
      builder: (context) => StockInFormDialog(
        record: record,
        onSave: () {
          Navigator.pop(context);
          _loadData(); // إعادة تحميل البيانات بعد الحفظ
        },
      ),
    );
  }

  // عرض تفاصيل السجل
  void _viewRecord(StockInRecord record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Stock In Record - ${record.recordId}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Record ID:', record.recordId),
            _buildDetailRow('Addition Number:', record.additionNumber),
            _buildDetailRow('Product ID:', record.productId),
            _buildDetailRow('Product Name:', record.productName),
            _buildDetailRow('Quantity:', '${record.quantity} ${record.unit}'),
            _buildDetailRow('Supplier:', record.supplierName),
            _buildDetailRow('Tax Number:', record.supplierTaxNumber),
            _buildDetailRow('Warehouse:', 
              record.warehouseName != null 
                ? '${record.warehouseName} (${record.warehouseCode ?? 'N/A'})'
                : record.warehouseCode ?? 'N/A'),
            _buildDetailRow('Notes:', record.notes),
            _buildDetailRow('Date:', 
              (record.invoiceDate ?? record.createdAt) != null 
                ? '${(record.invoiceDate ?? record.createdAt)!.day}/${(record.invoiceDate ?? record.createdAt)!.month}/${(record.invoiceDate ?? record.createdAt)!.year}'
                : 'N/A'),
            if (record.electronicInvoiceUrl != null) ...[
              _buildDetailRow('Invoice File:', record.invoiceFileName ?? 'Electronic Invoice'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value ?? 'N/A')),
        ],
      ),
    );
  }
}

// حوار إضافة/تعديل سجل Stock In
class StockInFormDialog extends StatefulWidget {
  final StockInRecord? record;
  final VoidCallback onSave;

  const StockInFormDialog({
    super.key,
    this.record,
    required this.onSave,
  });

  @override
  State<StockInFormDialog> createState() => _StockInFormDialogState();
}

class _StockInFormDialogState extends State<StockInFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final StockInLogic _stockInLogic = StockInLogic();

  // Controllers
  final _productIdController = TextEditingController();
  final _productNameController = TextEditingController();
  final _supplierTaxController = TextEditingController();
  final _supplierNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();

  // Selected values
  String? _selectedProductId;
  String? _selectedSupplierId;
  String? _selectedWarehouseId;
  String? _selectedUnit = 'PC';
  DateTime? _selectedDate;

  // Invoice file state
  String? _selectedInvoiceFilePath;
  String? _selectedInvoiceFileName;
  bool _isUploadingInvoice = false;

  // State
  bool _isLoading = false;
  bool _isLoadingData = true;

  // Data lists
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  List<Map<String, dynamic>> _suppliers = [];
  List<Map<String, dynamic>> _filteredSuppliers = [];
  List<Map<String, dynamic>> _warehouses = [];

  @override
  void initState() {
    super.initState();
    _loadFormData();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.record != null) {
      _productIdController.text = widget.record!.productId;
      _productNameController.text = widget.record!.productName ?? '';
      _quantityController.text = widget.record!.quantity.toString();
      _notesController.text = widget.record!.notes ?? '';
      _selectedProductId = widget.record!.productId;
      _selectedSupplierId = widget.record!.supplierId;
      _selectedWarehouseId = widget.record!.warehouseId;
      _selectedUnit = widget.record!.unit;
      _selectedDate = widget.record!.invoiceDate ?? widget.record!.createdAt;
      
      // تعبئة بيانات الفاتورة
      if (widget.record!.electronicInvoiceUrl != null) {
        _selectedInvoiceFilePath = widget.record!.electronicInvoiceUrl;
        _selectedInvoiceFileName = widget.record!.invoiceFileName ?? 'Invoice.pdf';
      }
      
      // تعبئة بيانات المورد
      if (widget.record!.supplierTaxNumber != null) {
        _supplierTaxController.text = widget.record!.supplierTaxNumber!;
      }
      if (widget.record!.supplierName != null) {
        _supplierNameController.text = widget.record!.supplierName!;
      }
    } else {
      // للسجل الجديد، استخدم التاريخ الحالي كافتراضي
      _selectedDate = DateTime.now();
    }
  }

  Future<void> _loadFormData() async {
    try {
      setState(() => _isLoadingData = true);

      print('Loading form data...'); // للتصحيح

      // تحميل البيانات الفعلية من قاعدة البيانات
      final products = await _stockInLogic.getProducts();
      final suppliers = await _stockInLogic.getSuppliers();
      final warehouses = await _stockInLogic.getWarehouses();

      print('Products loaded: ${products.length}'); // للتصحيح
      print('Suppliers loaded: ${suppliers.length}'); // للتصحيح  
      print('Warehouses loaded: ${warehouses.length}'); // للتصحيح

      setState(() {
        _products = products;
        _filteredProducts = products;
        _suppliers = suppliers;
        _filteredSuppliers = suppliers;
        _warehouses = warehouses;
        _isLoadingData = false;
      });
    } catch (e) {
      print('Error loading form data: $e'); // للتصحيح
      setState(() => _isLoadingData = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading form data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _productIdController.dispose();
    _productNameController.dispose();
    _supplierTaxController.dispose();
    _supplierNameController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // فلترة المنتجات بناءً على النص المدخل
  void _filterProducts(String query) {
    print('Filtering products with query: $query'); // للتصحيح
    print('Total products: ${_products.length}'); // للتصحيح
    
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = _products;
      } else {
        _filteredProducts = _products.where((product) {
          final productId = product['id']?.toString().toLowerCase() ?? '';
          final productName = product['name']?.toString().toLowerCase() ?? '';
          final searchQuery = query.toLowerCase();
          final matches = productId.contains(searchQuery) || productName.contains(searchQuery);
          return matches;
        }).toList();
      }
    });
    
    print('Filtered products: ${_filteredProducts.length}'); // للتصحيح
  }

  // فلترة الموردين بناءً على النص المدخل
  void _filterSuppliers(String query) {
    print('Filtering suppliers with query: $query'); // للتصحيح
    print('Total suppliers: ${_suppliers.length}'); // للتصحيح
    
    setState(() {
      if (query.isEmpty) {
        _filteredSuppliers = _suppliers;
      } else {
        _filteredSuppliers = _suppliers.where((supplier) {
          final taxNumber = supplier['tax_number']?.toString().toLowerCase() ?? '';
          final supplierName = supplier['name']?.toString().toLowerCase() ?? '';
          final searchQuery = query.toLowerCase();
          final matches = taxNumber.contains(searchQuery) || supplierName.contains(searchQuery);
          return matches;
        }).toList();
      }
    });
    
    print('Filtered suppliers: ${_filteredSuppliers.length}'); // للتصحيح
  }

  // البحث عن منتج بالـ ID وتعبئة الاسم
  void _findProductById(String productId) {
    print('Finding product by ID: $productId'); // للتصحيح
    
    final product = _products.firstWhere(
      (p) => p['id'] == productId,
      orElse: () => {},
    );
    
    print('Found product: $product'); // للتصحيح
    
    if (product.isNotEmpty) {
      setState(() {
        _selectedProductId = product['id'];
        _productNameController.text = product['name'] ?? '';
      });
    } else {
      setState(() {
        _selectedProductId = null;
        _productNameController.text = '';
      });
    }
  }

  // البحث عن مورد بالرقم الضريبي وتعبئة الاسم
  void _findSupplierByTaxNumber(String taxNumber) {
    print('Finding supplier by tax number: $taxNumber'); // للتصحيح
    
    final supplier = _suppliers.firstWhere(
      (s) => s['tax_number'] == taxNumber,
      orElse: () => {},
    );
    
    print('Found supplier: $supplier'); // للتصحيح
    
    if (supplier.isNotEmpty) {
      setState(() {
        _selectedSupplierId = supplier['id'];
        _supplierNameController.text = supplier['name'] ?? '';
      });
    } else {
      setState(() {
        _selectedSupplierId = null;
        _supplierNameController.text = '';
      });
    }
  }

  // اختيار التاريخ
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900), // تاريخ بعيد في الماضي
      lastDate: DateTime(2100),  // تاريخ بعيد في المستقبل
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // ===============================
  // وظائف إدارة الفواتير الإلكترونية
  // ===============================

  // اختيار ملف الفاتورة
  Future<void> _pickInvoiceFile() async {
    try {
      setState(() => _isUploadingInvoice = true);

      final file = await _stockInLogic.pickPdfFile();
      if (file != null) {
        // التحقق من صحة الملف
        final fileValidation = _stockInLogic.validatePdfFile(file);
        if (fileValidation != null) {
          throw Exception(fileValidation);
        }

        // التحقق من حجم الملف
        final sizeValidation = await _stockInLogic.validateFileSize(file);
        if (sizeValidation != null) {
          throw Exception(sizeValidation);
        }

        setState(() {
          _selectedInvoiceFilePath = file.path;
          _selectedInvoiceFileName = file.path.split('/').last;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invoice file selected: $_selectedInvoiceFileName'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting invoice: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isUploadingInvoice = false);
    }
  }

  // إزالة ملف الفاتورة
  void _removeInvoiceFile() {
    setState(() {
      _selectedInvoiceFilePath = null;
      _selectedInvoiceFileName = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invoice file removed'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Icon(
                  widget.record != null ? Icons.edit : Icons.add,
                  size: 28,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  widget.record != null ? 'Edit Stock In Record' : 'Record Stock In',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(height: 24),
            // Form Content
            Expanded(
              child: _isLoadingData
                  ? const Center(child: CircularProgressIndicator())
                  : _buildForm(),
            ),
            // Actions
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveRecord,
                  child: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(widget.record != null ? 'Update' : 'Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Selection
            Text(
              'Product Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            // Product ID Field
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: _productIdController,
                    decoration: InputDecoration(
                      labelText: 'Product ID',
                      border: const OutlineInputBorder(),
                      hintText: 'Enter product ID',
                      prefixIcon: _selectedProductId != null 
                          ? Icon(Icons.check_circle, color: Colors.green) 
                          : const Icon(Icons.tag),
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        _findProductById(value);
                      } else {
                        setState(() {
                          _selectedProductId = null;
                          _productNameController.text = '';
                        });
                      }
                    },
                    validator: (value) {
                      if (_selectedProductId == null) {
                        return 'Please select a valid product';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Text('OR', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _productNameController,
                        decoration: InputDecoration(
                          labelText: 'Product Name',
                          border: const OutlineInputBorder(),
                          hintText: 'Type to search products...',
                          prefixIcon: _selectedProductId != null 
                              ? Icon(Icons.check_circle, color: Colors.green) 
                              : const Icon(Icons.search),
                          suffixIcon: _productNameController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _productNameController.clear();
                                    _productIdController.clear();
                                    setState(() {
                                      _selectedProductId = null;
                                      _filteredProducts = _products;
                                    });
                                  },
                                )
                              : null,
                        ),
                        onChanged: (value) {
                          _filterProducts(value);
                          if (value.isEmpty) {
                            setState(() {
                              _selectedProductId = null;
                              _productIdController.text = '';
                            });
                          }
                        },
                        validator: (value) {
                          if (_selectedProductId == null) {
                            return 'Please select a valid product';
                          }
                          return null;
                        },
                      ),
                      // Product suggestions dropdown
                      if (_productNameController.text.isNotEmpty && _selectedProductId == null)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade600),
                            borderRadius: BorderRadius.circular(8),
                            color: Theme.of(context).cardColor,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: Material(
                            color: Colors.transparent,
                            child: _filteredProducts.isEmpty
                                ? Container(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.search_off,
                                          color: Theme.of(context).textTheme.bodySmall?.color,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'No products found',
                                          style: TextStyle(
                                            color: Theme.of(context).textTheme.bodySmall?.color,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: _filteredProducts.take(10).length,
                              itemBuilder: (context, index) {
                                final product = _filteredProducts[index];
                                final isLast = index == _filteredProducts.take(10).length - 1;
                                return Container(
                                  decoration: BoxDecoration(
                                    border: isLast ? null : Border(
                                      bottom: BorderSide(
                                        color: Theme.of(context).dividerColor.withOpacity(0.5),
                                        width: 0.5,
                                      ),
                                    ),
                                  ),
                                  child: ListTile(
                                    dense: true,
                                    hoverColor: Theme.of(context).hoverColor,
                                    title: Text(
                                      product['name'] ?? 'Unknown Product',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Theme.of(context).textTheme.bodyLarge?.color,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'ID: ${product['id'] ?? 'N/A'}',
                                      style: TextStyle(
                                        fontSize: 12, 
                                        color: Theme.of(context).textTheme.bodySmall?.color,
                                      ),
                                    ),
                                    trailing: Icon(
                                      Icons.arrow_forward_ios,
                                      size: 12,
                                      color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                                    ),
                                    onTap: () {
                                      setState(() {
                                        _selectedProductId = product['id'];
                                        _productIdController.text = product['id'] ?? '';
                                        _productNameController.text = product['name'] ?? '';
                                        _filteredProducts = [];
                                      });
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Quantity & Unit
            Text(
              'Quantity Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Quantity *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter quantity';
                      }
                      if (double.tryParse(value) == null || double.parse(value) <= 0) {
                        return 'Please enter a valid quantity';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Unit *',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedUnit,
                    items: const [
                      DropdownMenuItem(value: 'PC', child: Text('Piece')),
                      DropdownMenuItem(value: 'KG', child: Text('Kilogram')),
                      DropdownMenuItem(value: 'BOX', child: Text('Box')),
                      DropdownMenuItem(value: 'CARTON', child: Text('Carton')),
                      DropdownMenuItem(value: 'LITER', child: Text('Liter')),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedUnit = value);
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a unit';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Supplier Selection
            Text(
              'Supplier Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            // Supplier Tax Number Field
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: _supplierTaxController,
                    decoration: InputDecoration(
                      labelText: 'Supplier Tax Number',
                      border: const OutlineInputBorder(),
                      hintText: 'Enter tax number',
                      prefixIcon: _selectedSupplierId != null 
                          ? Icon(Icons.check_circle, color: Colors.green) 
                          : const Icon(Icons.numbers),
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        _findSupplierByTaxNumber(value);
                      } else {
                        setState(() {
                          _selectedSupplierId = null;
                          _supplierNameController.text = '';
                        });
                      }
                    },
                    validator: (value) {
                      if (_selectedSupplierId == null) {
                        return 'Please select a valid supplier';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Text('OR', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _supplierNameController,
                        decoration: InputDecoration(
                          labelText: 'Supplier Name',
                          border: const OutlineInputBorder(),
                          hintText: 'Type to search suppliers...',
                          prefixIcon: _selectedSupplierId != null 
                              ? Icon(Icons.check_circle, color: Colors.green) 
                              : const Icon(Icons.search),
                          suffixIcon: _supplierNameController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _supplierNameController.clear();
                                    _supplierTaxController.clear();
                                    setState(() {
                                      _selectedSupplierId = null;
                                      _filteredSuppliers = _suppliers;
                                    });
                                  },
                                )
                              : null,
                        ),
                        onChanged: (value) {
                          _filterSuppliers(value);
                          if (value.isEmpty) {
                            setState(() {
                              _selectedSupplierId = null;
                              _supplierTaxController.text = '';
                            });
                          }
                        },
                        validator: (value) {
                          if (_selectedSupplierId == null) {
                            return 'Please select a valid supplier';
                          }
                          return null;
                        },
                      ),
                      // Supplier suggestions dropdown
                      if (_supplierNameController.text.isNotEmpty && _selectedSupplierId == null)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade600),
                            borderRadius: BorderRadius.circular(8),
                            color: Theme.of(context).cardColor,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: Material(
                            color: Colors.transparent,
                            child: _filteredSuppliers.isEmpty
                                ? Container(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.search_off,
                                          color: Theme.of(context).textTheme.bodySmall?.color,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'No suppliers found',
                                          style: TextStyle(
                                            color: Theme.of(context).textTheme.bodySmall?.color,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: _filteredSuppliers.take(10).length,
                                    itemBuilder: (context, index) {
                                      final supplier = _filteredSuppliers[index];
                                      final isLast = index == _filteredSuppliers.take(10).length - 1;
                                      return Container(
                                        decoration: BoxDecoration(
                                          border: isLast ? null : Border(
                                            bottom: BorderSide(
                                              color: Theme.of(context).dividerColor.withOpacity(0.5),
                                              width: 0.5,
                                            ),
                                          ),
                                        ),
                                        child: ListTile(
                                          dense: true,
                                          hoverColor: Theme.of(context).hoverColor,
                                          title: Text(
                                            supplier['name'] ?? 'Unknown Supplier',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Theme.of(context).textTheme.bodyLarge?.color,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          subtitle: Text(
                                            'Tax No: ${supplier['tax_number'] ?? 'N/A'}',
                                            style: TextStyle(
                                              fontSize: 12, 
                                              color: Theme.of(context).textTheme.bodySmall?.color,
                                            ),
                                          ),
                                          trailing: Icon(
                                            Icons.arrow_forward_ios,
                                            size: 12,
                                            color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                                          ),
                                          onTap: () {
                                            setState(() {
                                              _selectedSupplierId = supplier['id'];
                                              _supplierTaxController.text = supplier['tax_number'] ?? '';
                                              _supplierNameController.text = supplier['name'] ?? '';
                                              _filteredSuppliers = [];
                                            });
                                          },
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Warehouse Selection
            Text(
              'Warehouse Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Select Warehouse *',
                border: OutlineInputBorder(),
              ),
              value: _selectedWarehouseId,
              items: _warehouses.map((warehouse) {
                return DropdownMenuItem<String>(
                  value: warehouse['id'],
                  child: Text('${warehouse['code']} - ${warehouse['name']}'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedWarehouseId = value);
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a warehouse';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Date Selection
            Text(
              'Date Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _selectDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade600),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedDate != null
                            ? 'Selected Date: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                            : 'Select Date',
                        style: TextStyle(
                          fontSize: 16,
                          color: _selectedDate != null 
                              ? Theme.of(context).textTheme.bodyLarge?.color
                              : Theme.of(context).hintColor,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down,
                      color: Theme.of(context).iconTheme.color,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Electronic Invoice Upload
            Text(
              'Electronic Invoice',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade50,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_selectedInvoiceFileName == null) ...[
                    // Upload button when no file selected
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.cloud_upload_outlined,
                            size: 48,
                            color: Colors.blue.shade600,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Upload Electronic Invoice (PDF)',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade800,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Max file size: 10MB • PDF format only',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _isUploadingInvoice ? null : _pickInvoiceFile,
                            icon: _isUploadingInvoice 
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2,color: Colors.black,),
                                  )
                                : const Icon(Icons.attach_file),
                            label: Text(_isUploadingInvoice ? 'Selecting...' : 'Choose PDF File',
                              style: TextStyle(color: Colors.black),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // File selected display
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        border: Border.all(color: Colors.green.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.picture_as_pdf,
                            color: Colors.red.shade600,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedInvoiceFileName!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green.shade800,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.record?.electronicInvoiceUrl != null
                                      ? 'Previously uploaded invoice'
                                      : 'Ready to upload',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: _removeInvoiceFile,
                            icon: Icon(
                              Icons.close,
                              color: Colors.red.shade600,
                            ),
                            tooltip: 'Remove file',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Replace file button
                    Center(
                      child: TextButton.icon(
                        onPressed: _isUploadingInvoice ? null : _pickInvoiceFile,
                        icon: _isUploadingInvoice
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.refresh,color: Colors.black,),
                        label: Text(_isUploadingInvoice ? 'Selecting...' : 'Choose Different File', style: TextStyle(color: Colors.black)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Notes
            Text(
              'Additional Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) return;

    // التحقق من أن التاريخ محدد
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    print('Saving record...'); // للتصحيح
    print('Selected Product ID: $_selectedProductId'); // للتصحيح
    print('Selected Supplier ID: $_selectedSupplierId'); // للتصحيح
    print('Selected Warehouse ID: $_selectedWarehouseId'); // للتصحيح
    print('Selected Date: $_selectedDate'); // للتصحيح

    setState(() => _isLoading = true);

    try {
      // إنشاء السجل أولاً
      final record = StockInRecord(
        id: widget.record?.id,
        recordId: widget.record?.recordId ?? '', // سيتم إنشاؤه في الخادم
        additionNumber: widget.record?.additionNumber ?? '', // سيتم إنشاؤه في الخادم
        productId: _selectedProductId!,
        quantity: int.parse(_quantityController.text),
        unit: _selectedUnit!,
        supplierId: _selectedSupplierId!,
        warehouseId: _selectedWarehouseId!,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        invoiceDate: _selectedDate, // إضافة التاريخ المحدد
      );

      print('Record to save: ${record.toJson()}'); // للتصحيح

      String? recordId;
      
      if (widget.record != null && widget.record!.id != null) {
        // تحديث سجل موجود
        await _stockInLogic.updateStockInRecordWithStock(widget.record!.id!, widget.record!, record);
        recordId = widget.record!.id;
      } else {
        // إضافة سجل جديد
        await _stockInLogic.addStockInRecordWithStock(record);
        
        // الحصول على السجل المضاف حديثاً للحصول على ID
        final newRecords = await _stockInLogic.getStockInRecords();
        if (newRecords.isNotEmpty) {
          recordId = newRecords.first.id;
        }
      }

      // رفع الفاتورة إذا تم اختيارها
      if (_selectedInvoiceFilePath != null && 
          recordId != null && 
          !_selectedInvoiceFilePath!.startsWith('http')) {
        // ملف جديد محلي يحتاج للرفع
        try {
          print('Uploading invoice file...'); // للتصحيح
          
          final file = File(_selectedInvoiceFilePath!);
          await _stockInLogic.uploadInvoiceComplete(
            recordId: recordId,
            file: file,
          );
          
          print('Invoice uploaded successfully'); // للتصحيح
        } catch (e) {
          print('Error uploading invoice: $e'); // للتصحيح
          // لا نرمي خطأ هنا، فقط نعرض تحذير
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Record saved but invoice upload failed: ${e.toString()}'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.record != null 
                  ? 'Record updated successfully'
                  : 'Record added successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSave();
      }
    } catch (e) {
      print('Error saving record: $e'); // للتصحيح
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving record: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
