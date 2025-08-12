import 'package:supabase_flutter/supabase_flutter.dart';

// Warehouse Model
class Warehouse {
  final String? id;
  final String code;
  final String name;
  final String location;
  final String? address;
  final String? manager;
  final String? accountant;
  final String? warehouseKeeper;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Warehouse({
    this.id,
    required this.code,
    required this.name,
    required this.location,
    this.address,
    this.manager,
    this.accountant,
    this.warehouseKeeper,
    this.createdAt,
    this.updatedAt,
  });

  factory Warehouse.fromJson(Map<String, dynamic> json) {
    return Warehouse(
      id: json['id'],
      code: json['code'],
      name: json['name'],
      location: json['location'],
      address: json['address'],
      manager: json['manager'],
      accountant: json['accountant'],
      warehouseKeeper: json['warehouse_keeper'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'location': location,
      'address': address,
      'manager': manager,
      'accountant': accountant,
      'warehouse_keeper': warehouseKeeper,
    };
  }
}

// WarehouseStock Model
class WarehouseStock {
  final String? id;
  final String warehouseId;
  final String productId;
  // Use double to allow fractional quantities
  final double currentQuantity;
  final String unit;
  final int? minStockLevel;
  final int? maxStockLevel;
  final String? productName;
  final String? categoryName;
  final String? warehouseCode;

  WarehouseStock({
    this.id,
    required this.warehouseId,
    required this.productId,
    required this.currentQuantity,
    required this.unit,
    this.minStockLevel,
    this.maxStockLevel,
    this.productName,
    this.categoryName,
    this.warehouseCode,
  });

  factory WarehouseStock.fromJson(Map<String, dynamic> json) {
    return WarehouseStock(
      id: json['id'],
      warehouseId: json['warehouse_id'],
      productId: json['product_id'],
      // numeric -> double
      currentQuantity: (json['current_quantity'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] ?? '',
      minStockLevel: json['min_stock_level'],
      maxStockLevel: json['max_stock_level'],
      productName: json['products']?['name'],
      categoryName: json['products']?['category']?['name'] ?? 'General',
      warehouseCode: json['warehouses']?['code'],
    );
  }
}

// ===============================
// Enhanced Models for Dynamic Overview
// ===============================

// عمود المخزن للجدول الديناميكي
class WarehouseColumn {
  final String warehouseId;
  final String warehouseName;

  WarehouseColumn({
    required this.warehouseId,
    required this.warehouseName,
  });
}

// StockOverview Model for combined warehouse data (Enhanced)
class StockOverview {
  final String productId;
  final String productName;
  final String categoryName;
  final Map<String, WarehouseStockInfo> warehouseStocks;

  StockOverview({
    required this.productId,
    required this.productName,
    required this.categoryName,
    required this.warehouseStocks,
  });
}

class WarehouseStockInfo {
  // Use double to allow fractional quantities
  final double quantity;
  final String unit;

  WarehouseStockInfo({
    required this.quantity,
    required this.unit,
  });
}

// New Enhanced Overview Model for dynamic columns
class WarehouseOverviewData {
  final String productId;
  final String productName;
  final String categoryName;
  final Map<String, WarehouseStockDetail> warehouseStocks; // Key: warehouse_id

  WarehouseOverviewData({
    required this.productId,
    required this.productName,
    required this.categoryName,
    required this.warehouseStocks,
  });

  // الحساب بالإجمالي عبر جميع المخازن كقيمة عشرية
  double get totalQuantity {
    return warehouseStocks.values
        .fold<double>(0.0, (sum, stock) => sum + stock.quantity);
  }

  // التحقق من وجود مخزون
  bool get hasStock {
    return totalQuantity > 0.0;
  }

  // جلب قائمة المخازن التي تحتوي على مخزون
  List<WarehouseStockDetail> get stocksWithQuantity {
    return warehouseStocks.values
        .where((stock) => stock.quantity > 0)
        .toList();
  }

  // جلب معلومات مخزن معين
  WarehouseStockDetail? getStockForWarehouse(String warehouseId) {
    return warehouseStocks[warehouseId];
  }
}

class WarehouseStockDetail {
  final String warehouseId;
  final String warehouseName;
  // Use double to allow fractional quantities
  final double quantity;
  final String unit;

  WarehouseStockDetail({
    required this.warehouseId,
    required this.warehouseName,
    required this.quantity,
    required this.unit,
  });
}

// Warehouse Logic Class
class WarehouseLogic {
  final SupabaseClient _supabase = Supabase.instance.client;

