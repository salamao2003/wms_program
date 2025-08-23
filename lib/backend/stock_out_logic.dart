import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'supabase_service.dart';
import 'warehouse_logic.dart';

// ===========================
// Stock Out Models
// ===========================

class StockOutItem {
    final String? recordId;  // أضف هذا
  final String productId;
  final String productName;
  final double quantity;
  final String unit;

  StockOutItem({
        this.recordId,  // أضف هذا
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

  factory StockOutItem.fromJson(Map<String, dynamic> json) {
    return StockOutItem(
            recordId: json['record_id'],  // أضف هذا
      productId: json['product_id'] ?? '',
      productName: json['product_name'] ?? '',
      quantity: (json['quantity'] ?? 0).toDouble(),
      unit: json['unit'] ?? '',
    );
  }
}

class StockOut {
  final int? id;
  final String recordId;
  final String exchangeNumber;
  final String warehouseId;
  final String warehouseName;
  final String type; // used, transfer, return, damage
  final String? usageLocation;
  final String? fromWarehouseId;
  final String? fromWarehouseName;
  final String? toWarehouseId;
  final String? toWarehouseName;
  final DateTime date;
  final String? notes;
  final List<StockOutItem> items;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;

  StockOut({
    this.id,
    required this.recordId,
    required this.exchangeNumber,
    required this.warehouseId,
    required this.warehouseName,
    required this.type,
    this.usageLocation,
    this.fromWarehouseId,
    this.fromWarehouseName,
    this.toWarehouseId,
    this.toWarehouseName,
    required this.date,
    this.notes,
    required this.items,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
  });

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'record_id': recordId,
      'exchange_number': exchangeNumber,
      'warehouse_id': warehouseId,
      'warehouse_name': warehouseName,
      'type': type,
      'usage_location': usageLocation,
      'from_warehouse_id': fromWarehouseId,
      'from_warehouse_name': fromWarehouseName,
      'to_warehouse_id': toWarehouseId,
      'to_warehouse_name': toWarehouseName,
      'date': date.toIso8601String(),
      'notes': notes,
      'items': items.map((item) => item.toJson()).toList(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'created_by': createdBy,
    };
  }

  factory StockOut.fromJson(Map<String, dynamic> json) {
    return StockOut(
      id: json['id'],
      recordId: json['record_id'] ?? '',
      exchangeNumber: json['exchange_number'] ?? '',
      warehouseId: json['warehouse_id'] ?? '',
      warehouseName: json['warehouse_name'] ?? '',
      type: json['type'] ?? 'used',
      usageLocation: json['usage_location'],
      fromWarehouseId: json['from_warehouse_id'],
      fromWarehouseName: json['from_warehouse_name'],
      toWarehouseId: json['to_warehouse_id'],
      toWarehouseName: json['to_warehouse_name'],
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      notes: json['notes'],
      items: (json['items'] as List? ?? [])
          .map((item) => StockOutItem.fromJson(item))
          .toList(),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
      createdBy: json['created_by'],
    );
  }
}

// ===========================
// Filter Model
// ===========================

class StockOutFilter {
  final String? searchQuery;
  final String? type;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? warehouseId;

  StockOutFilter({
    this.searchQuery,
    this.type,
    this.startDate,
    this.endDate,
    this.warehouseId,
  });
}

// ===========================
// Stock Out Logic Class
// ===========================

class StockOutLogic {
  final SupabaseClient _supabase = Supabase.instance.client;
  // If your database has triggers that update warehouse_stock on stock_out_items
  // insert/update/delete, set this to true to prevent double adjustments.
  static const bool _stockManagedByDbTriggers = true;

  // ===========================
  // جلب البيانات
  // ===========================

