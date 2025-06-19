import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  SupabaseClient get client => _client;

  Future<void> initialize() async {
    await Supabase.initialize(
      url: 'https://yiqegbzhuxyjygqkaehz.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlpcWVnYnpodXh5anlncWthZWh6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTAyNDc3NTksImV4cCI6MjA2NTgyMzc1OX0.ePivHHvtLExB-B8a5F12AzLQd5j7jmHu-LrDt3viGWk',
    );
  }
}