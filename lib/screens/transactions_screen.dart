import 'package:flutter/material.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _selectedType = 'All';
  DateTimeRange? _selectedDateRange;

  final List<String> _transactionTypes = ['All', 'Stock In', 'Stock Out', 'Transfer', 'Adjustment'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        automaticallyImplyLeading: false,
        actions: [
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.download),
            label: const Text('Export'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Filters Row
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Transaction Type',
                      border: OutlineInputBorder(),
                    ),
                    items: _transactionTypes.map((type) {
                      return DropdownMenuItem(value: type, child: Text(type));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedType = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final range = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        initialDateRange: _selectedDateRange,
                      );
                      if (range != null) {
                        setState(() {
                          _selectedDateRange = range;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date Range',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.date_range),
                      ),
                      child: Text(
                        _selectedDateRange == null
                            ? 'Select date range'
                            : '${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month} - ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    // Apply filters
                  },
                  child: const Text('Filter'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Transactions Table
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transaction History',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: SingleChildScrollView(
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Transaction ID')),
                              DataColumn(label: Text('Date')),
                              DataColumn(label: Text('Type')),
                              DataColumn(label: Text('Product')),
                              DataColumn(label: Text('Quantity')),
                              DataColumn(label: Text('Warehouse')),
                              DataColumn(label: Text('Reference')),
                              DataColumn(label: Text('Actions')),
                            ],
                            rows: [
                              // Sample data
                              DataRow(cells: [
                                const DataCell(Text('TXN001')),
                                const DataCell(Text('15/12/2023')),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text('Stock In', style: TextStyle(color: Colors.green)),
                                  ),
                                ),
                                const DataCell(Text('Laptop Dell XPS')),
                                const DataCell(Text('+10')),
                                const DataCell(Text('WH001')),
                                const DataCell(Text('SI001')),
                                DataCell(
                                  IconButton(
                                    icon: const Icon(Icons.visibility),
                                    onPressed: () {},
                                  ),
                                ),
                              ]),
                            ],
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
}
