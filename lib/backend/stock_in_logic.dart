import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'supabase_service.dart';
import 'warehouse_logic.dart';

// Stock In Models
class StockInItem {
  final String productId;
  final String productName;
  final double quantity;
  final String unit;

  StockInItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unit,
  });

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'unit': unit,
    };
  }

  factory StockInItem.fromJson(Map<String, dynamic> json) {
    return StockInItem(
      productId: json['product_id'] ?? '',
      productName: json['product_name'] ?? '',
      quantity: (json['quantity'] ?? 0).toDouble(),
      unit: json['unit'] ?? '',
    );
  }
}

class StockIn {
  final int? id;
  final String recordId;
  final String additionNumber;
  final String warehouseId;
  final String warehouseName;
  final String supplierId;
  final String supplierName;
  final DateTime date;
  final String? notes;
  final String? invoiceFilePath;
  final List<StockInItem> products;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  StockIn({
    this.id,
    required this.recordId,
    required this.additionNumber,
    required this.warehouseId,
    required this.warehouseName,
    required this.supplierId,
    required this.supplierName,
    required this.date,
    this.notes,
    this.invoiceFilePath,
    required this.products,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'record_id': recordId,
      'addition_number': additionNumber,
      'warehouse_id': warehouseId,
      'warehouse_name': warehouseName,
      'supplier_id': supplierId,
      'supplier_name': supplierName,
      'date': date.toIso8601String(),
      'notes': notes,
      'invoice_file_path': invoiceFilePath,
      'products': products.map((item) => item.toJson()).toList(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory StockIn.fromJson(Map<String, dynamic> json) {
    List<StockInItem> productsList = [];
    
    // Handle different formats of products data
    if (json['products'] != null) {
      if (json['products'] is String) {
        // If products is a JSON string, parse it
        try {
          final productsData = jsonDecode(json['products']);
          if (productsData is List) {
            productsList = productsData
                .map((item) => StockInItem.fromJson(item as Map<String, dynamic>))
                .toList();
          }
        } catch (e) {
          print('Error parsing products JSON: $e');
        }
      } else if (json['products'] is List) {
        productsList = (json['products'] as List)
            .map((item) => StockInItem.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    }

    return StockIn(
      id: json['id'] is String ? int.tryParse(json['id']) : json['id'],
      recordId: json['record_id']?.toString() ?? '',
      additionNumber: json['addition_number']?.toString() ?? '',
      warehouseId: json['warehouse_id']?.toString() ?? '',
      warehouseName: json['warehouse_name']?.toString() ?? '',
      supplierId: json['supplier_id']?.toString() ?? '',
      supplierName: json['supplier_name']?.toString() ?? '',
      date: json['date'] != null 
          ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      notes: json['notes']?.toString(),
      invoiceFilePath: json['invoice_file_path']?.toString(),
      products: productsList,
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'].toString()) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.tryParse(json['updated_at'].toString()) 
          : null,
    );
  }
}

class StockInRequest {
  final String warehouseId;
  final String supplierId;
  final DateTime date;
  final String? notes;
  final String? invoiceFilePath;
  final List<StockInItem> products;

  StockInRequest({
    required this.warehouseId,
    required this.supplierId,
    required this.date,
    this.notes,
    this.invoiceFilePath,
    required this.products,
  });

  Map<String, dynamic> toJson() {
    return {
      'warehouse_id': warehouseId,
      'supplier_id': supplierId,
      'date': date.toIso8601String().split('T')[0], // Date only
      'notes': notes,
      'invoice_file_path': invoiceFilePath,
      'products': products.map((item) => item.toJson()).toList(),
    };
  }
}

class ProductSearchResult {
  final String id;
  final String name;
  final String supplier;
  final int? categoryId;
  final String? unit;  // ✅ أضف هذا كـ field عادي

  ProductSearchResult({
    required this.id,
    required this.name,
    required this.supplier,
    this.categoryId,
    this.unit,  // ✅ أضف هذا
  });

  factory ProductSearchResult.fromJson(Map<String, dynamic> json) {
    return ProductSearchResult(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      supplier: json['supplier'] ?? '',
      categoryId: json['category_id'],
      unit: json['unit'],  // ✅ أضف هذا
    );
  }
  // ✅ احذف السطر get unit => null;
}
class SupplierSearchResult {
  final String id;
  final String name;
  final String? taxNumber;

  SupplierSearchResult({
    required this.id,
    required this.name,
    this.taxNumber,
  });

  factory SupplierSearchResult.fromJson(Map<String, dynamic> json) {
    return SupplierSearchResult(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      taxNumber: json['tax_number'],
    );
  }
}

class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final String? message;

  ApiResponse({
    required this.success,
    this.data,
    this.error,
    this.message,
  });

  factory ApiResponse.success(T data, {String? message}) {
    return ApiResponse(
      success: true,
      data: data,
      message: message,
    );
  }

  factory ApiResponse.error(String error) {
    return ApiResponse(
      success: false,
      error: error,
    );
  }
}

// Stock In Service
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'supabase_service.dart';

class StockInService {
  static final StockInService _instance = StockInService._internal();
  factory StockInService() => _instance;
  StockInService._internal();

  final SupabaseClient _client = SupabaseService().client;

  // Create Stock In Record
 Future<ApiResponse<Map<String, dynamic>>> createStockInRecord(
  StockInRequest request,
) async {
  try {
    final user = _client.auth.currentUser;
    if (user == null) {
      return ApiResponse.error('المستخدم غير مصرح له');
    }

    // الحصول على رقم إضافة
    final additionNumberResponse = await _client
        .rpc('generate_addition_number', params: {
          'p_warehouse_id': request.warehouseId,
        });
    
    if (additionNumberResponse == null) {
      return ApiResponse.error('فشل في توليد رقم الإضافة');
    }
    
    final additionNumber = additionNumberResponse.toString();
    
    List<Map<String, dynamic>> createdRecords = [];

    // إنشاء سجل منفصل لكل منتج
    for (var product in request.products) {
      try {
        // الحصول على رقم سجل فريد
        final recordIdResponse = await _client.rpc('generate_record_id');
        
        if (recordIdResponse == null) {
          print('Failed to generate record ID for product: ${product.productId}');
          continue;
        }
        
        final recordId = recordIdResponse.toString();

        // إدخال السجل في جدول stock_in
        final stockInData = await _client
            .from('stock_in')
            .insert({
              'record_id': recordId,
              'addition_number': additionNumber,
              'warehouse_id': request.warehouseId,
              'supplier_id': request.supplierId,
              'date': request.date.toIso8601String().split('T')[0],
              'notes': request.notes,
              'invoice_file_path': request.invoiceFilePath,
              'created_by': user.id,
            })
            .select()
            .single();

        print('Created stock_in record: ${stockInData['id']}');

        // إدخال تفاصيل المنتج
        await _client.from('stock_in_items').insert({
          'stock_in_id': stockInData['id'],
          'product_id': product.productId,
          'quantity': product.quantity,
          'unit': product.unit,
        });

        print('Created stock_in_item for product: ${product.productId}');

        // تم الاعتماد على trigger في قاعدة البيانات لتحديث warehouse_stock
        // لذلك نلغي التحديث اليدوي لتجنب الازدواجية
        // await _updateWarehouseStock(
        //   warehouseId: request.warehouseId,
        //   productId: product.productId,
        //   quantity: product.quantity,
        //   unit: product.unit,
        //   isAddition: true,
        // );
        
        print('Warehouse stock will be updated by DB trigger');

        createdRecords.add(stockInData);
      } catch (productError) {
        print('Error processing product ${product.productId}: $productError');
        continue;
      }
    }

    if (createdRecords.isEmpty) {
      return ApiResponse.error('فشل في إنشاء أي سجلات');
    }

    print('Successfully created ${createdRecords.length} records');
    
    return ApiResponse.success({
      'success': true,
      'message': 'تم إنشاء ${createdRecords.length} سجل بنجاح',
      'data': createdRecords,
      'addition_number': additionNumber,
    });
  } catch (e) {
    print('Error in createStockInRecord: $e');
    return ApiResponse.error('خطأ: ${e.toString()}');
  }
}

// دالة مساعدة لتحديث مخزون المخزن
// تُركت هنا للتوافق الخلفي، ولكن لم تعد تُستخدم لأن التحديث يتم عبر التريجر
// Get Stock In Records with filters
  // Get Stock In Records with filters
Future<ApiResponse<List<StockIn>>> getStockInRecords({
  String? searchTerm,
  String? supplierId,
  DateTime? startDate,
  DateTime? endDate,
  int limit = 50,
  int offset = 0,
}) async {
  try {
    // Build the query - تعديل الاستعلام
    var query = _client
        .from('stock_in')
        .select('''
          id,
          record_id,
          addition_number,
          warehouse_id,
          supplier_id,
          date,
          notes,
          invoice_file_path,
          created_at,
          updated_at,
          warehouses:warehouse_id(id, name),
          suppliers:supplier_id(id, name)
        ''');

    // Apply filters
    if (searchTerm != null && searchTerm.isNotEmpty) {
      query = query.or('record_id.ilike.%$searchTerm%,addition_number.ilike.%$searchTerm%');
    }

    if (supplierId != null && supplierId.isNotEmpty) {
      query = query.eq('supplier_id', supplierId);
    }

    if (startDate != null) {
      query = query.gte('date', startDate.toIso8601String().split('T')[0]);
    }

    if (endDate != null) {
      query = query.lte('date', endDate.toIso8601String().split('T')[0]);
    }

    // Execute query
    final response = await query
        .limit(limit)
        .range(offset, offset + limit - 1)
        .order('created_at', ascending: false);

    print('Stock In Records Response: $response'); // للتشخيص

    // Get stock_in_items for each record
    List<StockIn> stockInList = [];
    for (var record in response) {
      try {
        // Get items for this stock_in record with product names
        final itemsResponse = await _client
            .from('stock_in_items')
            .select('''
              product_id,
              quantity,
              unit,
              products:product_id(id, name)
            ''')
            .eq('stock_in_id', record['id']);

        print('Items Response for record ${record['id']}: $itemsResponse'); // للتشخيص

        final products = itemsResponse.map((item) => StockInItem(
          productId: item['product_id'] ?? '',
          productName: item['products']?['name'] ?? 'Unknown Product',
          quantity: (item['quantity'] ?? 0).toDouble(),
          unit: item['unit'] ?? 'piece',
        )).toList();

        // Create StockIn object - معالجة آمنة للبيانات
        final stockIn = StockIn(
          id: record['id'],
          recordId: record['record_id']?.toString() ?? '',
          additionNumber: record['addition_number']?.toString() ?? '',
          warehouseId: record['warehouse_id']?.toString() ?? '',
          warehouseName: record['warehouses']?['name']?.toString() ?? 'Unknown Warehouse',
          supplierId: record['supplier_id']?.toString() ?? '',
          supplierName: record['suppliers']?['name']?.toString() ?? 'Unknown Supplier',
          date: record['date'] != null 
              ? DateTime.parse(record['date'].toString())
              : DateTime.now(),
          notes: record['notes']?.toString(),
          invoiceFilePath: record['invoice_file_path']?.toString(),
          products: products,
          createdAt: record['created_at'] != null 
              ? DateTime.parse(record['created_at'].toString()) 
              : null,
          updatedAt: record['updated_at'] != null 
              ? DateTime.parse(record['updated_at'].toString()) 
              : null,
        );

        stockInList.add(stockIn);
      } catch (e) {
        print('Error processing record ${record['id']}: $e');
        // نكمل معالجة باقي السجلات حتى لو فشل واحد
        continue;
      }
    }

    return ApiResponse.success(stockInList);
  } catch (e) {
    print('Error in getStockInRecords: $e');
    return ApiResponse.error('خطأ في تحميل البيانات: ${e.toString()}');
  }
}
  // Update Stock In Record
  Future<ApiResponse<Map<String, dynamic>>> updateStockInRecord(
    int stockInId,
    StockInRequest request,
  ) async {
    try {
      // Fetch the existing record to know the previous warehouse and items
      final existing = await _client
          .from('stock_in')
          .select('id, warehouse_id')
          .eq('id', stockInId)
          .maybeSingle();

      if (existing == null) {
        return ApiResponse.error('السجل غير موجود');
      }

      final String oldWarehouseId = existing['warehouse_id']?.toString() ?? '';

      // Load old items and subtract their quantities from old warehouse stock
      final oldItems = await _client
          .from('stock_in_items')
          .select('product_id, quantity')
          .eq('stock_in_id', stockInId);

      for (final item in oldItems) {
        final String productId = item['product_id']?.toString() ?? '';
        final double qty = (item['quantity'] ?? 0).toDouble();
        try {
          final stockRows = await _client
              .from('warehouse_stock')
              .select('id, current_quantity')
              .eq('warehouse_id', oldWarehouseId)
              .eq('product_id', productId)
              .limit(1);

          if (stockRows.isNotEmpty) {
            final stockRow = stockRows.first;
            final String stockId = stockRow['id'].toString();
            final double currentQty = (stockRow['current_quantity'] ?? 0).toDouble();
            final double newQty = currentQty - qty;
            if (newQty > 0) {
              await _client
                  .from('warehouse_stock')
                  .update({'current_quantity': newQty})
                  .eq('id', stockId);
            } else {
              await _client
                  .from('warehouse_stock')
                  .delete()
                  .eq('id', stockId);
            }
          }
        } catch (e) {
          print('Error subtracting old item from warehouse_stock: $e');
        }
      }

      // Update stock_in table
      final stockInData = await _client
          .from('stock_in')
          .update({
            'warehouse_id': request.warehouseId,
            'supplier_id': request.supplierId,
            'date': request.date.toIso8601String().split('T')[0],
            'notes': request.notes,
            'invoice_file_path': request.invoiceFilePath,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', stockInId)
          .select()
          .single();

      // Delete existing items
      await _client
          .from('stock_in_items')
          .delete()
          .eq('stock_in_id', stockInId);

      // Insert new items
      if (request.products.isNotEmpty) {
        final itemsData = request.products.map((product) => {
          'stock_in_id': stockInId,
          'product_id': product.productId,
          'quantity': product.quantity,
          'unit': product.unit,
        }).toList();

        await _client.from('stock_in_items').insert(itemsData);
  // Rely on DB INSERT trigger to add to warehouse_stock
      }

      return ApiResponse.success({
        'success': true,
        'message': 'تم تحديث السجل بنجاح',
        'data': stockInData,
      });
    } catch (e) {
      return ApiResponse.error('خطأ: ${e.toString()}');
    }
  }

  // Delete Stock In Record
  Future<ApiResponse<Map<String, dynamic>>> deleteStockInRecord(
    int stockInId,
  ) async {
    try {
      // 1) Read the stock_in record to get the warehouse_id
      final stockInRecord = await _client
          .from('stock_in')
          .select('id, warehouse_id')
          .eq('id', stockInId)
          .maybeSingle();

      if (stockInRecord == null) {
        return ApiResponse.error('السجل غير موجود');
      }

      final String warehouseId = stockInRecord['warehouse_id']?.toString() ?? '';

      // 2) Read all items for this stock_in
      final items = await _client
          .from('stock_in_items')
          .select('product_id, quantity, unit')
          .eq('stock_in_id', stockInId);

      // 3) For each item, decrease warehouse_stock and delete the row if it becomes 0
      for (final item in items) {
        final String productId = item['product_id']?.toString() ?? '';
        final double qty = (item['quantity'] ?? 0).toDouble();

        try {
          final stockRows = await _client
              .from('warehouse_stock')
              .select('id, current_quantity')
              .eq('warehouse_id', warehouseId)
              .eq('product_id', productId)
              .limit(1);

          if (stockRows.isNotEmpty) {
            final stockRow = stockRows.first;
            final String stockId = stockRow['id'].toString();
            final double currentQty = (stockRow['current_quantity'] ?? 0).toDouble();
            final double newQty = currentQty - qty;

            if (newQty > 0) {
              await _client
                  .from('warehouse_stock')
                  .update({'current_quantity': newQty})
                  .eq('id', stockId);
            } else {
              // Delete the row when quantity goes to zero or negative
              await _client
                  .from('warehouse_stock')
                  .delete()
                  .eq('id', stockId);
            }
          }
        } catch (adjErr) {
          // Continue processing other items even if one fails
          print('Error adjusting warehouse_stock for product $productId: $adjErr');
        }
      }

      // 4) Delete items (foreign key constraint) and the main record
      // Delete items first (foreign key constraint)
      await _client
          .from('stock_in_items')
          .delete()
          .eq('stock_in_id', stockInId);

      // Delete the main record
      await _client
          .from('stock_in')
          .delete()
          .eq('id', stockInId);

      // 5) Ask warehouse logic to refresh any cached data (for UI)
      try {
        await WarehouseLogic().refreshWarehouseData();
      } catch (_) {}

      return ApiResponse.success({
        'success': true,
        'message': 'تم حذف السجل بنجاح',
      });
    } catch (e) {
      return ApiResponse.error('خطأ: ${e.toString()}');
    }
  }

  // Search Products
  Future<ApiResponse<List<ProductSearchResult>>> searchProducts(
    String searchTerm,
  ) async {
    try {
      // البحث مباشرة في جدول المنتجات
      final response = await _client
          .from('products')
           .select('id, name, supplier, category_id, unit')  // ✅ أضف unit
          .or('id.ilike.%$searchTerm%,name.ilike.%$searchTerm%,supplier.ilike.%$searchTerm%')
          .limit(10)
          .order('name');

      final productsList = response
          .map((item) => ProductSearchResult.fromJson(item))
          .toList();
      
      return ApiResponse.success(productsList);
    } catch (e) {
      print('Error in searchProducts: $e');
      return ApiResponse.success(<ProductSearchResult>[]);
    }
  }

  // Search Suppliers
  Future<ApiResponse<List<SupplierSearchResult>>> searchSuppliers(
    String searchTerm,
  ) async {
    try {
      // البحث مباشرة في جدول الموردين
      final response = await _client
          .from('suppliers')
          .select('id, name, tax_number')
          .or('name.ilike.%$searchTerm%,tax_number.ilike.%$searchTerm%')
          .limit(10)
          .order('name');

      final suppliersList = response
          .map((item) => SupplierSearchResult.fromJson(item))
          .toList();
      
      return ApiResponse.success(suppliersList);
    } catch (e) {
      print('Error in searchSuppliers: $e');
      return ApiResponse.success(<SupplierSearchResult>[]);
    }
  }

  // Get Warehouses for dropdown
  Future<ApiResponse<List<Map<String, dynamic>>>> getWarehouses() async {
    try {
      final response = await _client
          .from('warehouses')
          .select('id, name, code')
          .order('name');

      return ApiResponse.success(response);
    } catch (e) {
      return ApiResponse.error('خطأ: ${e.toString()}');
    }
  }

  // Upload Invoice File
  Future<ApiResponse<String>> uploadInvoiceFile(
  String fileName,
  Uint8List fileBytes,
) async {
  try {
    final user = _client.auth.currentUser;
    if (user == null) {
      return ApiResponse.error('المستخدم غير مصرح له');
    }

    // إنشاء مسار فريد للملف
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = '${user.id}/${timestamp}_$fileName';
    
    // رفع الملف إلى Supabase Storage
    await _client.storage
        .from('invoices')
        .uploadBinary(
          filePath,
          fileBytes,
          fileOptions: const FileOptions(
            contentType: 'application/pdf',
            upsert: true,
          ),
        );

    // الحصول على الرابط العام للملف
    final publicUrl = _client.storage
        .from('invoices')
        .getPublicUrl(filePath);

    return ApiResponse.success(publicUrl);
  } catch (e) {
    print('Error uploading invoice: $e');
    return ApiResponse.error('خطأ في رفع الفاتورة: ${e.toString()}');
  }
}
  // Download Invoice File
  Future<ApiResponse<Uint8List>> downloadInvoiceFile(String filePath) async {
  try {
    // استخراج المسار من الرابط الكامل إذا لزم
    String cleanPath = filePath;
    if (filePath.contains('/storage/v1/object/public/invoices/')) {
      cleanPath = filePath.split('/storage/v1/object/public/invoices/').last;
    }

    final response = await _client.storage
        .from('invoices')
        .download(cleanPath);

    return ApiResponse.success(response);
  } catch (e) {
    print('Error downloading invoice: $e');
    return ApiResponse.error('خطأ في تحميل الفاتورة: ${e.toString()}');
  }
}

// Delete Invoice File from Supabase Storage
Future<ApiResponse<bool>> deleteInvoiceFile(String filePath) async {
  try {
    String cleanPath = filePath;
    if (filePath.contains('/storage/v1/object/public/invoices/')) {
      cleanPath = filePath.split('/storage/v1/object/public/invoices/').last;
    }

    await _client.storage
        .from('invoices')
        .remove([cleanPath]);

    return ApiResponse.success(true);
  } catch (e) {
    print('Error deleting invoice: $e');
    return ApiResponse.error('خطأ في حذف الفاتورة: ${e.toString()}');
  }
}
}

// Stock In Controller for State Management
class StockInController {
  static final StockInController _instance = StockInController._internal();
  factory StockInController() => _instance;
  StockInController._internal();

  final StockInService _service = StockInService();
  
  // State variables
  List<StockIn> _stockInRecords = [];
  List<ProductSearchResult> _searchedProducts = [];
  List<SupplierSearchResult> _searchedSuppliers = [];
  List<Map<String, dynamic>> _warehouses = [];
  
  bool _isLoading = false;
  String? _error;

  // Getters
  List<StockIn> get stockInRecords => _stockInRecords;
  List<ProductSearchResult> get searchedProducts => _searchedProducts;
  List<SupplierSearchResult> get searchedSuppliers => _searchedSuppliers;
  List<Map<String, dynamic>> get warehouses => _warehouses;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load Stock In Records
  Future<bool> loadStockInRecords({
    String? searchTerm,
    String? supplierId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
    int offset = 0,
  }) async {
    _isLoading = true;
    _error = null;

    final response = await _service.getStockInRecords(
      searchTerm: searchTerm,
      supplierId: supplierId,
      startDate: startDate,
      endDate: endDate,
      limit: limit,
      offset: offset,
    );

    _isLoading = false;

    if (response.success) {
      _stockInRecords = response.data ?? [];
      return true;
    } else {
      _error = response.error;
      return false;
    }
  }

  // Create Stock In Record
  Future<bool> createStockInRecord(StockInRequest request) async {
    _isLoading = true;
    _error = null;

    final response = await _service.createStockInRecord(request);

    _isLoading = false;

    if (response.success) {
      // Reload records to get the new one
      await loadStockInRecords();
      return true;
    } else {
      _error = response.error;
      return false;
    }
  }

  // Update Stock In Record
  Future<bool> updateStockInRecord(int stockInId, StockInRequest request) async {
    _isLoading = true;
    _error = null;

    final response = await _service.updateStockInRecord(stockInId, request);

    _isLoading = false;

    if (response.success) {
      // Reload records to get the updated one
      await loadStockInRecords();
      return true;
    } else {
      _error = response.error;
      return false;
    }
  }

  // Delete Stock In Record
  Future<bool> deleteStockInRecord(int stockInId) async {
    _isLoading = true;
    _error = null;

    final response = await _service.deleteStockInRecord(stockInId);

    _isLoading = false;

    if (response.success) {
      // Remove from local list
      _stockInRecords.removeWhere((record) => record.id == stockInId);
      return true;
    } else {
      _error = response.error;
      return false;
    }
  }

  // Search Products
  Future<bool> searchProducts(String searchTerm) async {
    if (searchTerm.isEmpty) {
      _searchedProducts = [];
      return true;
    }

    final response = await _service.searchProducts(searchTerm);

    if (response.success) {
      _searchedProducts = response.data ?? [];
      return true;
    } else {
      _error = response.error;
      return false;
    }
  }

  // Search Suppliers
  Future<bool> searchSuppliers(String searchTerm) async {
    if (searchTerm.isEmpty) {
      _searchedSuppliers = [];
      return true;
    }

    final response = await _service.searchSuppliers(searchTerm);

    if (response.success) {
      _searchedSuppliers = response.data ?? [];
      return true;
    } else {
      _error = response.error;
      return false;
    }
  }

  // Load Warehouses
  Future<bool> loadWarehouses() async {
    final response = await _service.getWarehouses();

    if (response.success) {
      _warehouses = response.data ?? [];
      return true;
    } else {
      _error = response.error;
      return false;
    }
  }

 // Upload Invoice File
Future<String?> uploadInvoiceFile(String fileName, Uint8List fileBytes) async {
  _isLoading = true;
  _error = null;

  final response = await _service.uploadInvoiceFile(fileName, fileBytes);

  _isLoading = false;

  if (response.success) {
    return response.data;
  } else {
    _error = response.error;
    return null;
  }
}

  // Download Invoice File
Future<Uint8List?> downloadInvoiceFile(String filePath) async {
  _isLoading = true;
  _error = null;

  final response = await _service.downloadInvoiceFile(filePath);

  _isLoading = false;

  if (response.success) {
    return response.data;
  } else {
    _error = response.error;
    return null;
  }
}
  // Clear error
  void clearError() {
    _error = null;
  }

  // Reset search results
  void clearSearchResults() {
    _searchedProducts = [];
    _searchedSuppliers = [];
  }
}