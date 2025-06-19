import 'package:flutter/material.dart';

class StockOutScreen extends StatefulWidget {
  const StockOutScreen({super.key});

  @override
  State<StockOutScreen> createState() => _StockOutScreenState();
}

class _StockOutScreenState extends State<StockOutScreen> {
  final List<StockOutRecord> _stockOutRecords = [
    StockOutRecord('SO001', DateTime.now().subtract(const Duration(hours: 2)), 'P001', 'Laptop Dell XPS', 5, 'Customer ABC', 'WH001', 'Sale'),
    StockOutRecord('SO002', DateTime.now().subtract(const Duration(hours: 4)), 'P002', 'T-Shirt Blue', 20, 'Branch Office', 'WH001', 'Transfer'),
    StockOutRecord('SO003', DateTime.now().subtract(const Duration(days: 1)), 'P003', 'Coffee Beans', 10, 'Customer XYZ', 'WH002', 'Sale'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Out'),
        automaticallyImplyLeading: false,
        actions: [
          ElevatedButton.icon(
            onPressed: () => _showStockOutDialog(),
            icon: const Icon(Icons.remove),
            label: const Text('Record Stock Out'),
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
                            Icons.output,
                            size: 32,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Today\'s Stock Out',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            '12',
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
                            Icons.trending_down,
                            size: 32,
                            color: Colors.orange,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'This Week',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            '67',
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
                            color: Colors.purple,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'This Month',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            '289',
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
            // Stock Out Records Table
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recent Stock Out Records',
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
                              DataColumn(label: Text('Destination')),
                              DataColumn(label: Text('Warehouse')),
                              DataColumn(label: Text('Type')),
                              DataColumn(label: Text('Actions')),
                            ],
                            rows: _stockOutRecords.map((record) {
                              return DataRow(
                                cells: [
                                  DataCell(Text(record.id)),
                                  DataCell(Text('${record.date.day}/${record.date.month}/${record.date.year}')),
                                  DataCell(Text(record.productCode)),
                                  DataCell(Text(record.productName)),
                                  DataCell(Text(record.quantity.toString())),
                                  DataCell(Text(record.destination)),
                                  DataCell(Text(record.warehouse)),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: record.type == 'Sale' ? Colors.green.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        record.type,
                                        style: TextStyle(
                                          color: record.type == 'Sale' ? Colors.green : Colors.blue,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
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
                                          onPressed: () => _showStockOutDialog(record: record),
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

  void _showStockOutDialog({StockOutRecord? record}) {
    final isEditing = record != null;
    final productCodeController = TextEditingController(text: record?.productCode ?? '');
    final quantityController = TextEditingController(text: record?.quantity.toString() ?? '');
    final destinationController = TextEditingController(text: record?.destination ?? '');
    String selectedWarehouse = record?.warehouse ?? 'WH001';
    String selectedType = record?.type ?? 'Sale';
    DateTime selectedDate = record?.date ?? DateTime.now();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Stock Out Record' : 'Record Stock Out'),
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
                  controller: destinationController,
                  decoration: const InputDecoration(
                    labelText: 'Destination (Customer/Branch)',
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
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(),
                  ),
                  items: ['Sale', 'Transfer', 'Return', 'Damage'].map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    selectedType = value!;
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
              // Save stock out record logic here
              Navigator.pop(context);
            },
            child: Text(isEditing ? 'Update' : 'Record'),
          ),
        ],
      ),
    );
  }

  void _viewRecord(StockOutRecord record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Stock Out Record - ${record.id}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Date:', '${record.date.day}/${record.date.month}/${record.date.year}'),
            _buildDetailRow('Product Code:', record.productCode),
            _buildDetailRow('Product Name:', record.productName),
            _buildDetailRow('Quantity:', record.quantity.toString()),
            _buildDetailRow('Destination:', record.destination),
            _buildDetailRow('Warehouse:', record.warehouse),
            _buildDetailRow('Type:', record.type),
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

class StockOutRecord {
  final String id;
  final DateTime date;
  final String productCode;
  final String productName;
  final int quantity;
  final String destination;
  final String warehouse;
  final String type;

  StockOutRecord(this.id, this.date, this.productCode, this.productName, this.quantity, this.destination, this.warehouse, this.type);
}