  // جلب جميع المخازن
  Future<List<Warehouse>> getWarehouses() async {
    try {
      final response = await _supabase
          .from('warehouses')
          .select()
          .order('name');
      
      return (response as List)
          .map((data) => Warehouse.fromJson(data))
          .toList();
    } catch (e) {
      throw Exception('Error fetching warehouses: $e');
    }
  }

  // جلب مخزون جميع المخازن (للـ Overview)
  Future<List<StockOverview>> getAllWarehousesStock() async {
    try {
      final response = await _supabase
          .from('warehouse_stock')
          .select('''
            product_id,
            current_quantity,
            unit,
            products(id, name, category:category_id(id, name)),
            warehouses(code)
          ''')
          .order('product_id');
      
      Map<String, StockOverview> overviewMap = {};
      
      for (var item in response) {
        final productId = item['product_id'];
        final warehouseCode = item['warehouses']['code'];
        final productName = item['products']['name'];
        final categoryName = item['products']['category']?['name'] as String? ?? 'General';
        
        if (!overviewMap.containsKey(productId)) {
          overviewMap[productId] = StockOverview(
            productId: productId,
            productName: productName,
            categoryName: categoryName,
            warehouseStocks: {},
          );
        }
        
        overviewMap[productId]!.warehouseStocks[warehouseCode] = WarehouseStockInfo(
          // numeric -> double
          quantity: (item['current_quantity'] as num?)?.toDouble() ?? 0.0,
          unit: item['unit'] ?? '',
        );
      }
      
      return overviewMap.values.toList();
    } catch (e) {
      throw Exception('Error fetching stock overview: $e');
    }
  }

  // جلب مخزون مخزن محدد
  Future<List<WarehouseStock>> getWarehouseStock(String warehouseId) async {
    try {
      final response = await _supabase
          .from('warehouse_stock')
          .select('''
            *,
            products(id, name, category:category_id(id, name))
          ''')
          .eq('warehouse_id', warehouseId)
          .order('product_id');
      
      return (response as List)
          .map((data) => WarehouseStock.fromJson(data))
          .toList();
    } catch (e) {
      throw Exception('Error fetching warehouse stock: $e');
    }
  }

  // إضافة مخزن جديد
  Future<void> addWarehouse(Warehouse warehouse) async {
    try {
      await _supabase
          .from('warehouses')
          .insert(warehouse.toJson());
    } catch (e) {
      throw Exception('Error adding warehouse: $e');
    }
  }

  // تحديث مخزن
  Future<void> updateWarehouse(String id, Warehouse warehouse) async {
    try {
      await _supabase
          .from('warehouses')
          .update(warehouse.toJson())
          .eq('id', id);
    } catch (e) {
      throw Exception('Error updating warehouse: $e');
    }
  }

  // حذف مخزن
  Future<void> deleteWarehouse(String id) async {
    try {
      // أولاً احذف المخزون المرتبط
      await _supabase
          .from('warehouse_stock')
          .delete()
          .eq('warehouse_id', id);
      
      // ثم احذف المخزن
      await _supabase
          .from('warehouses')
          .delete()
          .eq('id', id);
    } catch (e) {
      throw Exception('Error deleting warehouse: $e');
    }
  }

  // ===============================
  // New Enhanced Overview Functions
  // ===============================

  // جلب جميع المخازن كأعمدة للجدول الديناميكي
  Future<List<WarehouseColumn>> getWarehouseColumns() async {
    try {
      final response = await _supabase
          .from('warehouses')
          .select('id, name')
          .order('name');
      
      return (response as List)
          .map((data) => WarehouseColumn(
            warehouseId: data['id'],
            warehouseName: data['name'],
          ))
          .toList();
    } catch (e) {
      throw Exception('Error fetching warehouse columns: $e');
    }
  }

