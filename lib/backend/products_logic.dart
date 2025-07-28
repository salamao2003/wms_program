import 'package:warehouse_management_system/backend/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductsLogic {
  final SupabaseService _supabaseService = SupabaseService();

  // ======================= CATEGORIES OPERATIONS =======================

  /// جلب جميع الفئات الرئيسية (بدون parent)
  Future<List<Map<String, dynamic>>> getRootCategories() async {
    try {
      final response = await _supabaseService.client
          .from('categories')
          .select('*')
          .isFilter('parent_id', null)
          .order('name');
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch root categories: $e');
    }
  }

  /// جلب الفئات الفرعية لفئة معينة
  Future<List<Map<String, dynamic>>> getSubCategories(int parentId) async {
    try {
      final response = await _supabaseService.client
          .from('categories')
          .select('*')
          .eq('parent_id', parentId)
          .order('name');
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch subcategories: $e');
    }
  }

  /// جلب المسار الكامل للفئة من الـ View
  Future<String> getCategoryPath(int categoryId) async {
    try {
      final response = await _supabaseService.client
          .from('categories_with_path')
          .select('path')
          .eq('id', categoryId)
          .single();
      
      return response['path'] ?? '';
    } catch (e) {
      return 'Unknown Category';
    }
  }

  /// إضافة فئة جديدة
  Future<Map<String, dynamic>> addCategory({
    required String name,
    int? parentId,
    String? description,
  }) async {
    try {
      // حساب المستوى
      int level = 1;
      if (parentId != null) {
        final parentResponse = await _supabaseService.client
            .from('categories')
            .select('level')
            .eq('id', parentId)
            .single();
        level = (parentResponse['level'] ?? 0) + 1;
      }

      final response = await _supabaseService.client
          .from('categories')
          .insert({
            'name': name,
            'parent_id': parentId,
            'level': level,
            'description': description,
          })
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to add category: $e');
    }
  }

  /// تحديث فئة
  Future<void> updateCategory({
    required int id,
    required String name,
    String? description,
  }) async {
    try {
      await _supabaseService.client
          .from('categories')
          .update({
            'name': name,
            'description': description,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
    } catch (e) {
      throw Exception('Failed to update category: $e');
    }
  }

  /// حذف فئة (وجميع الفئات الفرعية تلقائياً بسبب CASCADE)
  Future<void> deleteCategory(int id) async {
    try {
      // التحقق من عدم وجود منتجات مرتبطة بالفئة
      final products = await _supabaseService.client
          .from('products')
          .select('id')
          .eq('category_id', id);

      if (products.isNotEmpty) {
        throw Exception('Cannot delete category: Products are linked to this category');
      }

      await _supabaseService.client
          .from('categories')
          .delete()
          .eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete category: $e');
    }
  }

  // ======================= PRODUCTS OPERATIONS =======================

  /// جلب جميع المنتجات مع تفاصيل الفئات
  Future<List<Map<String, dynamic>>> getProducts() async {
    try {
      final response = await _supabaseService.client
          .from('products')
          .select('''
            *,
            category:category_id (
              id,
              name
            )
          ''')
          .order('name');
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }

  /// جلب منتج واحد بتفاصيله
  Future<Map<String, dynamic>?> getProduct(String id) async {
    try {
      final response = await _supabaseService.client
          .from('products')
          .select('''
            *,
            category:category_id (
              id,
              name
            )
          ''')
          .eq('id', id)
          .single();
      
      return response;
    } catch (e) {
      return null;
    }
  }

  /// التحقق من توفر Product ID
  Future<bool> isProductIdAvailable(String id) async {
    try {
      final response = await _supabaseService.client
          .from('products')
          .select('id')
          .eq('id', id);
      
      return response.isEmpty;
    } catch (e) {
      return false;
    }
  }

  /// إضافة منتج جديد
  Future<Map<String, dynamic>> addProduct({
    required String id,
    required String name,
    int? categoryId,
    String? supplier,
    String? supplierTaxNumber,
    String? electronicInvoiceNumber,
    String? poNumber,
  }) async {
    try {
      // التحقق من عدم تكرار الـ ID
      final isAvailable = await isProductIdAvailable(id);
      if (!isAvailable) {
        throw Exception('Product ID already exists');
      }

      // إضافة المنتج
      final productResponse = await _supabaseService.client
          .from('products')
          .insert({
            'id': id,
            'name': name,
            'category_id': categoryId,
            'supplier': supplier,
            'supplier_tax_number': supplierTaxNumber,
            'electronic_invoice_number': electronicInvoiceNumber,
            'po_number': poNumber,
            'status': 'active',
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return productResponse;
    } catch (e) {
      // فحص رسالة الخطأ
      final msg = e.toString();
      if (msg.contains('unique_electronic_invoice_number') || msg.contains('already exists')) {
        throw Exception('رقم الفاتورة الالكترونية موجود مسبقا');
      }
      throw Exception('Failed to add product: $msg');
    }
  }

  /// تحديث منتج
  Future<void> updateProduct({
    required String id,
    required String name,
    int? categoryId,
    String? supplier,
    String? supplierTaxNumber,
    String? electronicInvoiceNumber,
    String? poNumber,
  }) async {
    try {
      await _supabaseService.client
          .from('products')
          .update({
            'name': name,
            'category_id': categoryId,
            'supplier': supplier,
            'supplier_tax_number': supplierTaxNumber,
            'electronic_invoice_number': electronicInvoiceNumber,
            'po_number': poNumber,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
    } catch (e) {
      // فحص رسالة الخطأ
      final msg = e.toString();
      if (msg.contains('unique_electronic_invoice_number') || msg.contains('already exists')) {
        throw Exception('رقم الفاتورة الالكترونية موجود مسبقا');
      }
      throw Exception('Failed to update product: $msg');
    }
  }

  /// حذف منتج
  Future<void> deleteProduct(String id) async {
    try {
      print('Starting delete process for product: $id');

      // حذف المخزون المرتبط أولاً (ignore errors)
      try {
        await _supabaseService.client
            .from('warehouse_stock')
            .delete()
            .eq('product_id', id);
        print('Warehouse stock deleted successfully');
      } catch (stockError) {
        print('Warning: Could not delete warehouse stock: $stockError');
        // نكمل العملية حتى لو فشل حذف المخزون
      }

      // حذف المعاملات المرتبطة (ignore errors)
      try {
        await _supabaseService.client
            .from('stock_transactions')
            .delete()
            .eq('product_id', id);
        print('Stock transactions deleted successfully');
      } catch (transError) {
        print('Warning: Could not delete stock transactions: $transError');
        // نكمل العملية حتى لو فشل حذف المعاملات
      }

      // حذف المنتج (هذا الأهم)
      await _supabaseService.client
          .from('products')
          .delete()
          .eq('id', id);
      
      print('Product deleted successfully');
    } catch (e) {
      print('Error deleting product: $e');
      throw Exception('Failed to delete product: ${e.toString()}');
    }
  }

  // ======================= SEARCH AND FILTER =======================

  /// البحث المتقدم في المنتجات
Future<List<Map<String, dynamic>>> searchProducts({
  String? searchTerm,
  int? categoryId,
  String? status,
}) async {
  try {
    var query = _supabaseService.client
        .from('products')
        .select('''
          *,
          category:category_id (
            id,
            name
          )
        ''');

    // البحث الشامل في عدة حقول
    if (searchTerm != null && searchTerm.isNotEmpty) {
      // البحث في:
      // 1. ID المنتج
      // 2. اسم المنتج
      // 3. رقم الفاتورة الإلكترونية
      // 4. الرقم الضريبي للمورد
      // 5. رقم PO
      // 6. اسم المورد
      query = query.or(
        'id.ilike.%$searchTerm%,'
        'name.ilike.%$searchTerm%,'
        'electronic_invoice_number.ilike.%$searchTerm%,'
        'supplier_tax_number.ilike.%$searchTerm%,'
        'po_number.ilike.%$searchTerm%,'
        'supplier.ilike.%$searchTerm%'
      );
    }

    // فلترة بالفئة
    if (categoryId != null) {
      query = query.eq('category_id', categoryId);
    }

    // فلترة بالحالة
    if (status != null) {
      query = query.eq('status', status);
    }

    final response = await query.order('name');
    return List<Map<String, dynamic>>.from(response);
  } catch (e) {
    throw Exception('Failed to search products: $e');
  }
}

/// البحث المتخصص حسب نوع البحث
Future<List<Map<String, dynamic>>> searchProductsByField({
  String? searchTerm,
  required String searchField, // 'id', 'name', 'invoice', 'tax', 'po', 'supplier'
  int? categoryId,
  String? status,
}) async {
  try {
    var query = _supabaseService.client
        .from('products')
        .select('''
          *,
          category:category_id (
            id,
            name
          )
        ''');

    // البحث المتخصص حسب الحقل المحدد
    if (searchTerm != null && searchTerm.isNotEmpty) {
      switch (searchField) {
        case 'id':
          query = query.ilike('id', '%$searchTerm%');
          break;
        case 'name':
          query = query.ilike('name', '%$searchTerm%');
          break;
        case 'invoice':
          query = query.ilike('electronic_invoice_number', '%$searchTerm%');
          break;
        case 'tax':
          query = query.ilike('supplier_tax_number', '%$searchTerm%');
          break;
        case 'po':
          query = query.ilike('po_number', '%$searchTerm%');
          break;
        case 'supplier':
          query = query.ilike('supplier', '%$searchTerm%');
          break;
        default:
          // البحث الشامل
          query = query.or(
            'id.ilike.%$searchTerm%,'
            'name.ilike.%$searchTerm%,'
            'electronic_invoice_number.ilike.%$searchTerm%,'
            'supplier_tax_number.ilike.%$searchTerm%,'
            'po_number.ilike.%$searchTerm%,'
            'supplier.ilike.%$searchTerm%'
          );
      }
    }

    // باقي الفلاتر
    if (categoryId != null) {
      query = query.eq('category_id', categoryId);
    }
    if (status != null) {
      query = query.eq('status', status);
    }

    final response = await query.order('name');
    return List<Map<String, dynamic>>.from(response);
  } catch (e) {
    throw Exception('Failed to search products by field: $e');
  }
}

  // ======================= UTILITY METHODS =======================

  /// جلب إحصائيات المنتجات
  Future<Map<String, int>> getProductsStats() async {
    try {
      final totalProducts = await _supabaseService.client
          .from('products')
          .select('id')
          .count(CountOption.exact);

      final activeProducts = await _supabaseService.client
          .from('products')
          .select('id')
          .eq('status', 'active')
          .count(CountOption.exact);

      final categoriesCount = await _supabaseService.client
          .from('categories')
          .select('id')
          .count(CountOption.exact);

      return {
        'total_products': totalProducts.count,
        'active_products': activeProducts.count,
        'total_categories': categoriesCount.count,
      };
    } catch (e) {
      return {
        'total_products': 0,
        'active_products': 0,
        'total_categories': 0,
      };
    }
  }

  /// جلب المخزون الإجمالي لمنتج
  Future<Map<String, dynamic>> getProductTotalStock(String productId) async {
    try {
      final response = await _supabaseService.client
          .from('products_total_stock')
          .select('*')
          .eq('id', productId)
          .single();
      
      return response;
    } catch (e) {
      return {
        'total_quantity': 0,
        'total_reserved': 0,
        'available_quantity': 0,
        'warehouses_count': 0,
      };
    }
  }

  /// التحقق من صحة بيانات المنتج
  String? validateProductData({
    required String id,
    required String name,
  }) {
    if (id.trim().isEmpty) {
      return 'Product ID is required';
    }
    
    if (id.trim().length < 3) {
      return 'Product ID must be at least 3 characters';
    }

    if (name.trim().isEmpty) {
      return 'Product name is required';
    }

    if (name.trim().length < 2) {
      return 'Product name must be at least 2 characters';
    }

    return null; // البيانات صحيحة
  }
}