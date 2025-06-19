import 'package:flutter/material.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildReportCard(context, 'Stock Levels Report', Icons.inventory, Colors.blue),
            _buildReportCard(context, 'Sales Report', Icons.trending_up, Colors.green),
            _buildReportCard(context, 'Purchase Report', Icons.shopping_cart, Colors.orange),
            _buildReportCard(context, 'Low Stock Alert', Icons.warning, Colors.red),
            _buildReportCard(context, 'Warehouse Summary', Icons.warehouse, Colors.purple),
            _buildReportCard(context, 'Transaction History', Icons.history, Colors.teal),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(BuildContext context, String title, IconData icon, Color color) {
    return Card(
      child: InkWell(
        onTap: () {
          // Navigate to specific report
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {},
                child: const Text('Generate'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
