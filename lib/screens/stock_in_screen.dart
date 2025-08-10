import 'package:flutter/material.dart';
import 'dart:async';
import '../backend/stock_in_logic.dart';
import '../l10n/app_localizations.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:url_launcher/url_launcher.dart';
 import 'package:flutter/services.dart';
import 'package:warehouse_management_system/screens/print_invoice_screen.dart';
class StockInScreen extends StatefulWidget {
  const StockInScreen({super.key});

  @override
  State<StockInScreen> createState() => _StockInScreenState();
}

class _StockInScreenState extends State<StockInScreen> {
  final StockInController _stockInController = StockInController();
  final TextEditingController _searchController = TextEditingController();
  
  List<StockIn> _stockInRecords = [];
  Map<String, int> _stats = {};
  
  bool _isLoading = true;
  String? _errorMessage;
  
  // للفلترة
  String _searchTerm = '';
  String? _selectedSupplierFilter;
  DateTime? _startDate;
  DateTime? _endDate;

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
      // Load warehouses and initial data
      await _stockInController.loadWarehouses();
      final success = await _stockInController.loadStockInRecords();
      
      if (success) {
        setState(() {
          _stockInRecords = _stockInController.stockInRecords;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = _stockInController.error;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _searchStockInRecords() async {
    try {
      final success = await _stockInController.loadStockInRecords(
        searchTerm: _searchTerm.isNotEmpty ? _searchTerm : null,
        supplierId: _selectedSupplierFilter,
        startDate: _startDate,
        endDate: _endDate,
      );

      if (success) {
        setState(() {
          _stockInRecords = _stockInController.stockInRecords;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل البحث: ${_stockInController.error}')),
        );
      }
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
        title: Text(localizations?.productsTitle ?? 'Stock In Management'),
        automaticallyImplyLeading: false,
        actions: [
          // إحصائيات سريعة
          if (_stats.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inventory, size: 16, color: Colors.blue[700]),
                  const SizedBox(width: 4),
                  Text(
                    '${_stats['total'] ?? 0}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
          ElevatedButton.icon(
            onPressed: () => _showStockInDialog(),
            icon: const Icon(Icons.add),
            label: Text(localizations?.addProduct ?? 'Record Stock In'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
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
          
          // جدول stock in records
          Expanded(
            child: _stockInRecords.isEmpty ? _buildEmptyState() : _buildStockInTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    final localizations = AppLocalizations.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // الصف الأول: حقل البحث
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: localizations?.searchText ?? 'البحث...',
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                      hintText: 'ابحث برقم الإضافة، رقم السجل، أو اسم المنتج...',
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchTerm = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _searchStockInRecords,
                  icon: const Icon(Icons.search),
                  label: Text(localizations?.searchText ?? 'بحث'),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // الصف الثاني: فلاتر إضافية
            Row(
              children: [
                // فلتر المورد
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'فلتر بالمورد',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.business),
                    ),
                    value: _selectedSupplierFilter,
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('جميع الموردين'),
                      ),
                      // سيتم ملؤها من بيانات الموردين
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedSupplierFilter = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                
                // فلتر التاريخ من
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'من تاريخ',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    controller: TextEditingController(
                      text: _startDate != null 
                          ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                          : '',
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _startDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() {
                          _startDate = date;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                
                // فلتر التاريخ إلى
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'إلى تاريخ',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    controller: TextEditingController(
                      text: _endDate != null 
                          ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                          : '',
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _endDate ?? DateTime.now(),
                        firstDate: _startDate ?? DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() {
                          _endDate = date;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                
                // زر مسح الفلاتر
                IconButton(
                  onPressed: () {
                    setState(() {
                      _searchTerm = '';
                      _selectedSupplierFilter = null;
                      _startDate = null;
                      _endDate = null;
                      _searchController.clear();
                    });
                    _loadInitialData();
                  },
                  icon: const Icon(Icons.clear),
                  tooltip: 'مسح الفلاتر',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'لا توجد سجلات إدخال مخزون',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text('ابدأ بتسجيل أول عملية إدخال مخزون'),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showStockInDialog(),
            icon: const Icon(Icons.add),
            label: const Text('تسجيل أول عملية إدخال'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockInTable() {
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            columnSpacing: 20,
            columns: const [
              DataColumn(
                label: Text(
                  'رقم الإضافة',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'رقم السجل',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'التاريخ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'رقم المنتج',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'اسم المنتج',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'الكمية',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'الوحدة',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'المورد',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'المخزن',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'ملاحظات',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'الإجراءات',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
            rows: _buildTableRows(),
          ),
        ),
      ),
    );
  }

  List<DataRow> _buildTableRows() {
    List<DataRow> rows = [];
    
    for (var stockIn in _stockInRecords) {
      // If there are multiple products, create a row for each product
      if (stockIn.products.isNotEmpty) {
        for (int i = 0; i < stockIn.products.length; i++) {
          final product = stockIn.products[i];
          rows.add(
            DataRow(
              cells: [
                // Addition Number - show only on first row for this record
                DataCell(
                  Text(
                    i == 0 ? stockIn.additionNumber : '',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                // Record ID - show only on first row for this record
                DataCell(
                  Text(
                    i == 0 ? stockIn.recordId : '',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                // Date - show only on first row for this record
                DataCell(
                  Text(
                    i == 0 ? '${stockIn.date.day}/${stockIn.date.month}/${stockIn.date.year}' : '',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                // Product ID
                DataCell(
                  Text(
                    product.productId,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                // Product Name
                DataCell(
                  Text(
                    product.productName,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                // Quantity
                DataCell(
                  Text(
                    product.quantity.toString(),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                // Unit
                DataCell(
                  Text(
                    product.unit,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                // Supplier - show only on first row for this record
                DataCell(
                  Text(
                    i == 0 ? stockIn.supplierName : '',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                // Warehouse - show only on first row for this record
                DataCell(
                  Text(
                    i == 0 ? stockIn.warehouseName : '',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                // Notes - show only on first row for this record
                DataCell(
                  Text(
                    i == 0 ? (stockIn.notes ?? '-') : '',
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Actions - show only on first row for this record
                DataCell(
                  i == 0 ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Edit button
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue, size: 18),
                        onPressed: () => _showStockInDialog(stockIn: stockIn),
                        tooltip: 'تعديل',
                      ),
                      // Delete button
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                        onPressed: () => _confirmDeleteStockIn(stockIn),
                        tooltip: 'حذف',
                      ),
                      // Download button
                     // في _buildTableRows() - عدّل زر التحميل
if (stockIn.invoiceFilePath != null)
  PopupMenuButton<String>(
    onSelected: (value) async {
      if (value == 'open') {
        await _openInvoiceInNewTab(stockIn);
      } else if (value == 'copy') {
        await _copyInvoiceLink(stockIn);
      }
    },
    itemBuilder: (context) => [
      const PopupMenuItem(
        value: 'open',
        child: Row(
          children: [
            Icon(Icons.open_in_new, color: Colors.blue, size: 18),
            SizedBox(width: 8),
            Text('فتح في تبويب جديد'),
          ],
        ),
      ),
      const PopupMenuItem(
        value: 'copy',
        child: Row(
          children: [
            Icon(Icons.copy, color: Colors.green, size: 18),
            SizedBox(width: 8),
            Text('نسخ الرابط'),
          ],
        ),
      ),
    ],
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.picture_as_pdf, color: Colors.green, size: 16),
          SizedBox(width: 4),
          Text(
            'PDF',
            style: TextStyle(
              color: Colors.green,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
    tooltip: 'الفاتورة',
  ),
                      // Print button
                      IconButton(
                        icon: const Icon(Icons.print, color: Colors.purple, size: 18),
                        onPressed: () => _printStockIn(stockIn),
                        tooltip: 'طباعة',
                      ),
                    ],
                  ) : const SizedBox.shrink(),
                ),
              ],
            ),
          );
        }
      } else {
        // If no products, show a row with empty product info
        rows.add(
          DataRow(
            cells: [
              DataCell(Text(stockIn.additionNumber, style: const TextStyle(fontSize: 12))),
              DataCell(Text(stockIn.recordId, style: const TextStyle(fontSize: 12))),
              DataCell(Text('${stockIn.date.day}/${stockIn.date.month}/${stockIn.date.year}', style: const TextStyle(fontSize: 12))),
              const DataCell(Text('-', style: TextStyle(fontSize: 12))), // Product ID
              const DataCell(Text('-', style: TextStyle(fontSize: 12))), // Product Name
              const DataCell(Text('-', style: TextStyle(fontSize: 12))), // Quantity
              const DataCell(Text('-', style: TextStyle(fontSize: 12))), // Unit
              DataCell(Text(stockIn.supplierName, style: const TextStyle(fontSize: 12))),
              DataCell(Text(stockIn.warehouseName, style: const TextStyle(fontSize: 12))),
              DataCell(Text(stockIn.notes ?? '-', style: const TextStyle(fontSize: 12))),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue, size: 18),
                      onPressed: () => _showStockInDialog(stockIn: stockIn),
                      tooltip: 'تعديل',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                      onPressed: () => _confirmDeleteStockIn(stockIn),
                      tooltip: 'حذف',
                    ),
                   // في _buildTableRows() - عدّل زر التحميل
if (stockIn.invoiceFilePath != null)
  PopupMenuButton<String>(
    onSelected: (value) async {
      if (value == 'open') {
        await _openInvoiceInNewTab(stockIn);
      } else if (value == 'copy') {
        await _copyInvoiceLink(stockIn);
      }
    },
    itemBuilder: (context) => [
      const PopupMenuItem(
        value: 'open',
        child: Row(
          children: [
            Icon(Icons.open_in_new, color: Colors.blue, size: 18),
            SizedBox(width: 8),
            Text('فتح في تبويب جديد'),
          ],
        ),
      ),
      const PopupMenuItem(
        value: 'copy',
        child: Row(
          children: [
            Icon(Icons.copy, color: Colors.green, size: 18),
            SizedBox(width: 8),
            Text('نسخ الرابط'),
          ],
        ),
      ),
    ],
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.picture_as_pdf, color: Colors.green, size: 16),
          SizedBox(width: 4),
          Text(
            'PDF',
            style: TextStyle(
              color: Colors.green,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
    tooltip: 'الفاتورة',
  ),
                    IconButton(
                      icon: const Icon(Icons.print, color: Colors.purple, size: 18),
                      onPressed: () => _printStockIn(stockIn),
                      tooltip: 'طباعة',
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }
    }
    
    return rows;
  }

  Future<void> _confirmDeleteStockIn(StockIn stockIn) async {
    await _deleteStockIn(stockIn);
  }

  // ============== DIALOG METHODS ==============

  Future<void> _showStockInDialog({StockIn? stockIn}) async {
    await showDialog(
      context: context,
      builder: (context) => StockInFormDialog(
        stockIn: stockIn,
        stockInController: _stockInController,
        onSuccess: () async {
          // Force reload of data after successful save
          await _loadInitialData();
        },
      ),
    );
  }

  Future<void> _deleteStockIn(StockIn stockIn) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف سجل إدخال المخزون'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('هل أنت متأكد من حذف سجل إدخال المخزون؟'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('رقم السجل: ${stockIn.recordId}'),
                  Text('رقم الإضافة: ${stockIn.additionNumber}'),
                  Text('المورد: ${stockIn.supplierName}'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'تحذير: لا يمكن التراجع عن هذا الإجراء!',
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

    if (confirmed == true && stockIn.id != null) {
      try {
        final success = await _stockInController.deleteStockInRecord(stockIn.id!);
        if (success && mounted) {
          setState(() {
            _stockInRecords = _stockInController.stockInRecords;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حذف السجل بنجاح')),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('فشل في حذف السجل: ${_stockInController.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  

Future<void> _downloadInvoice(StockIn stockIn) async {
  if (stockIn.invoiceFilePath == null) return;
  
  try {
    // فتح الرابط في تبويب جديد
    final Uri url = Uri.parse(stockIn.invoiceFilePath!);
    
    if (await canLaunchUrl(url)) {
      await launchUrl(
        url,
        webOnlyWindowName: '_blank', // فتح في تبويب جديد
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم فتح الفاتورة في تبويب جديد'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      // إذا فشل فتح الرابط، نحاول طريقة بديلة
      _openInNewTabAlternative(stockIn.invoiceFilePath!);
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في فتح الفاتورة: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// طريقة بديلة باستخدام dart:html (للويب فقط)
void _openInNewTabAlternative(String url) {
  // استخدم هذا الكود فقط إذا كنت تستهدف الويب
  // import 'dart:html' as html;
  // html.window.open(url, '_blank');
  
  // أو يمكنك نسخ الرابط للحافظة
  _copyToClipboard(url);
}

// دالة نسخ الرابط للحافظة
void _copyToClipboard(String url) {
 
  
  Clipboard.setData(ClipboardData(text: url));
  
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('تم نسخ رابط الفاتورة'),
            const SizedBox(height: 4),
            Text(
              'الصق الرابط في متصفحك لتحميل الفاتورة',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'فتح',
          textColor: Colors.white,
          onPressed: () async {
            final Uri uri = Uri.parse(url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, webOnlyWindowName: '_blank');
            }
          },
        ),
      ),
    );
  }
}

// فتح الفاتورة في تبويب جديد
Future<void> _openInvoiceInNewTab(StockIn stockIn) async {
  if (stockIn.invoiceFilePath == null) return;
  
  try {
    final Uri url = Uri.parse(stockIn.invoiceFilePath!);
    
    if (await canLaunchUrl(url)) {
      await launchUrl(
        url,
        mode: LaunchMode.externalApplication, // يفتح في المتصفح
        webOnlyWindowName: '_blank',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم فتح الفاتورة في تبويب جديد'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      throw 'لا يمكن فتح الرابط';
    }
  } catch (e) {
    if (mounted) {
      // إذا فشل، انسخ الرابط
      await _copyInvoiceLink(stockIn);
    }
  }
}

// نسخ رابط الفاتورة
Future<void> _copyInvoiceLink(StockIn stockIn) async {
  if (stockIn.invoiceFilePath == null) return;
  
  await Clipboard.setData(ClipboardData(text: stockIn.invoiceFilePath!));
  
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('تم نسخ رابط الفاتورة - الصقه في متصفحك'),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'فتح الآن',
          textColor: Colors.white,
          onPressed: () async {
            final Uri url = Uri.parse(stockIn.invoiceFilePath!);
            if (await canLaunchUrl(url)) {
              await launchUrl(url, webOnlyWindowName: '_blank');
            }
          },
        ),
      ),
    );
  }
}

  Future<void> _printStockIn(StockIn stockIn) async {
    // اجمع كل السجلات اللي لها نفس رقم الإضافة
    final grouped = _stockInRecords
        .where((r) => r.additionNumber == stockIn.additionNumber)
        .toList();

    if (grouped.isEmpty) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrintInvoiceScreen(records: grouped),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// ============== STOCK IN FORM DIALOG ==============

class StockInFormDialog extends StatefulWidget {
  final StockIn? stockIn;
  final StockInController stockInController;
  final VoidCallback onSuccess;

  const StockInFormDialog({
    super.key,
    this.stockIn,
    required this.stockInController,
    required this.onSuccess,
  });

  @override
  State<StockInFormDialog> createState() => _StockInFormDialogState();
}

class _StockInFormDialogState extends State<StockInFormDialog> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers for products
  final List<ProductRowController> _productControllers = [];
  
  // General information controllers
  final TextEditingController _supplierSearchController = TextEditingController();
  final TextEditingController _supplierTaxController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  // Search timers
  Timer? _productSearchTimer;
  Timer? _supplierSearchTimer;
  
  // State variables
  List<SupplierSearchResult> _supplierSearchResults = [];
  
  String? _selectedSupplierId;
  String? _selectedWarehouseId;
  DateTime _selectedDate = DateTime.now();
  String? _invoiceFilePath;
  String? _selectedFileName;
  
  bool _isLoading = false;
  // إضافة متغيرات للملف
Uint8List? _invoiceFileBytes;
String? _invoiceFileName;
String? _uploadedInvoiceUrl;
  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    // Add initial product row
    _addProductRow();
    
    // If editing, populate fields
    if (widget.stockIn != null) {
      final stockIn = widget.stockIn!;
      
      // Populate products
      _productControllers.clear();
      for (var product in stockIn.products) {
        final controller = ProductRowController();
        controller.productIdController.text = product.productId;
        controller.productNameController.text = product.productName;
        controller.quantityController.text = product.quantity.toString();
        controller.selectedUnit = product.unit;
        _productControllers.add(controller);
      }
      
      // Populate general info
      _selectedSupplierId = stockIn.supplierId;
      _supplierSearchController.text = stockIn.supplierName;
      _supplierTaxController.text = ''; // سيتم ملؤه إذا كان متاحاً في البيانات
      _selectedWarehouseId = stockIn.warehouseId;
      _selectedDate = stockIn.date;
      _notesController.text = stockIn.notes ?? '';
      _invoiceFilePath = stockIn.invoiceFilePath;
    }
    
    // Load warehouses
    _loadWarehouses();
  }

  void _addProductRow() {
    setState(() {
      _productControllers.add(ProductRowController());
    });
  }

  void _removeProductRow(int index) {
    if (_productControllers.length > 1) {
      setState(() {
        _productControllers[index].dispose();
        _productControllers.removeAt(index);
      });
    }
  }

  Future<void> _loadWarehouses() async {
    await widget.stockInController.loadWarehouses();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.stockIn != null;
    final localizations = AppLocalizations.of(context);
    
    return AlertDialog(
      title: Text(isEditing 
          ? 'تعديل سجل إدخال المخزون' 
          : 'تسجيل إدخال مخزون جديد'),
      content: SizedBox(
        width: 800,
        height: 700,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // القسم الأول - المنتجات
                _buildProductsSection(),
                const SizedBox(height: 24),
                
                // القسم الثاني - المعلومات العامة
                _buildGeneralInfoSection(),
                const SizedBox(height: 24),
                
                // القسم الثالث - رفع الفاتورة
                _buildInvoiceUploadSection(),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(localizations?.cancel ?? 'إلغاء'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveStockIn,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEditing ? 'تحديث' : 'حفظ'),
        ),
      ],
    );
  }

  Widget _buildProductsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.inventory_2, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'المنتجات',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _addProductRow,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('إضافة منتج'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // صفوف المنتجات
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _productControllers.length,
              itemBuilder: (context, index) {
                return _buildProductRow(index);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductRow(int index) {
    final controller = _productControllers[index];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.grey.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Text('منتج ${index + 1}', 
                     style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                if (_productControllers.length > 1)
                  IconButton(
                    onPressed: () => _removeProductRow(index),
                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                    tooltip: 'حذف المنتج',
                  ),
              ],
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                // Product ID
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: controller.productIdController,
                        decoration: const InputDecoration(
                          labelText: 'رقم المنتج *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.tag),
                          hintText: 'اكتب رقم أو اسم المنتج',
                        ),
                        onChanged: (value) => _searchProductById(value, index),
                        onTap: () {
                          // عرض نتائج البحث عند النقر على الحقل
                          if (controller.productIdController.text.isNotEmpty) {
                            _searchProductById(controller.productIdController.text, index);
                          }
                        },
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'رقم المنتج مطلوب';
                          }
                          return null;
                        },
                      ),
                      // عرض نتائج البحث
                      if (controller.isSearching)
                        Container(
                          padding: const EdgeInsets.all(16),
                          child: const Row(
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              SizedBox(width: 8),
                              Text('جاري البحث...', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        )
                      else if (controller.searchResults.isNotEmpty)
                        Container(
                          constraints: const BoxConstraints(maxHeight: 200),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: controller.searchResults.length,
                            itemBuilder: (context, searchIndex) {
                              final product = controller.searchResults[searchIndex];
                              return ListTile(
                                dense: true,
                                title: Text(
                                  product.name,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                subtitle: Text(
                                  'رقم المنتج: ${product.id}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                leading: const Icon(Icons.inventory_2, size: 20),
                                onTap: () => _selectProduct(product, index),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                
                // Product Name
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: controller.productNameController,
                        decoration: const InputDecoration(
                          labelText: 'اسم المنتج *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.inventory),
                          hintText: 'اكتب اسم المنتج للبحث',
                        ),
                        onChanged: (value) => _searchProductByName(value, index),
                        onTap: () {
                          // عرض نتائج البحث عند النقر على الحقل
                          if (controller.productNameController.text.isNotEmpty) {
                            _searchProductByName(controller.productNameController.text, index);
                          }
                        },
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'اسم المنتج مطلوب';
                          }
                          return null;
                        },
                      ),
                      // عرض نتائج البحث للاسم أيضاً (في حالة البحث من خلال الاسم)
                      if (controller.isSearching && controller.productIdController.text.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          child: const Row(
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              SizedBox(width: 8),
                              Text('جاري البحث...', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        )
                      else if (controller.searchResults.isNotEmpty && 
                          controller.productIdController.text.isEmpty)
                        Container(
                          constraints: const BoxConstraints(maxHeight: 200),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: controller.searchResults.length,
                            itemBuilder: (context, searchIndex) {
                              final product = controller.searchResults[searchIndex];
                              return ListTile(
                                dense: true,
                                title: Text(
                                  product.name,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                subtitle: Text(
                                  'رقم المنتج: ${product.id}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                leading: const Icon(Icons.inventory_2, size: 20),
                                onTap: () => _selectProduct(product, index),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                // Quantity
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: controller.quantityController,
                    decoration: const InputDecoration(
                      labelText: 'الكمية *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.numbers),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'الكمية مطلوبة';
                      }
                      if (double.tryParse(value!) == null || double.parse(value) <= 0) {
                        return 'كمية غير صحيحة';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                
                // Unit
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: controller.selectedUnit,
                    decoration: const InputDecoration(
                      labelText: 'الوحدة *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.straighten),
                    ),
                    items: ['piece', 'KG', 'Liter', 'Meter'].map((unit) {
                      return DropdownMenuItem(
                        value: unit,
                        child: Text(unit),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        controller.selectedUnit = value;
                      });
                    },
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'الوحدة مطلوبة';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'المعلومات العامة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Column(
              children: [
                Row(
                  children: [
                    // Supplier Tax Number
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _supplierTaxController,
                        decoration: const InputDecoration(
                          labelText: 'الرقم الضريبي للمورد *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.numbers),
                          hintText: 'اكتب الرقم الضريبي',
                        ),
                        onChanged: (value) => _searchSuppliersByTax(value),
                        onTap: () {
                          if (_supplierTaxController.text.isNotEmpty) {
                            _searchSuppliersByTax(_supplierTaxController.text);
                          }
                        },
                        validator: (value) {
                          if (_selectedSupplierId == null) {
                            return 'يجب اختيار مورد';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Supplier Name
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _supplierSearchController,
                        decoration: const InputDecoration(
                          labelText: 'اسم المورد *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.business),
                          hintText: 'اكتب اسم المورد',
                        ),
                        onChanged: (value) => _searchSuppliersByName(value),
                        onTap: () {
                          if (_supplierSearchController.text.isNotEmpty) {
                            _searchSuppliersByName(_supplierSearchController.text);
                          }
                        },
                        validator: (value) {
                          if (_selectedSupplierId == null) {
                            return 'يجب اختيار مورد';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                
                Row(
                  children: [
                    // Warehouse dropdown
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedWarehouseId,
                        decoration: const InputDecoration(
                          labelText: 'المخزن *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.warehouse),
                        ),
                        items: widget.stockInController.warehouses.map((warehouse) {
                          return DropdownMenuItem<String>(
                            value: warehouse['id'].toString(),
                            child: Text(warehouse['name'] ?? ''),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedWarehouseId = value;
                          });
                        },
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'المخزن مطلوب';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Date picker
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'التاريخ *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        readOnly: true,
                        controller: TextEditingController(
                          text: '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        ),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(const Duration(days: 1)),
                          );
                          if (date != null) {
                            setState(() {
                              _selectedDate = date;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            // Supplier search results
            if (_supplierSearchResults.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 12),
                constraints: const BoxConstraints(maxHeight: 150),
                child: Card(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _supplierSearchResults.length,
                    itemBuilder: (context, index) {
                      final supplier = _supplierSearchResults[index];
                      return ListTile(
                        title: Text(supplier.name),
                        subtitle: Text('الرقم الضريبي: ${supplier.taxNumber ?? 'غير متوفر'}'),
                        dense: true,
                        onTap: () => _selectSupplier(supplier),
                      );
                    },
                  ),
                ),
              ),
            
            const SizedBox(height: 12),
            
            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'ملاحظات',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceUploadSection() {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.upload_file, color: Colors.purple),
              const SizedBox(width: 8),
              const Text(
                'رفع الفاتورة',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _uploadedInvoiceUrl != null 
                          ? Colors.green.withOpacity(0.5)
                          : Colors.grey.withOpacity(0.5),
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: _uploadedInvoiceUrl != null 
                        ? Colors.green.withOpacity(0.05)
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.picture_as_pdf, 
                        color: _uploadedInvoiceUrl != null ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedFileName ?? 'لم يتم اختيار ملف',
                              style: TextStyle(
                                color: _selectedFileName != null 
                                    ? Colors.black 
                                    : Colors.grey,
                              ),
                            ),
                            if (_uploadedInvoiceUrl != null)
                              const Text(
                                'تم الرفع بنجاح ✓',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (_isLoading)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _pickInvoiceFile,
                icon: const Icon(Icons.folder_open),
                label: Text(_selectedFileName != null ? 'تغيير الملف' : 'اختيار ملف'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
              ),
              if (_selectedFileName != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _removeInvoiceFile,
                  icon: const Icon(Icons.clear, color: Colors.red),
                  tooltip: 'إزالة الملف',
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'يُسمح برفع ملفات PDF فقط (حجم أقصى 10 ميجا)',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    ),
  );
}
  // Search methods
  void _searchProductById(String value, int index) {
    // Cancel previous timer if exists
    _productSearchTimer?.cancel();
    
    if (value.isEmpty) {
      setState(() {
        _productControllers[index].searchResults.clear();
        _productControllers[index].isSearching = false;
      });
      return;
    }

    // Show searching indicator
    setState(() {
      _productControllers[index].isSearching = true;
    });

    // Start new timer for delayed search
    _productSearchTimer = Timer(const Duration(milliseconds: 500), () async {
      final success = await widget.stockInController.searchProducts(value);
      
      if (success && mounted) {
        setState(() {
          _productControllers[index].searchResults = widget.stockInController.searchedProducts;
          _productControllers[index].isSearching = false;
        });
        
        // Auto-fill if exact match by ID
        final exactMatch = widget.stockInController.searchedProducts
            .where((p) => p.id.toLowerCase() == value.toLowerCase())
            .firstOrNull;
        
        if (exactMatch != null && mounted) {
          _productControllers[index].productNameController.text = exactMatch.name;
          setState(() {
            _productControllers[index].searchResults.clear();
          });
        }
      } else if (mounted) {
        setState(() {
          _productControllers[index].isSearching = false;
        });
      }
    });
  }

  void _searchProductByName(String value, int index) {
    // Cancel previous timer if exists
    _productSearchTimer?.cancel();
    
    if (value.isEmpty) {
      setState(() {
        _productControllers[index].searchResults.clear();
        _productControllers[index].isSearching = false;
      });
      return;
    }

    // Show searching indicator
    setState(() {
      _productControllers[index].isSearching = true;
    });

    // Start new timer for delayed search
    _productSearchTimer = Timer(const Duration(milliseconds: 500), () async {
      final success = await widget.stockInController.searchProducts(value);
      if (success && mounted) {
        setState(() {
          _productControllers[index].searchResults = widget.stockInController.searchedProducts;
          _productControllers[index].isSearching = false;
        });
        
        // Auto-fill if exact match by name
        final exactMatch = widget.stockInController.searchedProducts
            .where((p) => p.name.toLowerCase() == value.toLowerCase())
            .firstOrNull;
        
        if (exactMatch != null && mounted) {
          _productControllers[index].productIdController.text = exactMatch.id;
          setState(() {
            _productControllers[index].searchResults.clear();
          });
        }
      } else if (mounted) {
        setState(() {
          _productControllers[index].isSearching = false;
        });
      }
    });
  }

  void _selectProduct(ProductSearchResult product, int index) {
    _productControllers[index].productIdController.text = product.id;
    _productControllers[index].productNameController.text = product.name;
    setState(() {
      _productControllers[index].searchResults.clear();
      _productControllers[index].isSearching = false;
    });
    
    // إخفاء لوحة المفاتيح
    FocusScope.of(context).unfocus();
  }

  // Search suppliers by tax number
  void _searchSuppliersByTax(String value) {
    // Cancel previous timer if exists
    _supplierSearchTimer?.cancel();
    
    if (value.isEmpty) {
      setState(() {
        _supplierSearchResults.clear();
        _selectedSupplierId = null;
      });
      return;
    }

    // Start new timer for delayed search
    _supplierSearchTimer = Timer(const Duration(milliseconds: 500), () async {
      final success = await widget.stockInController.searchSuppliers(value);
      
      if (success && mounted) {
        setState(() {
          _supplierSearchResults = widget.stockInController.searchedSuppliers;
        });
        
        // Auto-fill if exact match by tax number
        final exactMatch = widget.stockInController.searchedSuppliers
            .where((s) => s.taxNumber?.toLowerCase() == value.toLowerCase())
            .firstOrNull;
        
        if (exactMatch != null && mounted) {
          _supplierSearchController.text = exactMatch.name;
          setState(() {
            _selectedSupplierId = exactMatch.id;
            _supplierSearchResults.clear();
          });
        }
      }
    });
  }

  // Search suppliers by name
  void _searchSuppliersByName(String value) {
    // Cancel previous timer if exists
    _supplierSearchTimer?.cancel();
    
    if (value.isEmpty) {
      setState(() {
        _supplierSearchResults.clear();
        _selectedSupplierId = null;
      });
      return;
    }

    // Start new timer for delayed search
    _supplierSearchTimer = Timer(const Duration(milliseconds: 500), () async {
      final success = await widget.stockInController.searchSuppliers(value);
      
      if (success && mounted) {
        setState(() {
          _supplierSearchResults = widget.stockInController.searchedSuppliers;
        });
        
        // Auto-fill if exact match by name
        final exactMatch = widget.stockInController.searchedSuppliers
            .where((s) => s.name.toLowerCase() == value.toLowerCase())
            .firstOrNull;
        
        if (exactMatch != null && mounted) {
          _supplierTaxController.text = exactMatch.taxNumber ?? '';
          setState(() {
            _selectedSupplierId = exactMatch.id;
            _supplierSearchResults.clear();
          });
        }
      }
    });
  }

  void _selectSupplier(SupplierSearchResult supplier) {
    setState(() {
      _selectedSupplierId = supplier.id;
      _supplierSearchController.text = supplier.name;
      _supplierTaxController.text = supplier.taxNumber ?? '';
      _supplierSearchResults.clear();
    });
    
    // إخفاء لوحة المفاتيح
    FocusScope.of(context).unfocus();
  }

  Future<void> _pickInvoiceFile() async {
  try {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true, // مهم للحصول على bytes الملف
    );

    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _invoiceFileBytes = result.files.single.bytes!;
        _invoiceFileName = result.files.single.name;
        _selectedFileName = result.files.single.name;
      });
      
      // رفع الملف مباشرة
      await _uploadInvoice();
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في اختيار الملف: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// دالة رفع الفاتورة
Future<void> _uploadInvoice() async {
  if (_invoiceFileBytes == null || _invoiceFileName == null) return;
  
  setState(() {
    _isLoading = true;
  });
  
  try {
    final url = await widget.stockInController.uploadInvoiceFile(
      _invoiceFileName!,
      _invoiceFileBytes!,
    );
    
    if (url != null) {
      setState(() {
        _uploadedInvoiceUrl = url;
        _invoiceFilePath = url;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم رفع الفاتورة بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في رفع الفاتورة: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}

 void _removeInvoiceFile() {
  setState(() {
    _selectedFileName = null;
    _invoiceFilePath = null;
    _invoiceFileBytes = null;
    _invoiceFileName = null;
    _uploadedInvoiceUrl = null;
  });
}

  Future<void> _saveStockIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Prepare products list
      final products = _productControllers.map((controller) {
        return StockInItem(
          productId: controller.productIdController.text.trim(),
          productName: controller.productNameController.text.trim(),
          quantity: double.parse(controller.quantityController.text.trim()),
          unit: controller.selectedUnit!,
        );
      }).toList();

      // Create request
      final request = StockInRequest(
        warehouseId: _selectedWarehouseId!,
        supplierId: _selectedSupplierId!,
        date: _selectedDate,
        notes: _notesController.text.trim().isNotEmpty 
            ? _notesController.text.trim() 
            : null,
        invoiceFilePath: _invoiceFilePath,
        products: products,
      );

      bool success;
      if (widget.stockIn != null) {
        // Update existing record
        success = await widget.stockInController.updateStockInRecord(
          widget.stockIn!.id!,
          request,
        );
      } else {
        // Create new record
        success = await widget.stockInController.createStockInRecord(request);
      }

      if (success) {
        if (mounted) {
          Navigator.pop(context);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.stockIn != null 
                  ? 'تم تحديث السجل بنجاح' 
                  : 'تم حفظ السجل بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Call onSuccess after showing the message
          widget.onSuccess();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ: ${widget.stockInController.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    // Cancel timers
    _productSearchTimer?.cancel();
    _supplierSearchTimer?.cancel();
    
    for (var controller in _productControllers) {
      controller.dispose();
    }
    _supplierSearchController.dispose();
    _supplierTaxController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}

// Helper class for product row controllers
class ProductRowController {
  final TextEditingController productIdController = TextEditingController();
  final TextEditingController productNameController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  String? selectedUnit;
  List<ProductSearchResult> searchResults = [];
  bool isSearching = false;

  void dispose() {
    productIdController.dispose();
    productNameController.dispose();
    quantityController.dispose();
  }
}