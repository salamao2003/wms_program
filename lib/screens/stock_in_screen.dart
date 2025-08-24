import 'package:flutter/material.dart';
import 'dart:async';
import '../backend/stock_in_logic.dart';
import '../backend/main_layout_logic.dart';
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
  final MainLayoutLogic _layoutLogic = MainLayoutLogic();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  List<StockIn> _stockInRecords = [];
  Map<String, int> _stats = {};
  
  bool _isLoading = true;
  String? _errorMessage;
  String? _userRole;
  
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
      // Load user role
      _userRole = await _layoutLogic.getCurrentUserRole();
      
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
          SnackBar(content: Text('${AppLocalizations.of(context)?.searchFailed ?? 'Search failed'}: ${_stockInController.error}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context)?.searchFailed ?? 'Search failed'}: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations?.stockIn ?? 'Stock In'),
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
          // Hide Add button for project_manager
          if (_userRole != 'project_manager')
            ElevatedButton.icon(
              onPressed: () => _showStockInDialog(),
              icon: const Icon(Icons.add),
              label: Text(localizations?.add ?? 'Add'),
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
    final localizations = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            localizations?.error ?? 'Error',
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
            label: Text(localizations?.retry ?? 'Retry'),
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
                      labelText: localizations?.searchText ?? 'Search',
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                      hintText: localizations?.searchAll ?? 'Search in all fields...',
                    ),
                    onChanged: (value) {
                      setState(() => _searchTerm = value);
                      // بحث تلقائي بعد التوقف عن الكتابة بـ 400ms
                      _searchDebounce?.cancel();
                      _searchDebounce = Timer(const Duration(milliseconds: 400), _searchStockInRecords);
                    },
                  ),
                ),
                // زر البحث محذوف - يعمل البحث تلقائياً
              ],
            ),
            
            const SizedBox(height: 12),
            
            // الصف الثاني: فلاتر إضافية
            Row(
              children: [
                // فلتر المورد
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    decoration: InputDecoration(
                      labelText: localizations?.supplierFilter ?? 'Supplier Filter',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.business),
                    ),
                    value: _selectedSupplierFilter,
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(localizations?.all ?? 'All'),
                      ),
                      // نبني قائمة الموردين من السجلات الحالية (unique by id)
                      ...{
                        for (final r in _stockInRecords)
                          if (r.supplierId.isNotEmpty) r.supplierId: r.supplierName
                      }.entries.map(
                        (e) => DropdownMenuItem<String?>(
                          value: e.key,
                          child: Text(e.value),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedSupplierFilter = value);
                      _searchStockInRecords();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                
                // فلتر التاريخ من
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: localizations?.fromDate ?? 'From date',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.calendar_today),
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
                      _searchStockInRecords();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                
                // فلتر التاريخ إلى
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: localizations?.toDate ?? 'To date',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.calendar_today),
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
                  _searchStockInRecords();
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
                  tooltip: localizations?.clearFilters ?? 'Clear filters',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final localizations = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            localizations?.noStockInRecords ?? 'No stock-in records found',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(localizations?.noStockInRecordsSubtext ?? 'Start by recording your first stock in operation'),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showStockInDialog(),
            icon: const Icon(Icons.add),
            label: Text(localizations?.firstStockInRecord ?? 'Record First Stock In'),
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
    final localizations = AppLocalizations.of(context);
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            columnSpacing: 20,
            columns: [
              DataColumn(
                label: Text(
                  localizations?.additionNumber ?? 'Addition No.',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  localizations?.recordIdLabel ?? 'Record ID',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  localizations?.date ?? 'Date',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  localizations?.productId ?? 'Product ID',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  localizations?.productName ?? 'Product Name',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  localizations?.quantity ?? 'Quantity',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  localizations?.unit ?? 'Unit',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  localizations?.supplier ?? 'Supplier',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  localizations?.warehouseLabel ?? 'Warehouse',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  localizations?.notes ?? 'Notes',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  localizations?.actions ?? 'Actions',
                  style: const TextStyle(fontWeight: FontWeight.bold),
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
    final localizations = AppLocalizations.of(context);
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
                      // Edit button - hide for warehouse_manager and project_manager
                      if (_userRole != 'warehouse_manager' && _userRole != 'project_manager')
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue,),
                          onPressed: () => _showStockInDialog(stockIn: stockIn),
                          tooltip: localizations?.edit ?? 'Edit',
                        ),
                      // Delete button - hide for project_manager
                      if (_userRole != 'project_manager')
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red,),
                          onPressed: () => _confirmDeleteStockIn(stockIn),
                          tooltip: localizations?.delete ?? 'Delete',
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
       PopupMenuItem(
         value: 'open',
         child: Row(
           children: [
             Icon(Icons.open_in_new, color: Colors.blue, size: 18),
             SizedBox(width: 8),
             Text(localizations?.openInNewTab ?? 'Open in new tab'),
           ],
         ),
       ),
       PopupMenuItem(
         value: 'copy',
         child: Row(
           children: [
             Icon(Icons.copy, color: Colors.green, size: 18),
             SizedBox(width: 8),
             Text(localizations?.copyLink ?? 'Copy link'),
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
     tooltip: localizations?.invoice ?? 'Invoice',
   ),
                      // Print button
                      IconButton(
                        icon: const Icon(Icons.print, color: Colors.purple, ),
                        onPressed: () => _printStockIn(stockIn),
                        tooltip: localizations?.print ?? 'Print',
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
                    // Edit button - hide for warehouse_manager and project_manager
                    if (_userRole != 'warehouse_manager' && _userRole != 'project_manager')
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue, size: 18),
                        onPressed: () => _showStockInDialog(stockIn: stockIn),
                        tooltip: localizations?.edit ?? 'Edit',
                      ),
                    // Delete button - hide for project_manager
                    if (_userRole != 'project_manager')
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                        onPressed: () => _confirmDeleteStockIn(stockIn),
                        tooltip: localizations?.delete ?? 'Delete',
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
      PopupMenuItem(
        value: 'open',
        child: Row(
          children: [
            const Icon(Icons.open_in_new, color: Colors.blue, size: 18),
            const SizedBox(width: 8),
            Text(localizations?.openInNewTab ?? 'Open in new tab'),
          ],
        ),
      ),
      PopupMenuItem(
        value: 'copy',
        child: Row(
          children: [
            const Icon(Icons.copy, color: Colors.green, size: 18),
            const SizedBox(width: 8),
            Text(localizations?.copyLink ?? 'Copy link'),
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
    tooltip: localizations?.invoiceUpload ?? 'Invoice',
  ),
                    IconButton(
                      icon: const Icon(Icons.print, color: Colors.purple, size: 18),
                      onPressed: () => _printStockIn(stockIn),
                      tooltip: localizations?.print ?? 'Print',
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
    final localizations = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations?.deleteStockInTitle ?? 'Delete Stock In Record'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(localizations?.deleteStockInConfirmation ?? 'Are you sure you want to delete this stock in record?'),
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
                  Text('${localizations?.recordIdLabel ?? 'Record ID'}: ${stockIn.recordId}'),
                  Text('${localizations?.additionNumber ?? 'Addition Number'}: ${stockIn.additionNumber}'),
                  Text('${localizations?.supplier ?? 'Supplier'}: ${stockIn.supplierName}'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              localizations?.deleteCannotUndo ?? 'Warning: This action cannot be undone!',
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(localizations?.cancel ?? 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(localizations?.delete ?? 'Delete', style: const TextStyle(color: Colors.white)),
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
            SnackBar(content: Text(localizations?.stockInDeleted ?? 'Record deleted successfully')),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${localizations?.recordDeleteFailed ?? 'Failed to delete record'}: ${_stockInController.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${localizations?.error ?? 'Error'}: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
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
          SnackBar(
            content: Text(AppLocalizations.of(context)?.invoiceUploaded ?? 'Invoice opened in new tab'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      throw AppLocalizations.of(context)?.uploadError ?? 'Cannot open link';
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
        content: Text(AppLocalizations.of(context)?.linkCopied ?? 'Link copied - paste it in your browser'),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: AppLocalizations.of(context)?.openInNewTab ?? 'Open now',
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
    _searchDebounce?.cancel();
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
          ? (localizations?.editStockInRecord ?? 'Edit Stock In Record')
          : (localizations?.newStockInRecord ?? 'Record New Stock In')),
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
          child: Text(localizations?.cancel ?? 'Cancel'),
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
              : Text(isEditing ? (localizations?.save ?? 'Update') : (localizations?.save ?? 'Save')),
        ),
      ],
    );
  }

  Widget _buildProductsSection() {
    final localizations = AppLocalizations.of(context);
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
                Text(
                  localizations?.productsSection ?? 'Products',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _addProductRow,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(localizations?.add ?? 'Add Product'),
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
    final localizations = AppLocalizations.of(context);
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
                Text('${localizations?.productNumber ?? 'Product'} ${index + 1}', 
                     style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                if (_productControllers.length > 1)
                  IconButton(
                    onPressed: () => _removeProductRow(index),
                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                    tooltip: localizations?.delete ?? 'Delete Product',
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
                        decoration: InputDecoration(
                          labelText: localizations?.productIdLabel ?? 'Product ID *',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.tag),
                          hintText: localizations?.searchProducts ?? 'Enter product ID or name',
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
                            return localizations?.productIdLabel ?? 'Product ID is required';
                          }
                          return null;
                        },
                      ),
                      // عرض نتائج البحث
                      if (controller.isSearching)
                        Container(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              const SizedBox(width: 8),
                              Text(localizations?.searching ?? 'Searching...', style: const TextStyle(fontSize: 12)),
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
                        decoration: InputDecoration(
                          labelText: localizations?.productNameLabel ?? 'Product Name *',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.inventory),
                          hintText: localizations?.searchProducts ?? 'Enter product name to search',
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
                            return localizations?.productNameLabel ?? 'Product name is required';
                          }
                          return null;
                        },
                      ),
                      // عرض نتائج البحث للاسم أيضاً (في حالة البحث من خلال الاسم)
                      if (controller.isSearching && controller.productIdController.text.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              const SizedBox(width: 8),
                              Text(localizations?.searching ?? 'Searching...', style: const TextStyle(fontSize: 12)),
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
                    decoration: InputDecoration(
                      labelText: localizations?.quantityLabel ?? 'Quantity *',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.numbers),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return localizations?.quantityRequired ?? 'Quantity is required';
                      }
                      if (double.tryParse(value!) == null || double.parse(value) <= 0) {
                        return localizations?.invalidQuantity ?? 'Invalid quantity';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                
                // Unit
               // Unit - للقراءة فقط إذا تم تحديد منتج
Expanded(
  flex: 2,
  child: controller.productUnit != null 
    ? Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(
              _getUnitIcon(controller.productUnit!),
              color: Colors.blue[700],
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations?.unitLabel ?? 'Unit',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getUnitLabel(controller.productUnit!),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Tooltip(
              message: 'وحدة ثابتة للمنتج',
              child: Icon(
                Icons.lock,
                size: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      )
    : DropdownButtonFormField<String>(
        value: controller.selectedUnit ?? 'piece',
        decoration: InputDecoration(
          labelText: localizations?.unitLabel ?? 'Unit *',
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.straighten),
          helperText: 'حدد المنتج أولاً',
        ),
        items: ['piece', 'kg', 'liter', 'meter', 'box', 'pack'].map((unit) {
          return DropdownMenuItem(
            value: unit,
            child: Row(
              children: [
                Icon(_getUnitIcon(unit), size: 18),
                const SizedBox(width: 8),
                Text(_getUnitLabel(unit)),
              ],
            ),
          );
        }).toList(),
        onChanged: controller.productUnit == null ? (value) {
          setState(() {
            controller.selectedUnit = value;
          });
        } : null, // معطل إذا تم تحديد منتج
        validator: (value) {
          if (value?.isEmpty ?? true) {
            return localizations?.unitRequired ?? 'Unit is required';
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
    final localizations = AppLocalizations.of(context);
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
                Text(
                  localizations?.generalInfo ?? 'General Information',
                  style: const TextStyle(
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
                        decoration: InputDecoration(
                          labelText: localizations?.supplierTaxNumber ?? 'Supplier Tax Number *',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.numbers),
                          hintText: localizations?.supplierTaxNumber ?? 'Enter tax number',
                        ),
                        onChanged: (value) => _searchSuppliersByTax(value),
                        onTap: () {
                          if (_supplierTaxController.text.isNotEmpty) {
                            _searchSuppliersByTax(_supplierTaxController.text);
                          }
                        },
                        validator: (value) {
                          if (_selectedSupplierId == null) {
                            return localizations?.mustSelectSupplier ?? 'Must select a supplier';
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
                        decoration: InputDecoration(
                          labelText: localizations?.supplierName ?? 'Supplier Name *',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.business),
                          hintText: localizations?.searchSuppliers ?? 'Enter supplier name',
                        ),
                        onChanged: (value) => _searchSuppliersByName(value),
                        onTap: () {
                          if (_supplierSearchController.text.isNotEmpty) {
                            _searchSuppliersByName(_supplierSearchController.text);
                          }
                        },
                        validator: (value) {
                          if (_selectedSupplierId == null) {
                            return localizations?.mustSelectSupplier ?? 'Must select a supplier';
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
                        decoration: InputDecoration(
                          labelText: localizations?.warehouse ?? 'Warehouse *',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.warehouse),
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
                            return localizations?.warehouseRequired ?? 'Warehouse is required';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Date picker
                    Expanded(
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: localizations?.dateLabel ?? 'Date *',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.calendar_today),
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
              decoration: InputDecoration(
                labelText: localizations?.notesLabel ?? 'Notes',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.note),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceUploadSection() {
  final localizations = AppLocalizations.of(context);
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
              Text(
                localizations?.invoiceUpload ?? 'Upload Invoice',
                style: const TextStyle(
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
                              _selectedFileName ?? (localizations?.noFileSelected ?? 'No file selected'),
                              style: TextStyle(
                                color: _selectedFileName != null 
                                    ? Colors.black 
                                    : Colors.grey,
                              ),
                            ),
                            if (_uploadedInvoiceUrl != null)
                              Text(
                                localizations?.fileUploadSuccess ?? 'Uploaded successfully ✓',
                                style: const TextStyle(
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
                label: Text(_selectedFileName != null ? (localizations?.changeFile ?? 'Change File') : (localizations?.chooseFile ?? 'Choose File')),
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
                  tooltip: localizations?.removeFile ?? 'Remove File',
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            localizations?.fileSizeLimit ?? 'Only PDF files allowed (max 10MB)',
            style: const TextStyle(
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
        _productControllers[index].productUnit = null; // أضف هذا
    _productControllers[index].selectedUnit = 'piece'; // reset للقيمة الافتراضية
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

          _productControllers[index].selectedUnit = exactMatch.unit ?? 'piece';
  _productControllers[index].productUnit = exactMatch.unit ?? 'piece';
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
         _productControllers[index].productUnit = null; // أضف هذا
    _productControllers[index].selectedUnit = 'piece'; // reset للقيمة الافتراضية
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

    // أضف هذه الأسطر لتعيين الوحدة
  _productControllers[index].selectedUnit = product.unit ?? 'piece';
  _productControllers[index].productUnit = product.unit ?? 'piece';
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
  final localizations = AppLocalizations.of(context);
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
          content: Text('${localizations?.filePickError ?? 'File selection error'}: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// دالة رفع الفاتورة
Future<void> _uploadInvoice() async {
  final localizations = AppLocalizations.of(context);
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
          SnackBar(
            content: Text(localizations?.invoiceUploaded ?? 'Invoice uploaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${localizations?.uploadError ?? 'Invoice upload error'}: ${e.toString()}'),
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

// Helper methods للوحدات
IconData _getUnitIcon(String unit) {
  switch (unit.toLowerCase()) {
    case 'piece': return Icons.category;
    case 'kg': return Icons.scale;
    case 'liter': return Icons.water_drop;
    case 'meter': return Icons.straighten;
    case 'box': return Icons.inventory_2;
    case 'pack': return Icons.backpack;
    default: return Icons.category;
  }
}

String _getUnitLabel(String unit) {
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';
  switch (unit.toLowerCase()) {
    case 'piece': return isArabic ? 'قطعة' : 'Piece';
    case 'kg': return isArabic ? 'كيلوجرام' : 'Kilogram';
    case 'liter': return isArabic ? 'لتر' : 'Liter';
    case 'meter': return isArabic ? 'متر' : 'Meter';
    case 'box': return isArabic ? 'صندوق' : 'Box';
    case 'pack': return isArabic ? 'عبوة' : 'Pack';
    default: return unit;
  }
}

}

// Helper class for product row controllers
class ProductRowController {
  final TextEditingController productIdController = TextEditingController();
  final TextEditingController productNameController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  String? selectedUnit;
  String? productUnit;
  List<ProductSearchResult> searchResults = [];
  bool isSearching = false;

  void dispose() {
    productIdController.dispose();
    productNameController.dispose();
    quantityController.dispose();
  }
}