  // جلب البيانات الشاملة للـ Overview الديناميكي
  Future<List<WarehouseOverviewData>> getEnhancedWarehouseOverview() async {
    try {
      // جلب جميع المنتجات مع الفئات
       final productsResponse = await _supabase
        .from('products')
        .select('''
          id, 
          name,
          categories!category_id (
            id,
            name
          )
        ''')
        .order('name');

      // جلب جميع المخازن
      final warehousesResponse = await _supabase
          .from('warehouses')
          .select('id, name')
          .order('name');

      // جلب جميع بيانات المخزون
      final stockResponse = await _supabase
          .from('warehouse_stock')
          .select('''
            warehouse_id,
            product_id,
            current_quantity,
            unit,
            warehouses(id, name)
          ''');

      // إنشاء خريطة للمخازن
      final Map<String, String> warehousesMap = {};
      for (var warehouse in warehousesResponse) {
        warehousesMap[warehouse['id']] = warehouse['name'];
      }

      // إنشاء خريطة للمخزون
      final Map<String, Map<String, WarehouseStockDetail>> stockMap = {};
      for (var stock in stockResponse) {
        final productId = stock['product_id'] as String;
        final warehouseId = stock['warehouse_id'] as String;
        final warehouseName = warehousesMap[warehouseId] ?? 'Unknown';

        if (!stockMap.containsKey(productId)) {
          stockMap[productId] = {};
        }

        stockMap[productId]![warehouseId] = WarehouseStockDetail(
          warehouseId: warehouseId,
          warehouseName: warehouseName,
          quantity: (stock['current_quantity'] as num?)?.toDouble() ?? 0.0,
          unit: stock['unit'] ?? 'PC',
        );
      }

      // إنشاء البيانات النهائية
      final List<WarehouseOverviewData> overviewData = [];
      
      for (var product in productsResponse) {
        final productId = product['id'] as String;
        final productName = product['name'] as String;
        final Map<String, WarehouseStockDetail> productStocks = {};
        
        for (var warehouseEntry in warehousesMap.entries) {
          final warehouseId = warehouseEntry.key;
          final warehouseName = warehouseEntry.value;
          
          if (stockMap[productId] != null && stockMap[productId]![warehouseId] != null) {
            productStocks[warehouseId] = stockMap[productId]![warehouseId]!;
          } else {
            productStocks[warehouseId] = WarehouseStockDetail(
              warehouseId: warehouseId,
              warehouseName: warehouseName,
              quantity: 0.0,
              unit: 'PC',
            );
          }
        }
        // معالجة آمنة لاسم الفئة
        String categoryName = 'General';
        try {
          if (product['category'] != null && product['category']['name'] != null) {
            categoryName = product['category']['name'] as String;
          }
        } catch (e) {
          print('Warning: Could not get category name for product $productId: $e');
        }

        overviewData.add(WarehouseOverviewData(
          productId: productId,
          productName: productName,
          categoryName: categoryName,
          warehouseStocks: productStocks,
        ));
      }

      return overviewData;
    } catch (e) {
      throw Exception('Error fetching enhanced warehouse overview: $e');
    }
  }

  // جلب إحصائيات المخزون
  Future<Map<String, dynamic>> getWarehouseOverviewStats() async {
    try {
      // جلب عدد المنتجات الإجمالي
      final productsResponse = await _supabase
          .from('products')
          .select('*');
      final productsCount = productsResponse.length;

      // جلب عدد المخازن
      final warehousesResponse = await _supabase
          .from('warehouses')
          .select('*');
      final warehousesCount = warehousesResponse.length;

      // جلب إجمالي المخزون
      final stockResponse = await _supabase
          .from('warehouse_stock')
          .select('current_quantity');
      
      double totalStock = 0.0;
      for (var stock in stockResponse) {
        totalStock += ((stock['current_quantity'] as num?)?.toDouble() ?? 0.0);
      }

      // جلب المنتجات بدون مخزون
      final allProductsResponse = await _supabase
          .from('products')
          .select('id');
      
      final productsWithStockResponse = await _supabase
          .from('warehouse_stock')
          .select('product_id')
          .gt('current_quantity', 0);

      final productsWithStock = productsWithStockResponse
          .map((e) => e['product_id'])
          .toSet();
      
      final productsWithoutStock = allProductsResponse.length - productsWithStock.length;

      return {
        'totalProducts': productsCount,
        'totalWarehouses': warehousesCount,
        'totalStock': totalStock,
        'productsWithoutStock': productsWithoutStock,
        'productsWithStock': productsWithStock.length,
      };
    } catch (e) {
      throw Exception('Error fetching warehouse overview stats: $e');
    }
  }

  // ===============================
  // Original Functions (unchanged)
  // ===============================
  Future<List<Warehouse>> searchWarehouses(String query) async {
    try {
      final response = await _supabase
          .from('warehouses')
          .select()
          .or('name.ilike.%$query%,code.ilike.%$query%,location.ilike.%$query%')
          .order('name');
      
      return (response as List)
          .map((data) => Warehouse.fromJson(data))
          .toList();
    } catch (e) {
      throw Exception('Error searching warehouses: $e');
    }
  }

  // إضافة مخزون لمخزن
  Future<void> addStock(String warehouseId, String productId, double quantity, String unit) async {
    try {
      await _supabase
          .from('warehouse_stock')
          .upsert({
            'warehouse_id': warehouseId,
            'product_id': productId,
            'current_quantity': quantity,
            'unit': unit,
          });
    } catch (e) {
      throw Exception('Error adding stock: $e');
    }
  }

