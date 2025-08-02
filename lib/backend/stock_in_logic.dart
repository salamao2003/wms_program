import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:mime/mime.dart';
import 'package:url_launcher/url_launcher.dart';

// StockInRecord Model
class StockInRecord {
  final String? id;
  final String recordId;
  final String additionNumber;
  final String productId;
  final String? productName;
  final int quantity;
  final String unit;
  final String? supplierId;
  final String? supplierName;
  final String? supplierTaxNumber;
  final String? warehouseId;
  final String? warehouseCode;
  final String? warehouseName;
  final String? notes;
  final String? electronicInvoiceUrl;
  final String? invoiceFileName;
  final int? invoiceFileSize;
  final DateTime? invoiceUploadedAt;
  final DateTime? invoiceDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  StockInRecord({
    this.id,
    required this.recordId,
    required this.additionNumber,
    required this.productId,
    this.productName,
    required this.quantity,
    required this.unit,
    this.supplierId,
    this.supplierName,
    this.supplierTaxNumber,
    this.warehouseId,
    this.warehouseCode,
    this.warehouseName,
    this.notes,
    this.electronicInvoiceUrl,
    this.invoiceFileName,
    this.invoiceFileSize,
    this.invoiceUploadedAt,
    this.invoiceDate,
    this.createdAt,
    this.updatedAt,
  });

