import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;
  bool _notifications = true;
  bool _autoBackup = true;
  double _taxRate = 8.5;
  String _currency = 'USD';
  String _dateFormat = 'DD/MM/YYYY';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Settings Categories
            Expanded(
              flex: 1,
              child: Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Categories',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.palette),
                      title: const Text('Appearance'),
                      selected: true,
                      onTap: () {},
                    ),
                    ListTile(
                      leading: const Icon(Icons.notifications),
                      title: const Text('Notifications'),
                      onTap: () {},
                    ),
                    ListTile(
                      leading: const Icon(Icons.backup),
                      title: const Text('Backup'),
                      onTap: () {},
                    ),
                    ListTile(
                      leading: const Icon(Icons.print),
                      title: const Text('Printing'),
                      onTap: () {},
                    ),
                    ListTile(
                      leading: const Icon(Icons.attach_money),
                      title: const Text('Financial'),
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Settings Content
            Expanded(
              flex: 2,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'General Settings',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 24),
                      // Appearance Settings
                      _buildSettingsSection(
                        'Appearance',
                        [
                          SwitchListTile(
                            title: const Text('Dark Mode'),
                            subtitle: const Text('Enable dark theme'),
                            value: _darkMode,
                            onChanged: (value) {
                              setState(() {
                                _darkMode = value;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Notification Settings
                      _buildSettingsSection(
                        'Notifications',
                        [
                          SwitchListTile(
                            title: const Text('Enable Notifications'),
                            subtitle: const Text('Receive system notifications'),
                            value: _notifications,
                            onChanged: (value) {
                              setState(() {
                                _notifications = value;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Backup Settings
                      _buildSettingsSection(
                        'Backup',
                        [
                          SwitchListTile(
                            title: const Text('Auto Backup'),
                            subtitle: const Text('Automatically backup data daily'),
                            value: _autoBackup,
                            onChanged: (value) {
                              setState(() {
                                _autoBackup = value;
                              });
                            },
                          ),
                          ListTile(
                            title: const Text('Backup Now'),
                            subtitle: const Text('Create a manual backup'),
                            trailing: ElevatedButton(
                              onPressed: () {
                                // Backup logic
                              },
                              child: const Text('Backup'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Financial Settings
                      _buildSettingsSection(
                        'Financial',
                        [
                          ListTile(
                            title: const Text('Tax Rate (%)'),
                            subtitle: Slider(
                              value: _taxRate,
                              min: 0,
                              max: 20,
                              divisions: 40,
                              label: '${_taxRate.toStringAsFixed(1)}%',
                              onChanged: (value) {
                                setState(() {
                                  _taxRate = value;
                                });
                              },
                            ),
                          ),
                          ListTile(
                            title: const Text('Currency'),
                            subtitle: DropdownButton<String>(
                              value: _currency,
                              items: ['USD', 'EUR', 'GBP', 'JPY'].map((currency) {
                                return DropdownMenuItem(
                                  value: currency,
                                  child: Text(currency),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _currency = value!;
                                });
                              },
                            ),
                          ),
                          ListTile(
                            title: const Text('Date Format'),
                            subtitle: DropdownButton<String>(
                              value: _dateFormat,
                              items: ['DD/MM/YYYY', 'MM/DD/YYYY', 'YYYY-MM-DD'].map((format) {
                                return DropdownMenuItem(
                                  value: format,
                                  child: Text(format),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _dateFormat = value!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            // Save settings logic
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Settings saved successfully'),
                              ),
                            );
                          },
                          child: const Text('Save Settings'),
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

  Widget _buildSettingsSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }
}