  // تحديث كمية مخزون
  Future<void> updateStock(String warehouseId, String productId, double newQuantity) async {
    try {
      await _supabase
          .from('warehouse_stock')
          .update({'current_quantity': newQuantity})
          .eq('warehouse_id', warehouseId)
          .eq('product_id', productId);
    } catch (e) {
      throw Exception('Error updating stock: $e');
    }
  }

  // ===============================
  // Helper Functions for Overview
  // ===============================

  // فلترة البيانات حسب البحث
  List<WarehouseOverviewData> filterOverviewData(
    List<WarehouseOverviewData> data,
    String searchQuery,
  ) {
    if (searchQuery.isEmpty) return data;
    
    final query = searchQuery.toLowerCase();
    return data.where((item) {
      return item.productName.toLowerCase().contains(query) ||
             item.categoryName.toLowerCase().contains(query) ||
             item.productId.toLowerCase().contains(query);
    }).toList();
  }

  // ترتيب البيانات
  List<WarehouseOverviewData> sortOverviewData(
    List<WarehouseOverviewData> data,
    String sortBy,
    bool ascending,
  ) {
    data.sort((a, b) {
      int comparison;
      switch (sortBy) {
        case 'name':
          comparison = a.productName.compareTo(b.productName);
          break;
        case 'category':
          comparison = a.categoryName.compareTo(b.categoryName);
          break;
        case 'total':
          comparison = a.totalQuantity.compareTo(b.totalQuantity);
          break;
        default:
          comparison = a.productName.compareTo(b.productName);
      }
      return ascending ? comparison : -comparison;
    });
    return data;
  }

  // تحويل البيانات لتصدير CSV
  String convertToCSV(
    List<WarehouseOverviewData> data,
    List<WarehouseColumn> columns,
  ) {
    if (data.isEmpty) return '';
    
    // إنشاء العناوين المحدثة
    List<String> headers = ['Product ID', 'Product Name', 'Category'];
    
    // إضافة أعمدة المخازن (Quantity + Unit لكل مخزن)
    for (var column in columns) {
      headers.add('${column.warehouseName} Qty');
      headers.add('${column.warehouseName} Unit');
    }
    headers.add('Total Quantity');
    
    // إنشاء الصفوف
    List<String> rows = [headers.join(',')];
    
    for (var item in data) {
      List<String> row = [
        '"${item.productId}"',
        '"${item.productName}"',
        '"${item.categoryName}"',
      ];
      
      // إضافة كميات ووحدات المخازن مع معالجة الأخطاء
      for (var column in columns) {
        try {
          final stock = item.getStockForWarehouse(column.warehouseId);
          row.add('${stock?.quantity ?? 0}');
          row.add('"${stock?.unit ?? 'PC'}"');
        } catch (e) {
          print('Warning: Error getting stock data for warehouse ${column.warehouseId}: $e');
          row.add('0');
          row.add('"PC"');
        }
      }
      
      // إضافة الإجمالي مع معالجة الأخطاء
      try {
        row.add('${item.totalQuantity}');
      } catch (e) {
        print('Warning: Error calculating total quantity for ${item.productId}: $e');
        row.add('0');
      }
      
      rows.add(row.join(','));
    }
    
    return rows.join('\n');
  }

  // جلب البيانات مع البحث والفلترة
  Future<List<WarehouseOverviewData>> getFilteredOverviewData({
    String searchQuery = '',
    String sortBy = 'name',
    bool ascending = true,
    bool showEmptyStock = true,
  }) async {
    try {
      var data = await getEnhancedWarehouseOverview();
      
      // فلترة المنتجات بدون مخزون إذا طُلب ذلك
      if (!showEmptyStock) {
        data = data.where((item) => item.hasStock).toList();
      }
      
      // تطبيق البحث
      data = filterOverviewData(data, searchQuery);
      
      // تطبيق الترتيب
      data = sortOverviewData(data, sortBy, ascending);
      
      return data;
    } catch (e) {
      throw Exception('Error getting filtered overview data: $e');
    }
  }

  // في warehouse_logic.dart
// أضف هذه الدالة
Future<void> refreshWarehouseData() async {
  try {
    // إعادة تحميل جميع البيانات
    await getEnhancedWarehouseOverview();
    await getWarehouseOverviewStats();
  } catch (e) {
    print('Error refreshing warehouse data: $e');
  }
}

  // ===============================
  // End of Helper Functions
  // ===============================
}
