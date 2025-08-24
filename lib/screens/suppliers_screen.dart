import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../backend/suppliers_logic.dart';
import '../backend/main_layout_logic.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  final SupplierLogic _supplierLogic = SupplierLogic();
  final MainLayoutLogic _layoutLogic = MainLayoutLogic();
  final TextEditingController _searchController = TextEditingController();
  
  List<Supplier> _suppliers = [];
  List<Supplier> _filteredSuppliers = [];
  List<String> _specializations = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _userRole;
  String? _selectedSpecialization;

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSuppliers() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      // جلب دور المستخدم
      _userRole = await _layoutLogic.getCurrentUserRole();
      
      final suppliers = await _supplierLogic.getSuppliers();
      
      // استخراج قائمة التخصصات المميزة
      final specializationsSet = suppliers
          .map((s) => s.specialization)
          .where((s) => s.isNotEmpty)
          .toSet();
      
      setState(() {
        _suppliers = suppliers;
        _filteredSuppliers = suppliers;
        _specializations = specializationsSet.toList()..sort();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterSuppliers() {
    final searchQuery = _searchController.text.toLowerCase().trim();
    
    setState(() {
      _filteredSuppliers = _suppliers.where((supplier) {
        final matchesSearch = searchQuery.isEmpty ||
            supplier.name.toLowerCase().contains(searchQuery) ||
            supplier.taxNumber.toLowerCase().contains(searchQuery);
        
        final matchesSpecialization = _selectedSpecialization == null ||
            supplier.specialization == _selectedSpecialization;
        
        return matchesSearch && matchesSpecialization;
      }).toList();
    });
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedSpecialization = null;
      _filteredSuppliers = _suppliers;
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final isRTL = Localizations.localeOf(context).languageCode == 'ar';
    
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
      backgroundColor: Theme.of(context).brightness == Brightness.dark 
          ? const Color(0xFF121212) 
          : Colors.grey[50],
      appBar: AppBar(
        title: Text(localizations?.suppliers ?? 'Suppliers'),
        automaticallyImplyLeading: false,
        actions: [
          // Hide Add Supplier button for warehouse_manager and project_manager
            if (_userRole != null && _userRole != 'warehouse_manager' && _userRole != 'project_manager')
            ElevatedButton.icon(
              onPressed: () => _showSupplierDialog(),
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(localizations?.add ?? 'Add Supplier'),
              style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              ),
            ),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Search and Filter Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? const Color(0xFF1E1E1E) 
                    : Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Search Field
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: isRTL ? 'البحث بالاسم أو الرقم الضريبي...' : 'Search by name or tax number...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Theme.of(context).brightness == Brightness.dark 
                            ? const Color(0xFF2C2C2C) 
                            : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onChanged: (value) => _filterSuppliers(),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Specialization Filter
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String?>(
                      value: _selectedSpecialization,
                      decoration: InputDecoration(
                        labelText: isRTL ? 'التخصص' : 'Specialization',
                        filled: true,
                        fillColor: Theme.of(context).brightness == Brightness.dark 
                            ? const Color(0xFF2C2C2C) 
                            : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text(isRTL ? 'الكل' : 'All'),
                        ),
                        ..._specializations.map(
                          (specialization) => DropdownMenuItem<String?>(
                            value: specialization,
                            child: Text(specialization),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedSpecialization = value;
                        });
                        _filterSuppliers();
                      },
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Clear Filters Button
                  if (_searchController.text.isNotEmpty || _selectedSpecialization != null)
                    IconButton(
                      onPressed: _clearFilters,
                      icon: const Icon(Icons.clear),
                      tooltip: isRTL ? 'مسح الفلاتر' : 'Clear Filters',
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Data Table
            Expanded(
              child: Card(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? const Color(0xFF1E1E1E) 
                    : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: Theme.of(context).brightness == Brightness.dark ? 4 : 2,
                child: _filteredSuppliers.isEmpty 
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          _suppliers.isEmpty 
                            ? (isRTL ? 'لا توجد موردين\nاضغط "إضافة مورد" للبدء' : 'No suppliers found\nClick "Add Supplier" to get started')
                            : (isRTL ? 'لا توجد نتائج مطابقة للبحث' : 'No results match your search'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                  child: DataTable(
                    columns: [
                      DataColumn(label: Text(localizations?.name ?? (isRTL ? 'الاسم' : 'Name'))),
                      DataColumn(label: Text(localizations?.taxNumber ?? (isRTL ? 'الرقم الضريبي' : 'Tax Number'))),
                      DataColumn(label: Text(isRTL ? 'التخصص' : 'Specialization')),
                      DataColumn(label: Text(localizations?.address ?? (isRTL ? 'العنوان' : 'Address'))),
                      // Hide Actions column for warehouse_manager and project_manager
                      if (_userRole != 'warehouse_manager' && _userRole != 'project_manager')
                        DataColumn(label: Text(localizations?.actions ?? (isRTL ? 'الإجراءات' : 'Actions'))),
                    ],
                    rows: _filteredSuppliers.map((supplier) {
                      final cells = [
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
                      ];
                      
                      // Add Actions cell only if not warehouse_manager or project_manager
                      if (_userRole != 'warehouse_manager' && _userRole != 'project_manager') {
                        cells.add(
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.orange),
                                  onPressed: () => _showSupplierDialog(supplier: supplier),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteSupplier(supplier),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      
                      return DataRow(cells: cells);
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSupplierDialog({Supplier? supplier}) {
    final localizations = AppLocalizations.of(context);
    final isRTL = Localizations.localeOf(context).languageCode == 'ar';
    final isEditing = supplier != null;
    final nameController = TextEditingController(text: supplier?.name ?? '');
    final taxNumberController = TextEditingController(text: supplier?.taxNumber ?? '');
    final specializationController = TextEditingController(text: supplier?.specialization ?? '');
    final addressController = TextEditingController(text: supplier?.address ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing 
            ? (localizations?.edit ?? (isRTL ? 'تعديل مورد' : 'Edit Supplier'))
            : (localizations?.add ?? (isRTL ? 'إضافة مورد' : 'Add Supplier'))),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: localizations?.name ?? (isRTL ? 'اسم المورد' : 'Supplier Name'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: taxNumberController,
                  decoration: InputDecoration(
                    labelText: localizations?.taxNumber ?? (isRTL ? 'الرقم الضريبي' : 'Tax Number'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: specializationController,
                  decoration: InputDecoration(
                    labelText: isRTL ? 'التخصص' : 'Specialization',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: addressController,
                  decoration: InputDecoration(
                    labelText: localizations?.address ?? (isRTL ? 'العنوان' : 'Address'),
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
                  SnackBar(
                    content: Text(isRTL ? 'الرقم الضريبي موجود بالفعل' : 'Tax number already exists'),
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
                  await _loadSuppliers(); // إعادة تحميل البيانات
                  _filterSuppliers(); // إعادة تطبيق الفلاتر
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
                  SnackBar(
                    content: Text(isRTL ? 'يرجى ملء جميع الحقول' : 'Please fill all fields'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text(isEditing 
                ? (localizations?.edit ?? (isRTL ? 'تحديث' : 'Update')) 
                : (localizations?.add ?? (isRTL ? 'إضافة' : 'Add'))),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSupplier(Supplier supplier) async {
    final localizations = AppLocalizations.of(context);
    final isRTL = Localizations.localeOf(context).languageCode == 'ar';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations?.delete ?? (isRTL ? 'حذف مورد' : 'Delete Supplier')),
        content: Text('${localizations?.deleteConfirmation ?? (isRTL ? "هل أنت متأكد من حذف" : "Are you sure you want to delete")} ${supplier.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations?.cancel ?? (isRTL ? 'إلغاء' : 'Cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _supplierLogic.deleteSupplier(supplier.id!);
                Navigator.pop(context);
                await _loadSuppliers(); // إعادة تحميل البيانات
                _filterSuppliers(); // إعادة تطبيق الفلاتر
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
            child: Text(localizations?.delete ?? (isRTL ? 'حذف' : 'Delete')),
          ),
        ],
      ),
    );
  }
}
