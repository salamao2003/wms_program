import 'package:flutter/material.dart';

class StockInScreen extends StatefulWidget {
  const StockInScreen({super.key});

  @override
  State<StockInScreen> createState() => _StockInScreenState();
}

class _StockInScreenState extends State<StockInScreen> {
  final List<StockInRecord> _stockInRecords = [
    StockInRecord('SI001', DateTime.now().subtract(const Duration(days: 1)), 'P001', 'Laptop Dell XPS', 10, 'Dell Inc', 'WH001'),
    StockInRecord('SI002', DateTime.now().subtract(const Duration(days: 2)), 'P002', 'T-Shirt Blue', 50, 'Fashion Co', 'WH001'),
    StockInRecord('SI003', DateTime.now().subtract(const Duration(days: 3)), 'P003', 'Coffee Beans', 25, 'Coffee Ltd', 'WH002'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock In'),
        automaticallyImplyLeading: false,
        actions: [
          ElevatedButton.icon(
            onPressed: () => _showStockInDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Record Stock In'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Summary Cards
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(
                            Icons.input,
                            size: 32,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Today\'s Stock In',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            '15',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(
                            Icons.trending_up,
                            size: 32,
                            color: Colors.green,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'This Week',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            '85',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(
                            Icons.calendar_month,
                            size: 32,
                            color: Colors.blue,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'This Month',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            '342',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
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
                      Text(
                        'Recent Stock In Records',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: SingleChildScrollView(
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Record ID')),
                              DataColumn(label: Text('Date')),
                              DataColumn(label: Text('Product Code')),
                              DataColumn(label: Text('Product Name')),
                              DataColumn(label: Text('Quantity')),
                              DataColumn(label: Text('Supplier')),
                              DataColumn(label: Text('Warehouse')),
                              DataColumn(label: Text('Actions')),
                            ],
                            rows: _stockInRecords.map((record) {
                              return DataRow(
                                cells: [
                                  DataCell(Text(record.id)),
                                  DataCell(Text('${record.date.day}/${record.date.month}/${record.date.year}')),
                                  DataCell(Text(record.productCode)),
                                  DataCell(Text(record.productName)),
                                  DataCell(Text(record.quantity.toString())),
                                  DataCell(Text(record.supplier)),
                                  DataCell(Text(record.warehouse)),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.visibility),
                                          onPressed: () => _viewRecord(record),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.edit),
                                          onPressed: () => _showStockInDialog(record: record),
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
      ),
    );
  }

  void _showStockInDialog({StockInRecord? record}) {
    final isEditing = record != null;
    final productCodeController = TextEditingController(text: record?.productCode ?? '');
    final quantityController = TextEditingController(text: record?.quantity.toString() ?? '');
    final supplierController = TextEditingController(text: record?.supplier ?? '');
    String selectedWarehouse = record?.warehouse ?? 'WH001';
    DateTime selectedDate = record?.date ?? DateTime.now();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Stock In Record' : 'Record Stock In'),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: productCodeController,
                  decoration: const InputDecoration(
                    labelText: 'Product Code',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: quantityController,
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: supplierController,
                  decoration: const InputDecoration(
                    labelText: 'Supplier',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedWarehouse,
                  decoration: const InputDecoration(
                    labelText: 'Warehouse',
                    border: OutlineInputBorder(),
                  ),
                  items: ['WH001', 'WH002', 'WH003'].map((warehouse) {
                    return DropdownMenuItem(
                      value: warehouse,
                      child: Text(warehouse),
                    );
                  }).toList(),
                  onChanged: (value) {
                    selectedWarehouse = value!;
                  },
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      selectedDate = date;
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Save stock in record logic here
              Navigator.pop(context);
            },
            child: Text(isEditing ? 'Update' : 'Record'),
          ),
        ],
      ),
    );
  }

  void _viewRecord(StockInRecord record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Stock In Record - ${record.id}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Date:', '${record.date.day}/${record.date.month}/${record.date.year}'),
            _buildDetailRow('Product Code:', record.productCode),
            _buildDetailRow('Product Name:', record.productName),
            _buildDetailRow('Quantity:', record.quantity.toString()),
            _buildDetailRow('Supplier:', record.supplier),
            _buildDetailRow('Warehouse:', record.warehouse),
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

  Widget _buildDetailRow(String label, String value) {
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
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class StockInRecord {
  final String id;
  final DateTime date;
  final String productCode;
  final String productName;
  final int quantity;
  final String supplier;
  final String warehouse;

  StockInRecord(this.id, this.date, this.productCode, this.productName, this.quantity, this.supplier, this.warehouse);
}
