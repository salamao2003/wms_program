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
  final int currentQuantity;
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
      currentQuantity: json['current_quantity'] ?? 0,
      unit: json['unit'] ?? '',
      minStockLevel: json['min_stock_level'],
      maxStockLevel: json['max_stock_level'],
      productName: json['products']?['name'],
      categoryName: 'General', // Default category since categories table doesn't exist
      warehouseCode: json['warehouses']?['code'],
    );
  }
}

// StockOverview Model for combined warehouse data
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
  final int quantity;
  final String unit;

  WarehouseStockInfo({
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
            products(id, name),
            warehouses(code)
          ''')
          .order('product_id');
      
      // Group by product
      Map<String, StockOverview> overviewMap = {};
      
      for (var item in response) {
        final productId = item['product_id'];
        final warehouseCode = item['warehouses']['code'];
        final productName = item['products']['name'];
        final categoryName = 'General'; // Default category since categories table doesn't exist
        
        if (!overviewMap.containsKey(productId)) {
          overviewMap[productId] = StockOverview(
            productId: productId,
            productName: productName,
            categoryName: categoryName,
            warehouseStocks: {},
          );
        }
        
        overviewMap[productId]!.warehouseStocks[warehouseCode] = WarehouseStockInfo(
          quantity: item['current_quantity'] ?? 0,
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
            products(id, name)
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

  // البحث في المخازن
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
  Future<void> addStock(String warehouseId, String productId, int quantity, String unit) async {
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
  Future<void> updateStock(String warehouseId, String productId, int newQuantity) async {
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
}