  /// جلب جميع سجلات الصرف مع الفلترة
  Future<List<StockOut>> getStockOuts({StockOutFilter? filter}) async {
    try {
      var query = _supabase
          .from('stock_out')
          .select('''
            *,
            warehouses!warehouse_id(id, name, code),
            from_warehouse:warehouses!from_warehouse_id(id, name, code),
            to_warehouse:warehouses!to_warehouse_id(id, name, code),
            stock_out_items(
  *,
   record_id,
  products(id, name)
)
          ''');

      // تطبيق الفلاتر
      if (filter != null) {
        // فلتر البحث
        if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
          query = query.or(
            'record_id.ilike.%${filter.searchQuery}%,'
            'exchange_number.ilike.%${filter.searchQuery}%,'
            'notes.ilike.%${filter.searchQuery}%'
          );
        }

        // فلتر النوع
        if (filter.type != null && filter.type!.isNotEmpty) {
          query = query.eq('type', filter.type!);
        }

        // فلتر التاريخ
        if (filter.startDate != null) {
          query = query.gte('date', filter.startDate!.toIso8601String());
        }
        if (filter.endDate != null) {
          query = query.lte('date', filter.endDate!.toIso8601String());
        }

        // فلتر المخزن
        if (filter.warehouseId != null && filter.warehouseId!.isNotEmpty) {
          query = query.or(
            'warehouse_id.eq.${filter.warehouseId},'
            'from_warehouse_id.eq.${filter.warehouseId},'
            'to_warehouse_id.eq.${filter.warehouseId}'
          );
        }
      }

      final response = await query
          .order('date', ascending: false)
          .order('created_at', ascending: false);

      return (response as List).map((data) {
        // معالجة البيانات
        final warehouseData = data['warehouses'];
        final fromWarehouseData = data['from_warehouse'];
        final toWarehouseData = data['to_warehouse'];
        final itemsData = data['stock_out_items'] as List? ?? [];

        return StockOut(
          id: data['id'],
          recordId: data['record_id'],
          exchangeNumber: data['exchange_number'],
          warehouseId: data['warehouse_id'],
          warehouseName: warehouseData?['name'] ?? '',
          type: data['type'],
          usageLocation: data['usage_location'],
          fromWarehouseId: data['from_warehouse_id'],
          fromWarehouseName: fromWarehouseData?['name'],
          toWarehouseId: data['to_warehouse_id'],
          toWarehouseName: toWarehouseData?['name'],
          date: DateTime.parse(data['date']),
          notes: data['notes'],
          items: itemsData.map((item) => StockOutItem(
            recordId: item['record_id'],  // ← تأكد من وجود هذا السطر
  productId: item['product_id'],
  productName: item['products']?['name'] ?? '',  // جلب اسم المنتج
  quantity: (item['quantity'] ?? 0).toDouble(),
  unit: item['unit'] ?? '',
)).toList(),
          createdAt: data['created_at'] != null 
              ? DateTime.parse(data['created_at']) 
              : null,
          updatedAt: data['updated_at'] != null 
              ? DateTime.parse(data['updated_at']) 
              : null,
          createdBy: data['created_by'],
        );
      }).toList();
    } catch (e) {
      throw Exception('Error fetching stock outs: $e');
    }
  }

  /// جلب سجل صرف واحد بالتفاصيل
  Future<StockOut?> getStockOutById(int id) async {
    try {
      final response = await _supabase
          .from('stock_out')
          .select('''
            *,
            warehouses!warehouse_id(id, name, code),
            from_warehouse:warehouses!from_warehouse_id(id, name, code),
            to_warehouse:warehouses!to_warehouse_id(id, name, code),
            stock_out_items(
              *,
              products(id, name)
            )
          ''')
          .eq('id', id)
          .single();

      final warehouseData = response['warehouses'];
      final fromWarehouseData = response['from_warehouse'];
      final toWarehouseData = response['to_warehouse'];
      final itemsData = response['stock_out_items'] as List? ?? [];

      return StockOut(
        id: response['id'],
        recordId: response['record_id'],
        exchangeNumber: response['exchange_number'],
        warehouseId: response['warehouse_id'],
        warehouseName: warehouseData?['name'] ?? '',
        type: response['type'],
        usageLocation: response['usage_location'],
        fromWarehouseId: response['from_warehouse_id'],
        fromWarehouseName: fromWarehouseData?['name'],
        toWarehouseId: response['to_warehouse_id'],
        toWarehouseName: toWarehouseData?['name'],
        date: DateTime.parse(response['date']),
        notes: response['notes'],
        items: itemsData.map((item) => StockOutItem(
          recordId: item['record_id'],  // ← تأكد من وجود هذا السطر
          productId: item['product_id'],
          productName: item['products']?['name'] ?? '',
          quantity: (item['quantity'] ?? 0).toDouble(),
          unit: item['unit'] ?? '',
        )).toList(),
        createdAt: response['created_at'] != null 
            ? DateTime.parse(response['created_at']) 
            : null,
        updatedAt: response['updated_at'] != null 
            ? DateTime.parse(response['updated_at']) 
            : null,
        createdBy: response['created_by'],
      );
    } catch (e) {
      print('Error fetching stock out by id: $e');
      return null;
    }
  }

