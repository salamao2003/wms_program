import 'package:flutter/material.dart';

class WarehousesScreen extends StatefulWidget {
  const WarehousesScreen({super.key});

  @override
  State<WarehousesScreen> createState() => _WarehousesScreenState();
}

class _WarehousesScreenState extends State<WarehousesScreen> {
  int _selectedWarehouse = 0;
  
  final List<Warehouse> _warehouses = [
    Warehouse('WH001', 'Main Warehouse', 'New York', '123 Main St', 'John Doe'),
    Warehouse('WH002', 'Secondary Warehouse', 'Los Angeles', '456 Oak Ave', 'Jane Smith'),
    Warehouse('WH003', 'Distribution Center', 'Chicago', '789 Pine Rd', 'Bob Johnson'),
  ];

  final List<StockItem> _stockItems = [
    StockItem('P001', 'Laptop Dell XPS', 25, 15, 10),
    StockItem('P002', 'T-Shirt Blue', 100, 80, 120),
    StockItem('P003', 'Coffee Beans', 50, 30, 20),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Warehouses'),
        automaticallyImplyLeading: false,
        actions: [
          ElevatedButton.icon(
            onPressed: () => _showWarehouseDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Add Warehouse'),
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
                        'Warehouses',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    const Divider(),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _warehouses.length,
                        itemBuilder: (context, index) {
                          final warehouse = _warehouses[index];
                          return ListTile(
                            selected: _selectedWarehouse == index,
                            leading: const Icon(Icons.warehouse),
                            title: Text(warehouse.name),
                            subtitle: Text(warehouse.location),
                            trailing: PopupMenuButton(
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit),
                                      SizedBox(width: 8),
                                      Text('Edit'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete),
                                      SizedBox(width: 8),
                                      Text('Delete'),
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
                                _selectedWarehouse = index;
                              });
                            },
                          );
                        },
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
                  // Warehouse Details Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Warehouse Details',
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
                          _buildDetailRow('Code:', _warehouses[_selectedWarehouse].code),
                          _buildDetailRow('Name:', _warehouses[_selectedWarehouse].name),
                          _buildDetailRow('Location:', _warehouses[_selectedWarehouse].location),
                          _buildDetailRow('Address:', _warehouses[_selectedWarehouse].address),
                          _buildDetailRow('Manager:', _warehouses[_selectedWarehouse].manager),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Stock Items Card
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Stock by Location',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: SingleChildScrollView(
                                child: DataTable(
                                  columns: const [
                                    DataColumn(label: Text('Product Code')),
                                    DataColumn(label: Text('Product Name')),
                                    DataColumn(label: Text('WH001')),
                                    DataColumn(label: Text('WH002')),
                                    DataColumn(label: Text('WH003')),
                                  ],
                                  rows: _stockItems.map((item) {
                                    return DataRow(
                                      cells: [
                                        DataCell(Text(item.productCode)),
                                        DataCell(Text(item.productName)),
                                        DataCell(Text(item.wh001.toString())),
                                        DataCell(Text(item.wh002.toString())),
                                        DataCell(Text(item.wh003.toString())),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Text(value),
        ],
      ),
    );
  }

  void _showWarehouseDialog({Warehouse? warehouse}) {
    final isEditing = warehouse != null;
    final codeController = TextEditingController(text: warehouse?.code ?? '');
    final nameController = TextEditingController(text: warehouse?.name ?? '');
    final locationController = TextEditingController(text: warehouse?.location ?? '');
    final addressController = TextEditingController(text: warehouse?.address ?? '');
    final managerController = TextEditingController(text: warehouse?.manager ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Warehouse' : 'Add Warehouse'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeController,
                decoration: const InputDecoration(
                  labelText: 'Warehouse Code',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Warehouse Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: managerController,
                decoration: const InputDecoration(
                  labelText: 'Manager',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Save warehouse logic here
              Navigator.pop(context);
            },
            child: Text(isEditing ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }

  void _deleteWarehouse(Warehouse warehouse) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Warehouse'),
        content: Text('Are you sure you want to delete ${warehouse.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _warehouses.remove(warehouse);
                if (_selectedWarehouse >= _warehouses.length) {
                  _selectedWarehouse = _warehouses.length - 1;
                }
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class Warehouse {
  final String code;
  final String name;
  final String location;
  final String address;
  final String manager;

  Warehouse(this.code, this.name, this.location, this.address, this.manager);
}

class StockItem {
  final String productCode;
  final String productName;
  final int wh001;
  final int wh002;
  final int wh003;

  StockItem(this.productCode, this.productName, this.wh001, this.wh002, this.wh003);
}
