import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

abstract class AppLocalizations {
  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    delegate,
  ];

  static const List<Locale> supportedLocales = [
    Locale('ar'),
    Locale('en'),
  ];

  // App Title
  String get appTitle;

  // General
  String get language;
  String get arabic;
  String get english;
  String get changeLanguage;
  String get selectLanguage;
  String get apply;
  String get cancel;
  String get close;
  String get save;
  String get edit;
  String get delete;
  String get add;
  String get searchText;
  String get loading;
  String get error;
  String get success;
  String get warning;
  String get info;

  // Login
  String get loginTitle;
  String get email;
  String get password;
  String get loginButton;
  String get forgotPassword;
  String get signup;
  String get invalidEmail;
  String get invalidPassword;
  String get loginFailed;
  String get loginSuccess;

  // Sidebar
  String get dashboard;
  String get products;
  String get categories;
  String get stockIn;
  String get stockOut;
  String get inventoryCount;
  String get transactions;
  String get reports;
  String get customers;
  String get suppliers;
  String get users;
  String get invitations;
  String get settings;
  String get logout;

  // Products
  String get productsTitle;
  String get addProduct;
  String get editProduct;
  String get productDetails;
  String get productName;
  String get productId;
  String get category;
  String get supplier;
  String get taxNumber;
  String get invoiceNumber;
  String get poNumber;
  String get status;
  String get createdAt;
  String get updatedAt;
  String get actions;
  String get view;
  String get noProducts;
  String get productAdded;
  String get productUpdated;
  String get productDeleted;
  String get deleteProduct;
  String get deleteConfirmation;
  String get productIdExists;
  String get basicInfo;
  String get supplierInfo;
  String get statusActive;
  String get statusInactive;
  String get statusDiscontinued;

  // Categories
  String get categoriesTitle;
  String get addCategory;
  String get categoryName;
  String get parentCategory;
  String get description;
  String get mainCategory;
  String get subCategory1;
  String get subCategory2;
  String get subCategory3;
  String get level;
  String get categoryAdded;
  String get categoryUpdated;
  String get categoryDeleted;

  // Search
  String get searchAll;
  String get searchById;
  String get searchByName;
  String get searchByInvoice;
  String get searchByTax;
  String get searchByPo;
  String get searchBySupplier;
  String get searchFailed;
  String get noResults;

  // Validation
  String get requiredField;
  String get validationInvalidEmail;
  String get passwordMinLength;
  String get productIdRequired;
  String get productIdMinLength;
  String get productNameRequired;
  String get productNameMinLength;

  // Dashboard
  String get dashboardTitle;
  String get totalProducts;
  String get activeProducts;
  String get totalCategories;
  String get recentTransactions;
  String get lowStockProducts;
  String get statistics;

  // Common
  String get yes;
  String get no;
  String get ok;
  String get confirm;
  String get back;
  String get next;
  String get previous;
  String get finish;
  String get retry;
  String get refresh;
  String get filter;
  String get sort;
  String get export;
  String get import;
  String get print;
  String get share;
  String get copy;
  String get paste;
  String get clear;
  String get reset;
  String get selectAll;
  String get deselectAll;
  String get total;
  String get subtotal;
  String get date;
  String get time;
  String get name;
  String get commonDescription;
  String get notes;
  String get optional;
  String get required;
  String get notSpecified;
  String get none;
  String get all;
  String get any;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['ar', 'en'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    switch (locale.languageCode) {
      case 'ar':
        return AppLocalizationsAr();
      case 'en':
        return AppLocalizationsEn();
      default:
        return AppLocalizationsEn();
    }
  }

  @override
  bool shouldReload(LocalizationsDelegate<AppLocalizations> old) {
    return false;
  }
}
