import 'package:supabase_flutter/supabase_flutter.dart';

// Supplier Model
class Supplier {
  final String? id;
  final String name;
  final String taxNumber;
  final String specialization;
  final String address;
  final String? email;
  final String? phone;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Supplier({
    this.id,
    required this.name,
    required this.taxNumber,
    required this.specialization,
    required this.address,
    this.email,
    this.phone,
    this.status = 'active',
    this.createdAt,
    this.updatedAt,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id'],
      name: json['name'] ?? '',
      taxNumber: json['tax_number'] ?? '',
      specialization: json['specialization'] ?? '',
      address: json['address'] ?? '',
      email: json['email'],
      phone: json['phone'],
      status: json['status'] ?? 'active',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'tax_number': taxNumber,
      'specialization': specialization,
      'address': address,
      'email': email,
      'phone': phone,
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}

// Supplier Logic Class
class SupplierLogic {
  final SupabaseClient _supabase = Supabase.instance.client;

  // جلب جميع الموردين
  Future<List<Supplier>> getSuppliers() async {
    try {
      final response = await _supabase
          .from('suppliers')
          .select()
          .order('name');
      
      return (response as List)
          .map((item) => Supplier.fromJson(item))
          .toList();
    } catch (e) {
      throw Exception('Error fetching suppliers: $e');
    }
  }

  // إضافة مورد جديد
  Future<void> addSupplier(Supplier supplier) async {
    try {
      await _supabase
          .from('suppliers')
          .insert(supplier.toJson());
    } catch (e) {
      throw Exception('Error adding supplier: $e');
    }
  }

  // تحديث مورد
  Future<void> updateSupplier(String id, Supplier supplier) async {
    try {
      await _supabase
          .from('suppliers')
          .update(supplier.toJson())
          .eq('id', id);
    } catch (e) {
      throw Exception('Error updating supplier: $e');
    }
  }

  // حذف مورد
  Future<void> deleteSupplier(String id) async {
    try {
      await _supabase
          .from('suppliers')
          .delete()
          .eq('id', id);
    } catch (e) {
      throw Exception('Error deleting supplier: $e');
    }
  }

  // البحث في الموردين
  Future<List<Supplier>> searchSuppliers(String query) async {
    try {
      final response = await _supabase
          .from('suppliers')
          .select()
          .or('name.ilike.%$query%,tax_number.ilike.%$query%,specialization.ilike.%$query%')
          .order('name');
      
      return (response as List)
          .map((item) => Supplier.fromJson(item))
          .toList();
    } catch (e) {
      throw Exception('Error searching suppliers: $e');
    }
  }

  // التحقق من وجود رقم ضريبي
  Future<bool> isTaxNumberExists(String taxNumber, {String? excludeId}) async {
    try {
      var query = _supabase
          .from('suppliers')
          .select('id')
          .eq('tax_number', taxNumber);
      
      if (excludeId != null) {
        query = query.neq('id', excludeId);
      }
      
      final response = await query;
      return (response as List).isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // البحث عن مورد بالرقم الضريبي
  Future<Supplier?> getSupplierByTaxNumber(String taxNumber) async {
    try {
      final response = await _supabase
          .from('suppliers')
          .select()
          .eq('tax_number', taxNumber)
          .maybeSingle();
      
      if (response != null) {
        return Supplier.fromJson(response);
      }
      return null;
    } catch (e) {
      throw Exception('Error fetching supplier by tax number: $e');
    }
  }

  // البحث في أسماء الموردين للـ autocomplete
  Future<List<Supplier>> getSupplierSuggestions(String query) async {
    try {
      if (query.isEmpty) return [];
      
      final response = await _supabase
          .from('suppliers')
          .select()
          .ilike('name', '%$query%')
          .eq('status', 'active')
          .order('name')
          .limit(10);
      
      return (response as List)
          .map((item) => Supplier.fromJson(item))
          .toList();
    } catch (e) {
      throw Exception('Error fetching supplier suggestions: $e');
    }
  }

  // الحصول على جميع الموردين النشطين للـ dropdown
  Future<List<Supplier>> getActiveSuppliers() async {
    try {
      final response = await _supabase
          .from('suppliers')
          .select()
          .eq('status', 'active')
          .order('name');
      
      return (response as List)
          .map((item) => Supplier.fromJson(item))
          .toList();
    } catch (e) {
      throw Exception('Error fetching active suppliers: $e');
    }
  }
}