  // ===========================
  // توليد الأرقام التلقائية
  // ===========================

  /// توليد Record ID جديد
  Future<String> generateRecordId() async {
    try {
      final response = await _supabase
          .rpc('generate_stock_out_record_id');
      return response as String;
    } catch (e) {
      // إذا فشل، نولد رقم يدوي
      final count = await _supabase
          .from('stock_out')
          .select('id')
          .count();
      return 'SO-${count.count + 1}';
    }
  }

  /// توليد Exchange Number جديد
  Future<String> generateExchangeNumber(String warehouseId) async {
    try {
      final response = await _supabase
          .rpc('generate_exchange_number', params: {
            'p_warehouse_id': warehouseId
          });
      return response as String;
    } catch (e) {
      // إذا فشل، نولد رقم يدوي
      final warehouseResponse = await _supabase
          .from('warehouses')
          .select('code')
          .eq('id', warehouseId)
          .single();
      
      final warehouseCode = warehouseResponse['code'];
      
      final count = await _supabase
          .from('stock_out')
          .select('exchange_number')
          .like('exchange_number', 'EX-$warehouseCode-%')
          .count();
      
      return 'EX-$warehouseCode-${count.count + 1}';
    }
  }

  // ===========================
  // إضافة وتعديل وحذف
  // ===========================

  /// إضافة سجل صرف جديد
  Future<void> addStockOut(StockOut stockOut) async {
    try {
      // توليد الأرقام التلقائية
      final recordId = await generateRecordId();
      final exchangeNumber = await generateExchangeNumber(
        stockOut.type == 'transfer' 
            ? stockOut.fromWarehouseId! 
            : stockOut.warehouseId
      );

      // إضافة السجل الرئيسي
      final stockOutResponse = await _supabase
          .from('stock_out')
          .insert({
            'record_id': recordId,
            'exchange_number': exchangeNumber,
           'warehouse_id': stockOut.type == 'transfer' 
    ? stockOut.fromWarehouseId  // استخدم from_warehouse_id في حالة transfer
    : stockOut.warehouseId,
            'type': stockOut.type,
            'usage_location': stockOut.usageLocation,
            'from_warehouse_id': stockOut.type == 'transfer' 
                ? stockOut.fromWarehouseId 
                : null,
            'to_warehouse_id': stockOut.type == 'transfer' 
                ? stockOut.toWarehouseId 
                : null,
            'date': stockOut.date.toIso8601String(),
            'notes': stockOut.notes,
            'created_by': _supabase.auth.currentUser?.id,
          })
          .select()
          .single();

      final stockOutId = stockOutResponse['id'];

      // إضافة تفاصيل المنتجات
      final itemsToInsert = stockOut.items.map((item) => {
        'stock_out_id': stockOutId,
        'product_id': item.productId,
        'quantity': item.quantity,
        'unit': item.unit,
      }).toList();

      await _supabase
          .from('stock_out_items')
          .insert(itemsToInsert);

      // لا تحدّث المخزون يدوياً إذا كانت التريجرز تقوم بذلك
      if (!_stockManagedByDbTriggers) {
        await _updateWarehouseStock(stockOut, stockOutId);
      }

    } catch (e) {
      throw Exception('Error adding stock out: $e');
    }
  }

