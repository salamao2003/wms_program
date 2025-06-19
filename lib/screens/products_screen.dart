import 'package:flutter/material.dart';
import 'package:warehouse_management_system/backend/supabase_service.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Electronics', 'Clothing', 'Food', 'Books'];
  final SupabaseService _supabase = SupabaseService();
  

  List<Product> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    try {
      final response = await _supabase.client
          .from('products')
          .select('*')
          .order('id', ascending: true);

      setState(() {
        _products = (response as List).map((item) => Product(
          item['id']?.toString() ?? '',
          item['name'] ?? '',
          item['category'] ?? '',
          item['quantity'] ?? 0,
          item['unit'] ?? '',
          (item['price'] ?? 0.0).toDouble(),
          item['supplier'] ?? '',
        )).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch products: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        automaticallyImplyLeading: false,
        actions: [
          ElevatedButton.icon(
            onPressed: () => _showProductDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Add Product'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Search and Filter Row
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search products...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => _filterProducts(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: _categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value!;
                        _filterProducts();
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Products Table
            Expanded(
              child: Card(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('ID')),
                            DataColumn(label: Text('Name')),
                            DataColumn(label: Text('Category')),
                            DataColumn(label: Text('Quantity')),
                            DataColumn(label: Text('Unit')),
                            DataColumn(label: Text('Price')),
                            DataColumn(label: Text('Supplier')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: _products.map((product) {
                            return DataRow(
                              cells: [
                                DataCell(Text(product.id)),
                                DataCell(Text(product.name)),
                                DataCell(Text(product.category)),
                                DataCell(Text(product.quantity.toString())),
                                DataCell(Text(product.unit)),
                                DataCell(Text('\$${product.price.toStringAsFixed(2)}')),
                                DataCell(Text(product.supplier)),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () => _showProductDialog(product: product),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () => _deleteProduct(product),
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
          ],
        ),
      ),
    );
  }

  void _filterProducts() {
    // سيتم تنفيذها لاحقًا
  }

  Future<bool> _isProductIdUnique(String id) async {
    final response = await _supabase.client
        .from('products')
        .select()
        .eq('id', id);
    return (response as List).isEmpty;
  }

  Future<void> _showProductDialog({Product? product}) async {
    final isEditing = product != null;
    final idController = TextEditingController(
      text: product?.id ??  ''
    );
    final nameController = TextEditingController(text: product?.name ?? '');
    final quantityController = TextEditingController(text: product?.quantity.toString() ?? '');
    final unitController = TextEditingController(text: product?.unit ?? '');
    final priceController = TextEditingController(text: product?.price.toString() ?? '');
    final supplierController = TextEditingController(text: product?.supplier ?? '');
    String selectedCategory = product?.category ?? _categories[1];
    bool isIdValid = true;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(isEditing ? 'Edit Product' : 'Add Product'),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: idController,
                      enabled: !isEditing,
                      decoration: InputDecoration(
                        labelText: 'Product ID',
                        border: const OutlineInputBorder(),
                        errorText: isIdValid ? null : 'ID already exists',
                      ),
                      onChanged: (value) async {
                        if (!isEditing && value.isNotEmpty) {
                          final isUnique = await _isProductIdUnique(value);
                          setState(() => isIdValid = isUnique);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Product Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: _categories.skip(1).map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        selectedCategory = value!;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: quantityController,
                            decoration: const InputDecoration(
                              labelText: 'Quantity',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: unitController,
                            decoration: const InputDecoration(
                              labelText: 'Unit',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: priceController,
                      decoration: const InputDecoration(
                        labelText: 'Price',
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
                onPressed: () async {
                  if (!isEditing && !isIdValid) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a unique Product ID')),
                    );
                    return;
                  }

                  if (nameController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter Product Name')),
                    );
                    return;
                  }

                  try {
                    final newProduct = {
                      if (!isEditing) 'id': idController.text,
                      'name': nameController.text,
                      'category': selectedCategory,
                      'quantity': int.tryParse(quantityController.text) ?? 0,
                      'unit': unitController.text,
                      'price': double.tryParse(priceController.text) ?? 0.0,
                      'supplier': supplierController.text,
                    };

                    if (isEditing) {
                      await _supabase.client
                          .from('products')
                          .update(newProduct)
                          .eq('id', product!.id);
                    } else {
                      await _supabase.client
                          .from('products')
                          .insert(newProduct);
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(isEditing ? 'Product updated!' : 'Product added!')),
                    );

                    _fetchProducts();
                    Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                },
                child: Text(isEditing ? 'Update' : 'Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteProduct(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete ${product.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _supabase.client
            .from('products')
            .delete()
            .eq('id', product.id);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product deleted!')),
        );

        _fetchProducts();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: ${e.toString()}')),
        );
      }
    }
  }
}

class Product {
  final String id;
  final String name;
  final String category;
  final int quantity;
  final String unit;
  final double price;
  final String supplier;

  Product(this.id, this.name, this.category, this.quantity, this.unit, this.price, this.supplier);
}