import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../backend/warehouse_logic.dart';

class WarehousesScreen extends StatefulWidget {
  const WarehousesScreen({super.key});

  @override
  State<WarehousesScreen> createState() => _WarehousesScreenState();
}

class _WarehousesScreenState extends State<WarehousesScreen> {
  int _selectedWarehouse = 0;
  bool _isOverviewSelected = true; // Overview selected by default
  
  final WarehouseLogic _warehouseLogic = WarehouseLogic();
  List<Warehouse> _warehouses = [];
  Map<String, List<WarehouseStock>> _warehouseStocks = {};
  
  // New Enhanced Overview Data
  List<WarehouseOverviewData> _enhancedOverviewData = [];
  List<WarehouseColumn> _warehouseColumns = [];
  Map<String, dynamic> _overviewStats = {};
  
  // Search and Filter Options
  String _searchQuery = '';
  String _sortBy = 'name';
  bool _sortAscending = true;
  bool _showEmptyStock = true;
  
  bool _isLoading = true;
  String? _errorMessage;

  // Controller for horizontal scrolling of the overview table
  final ScrollController _overviewHScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadWarehouses();
  }

  @override
  void dispose() {
    // dispose controllers
    _overviewHScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadWarehouses() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      final warehouses = await _warehouseLogic.getWarehouses();
      
      // Load enhanced overview data
      final enhancedOverviewData = await _warehouseLogic.getFilteredOverviewData(
        searchQuery: _searchQuery,
        sortBy: _sortBy,
        ascending: _sortAscending,
        showEmptyStock: _showEmptyStock,
      );
      
      // Load warehouse columns for dynamic table
      final warehouseColumns = await _warehouseLogic.getWarehouseColumns();
      
      // Load overview statistics
      final overviewStats = await _warehouseLogic.getWarehouseOverviewStats();
      
      // Load individual warehouse stocks
      final Map<String, List<WarehouseStock>> warehouseStocks = {};
      for (final warehouse in warehouses) {
        if (warehouse.id != null) {
          final stocks = await _warehouseLogic.getWarehouseStock(warehouse.id!);
          warehouseStocks[warehouse.id!] = stocks;
        }
      }
      
      setState(() {
        _warehouses = warehouses;
        _enhancedOverviewData = enhancedOverviewData;
        _warehouseColumns = warehouseColumns;
        _overviewStats = overviewStats;
        _warehouseStocks = warehouseStocks;
        _isLoading = false;
      });
      
      // If no warehouses found, add demo data
      if (_warehouses.isEmpty) {
        await _addDemoData();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading warehouses: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _addDemoData() async {
    try {
      // Add demo warehouses
      final demoWarehouses = [
        Warehouse(
          code: 'WH001',
          name: 'Main Warehouse',
          location: 'New York',
          address: '123 Main St',
          manager: 'John Doe',
          accountant: 'Alice Cooper',
          warehouseKeeper: 'Mike Johnson',
        ),
        Warehouse(
          code: 'WH002',
          name: 'Secondary Warehouse',
          location: 'Los Angeles',
          address: '456 Oak Ave',
          manager: 'Jane Smith',
          accountant: 'Bob Wilson',
          warehouseKeeper: 'Sarah Davis',
        ),
      ];

      for (final warehouse in demoWarehouses) {
        await _warehouseLogic.addWarehouse(warehouse);
      }

      // Reload data
      _loadWarehouses();
    } catch (e) {
      print('Error adding demo data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(localizations?.warehousesTitle ?? 'Warehouses'),
          automaticallyImplyLeading: false,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(localizations?.warehousesTitle ?? 'Warehouses'),
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadWarehouses,
                child: Text(localizations?.retry ?? 'Retry'),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations?.warehousesTitle ?? 'Warehouses'),
        automaticallyImplyLeading: false,
        actions: [
          ElevatedButton.icon(
            onPressed: () => _showWarehouseDialog(),
            icon: const Icon(Icons.add),
            label: Text(localizations?.addWarehouse ?? 'Add Warehouse'),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              setState(() {
                _isLoading = true;
              });
              await _loadWarehouses();
              setState(() {
                _isLoading = false;
              });
            },
            tooltip: 'تحديث البيانات',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Warehouses List
            Expanded(
              flex: 1,
              child: Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        localizations?.warehousesTitle ?? 'Warehouses',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    const Divider(),
                    Expanded(
                      child: ListView(
                        children: [
                          // Overview Item
                          ListTile(
                            selected: _isOverviewSelected,
                            leading: const Icon(Icons.visibility),
                            title: Text(localizations?.overview ?? 'Overview'),
                            subtitle: Text(localizations?.stockByLocation ?? 'All Warehouses'),
                            onTap: () {
                              setState(() {
                                _isOverviewSelected = true;
                              });
                              // إعادة تحميل البيانات للحصول على الفئات المحدثة
                              _refreshOverviewData();
                            },
                          ),
                          const Divider(),
                          // Warehouses List
                          ...List.generate(_warehouses.length, (index) {
                            final warehouse = _warehouses[index];
                            return ListTile(
                              selected: !_isOverviewSelected && _selectedWarehouse == index,
                              leading: const Icon(Icons.warehouse),
                              title: Text(warehouse.name),
                              subtitle: Text(warehouse.location),
                              trailing: PopupMenuButton(
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        const Icon(Icons.edit),
                                        const SizedBox(width: 8),
                                        Text(localizations?.edit ?? 'Edit'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        const Icon(Icons.delete),
                                        const SizedBox(width: 8),
                                        Text(localizations?.delete ?? 'Delete'),
                                      ],
                                    ),
                                  ),
                                ],
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _showWarehouseDialog(warehouse: warehouse);
                                  } else if (value == 'delete') {
                                    _deleteWarehouse(warehouse);
                                  }
                                },
                              ),
                              onTap: () {
                                setState(() {
                                  _isOverviewSelected = false;
                                  _selectedWarehouse = index;
                                });
                              },
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Warehouse Details and Stock
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  // Warehouse Details Card - only show when not in overview
                  if (!_isOverviewSelected)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  localizations?.warehouseDetails ?? 'Warehouse Details',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _showWarehouseDialog(
                                    warehouse: _warehouses[_selectedWarehouse],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildDetailRow('${localizations?.warehouseCode ?? "Warehouse Code"} :', _warehouses[_selectedWarehouse].code),
                            _buildDetailRow('${localizations?.warehouseName ?? "Warehouse Name"} :', _warehouses[_selectedWarehouse].name),
                            _buildDetailRow('${localizations?.location ?? "Location"} :', _warehouses[_selectedWarehouse].location),
                            _buildDetailRow('${localizations?.address ?? "Address"} :', _warehouses[_selectedWarehouse].address ?? ''),
                            _buildDetailRow('${localizations?.manager ?? "Manager"} :', _warehouses[_selectedWarehouse].manager ?? ''),
                            _buildDetailRow('${localizations?.accountant ?? "Accountant"} :', _warehouses[_selectedWarehouse].accountant ?? ''),
                            _buildDetailRow('${localizations?.warehouseKeeper ?? "Warehouse Keeper"} :', _warehouses[_selectedWarehouse].warehouseKeeper ?? ''),
                          ],
                        ),
                      ),
                    ),
                  if (!_isOverviewSelected) const SizedBox(height: 16),
                  // Stock Items Card
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header with title and controls
                            Row(
                              children: [
                                Text(
                                  _isOverviewSelected 
                                    ? 'Warehouse Overview'
                                    : (localizations?.stockByLocation ?? 'Stock by Location'),
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const Spacer(),
                                if (_isOverviewSelected) ...[
                                  // Search field for overview
                                  SizedBox(
                                    width: 250,
                                    child: TextField(
                                      decoration: InputDecoration(
                                        hintText: 'Search products...',
                                        prefixIcon: const Icon(Icons.search),
                                        border: const OutlineInputBorder(),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          _searchQuery = value;
                                        });
                                        _refreshOverviewData();
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Sort dropdown
                                  DropdownButton<String>(
                                    value: _sortBy,
                                    items: [
                                      DropdownMenuItem(value: 'name', child: Text(localizations?.name ?? 'Name')),
                                      DropdownMenuItem(value: 'category', child: Text(localizations?.category ?? 'Category')),
                                      DropdownMenuItem(value: 'total', child: Text(localizations?.total ?? 'Total')),
                                    ],
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() {
                                          _sortBy = value;
                                        });
                                        _refreshOverviewData();
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  // Sort direction button
                                  IconButton(
                                    icon: Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
                                    onPressed: () {
                                      setState(() {
                                        _sortAscending = !_sortAscending;
                                      });
                                      _refreshOverviewData();
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  // Filter empty stock
                                 
                                  const SizedBox(width: 8),
                                  // Export button
                                  ElevatedButton.icon(
                                    onPressed: _exportToCSV,
                                    icon: const Icon(Icons.download),
                                    label: Text(localizations?.export ?? 'Export'),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Statistics Row for Overview
                            if (_isOverviewSelected && _overviewStats.isNotEmpty) ...[
                              Row(
                                children: [
                                  _buildStatCard(localizations?.totalProducts ?? 'Total Products', _overviewStats['totalProducts']?.toString() ?? '0', Icons.inventory, Colors.blue),
                                  const SizedBox(width: 16),
                                  _buildStatCard('Total Warehouses', _overviewStats['totalWarehouses']?.toString() ?? '0', Icons.warehouse, Colors.green),
                                  const SizedBox(width: 16),
                                              
                                ],
                              ),
                              const SizedBox(height: 16),
                            ],
                            // Table area: render selected table and ensure horizontal scrolling
                            Expanded(
                              child: _isOverviewSelected
                                  ? _buildEnhancedOverviewDataTable(localizations)
                                  : _buildWarehouseDataTable(localizations),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper functions for new features
  Widget _buildStatCard(String title, String value, IconData icon, [Color? color]) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: (color ?? Theme.of(context).primaryColor).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: (color ?? Theme.of(context).primaryColor).withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color ?? Theme.of(context).primaryColor, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color ?? Theme.of(context).primaryColor,
                    ),
                  ),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshOverviewData() async {
    try {
      // إعادة تحميل البيانات الكاملة للحصول على الفئات المحدثة
      final enhancedOverviewData = await _warehouseLogic.getFilteredOverviewData(
        searchQuery: _searchQuery,
        sortBy: _sortBy,
        ascending: _sortAscending,
        showEmptyStock: _showEmptyStock,
      );
      
      // إعادة تحميل الإحصائيات أيضاً
      final overviewStats = await _warehouseLogic.getWarehouseOverviewStats();
      
      setState(() {
        _enhancedOverviewData = enhancedOverviewData;
        _overviewStats = overviewStats;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error refreshing data: $e')),
      );
    }
  }

  Future<void> _exportToCSV() async {
    try {
      final csvData = _warehouseLogic.convertToCSV(_enhancedOverviewData, _warehouseColumns);
      
      // في بيئة الويب، يمكن استخدام download
      // في بيئة المحمول، يمكن حفظ الملف أو مشاركته
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('CSV Data Generated Successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      
      // TODO: تنفيذ حفظ الملف أو مشاركته
      print('CSV Data Generated: ${csvData.length} characters');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting data: $e')),
      );
    }
  }

  // دالة لإعطاء لون مميز لكل فئة
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      default:
        return Colors.teal;
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedOverviewDataTable(AppLocalizations? localizations) {
    if (_enhancedOverviewData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No stock data available',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Search for: "$_searchQuery"',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
              ),
            ],
          ],
        ),
      );
    }
    
    // Dynamic columns: Product info + Warehouse columns + Total
    final List<DataColumn> columns = [
      DataColumn(
        label: Text(localizations?.productId ?? 'Product ID'),
        tooltip: 'Product ID',
      ),
      DataColumn(
        label: Text(localizations?.productName ?? 'Product Name'),
        tooltip: 'Product Name',
      ),
      DataColumn(
        label: Text(localizations?.category ?? 'Category'),
        tooltip: 'Product Category',
      ),
    ];
    
    // Add dynamic warehouse columns (Quantity + Unit for each warehouse)
    for (final warehouseColumn in _warehouseColumns) {
      // Quantity column for warehouse
      columns.add(DataColumn(
        label: SizedBox(
          width: 80,
          child: Text(
            warehouseColumn.warehouseName,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        tooltip: '${warehouseColumn.warehouseName} - Quantity',
        numeric: true,
      ));
      
      // Unit column for warehouse
      columns.add(DataColumn(
        label: SizedBox(
          width: 60,
          child: Text(
            'Unit',
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white,
            ),
          ),
        ),
        tooltip: '${warehouseColumn.warehouseName} - Unit',
      ));
    }
    
    // Add total column
    columns.add(DataColumn(
      label: Text(localizations?.total ?? 'Total'),
      tooltip: 'Total Quantity Across All Warehouses',
      numeric: true,
    ));
    
    // Wrap the DataTable in a horizontal scroll with a minimum width so the last column never gets clipped
    return LayoutBuilder(
      builder: (context, constraints) {
        // Column width plan
        const double idW = 100;
        const double nameW = 220;
        const double categoryW = 120;
        const double qtyW = 90;
        const double unitW = 60;
        const double totalW = 110;

        final int dynamicPairs = _warehouseColumns.length; // each has Qty + Unit
        final double minWidth = idW + nameW + categoryW + (dynamicPairs * (qtyW + unitW)) + totalW;
        final double tableMinWidth = minWidth > constraints.maxWidth ? minWidth : constraints.maxWidth;

        return Scrollbar(
          controller: _overviewHScrollController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: _overviewHScrollController,
            primary: false,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: tableMinWidth),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  // vertical scroll for table rows
                  primary: false,
                  child: DataTable(
                    columnSpacing: 16,
                    horizontalMargin: 16,
                    headingRowColor: MaterialStateProperty.all(
                      Theme.of(context).primaryColor.withOpacity(0.1),
                    ),
                    columns: columns,
                    rows: _enhancedOverviewData.map((item) {
                      final List<DataCell> cells = [
                        // Product ID cell
                        DataCell(
                          SizedBox(
                            width: 100,
                            child: Text(
                              item.productId,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ),
                        // Product Name cell
                        DataCell(
                          SizedBox(
                            width: 150,
                            child: Tooltip(
                              message: item.productName,
                              child: Text(
                                item.productName,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Category cell
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getCategoryColor(item.categoryName).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _getCategoryColor(item.categoryName).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              item.categoryName,
                              style: TextStyle(
                                color: _getCategoryColor(item.categoryName),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ];
                      
                      // Add warehouse stock cells (Quantity + Unit for each warehouse)
                      for (final warehouseColumn in _warehouseColumns) {
                        final stock = item.getStockForWarehouse(warehouseColumn.warehouseId);
                        final quantity = stock?.quantity ?? 0;
                        final unit = stock?.unit ?? 'PC';
                        
                        // Quantity cell
                        cells.add(DataCell(
                          Container(
                            width: 80,
                            alignment: Alignment.center,
                            child: Text(
                              quantity.toString(),
                              style: TextStyle(
                                color: quantity > 0 ? Colors.green[700] : Colors.grey[500],
                                fontWeight: quantity > 0 ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                        ));
                        
                        // Unit cell
                        cells.add(DataCell(
                          Container(
                            width: 60,
                            alignment: Alignment.center,
                            child: Text(
                              unit,
                              style: TextStyle(
                                fontSize: 11,
                                color: quantity > 0 ? Colors.blue[600] : Colors.grey[400],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ));
                      }
                      
                      // Add total cell
                      cells.add(DataCell(
                        Container(
                          alignment: Alignment.center,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: item.totalQuantity > 0 
                                ? Colors.blue[100] 
                                : Colors.grey[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.totalQuantity.toString(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: item.totalQuantity > 0 
                                  ? Colors.blue[800] 
                                  : Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                      ));
                      
                      return DataRow(
                        cells: cells,
                        color: MaterialStateProperty.resolveWith<Color?>(
                          (Set<MaterialState> states) {
                            if (!item.hasStock) {
                              return Colors.red[100];
                            }
                            return null;
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWarehouseDataTable(AppLocalizations? localizations) {
    if (_warehouses.isEmpty) return Container();
    
    final selectedWarehouse = _warehouses[_selectedWarehouse];
    final warehouseId = selectedWarehouse.id;
    final stocks = warehouseId != null ? _warehouseStocks[warehouseId] ?? [] : <WarehouseStock>[];
    
    if (stocks.isEmpty) {
      return Center(
        child: Text(
          'No stock data available for this warehouse',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }
    
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color.fromARGB(255, 43, 43, 43)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DataTable(
        columnSpacing: 20,
        horizontalMargin: 16,
        headingRowColor: MaterialStateProperty.all(
          Theme.of(context).primaryColor.withOpacity(0.1),
        ),
        columns: [
          DataColumn(
            label: Row(
              children: [
                Icon(Icons.qr_code, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(localizations?.productId ?? 'Product ID'),
              ],
            ),
          ),
          DataColumn(
            label: Row(
              children: [
                Icon(Icons.inventory_2, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(localizations?.productName ?? 'Product Name'),
              ],
            ),
          ),
          DataColumn(
            label: Row(
              children: [
                Icon(Icons.category, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(localizations?.category ?? 'Category'),
              ],
            ),
          ),
          DataColumn(
            label: Row(
              children: [
                Icon(Icons.numbers, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(localizations?.quantity ?? 'Quantity'),
              ],
            ),
            numeric: true,
          ),
          DataColumn(
            label: Row(
              children: [
                Icon(Icons.straighten, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(localizations?.unit ?? 'Unit'),
              ],
            ),
          ),
        ],
        rows: stocks.map((stock) {
          final quantity = stock.currentQuantity;
          
            return DataRow(
            color: MaterialStateProperty.resolveWith<Color?>(
              (Set<MaterialState> states) {
              return const Color.fromARGB(255, 32, 32, 32);
              },
            ),
            cells: [
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    stock.productId,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ),
              DataCell(
                SizedBox(
                  width: 200,
                  child: Tooltip(
                    message: stock.productName ?? '',
                    child: Text(
                      stock.productName ?? '',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(stock.categoryName ?? 'General').withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getCategoryColor(stock.categoryName ?? 'General').withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    stock.categoryName ?? 'General',
                    style: TextStyle(
                      color: _getCategoryColor(stock.categoryName ?? 'General'),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: quantity == 0 
                          ? Colors.red 
                          : quantity < 10 
                            ? Colors.orange 
                            : quantity < 50 
                              ? Colors.yellow[700] 
                              : Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      quantity.toString(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: quantity == 0 
                          ? Colors.red[700] 
                          : quantity < 10 
                            ? Colors.orange[700] 
                            : quantity < 50 
                              ? Colors.yellow[800] 
                              : Colors.green[700],
                      ),
                    ),
                  ],
                ),
              ),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    stock.unit,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _showWarehouseDialog({Warehouse? warehouse}) {
    final localizations = AppLocalizations.of(context);
    final isEditing = warehouse != null;
    final codeController = TextEditingController(text: warehouse?.code ?? '');
    final nameController = TextEditingController(text: warehouse?.name ?? '');
    final locationController = TextEditingController(text: warehouse?.location ?? '');
    final addressController = TextEditingController(text: warehouse?.address ?? '');
    final managerController = TextEditingController(text: warehouse?.manager ?? '');
    final accountantController = TextEditingController(text: warehouse?.accountant ?? '');
    final warehouseKeeperController = TextEditingController(text: warehouse?.warehouseKeeper ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? (localizations?.editWarehouse ?? 'Edit Warehouse') : (localizations?.addWarehouse ?? 'Add Warehouse')),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: codeController,
                  decoration: InputDecoration(
                    labelText: localizations?.warehouseCode ?? 'Warehouse Code',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: localizations?.warehouseName ?? 'Warehouse Name',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: locationController,
                  decoration: InputDecoration(
                    labelText: localizations?.location ?? 'Location',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: addressController,
                  decoration: InputDecoration(
                    labelText: localizations?.address ?? 'Address',
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: managerController,
                  decoration: InputDecoration(
                    labelText: localizations?.manager ?? 'Manager',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: accountantController,
                  decoration: InputDecoration(
                    labelText: localizations?.accountant ?? 'Accountant',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: warehouseKeeperController,
                  decoration: InputDecoration(
                    labelText: localizations?.warehouseKeeper ?? 'Warehouse Keeper',
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations?.cancel ?? 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final newWarehouse = Warehouse(
                  id: warehouse?.id,
                  code: codeController.text,
                  name: nameController.text,
                  location: locationController.text,
                  address: addressController.text.isEmpty ? null : addressController.text,
                  manager: managerController.text.isEmpty ? null : managerController.text,
                  accountant: accountantController.text.isEmpty ? null : accountantController.text,
                  warehouseKeeper: warehouseKeeperController.text.isEmpty ? null : warehouseKeeperController.text,
                );

                if (isEditing && warehouse.id != null) {
                  await _warehouseLogic.updateWarehouse(warehouse.id!, newWarehouse);
                } else {
                  await _warehouseLogic.addWarehouse(newWarehouse);
                }

                Navigator.pop(context);
                _loadWarehouses(); // Reload data
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: Text(isEditing ? (localizations?.edit ?? 'Update') : (localizations?.add ?? 'Add')),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteWarehouse(Warehouse warehouse) async {
    final localizations = AppLocalizations.of(context);
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations?.deleteWarehouse ?? 'Delete Warehouse'),
        content: Text('${localizations?.deleteConfirmation ?? "Are you sure you want to delete"} ${warehouse.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(localizations?.cancel ?? 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(localizations?.delete ?? 'Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && warehouse.id != null) {
      try {
        await _warehouseLogic.deleteWarehouse(warehouse.id!);
        _loadWarehouses(); // Reload data
        
        // Reset selection if needed
        if (_selectedWarehouse >= _warehouses.length - 1) {
          setState(() {
            _selectedWarehouse = 0;
            _isOverviewSelected = true;
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting warehouse: $e')),
        );
      }
    }
  }
}
