import 'package:flutter/material.dart';

class InventoryCountScreen extends StatefulWidget {
  const InventoryCountScreen({super.key});

  @override
  State<InventoryCountScreen> createState() => _InventoryCountScreenState();
}

class _InventoryCountScreenState extends State<InventoryCountScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Count'),
        automaticallyImplyLeading: false,
        actions: [
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add),
            label: const Text('New Count'),
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
                          Icon(Icons.inventory_2, size: 32, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(height: 8),
                          Text('Active Counts', style: Theme.of(context).textTheme.titleMedium),
                          Text('3', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
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
                          Icon(Icons.check_circle, size: 32, color: Colors.green),
                          const SizedBox(height: 8),
                          Text('Completed', style: Theme.of(context).textTheme.titleMedium),
                          Text('15', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
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
                          Icon(Icons.warning, size: 32, color: Colors.orange),
                          const SizedBox(height: 8),
                          Text('Discrepancies', style: Theme.of(context).textTheme.titleMedium),
                          Text('7', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Inventory Count Table
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Inventory Count Sessions', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 16),
                      Expanded(
                        child: SingleChildScrollView(
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Count ID')),
                              DataColumn(label: Text('Date')),
                              DataColumn(label: Text('Warehouse')),
                              DataColumn(label: Text('Status')),
                              DataColumn(label: Text('Items Counted')),
                              DataColumn(label: Text('Discrepancies')),
                              DataColumn(label: Text('Actions')),
                            ],
                            rows: [
                              // Sample data
                              DataRow(cells: [
                                const DataCell(Text('IC001')),
                                const DataCell(Text('15/12/2023')),
                                const DataCell(Text('WH001')),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text('Completed', style: TextStyle(color: Colors.green)),
                                  ),
                                ),
                                const DataCell(Text('125')),
                                const DataCell(Text('3')),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(icon: const Icon(Icons.visibility), onPressed: () {}),
                                      IconButton(icon: const Icon(Icons.edit), onPressed: () {}),
                                    ],
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
