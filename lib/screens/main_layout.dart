import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'products_screen.dart';
import 'warehouses_screen.dart';
import 'stock_in_screen.dart';
import 'stock_out_screen.dart';
import 'transactions_screen.dart';
import 'inventory_count_screen.dart';
import 'reports_screen.dart';
import 'suppliers_screen.dart';
import 'customers_screen.dart';
import 'users_roles_screen.dart';
import 'settings_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;
  bool _isRailExtended = true;

  final List<NavigationItem> _navigationItems = [
    NavigationItem(Icons.dashboard, 'Dashboard', const DashboardScreen()),
    NavigationItem(Icons.inventory, 'Products', const ProductsScreen()),
    NavigationItem(Icons.warehouse, 'Warehouses', const WarehousesScreen()),
    NavigationItem(Icons.input, 'Stock In', const StockInScreen()),
    NavigationItem(Icons.output, 'Stock Out', const StockOutScreen()),
    NavigationItem(Icons.history, 'Transactions', const TransactionsScreen()),
    NavigationItem(Icons.inventory_2, 'Inventory Count', const InventoryCountScreen()),
    NavigationItem(Icons.assessment, 'Reports', const ReportsScreen()),
    NavigationItem(Icons.business, 'Suppliers', const SuppliersScreen()),
    NavigationItem(Icons.people, 'Customers', const CustomersScreen()),
    NavigationItem(Icons.admin_panel_settings, 'Users & Roles', const UsersRolesScreen()),
    NavigationItem(Icons.settings, 'Settings', const SettingsScreen()),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: _isRailExtended,
            destinations: _navigationItems.map((item) {
              return NavigationRailDestination(
                icon: Icon(item.icon),
                label: Text(item.label),
              );
            }).toList(),
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            leading: Column(
              children: [
                const SizedBox(height: 8),
                IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () {
                    setState(() {
                      _isRailExtended = !_isRailExtended;
                    });
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed('/login');
                    },
                  ),
                ),
              ),
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: _navigationItems[_selectedIndex].screen,
          ),
        ],
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final String label;
  final Widget screen;

  NavigationItem(this.icon, this.label, this.screen);
}
