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
  List<StockOverview> _stockOverview = [];
  Map<String, List<WarehouseStock>> _warehouseStocks = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadWarehouses();
  }

  Future<void> _loadWarehouses() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      final warehouses = await _warehouseLogic.getWarehouses();
      final stockOverview = await _warehouseLogic.getAllWarehousesStock();
      
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
        _stockOverview = stockOverview;
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
                            Text(
                              localizations?.stockByLocation ?? 'Stock by Location',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: SingleChildScrollView(
                                  child: _isOverviewSelected 
                                    ? _buildOverviewDataTable(localizations)
                                    : _buildWarehouseDataTable(localizations),
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
            ),
          ],
        ),
      ),
    );
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

  Widget _buildOverviewDataTable(AppLocalizations? localizations) {
    if (_stockOverview.isEmpty) {
      return Center(
        child: Text(
          'No stock data available',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }
    
    return DataTable(
      columnSpacing: 20,
      columns: [
        DataColumn(label: Text(localizations?.productId ?? 'Product ID')),
        DataColumn(label: Text(localizations?.productName ?? 'Product Name')),
        DataColumn(label: Text(localizations?.category ?? 'Category')),
        DataColumn(label: Text(localizations?.quantity ?? 'Total Quantity')),
        DataColumn(label: Text(localizations?.warehouses ?? 'Warehouses')),
      ],
      rows: _stockOverview.map((item) {
        // Calculate total quantity across all warehouses
        int totalQuantity = 0;
        for (var warehouseStock in item.warehouseStocks.values) {
          totalQuantity += warehouseStock.quantity;
        }
        
        return DataRow(
          cells: [
            DataCell(Text(item.productId)),
            DataCell(
              SizedBox(
                width: 120,
                child: Text(
                  item.productName,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            DataCell(Text(item.categoryName)),
            DataCell(Text(totalQuantity.toString())),
            DataCell(Text(item.warehouseStocks.length.toString())),
          ],
        );
      }).toList(),
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
    
    return DataTable(
      columnSpacing: 20,
      columns: [
        DataColumn(label: Text(localizations?.productId ?? 'Product ID')),
        DataColumn(label: Text(localizations?.productName ?? 'Product Name')),
        DataColumn(label: Text(localizations?.category ?? 'Category')),
        DataColumn(label: Text(localizations?.quantity ?? 'Quantity')),
        DataColumn(label: Text(localizations?.unit ?? 'Unit')),
      ],
      rows: stocks.map((stock) {
        return DataRow(
          cells: [
            DataCell(Text(stock.productId)),
            DataCell(
              SizedBox(
                width: 120,
                child: Text(
                  stock.productName ?? '',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            DataCell(Text(stock.categoryName ?? '')),
            DataCell(Text(stock.currentQuantity.toString())),
            DataCell(Text(stock.unit)),
          ],
        );
      }).toList(),
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