  factory StockInRecord.fromJson(Map<String, dynamic> json) {
    return StockInRecord(
      id: json['id'],
      recordId: json['record_id'] ?? '',
      additionNumber: json['addition_number'] ?? '',
      productId: json['product_id'] ?? '',
      productName: json['products']?['name'] ?? json['product_name'],
      quantity: json['quantity'] ?? 0,
      unit: json['unit'] ?? '',
      supplierId: json['supplier_id'],
      supplierName: json['suppliers']?['name'] ?? json['supplier_name'],
      supplierTaxNumber: json['suppliers']?['tax_number'] ?? json['supplier_tax_number'],
      warehouseId: json['warehouse_id'],
      warehouseCode: json['warehouses']?['code'] ?? json['warehouse_code'],
      warehouseName: json['warehouses']?['name'] ?? json['warehouse_name'],
      notes: json['notes'],
      electronicInvoiceUrl: json['electronic_invoice_url'],
      invoiceFileName: json['invoice_file_name'],
      invoiceFileSize: json['invoice_file_size'],
      invoiceUploadedAt: json['invoice_uploaded_at'] != null ? DateTime.parse(json['invoice_uploaded_at']) : null,
      invoiceDate: json['invoice_date'] != null ? DateTime.parse(json['invoice_date']) : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'quantity': quantity,
      'unit': unit,
      'supplier_id': supplierId,
      'warehouse_id': warehouseId,
      'notes': notes,
      'electronic_invoice_url': electronicInvoiceUrl,
      'invoice_file_name': invoiceFileName,
      'invoice_file_size': invoiceFileSize,
      'invoice_uploaded_at': invoiceUploadedAt?.toIso8601String(),
      'invoice_date': invoiceDate?.toIso8601String().split('T')[0],
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}

// Stock In Logic Class
class StockInLogic {
  final SupabaseClient _supabase = Supabase.instance.client;

  // جلب جميع سجلات Stock In مع البيانات المرتبطة
  Future<List<StockInRecord>> getStockInRecords() async {
    try {
      final response = await _supabase
          .from('stock_in_records')
          .select('''
            *,
            products(name),
            suppliers(name, tax_number),
            warehouses(code, name)
          ''')
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((item) => StockInRecord.fromJson(item))
          .toList();
    } catch (e) {
      throw Exception('Error fetching stock in records: $e');
    }
  }

  // إضافة سجل Stock In جديد
  Future<void> addStockInRecord(StockInRecord record) async {
    try {
      await _supabase
          .from('stock_in_records')
          .insert(record.toJson());
    } catch (e) {
      throw Exception('Error adding stock in record: $e');
    }
  }

  // تحديث سجل Stock In
  Future<void> updateStockInRecord(String id, StockInRecord record) async {
    try {
      await _supabase
          .from('stock_in_records')
          .update(record.toJson())
          .eq('id', id);
    } catch (e) {
      throw Exception('Error updating stock in record: $e');
    }
  }

  // حذف سجل Stock In
  Future<void> deleteStockInRecord(String id) async {
    try {
      await _supabase
          .from('stock_in_records')
          .delete()
          .eq('id', id);
    } catch (e) {
      throw Exception('Error deleting stock in record: $e');
    }
  }

  // البحث في سجلات Stock In مع الفلاتر
  Future<List<StockInRecord>> searchStockInRecords({
    String? searchTerm,
    String? supplierId,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? warehouseId,
  }) async {
    try {
      var query = _supabase
          .from('stock_in_records')
          .select('''
            *,
            products(name),
            suppliers(name, tax_number),
            warehouses(code, name)
          ''');

      // إضافة البحث النصي
      if (searchTerm != null && searchTerm.isNotEmpty) {
        query = query.or(
          'record_id.ilike.%$searchTerm%,'
          'addition_number.ilike.%$searchTerm%,'
          'product_id.ilike.%$searchTerm%,'
          'products.name.ilike.%$searchTerm%'
        );
      }

      // فلترة بالمورد
      if (supplierId != null && supplierId.isNotEmpty) {
        query = query.eq('supplier_id', supplierId);
      }

      // فلترة بالمخزن
      if (warehouseId != null && warehouseId.isNotEmpty) {
        query = query.eq('warehouse_id', warehouseId);
      }

      // فلترة بالتاريخ من
      if (dateFrom != null) {
        query = query.gte('invoice_date', dateFrom.toIso8601String().split('T')[0]);
      }

      // فلترة بالتاريخ إلى
      if (dateTo != null) {
        query = query.lte('invoice_date', dateTo.toIso8601String().split('T')[0]);
      }

      final response = await query.order('created_at', ascending: false);
      
      return (response as List)
          .map((item) => StockInRecord.fromJson(item))
          .toList();
    } catch (e) {
      throw Exception('Error searching stock in records: $e');
    }
  }

  // إحصائيات Stock In
  Future<Map<String, int>> getStockInStats() async {
    try {
      final today = DateTime.now();
      final todayStr = today.toIso8601String().split('T')[0];
      
      final weekStart = today.subtract(Duration(days: today.weekday - 1));
      final weekStartStr = weekStart.toIso8601String().split('T')[0];
      
      final monthStart = DateTime(today.year, today.month, 1);
      final monthStartStr = monthStart.toIso8601String().split('T')[0];

      // إحصائيات اليوم
      final todayResponse = await _supabase
          .from('stock_in_records')
          .select('quantity')
          .eq('invoice_date', todayStr);
      
      final todayCount = (todayResponse as List).fold<int>(
        0, (sum, record) => sum + (record['quantity'] as int? ?? 0)
      );

      // إحصائيات الأسبوع
      final weekResponse = await _supabase
          .from('stock_in_records')
          .select('quantity')
          .gte('invoice_date', weekStartStr)
          .lte('invoice_date', todayStr);
      
      final weekCount = (weekResponse as List).fold<int>(
        0, (sum, record) => sum + (record['quantity'] as int? ?? 0)
      );

      // إحصائيات الشهر
      final monthResponse = await _supabase
          .from('stock_in_records')
          .select('quantity')
          .gte('invoice_date', monthStartStr)
          .lte('invoice_date', todayStr);
      
      final monthCount = (monthResponse as List).fold<int>(
        0, (sum, record) => sum + (record['quantity'] as int? ?? 0)
      );

      return {
        'today': todayCount,
        'week': weekCount,
        'month': monthCount,
      };
    } catch (e) {
      throw Exception('Error fetching stock in stats: $e');
    }
  }

  // جلب جميع المخازن للـ dropdown
  Future<List<Map<String, dynamic>>> getWarehouses() async {
    try {
      final response = await _supabase
          .from('warehouses')
          .select('id, code, name')
          .order('code');
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error fetching warehouses: $e');
    }
  }

  // جلب جميع الموردين للـ dropdown
  Future<List<Map<String, dynamic>>> getSuppliers() async {
    try {
      final response = await _supabase
          .from('suppliers')
          .select('id, name, tax_number')
          .order('name');
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error fetching suppliers: $e');
    }
  }

  // جلب جميع المنتجات للـ autocomplete
  Future<List<Map<String, dynamic>>> getProducts({String? searchTerm}) async {
    try {
      var query = _supabase
          .from('products')
          .select('id, name');

      if (searchTerm != null && searchTerm.isNotEmpty) {
        query = query.or('id.ilike.%$searchTerm%,name.ilike.%$searchTerm%');
      }

      final response = await query
          .order('name')
          .limit(100);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error fetching products: $e');
    }
  }

  // التحقق من صحة البيانات
  String? validateStockInRecord({
    required String productId,
    required int quantity,
    required String unit,
    required String warehouseId,
    required String supplierId,
  }) {
    if (productId.trim().isEmpty) {
      return 'Product ID is required';
    }
    
    if (quantity <= 0) {
      return 'Quantity must be greater than 0';
    }

    if (unit.trim().isEmpty) {
      return 'Unit is required';
    }

    if (warehouseId.trim().isEmpty) {
      return 'Warehouse is required';
    }

    if (supplierId.trim().isEmpty) {
      return 'Supplier is required';
    }

    return null; // البيانات صحيحة
  }

  // ===============================
  // وظائف إدارة مخزون المخازن
  // ===============================

  // تحديث مخزون المخزن عند إضافة Stock In
  Future<void> updateWarehouseStock({
    required String warehouseId,
    required String productId,
    required int quantity,
    required String unit,
  }) async {
    try {
      // البحث عن السجل الموجود
      final existingStock = await _supabase
          .from('warehouse_stock')
          .select('*')
          .eq('warehouse_id', warehouseId)
          .eq('product_id', productId)
          .maybeSingle();

      if (existingStock != null) {
        // تحديث الكمية الموجودة
        final currentQuantity = existingStock['current_quantity'] as int? ?? 0;
        final newQuantity = currentQuantity + quantity;
        
        await _supabase
            .from('warehouse_stock')
            .update({
              'current_quantity': newQuantity,  // ✅ تم التصحيح
              'unit': unit,
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
              'current_quantity': quantity,  // ✅ تم التصحيح
              'unit': unit,
              'updated_at': DateTime.now().toIso8601String(),
            });
      }
    } catch (e) {
      throw Exception('Error updating warehouse stock: $e');
    }
  }

  // تقليل مخزون المخزن عند الحذف أو التعديل
  Future<void> reduceWarehouseStock({
    required String warehouseId,
    required String productId,
    required int quantity,
  }) async {
    try {
      // البحث عن السجل الموجود مع معالجة الأخطاء
      final existingStock = await _supabase
          .from('warehouse_stock')
          .select('*')
          .eq('warehouse_id', warehouseId)
          .eq('product_id', productId)
          .maybeSingle();

      if (existingStock != null) {
        final currentQuantity = existingStock['current_quantity'] as int? ?? 0;  // ✅ تم التصحيح
        final newQuantity = currentQuantity - quantity;

        if (newQuantity <= 0) {
          // حذف السجل إذا أصبحت الكمية صفر أو أقل
          await _supabase
              .from('warehouse_stock')
              .delete()
              .eq('warehouse_id', warehouseId)
              .eq('product_id', productId);
        } else {
          // تحديث الكمية
          await _supabase
              .from('warehouse_stock')
              .update({
                'current_quantity': newQuantity,  // ✅ تم التصحيح
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('warehouse_id', warehouseId)
              .eq('product_id', productId);
        }
      }
      // إذا لم يكن موجود، لا نفعل شيء (تجاهل الخطأ)
    } catch (e) {
      print('Warning: Could not reduce warehouse stock: $e');
      // لا نرمي Exception هنا لتجنب توقف العملية
    }
  }

  // مزامنة جميع سجلات Stock In الموجودة مع warehouse_stock
  Future<void> syncExistingStockInRecords() async {
    try {
      // مسح جميع بيانات warehouse_stock 
      await _supabase
          .from('warehouse_stock')
          .delete()
          .neq('id', '00000000-0000-0000-0000-000000000000'); // حذف جميع السجلات

      // جلب جميع سجلات Stock In
      final stockInRecords = await _supabase
          .from('stock_in_records')
          .select('warehouse_id, product_id, quantity, unit');

      // إعادة بناء warehouse_stock من سجلات Stock In
      final warehouseStockMap = <String, Map<String, dynamic>>{};

      for (final record in stockInRecords) {
        final warehouseId = record['warehouse_id'] as String?;
        final productId = record['product_id'] as String?;
        final quantity = record['quantity'] as int? ?? 0;
        final unit = record['unit'] as String? ?? 'PC';

        if (warehouseId != null && productId != null) {
          final key = '${warehouseId}_$productId';
          
          if (warehouseStockMap.containsKey(key)) {
            // زيادة الكمية الموجودة
            warehouseStockMap[key]!['current_quantity'] += quantity;  // ✅ تم التصحيح
          } else {
            // إنشاء سجل جديد
            warehouseStockMap[key] = {
              'warehouse_id': warehouseId,
              'product_id': productId,
              'current_quantity': quantity,  // ✅ تم التصحيح
              'unit': unit,
              'updated_at': DateTime.now().toIso8601String(),
            };
          }
        }
      }

      // إدراج البيانات المجمعة في warehouse_stock
      if (warehouseStockMap.isNotEmpty) {
        await _supabase
            .from('warehouse_stock')
            .insert(warehouseStockMap.values.toList());
      }

      print('Successfully synced ${warehouseStockMap.length} warehouse stock records');
    } catch (e) {
      throw Exception('Error syncing existing stock in records: $e');
    }
  }

  // ===============================
  // تحديث الوظائف الأساسية لتتضمن تحديث المخزون
  // ===============================

  // إضافة سجل Stock In جديد مع تحديث المخزون
  Future<void> addStockInRecordWithStock(StockInRecord record) async {
    try {
      // إضافة سجل Stock In
      await _supabase
          .from('stock_in_records')
          .insert(record.toJson());

      // تحديث مخزون المخزن
      if (record.warehouseId != null) {
        await updateWarehouseStock(
          warehouseId: record.warehouseId!,
          productId: record.productId,
          quantity: record.quantity,
          unit: record.unit,
        );
      }
    } catch (e) {
      throw Exception('Error adding stock in record with stock update: $e');
    }
  }

  // تحديث سجل Stock In مع تحديث المخزون
  Future<void> updateStockInRecordWithStock(String id, StockInRecord oldRecord, StockInRecord newRecord) async {
    try {
      // تحديث سجل Stock In
      await _supabase
          .from('stock_in_records')
          .update(newRecord.toJson())
          .eq('id', id);

      // تحديث المخزون - إزالة الكميات القديمة وإضافة الجديدة
      if (oldRecord.warehouseId != null) {
        await reduceWarehouseStock(
          warehouseId: oldRecord.warehouseId!,
          productId: oldRecord.productId,
          quantity: oldRecord.quantity,
        );
      }

      if (newRecord.warehouseId != null) {
        await updateWarehouseStock(
          warehouseId: newRecord.warehouseId!,
          productId: newRecord.productId,
          quantity: newRecord.quantity,
          unit: newRecord.unit,
        );
      }
    } catch (e) {
      throw Exception('Error updating stock in record with stock update: $e');
    }
  }

  // حذف سجل Stock In مع تحديث المخزون
  Future<void> deleteStockInRecordWithStock(String id, StockInRecord record) async {
    try {
      // حذف سجل Stock In
      await _supabase
          .from('stock_in_records')
          .delete()
          .eq('id', id);

      // تقليل المخزون
      if (record.warehouseId != null) {
        await reduceWarehouseStock(
          warehouseId: record.warehouseId!,
          productId: record.productId,
          quantity: record.quantity,
        );
      }
    } catch (e) {
      throw Exception('Error deleting stock in record with stock update: $e');
    }
  }

  // ===============================
  // وظائف إدارة الفواتير الإلكترونية
  // ===============================

  // اختيار ملف PDF
  Future<File?> pickPdfFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null) {
        String filePath = result.files.single.path!;
        File file = File(filePath);
        
        // التحقق من وجود الملف
        if (!await file.exists()) {
          throw Exception('Selected file does not exist');
        }

        // التحقق من نوع الملف
        String? mimeType = lookupMimeType(filePath);
        if (mimeType != 'application/pdf') {
          throw Exception('Please select a PDF file only');
        }

        // التحقق من حجم الملف (حد أقصى 10MB)
        int fileSize = await file.length();
        if (fileSize > 10 * 1024 * 1024) { // 10MB
          throw Exception('File size must be less than 10MB');
        }

        return file;
      }
      return null;
    } catch (e) {
      throw Exception('Error picking file: $e');
    }
  }

  // رفع الفاتورة الإلكترونية
  Future<Map<String, dynamic>> uploadElectronicInvoice({
    required File file,
    required String recordId,
  }) async {
    try {
      // إنشاء اسم ملف فريد
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(file.path);
      final fileName = '${recordId}_$timestamp$extension';
      
      // مسار الرفع بتنسيق سنة/شهر
      final now = DateTime.now();
      final year = now.year.toString();
      final month = now.month.toString().padLeft(2, '0');
      final uploadPath = 'electronic_invoices/$year/$month/$fileName';

      print('Uploading file to: $uploadPath'); // للتصحيح

      // رفع الملف إلى Supabase Storage
      await _supabase.storage
          .from('invoices')
          .upload(uploadPath, file);

      // الحصول على رابط الملف العام
      final publicUrl = _supabase.storage
          .from('invoices')
          .getPublicUrl(uploadPath);

      // معلومات الملف
      final fileSize = await file.length();
      final originalFileName = path.basename(file.path);

      print('File uploaded successfully: $publicUrl'); // للتصحيح

      return {
        'url': publicUrl,
        'fileName': originalFileName,
        'fileSize': fileSize,
        'uploadPath': uploadPath,
        'uploadedAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw Exception('Error uploading electronic invoice: $e');
    }
  }

  // حذف الفاتورة الإلكترونية
  Future<void> deleteElectronicInvoice(String fileUrl) async {
    try {
      // استخراج مسار الملف من الـ URL
      final uri = Uri.parse(fileUrl);
      final pathSegments = uri.pathSegments;
      
      // البحث عن مسار الملف بعد /storage/v1/object/public/invoices/
      final invoicesIndex = pathSegments.indexOf('invoices');
      if (invoicesIndex != -1 && invoicesIndex < pathSegments.length - 1) {
        final filePath = pathSegments.sublist(invoicesIndex + 1).join('/');
        
        print('Deleting file from path: $filePath'); // للتصحيح
        
        // حذف الملف من Storage
        await _supabase.storage
            .from('invoices')
            .remove([filePath]);
            
        print('File deleted successfully'); // للتصحيح
      } else {
        throw Exception('Invalid file URL format');
      }
    } catch (e) {
      throw Exception('Error deleting electronic invoice: $e');
    }
  }

  // تحديث بيانات الفاتورة في قاعدة البيانات
  Future<void> updateElectronicInvoiceInfo({
    required String recordId,
    required String invoiceUrl,
    required String fileName,
    required int fileSize,
  }) async {
    try {
      await _supabase
          .from('stock_in_records')
          .update({
            'electronic_invoice_url': invoiceUrl,
            'invoice_file_name': fileName,
            'invoice_file_size': fileSize,
            'invoice_uploaded_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', recordId);
    } catch (e) {
      throw Exception('Error updating invoice info: $e');
    }
  }

  // إزالة بيانات الفاتورة من قاعدة البيانات
  Future<void> removeElectronicInvoiceInfo(String recordId) async {
    try {
      await _supabase
          .from('stock_in_records')
          .update({
            'electronic_invoice_url': null,
            'invoice_file_name': null,
            'invoice_file_size': null,
            'invoice_uploaded_at': null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', recordId);
    } catch (e) {
      throw Exception('Error removing invoice info: $e');
    }
  }

  // رفع فاتورة إلكترونية (وظيفة شاملة)
  Future<String> uploadInvoiceComplete({
    required String recordId,
    required File file,
  }) async {
    try {
      // رفع الملف
      final uploadResult = await uploadElectronicInvoice(
        file: file,
        recordId: recordId,
      );

      // تحديث قاعدة البيانات
      await updateElectronicInvoiceInfo(
        recordId: recordId,
        invoiceUrl: uploadResult['url'],
        fileName: uploadResult['fileName'],
        fileSize: uploadResult['fileSize'],
      );

      return uploadResult['url'];
    } catch (e) {
      throw Exception('Error in complete invoice upload: $e');
    }
  }

  // حذف فاتورة إلكترونية (وظيفة شاملة)
  Future<void> deleteInvoiceComplete({
    required String recordId,
    required String fileUrl,
  }) async {
    try {
      // حذف الملف من Storage
      await deleteElectronicInvoice(fileUrl);

      // إزالة بيانات الفاتورة من قاعدة البيانات
      await removeElectronicInvoiceInfo(recordId);
    } catch (e) {
      throw Exception('Error in complete invoice deletion: $e');
    }
  }

  // التحقق من صيغة وحجم الملف
  String? validatePdfFile(File file) {
    try {
      // التحقق من الامتداد
      String extension = path.extension(file.path).toLowerCase();
      if (extension != '.pdf') {
        return 'Please select a PDF file only';
      }

      // التحقق من نوع الملف
      String? mimeType = lookupMimeType(file.path);
      if (mimeType != 'application/pdf') {
        return 'Invalid file format. Please select a valid PDF file';
      }

      return null; // الملف صحيح
    } catch (e) {
      return 'Error validating file: $e';
    }
  }

  // التحقق من حجم الملف بشكل منفصل
  Future<String?> validateFileSize(File file, {int maxSizeMB = 10}) async {
    try {
      int fileSize = await file.length();
      int maxSizeBytes = maxSizeMB * 1024 * 1024;
      
      if (fileSize > maxSizeBytes) {
        return 'File size (${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB) exceeds the maximum allowed size of $maxSizeMB MB';
      }

      return null; // الحجم مناسب
    } catch (e) {
      return 'Error checking file size: $e';
    }
  }

  // تحميل الفاتورة الإلكترونية
  Future<bool> downloadElectronicInvoice({
    required String invoiceUrl,
    required String fileName,
  }) async {
    try {
      // التحقق من صحة الرابط
      final Uri url = Uri.parse(invoiceUrl);
      
      // التحقق من إمكانية فتح الرابط
      if (await canLaunchUrl(url)) {
        // محاولة فتح الرابط في المتصفح الخارجي أولاً
        bool launched = await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
        
        // إذا فشل، جرب فتحه في WebView داخلي
        if (!launched) {
          launched = await launchUrl(
            url,
            mode: LaunchMode.inAppWebView,
          );
        }
        
        // إذا فشل، جرب الطريقة العادية
        if (!launched) {
          launched = await launchUrl(url);
        }
        
        if (launched) {
          print('Invoice opened successfully: $invoiceUrl'); // للتصحيح
          return true;
        } else {
          throw Exception('Failed to launch URL after multiple attempts');
        }
      } else {
        throw Exception('Cannot launch URL: $invoiceUrl');
      }
    } catch (e) {
      print('Error downloading electronic invoice: $e'); // للتصحيح
      throw Exception('فشل في فتح الفاتورة. تأكد من وجود متصفح على الجهاز أو اتصال الإنترنت');
    }
  }
}