  /// تعديل سجل صرف
  Future<void> updateStockOut(StockOut stockOut) async {
    try {
      if (stockOut.id == null) {
        throw Exception('Stock out ID is required for update');
      }

      // حذف المنتجات القديمة أولاً
      await _supabase
          .from('stock_out_items')
          .delete()
          .eq('stock_out_id', stockOut.id!);

      // استرجاع المخزون القديم إذا لم تكن هناك تريجرز تدير ذلك
      if (!_stockManagedByDbTriggers) {
        await _revertWarehouseStock(stockOut.id!);
      }

      // تحديث السجل الرئيسي
      await _supabase
          .from('stock_out')
          .update({
            'warehouse_id': stockOut.type == 'transfer' 
    ? stockOut.fromWarehouseId  // استخدم from_warehouse_id في حالة transfer
    : stockOut.warehouseId,
            'type': stockOut.type,
            'usage_location': stockOut.usageLocation,
            'from_warehouse_id': stockOut.type == 'transfer' 
                ? stockOut.fromWarehouseId 
                : null,
            'to_warehouse_id': stockOut.type == 'transfer' 
                ? stockOut.toWarehouseId 
                : null,
            'date': stockOut.date.toIso8601String(),
            'notes': stockOut.notes,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', stockOut.id!);

      // إضافة المنتجات الجديدة
      final itemsToInsert = stockOut.items.map((item) => {
        'stock_out_id': stockOut.id,
        'product_id': item.productId,
        'quantity': item.quantity,
        'unit': item.unit,
      }).toList();

      await _supabase
          .from('stock_out_items')
          .insert(itemsToInsert);

      // تحديث المخزون بالقيم الجديدة إذا لم تكن هناك تريجرز
      if (!_stockManagedByDbTriggers) {
        await _updateWarehouseStock(stockOut, stockOut.id!);
      }

    } catch (e) {
      throw Exception('Error updating stock out: $e');
    }
  }

  /// حذف سجل صرف
  Future<void> deleteStockOut(int id) async {
    try {
      // استرجاع المخزون أولاً إذا لم تكن هناك تريجرز تدير ذلك
      if (!_stockManagedByDbTriggers) {
        await _revertWarehouseStock(id);
      }

      // حذف السجل (المنتجات ستحذف تلقائياً بسبب CASCADE)
      await _supabase
          .from('stock_out')
          .delete()
          .eq('id', id);

    } catch (e) {
      throw Exception('Error deleting stock out: $e');
    }
  }

  // ===========================
  // وظائف مساعدة للمخزون
  // ===========================

  /// تحديث المخزون عند إضافة صرف
  Future<void> _updateWarehouseStock(StockOut stockOut, int stockOutId) async {
    try {
      if (stockOut.type == 'transfer') {
        // في حالة Transfer
        for (final item in stockOut.items) {
          // خصم من المخزن المصدر
          await _decreaseStock(
            stockOut.fromWarehouseId!, 
            item.productId, 
            item.quantity
          );

          // إضافة للمخزن الهدف
          await _increaseStock(
            stockOut.toWarehouseId!, 
            item.productId, 
            item.quantity,
            item.unit
          );
        }
      } else {
        // في حالة used, return, damage
        for (final item in stockOut.items) {
          await _decreaseStock(
            stockOut.warehouseId, 
            item.productId, 
            item.quantity
          );
        }
      }
    } catch (e) {
      throw Exception('Error updating warehouse stock: $e');
    }
  }

  /// استرجاع المخزون عند حذف أو تعديل
  Future<void> _revertWarehouseStock(int stockOutId) async {
    try {
      // جلب بيانات الصرف القديم
      final oldStockOut = await getStockOutById(stockOutId);
      if (oldStockOut == null) return;

      if (oldStockOut.type == 'transfer') {
        // استرجاع Transfer
        for (final item in oldStockOut.items) {
          // إضافة للمخزن المصدر
          await _increaseStock(
            oldStockOut.fromWarehouseId!, 
            item.productId, 
            item.quantity,
            item.unit
          );

          // خصم من المخزن الهدف
          await _decreaseStock(
            oldStockOut.toWarehouseId!, 
            item.productId, 
            item.quantity
          );
        }
      } else {
        // استرجاع الكمية للمخزن
        for (final item in oldStockOut.items) {
          await _increaseStock(
            oldStockOut.warehouseId, 
            item.productId, 
            item.quantity,
            item.unit
          );
        }
      }
    } catch (e) {
      throw Exception('Error reverting warehouse stock: $e');
    }
  }

  Future<void> _decreaseStock(
  String warehouseId, 
  String productId, 
  double quantity
) async {
  try {
    // جلب الكمية الحالية
    final currentStock = await _supabase
        .from('warehouse_stock')
        .select('current_quantity')
        .eq('warehouse_id', warehouseId)
        .eq('product_id', productId)
        .single();
    
    final currentQuantity = (currentStock['current_quantity'] ?? 0).toDouble();
    final newQuantity = currentQuantity - quantity;
    
    // تحديث الكمية
    await _supabase
        .from('warehouse_stock')
        .update({
          'current_quantity': newQuantity,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('warehouse_id', warehouseId)
        .eq('product_id', productId);
  } catch (e) {
    print('Error decreasing stock: $e');
    throw e;
  }
}

  /// إضافة للمخزون
  Future<void> _increaseStock(
  String warehouseId, 
  String productId, 
  double quantity,
  String unit
) async {
  try {
    // محاولة جلب السجل الموجود
    final existingStock = await _supabase
        .from('warehouse_stock')
        .select('current_quantity')
        .eq('warehouse_id', warehouseId)
        .eq('product_id', productId)
        .maybeSingle();
    
    if (existingStock != null) {
      // تحديث السجل الموجود
      final currentQuantity = (existingStock['current_quantity'] ?? 0).toDouble();
      final newQuantity = currentQuantity + quantity;
      
      await _supabase
          .from('warehouse_stock')
          .update({
            'current_quantity': newQuantity,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('warehouse_id', warehouseId)
          .eq('product_id', productId);
    } else {
      // إنشاء سجل جديد
      await _supabase
          .from('warehouse_stock')
          .insert({
            'warehouse_id': warehouseId,
            'product_id': productId,
            'current_quantity': quantity,
            'unit': unit,
            'min_stock_level': 0,
            'max_stock_level': 0,
          });
    }
  } catch (e) {
    print('Error increasing stock: $e');
    throw e;
  }
}
  // ===========================
  // وظائف البحث والاقتراحات
  // ===========================

  /// البحث عن المنتجات للـ Autocomplete
  Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    try {
      if (query.isEmpty) return [];

      final response = await _supabase
          .from('products')
          .select('id, name, unit')
          .or('id.ilike.%$query%,name.ilike.%$query%')
          .limit(10);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error searching products: $e');
      return [];
    }
  }

  /// جلب منتج بالـ ID
  Future<Map<String, dynamic>?> getProductById(String productId) async {
    try {
      final response = await _supabase
          .from('products')
          .select('id, name, unit')
          .eq('id', productId)
          .single();

      return response;
    } catch (e) {
      print('Error fetching product: $e');
      return null;
    }
  }

  /// جلب المخازن للـ Dropdown
  Future<List<Map<String, dynamic>>> getWarehouses() async {
    try {
      final response = await _supabase
          .from('warehouses')
          .select('id, name, code')
          .order('name');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching warehouses: $e');
      return [];
    }
  }

  /// التحقق من توفر الكمية في المخزن
  Future<bool> checkStockAvailability(
    String warehouseId, 
    String productId, 
    double quantity
  ) async {
    try {
      final response = await _supabase
          .from('warehouse_stock')
          .select('current_quantity')
          .eq('warehouse_id', warehouseId)
          .eq('product_id', productId)
          .single();

      final currentQuantity = (response['current_quantity'] ?? 0).toDouble();
      return currentQuantity >= quantity;
    } catch (e) {
      print('Error checking stock availability: $e');
      return false;
    }
  }

  /// جلب الكمية المتاحة في المخزن
  Future<double> getAvailableQuantity(
    String warehouseId, 
    String productId
  ) async {
    try {
      final response = await _supabase
          .from('warehouse_stock')
          .select('current_quantity')
          .eq('warehouse_id', warehouseId)
          .eq('product_id', productId)
          .single();

      return (response['current_quantity'] ?? 0).toDouble();
    } catch (e) {
      print('Error getting available quantity: $e');
      return 0;
    }
  }

  // ===========================
  // إحصائيات
  // ===========================

  /// جلب إحصائيات الصرف
  Future<Map<String, dynamic>> getStockOutStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _supabase
          .from('stock_out')
          .select('type, stock_out_items(quantity)');

      if (startDate != null) {
        query = query.gte('date', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('date', endDate.toIso8601String());
      }

      final response = await query;

      // حساب الإحصائيات
      Map<String, int> typeCounts = {
        'used': 0,
        'transfer': 0,
        'return': 0,
        'damage': 0,
      };

      Map<String, double> typeQuantities = {
        'used': 0,
        'transfer': 0,
        'return': 0,
        'damage': 0,
      };

      for (final record in response) {
        final type = record['type'] as String;
        typeCounts[type] = (typeCounts[type] ?? 0) + 1;

        final items = record['stock_out_items'] as List? ?? [];
        double totalQuantity = 0;
        for (final item in items) {
          totalQuantity += (item['quantity'] ?? 0).toDouble();
        }
        typeQuantities[type] = (typeQuantities[type] ?? 0) + totalQuantity;
      }

      return {
        'totalRecords': response.length,
        'typeCounts': typeCounts,
        'typeQuantities': typeQuantities,
      };
    } catch (e) {
      print('Error getting statistics: $e');
      return {
        'totalRecords': 0,
        'typeCounts': {},
        'typeQuantities': {},
      };
    }
  }
}