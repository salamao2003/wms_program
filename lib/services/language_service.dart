import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService extends ChangeNotifier {
  static const String _languageKey = 'selected_language';
  
  Locale _currentLocale = const Locale('ar'); // Default to Arabic
  
  Locale get currentLocale => _currentLocale;
  
  bool get isArabic => _currentLocale.languageCode == 'ar';
  bool get isEnglish => _currentLocale.languageCode == 'en';
  
  String get currentLanguageCode => _currentLocale.languageCode;
  
  /// Initialize the language service and load saved language
  Future<void> initialize() async {
    await _loadSavedLanguage();
  }
  
  /// Load the saved language from SharedPreferences
  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguageCode = prefs.getString(_languageKey);
      
      if (savedLanguageCode != null) {
        _currentLocale = Locale(savedLanguageCode);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading saved language: $e');
      // Keep default language if error occurs
    }
  }
  
  /// Change the current language
  Future<void> changeLanguage(String languageCode) async {
    if (languageCode != _currentLocale.languageCode) {
      _currentLocale = Locale(languageCode);
      await _saveLanguage(languageCode);
      notifyListeners();
    }
  }
  
  /// Save the language preference to SharedPreferences
  Future<void> _saveLanguage(String languageCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
    } catch (e) {
      debugPrint('Error saving language: $e');
    }
  }
  
  /// Toggle between Arabic and English
  Future<void> toggleLanguage() async {
    final newLanguageCode = isArabic ? 'en' : 'ar';
    await changeLanguage(newLanguageCode);
  }
  
  /// Set language to Arabic
  Future<void> setArabic() async {
    await changeLanguage('ar');
  }
  
  /// Set language to English
  Future<void> setEnglish() async {
    await changeLanguage('en');
  }
  
  /// Get the text direction based on current language
  TextDirection get textDirection {
    return isArabic ? TextDirection.rtl : TextDirection.ltr;
  }
  
  /// Get the opposite language code
  String get oppositeLanguageCode {
    return isArabic ? 'en' : 'ar';
  }
  
  /// Get the current language name in the current language
  String getCurrentLanguageName() {
    return isArabic ? 'العربية' : 'English';
  }
  
  /// Get the opposite language name in the current language
  String getOppositeLanguageName() {
    return isArabic ? 'English' : 'العربية';
  }
  
  /// Check if the given language code is supported
  bool isLanguageSupported(String languageCode) {
    return ['ar', 'en'].contains(languageCode);
  }
  
  /// Get all supported locales
  List<Locale> getSupportedLocales() {
    return const [
      Locale('ar'),
      Locale('en'),
    ];
  }
  
  /// Get language display name by language code
  String getLanguageDisplayName(String languageCode, {bool inCurrentLanguage = true}) {
    if (!isLanguageSupported(languageCode)) return languageCode;
    
    if (inCurrentLanguage) {
      if (isArabic) {
        return languageCode == 'ar' ? 'العربية' : 'الإنجليزية';
      } else {
        return languageCode == 'ar' ? 'Arabic' : 'English';
      }
    } else {
      return languageCode == 'ar' ? 'العربية' : 'English';
    }
  }
}
