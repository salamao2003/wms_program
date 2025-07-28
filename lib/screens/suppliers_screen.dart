import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../backend/suppliers_logic.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  final SupplierLogic _supplierLogic = SupplierLogic();
  List<Supplier> _suppliers = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  Future<void> _loadSuppliers() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      final suppliers = await _supplierLogic.getSuppliers();
      setState(() {
        _suppliers = suppliers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(localizations?.suppliers ?? 'Suppliers'),
          automaticallyImplyLeading: false,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(localizations?.suppliers ?? 'Suppliers'),
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $_errorMessage'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadSuppliers,
                child: Text(localizations?.retry ?? 'Retry'),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations?.suppliers ?? 'Suppliers'),
        automaticallyImplyLeading: false,
        actions: [
          ElevatedButton.icon(
            onPressed: () => _showSupplierDialog(),
            icon: const Icon(Icons.add),
            label: Text(localizations?.add ?? 'Add Supplier'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: _suppliers.isEmpty 
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'No suppliers found\nClick "Add Supplier" to get started',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              )
            : SingleChildScrollView(
            child: DataTable(
              columns: [
                DataColumn(label: Text(localizations?.name ?? 'Name')),
                DataColumn(label: Text(localizations?.taxNumber ?? 'Tax Number')),
                DataColumn(label: Text('Specialization')),
                DataColumn(label: Text(localizations?.address ?? 'Address')),
                DataColumn(label: Text(localizations?.actions ?? 'Actions')),
              ],
              rows: _suppliers.map((supplier) {
                return DataRow(
                  cells: [
                    DataCell(Text(supplier.name)),
                    DataCell(Text(supplier.taxNumber)),
                    DataCell(Text(supplier.specialization)),
                    DataCell(
                      SizedBox(
                        width: 200,
                        child: Text(
                          supplier.address,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showSupplierDialog(supplier: supplier),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteSupplier(supplier),
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
      ),
    );
  }

  void _showSupplierDialog({Supplier? supplier}) {
    final localizations = AppLocalizations.of(context);
    final isEditing = supplier != null;
    final nameController = TextEditingController(text: supplier?.name ?? '');
    final taxNumberController = TextEditingController(text: supplier?.taxNumber ?? '');
    final specializationController = TextEditingController(text: supplier?.specialization ?? '');
    final addressController = TextEditingController(text: supplier?.address ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? (localizations?.edit ?? 'Edit Supplier') : (localizations?.add ?? 'Add Supplier')),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: localizations?.name ?? 'Supplier Name',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: taxNumberController,
                  decoration: InputDecoration(
                    labelText: localizations?.taxNumber ?? 'Tax Number',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: specializationController,
                  decoration: const InputDecoration(
                    labelText: 'Specialization',
                    border: OutlineInputBorder(),
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
              if (nameController.text.isNotEmpty && 
                  taxNumberController.text.isNotEmpty &&
                  specializationController.text.isNotEmpty &&
                  addressController.text.isNotEmpty) {
                
                try {
                  // التحقق من وجود الرقم الضريبي
                  final taxExists = await _supplierLogic.isTaxNumberExists(
                    taxNumberController.text,
                    excludeId: supplier?.id,
                  );
                  
                  if (taxExists) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tax number already exists'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  final newSupplier = Supplier(
                    name: nameController.text,
                    taxNumber: taxNumberController.text,
                    specialization: specializationController.text,
                    address: addressController.text,
                  );

                  if (isEditing) {
                    await _supplierLogic.updateSupplier(supplier.id!, newSupplier);
                  } else {
                    await _supplierLogic.addSupplier(newSupplier);
                  }
                  
                  Navigator.pop(context);
                  _loadSuppliers(); // إعادة تحميل البيانات
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill all fields'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text(isEditing ? (localizations?.edit ?? 'Update') : (localizations?.add ?? 'Add')),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSupplier(Supplier supplier) async {
    final localizations = AppLocalizations.of(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations?.delete ?? 'Delete Supplier'),
        content: Text('${localizations?.deleteConfirmation ?? "Are you sure you want to delete"} ${supplier.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations?.cancel ?? 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _supplierLogic.deleteSupplier(supplier.id!);
                Navigator.pop(context);
                _loadSuppliers(); // إعادة تحميل البيانات
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(localizations?.delete ?? 'Delete'),
          ),
        ],
      ),
    );
  }
}
