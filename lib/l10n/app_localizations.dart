import 'package:flutter/material.dart';
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
  String get retry;
  String get all;
  String get date;
  String get notes;
  String get quantity;
  String get unit;
  String get actions;
  String get print;
  String get warehouseLabel;
  String get supplier;
  String get productId;
  String get productName;
  String get invoice;
  String get recordIdLabel;

  // Stock In Management
  String get stockIn;
  String get additionNumber;
  String get supplierFilter;
  String get fromDate;
  String get toDate;
  String get clearFilters;
  String get noStockInRecords;
  String get productsSection;
  String get uploadInvoice;
  String get deleteStockInTitle;
  String get deleteStockInConfirm;
  String get irreversibleWarning;
  String get deleteSuccess;
  String get deleteFailed;
  String get searchAll;
  String get openInNewTab;
  String get copyLink;
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
  String get warehouses;
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

  // Warehouses
  String get warehousesTitle;
  String get overview;
  String get warehouseDetails;
  String get stockByLocation;
  String get addWarehouse;
  String get editWarehouse;
  String get deleteWarehouse;
  String get warehouseCode;
  String get warehouseName;
  String get location;
  String get address;
  String get manager;
  String get accountant;
  String get warehouseKeeper;
  
  // Products
  String get productsTitle;
  String get addProduct;
  String get editProduct;
  String get productDetails;
  String get category;
  String get taxNumber;
  String get invoiceNumber;
  String get poNumber;
  String get status;
  String get createdAt;
  String get updatedAt;
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
  String get refresh;
  String get filter;
  String get sort;
  String get export;
  String get import;
  String get share;
  String get copy;
  String get paste;
  String get clear;
  String get reset;
  String get selectAll;
  String get deselectAll;
  String get total;
  String get subtotal;
  
  String get time;
  String get name;
  String get commonDescription;
  
  String get optional;
  String get required;
  String get notSpecified;
  String get none;
  
  String get any;

  // Stock In Management
  String get stockInManagement;
  String get recordStockIn;
  String get editStockIn;
  String get deleteStockIn;
 
  String get recordId;
  String get supplierTaxNumber;
  String get supplierName;
  String get warehouse;
  String get generalInfo;
  
  String get invoiceUpload;
  String get noFileSelected;
  String get chooseFile;
  String get changeFile;
  String get removeFile;
  String get searchSuppliers;
  String get searchProducts;
  String get allSuppliers;
  String get filterBySupplier;
 String get deleteStockInConfirmation;
  String get stockInDeleted;
  String get stockInSaved;
  String get stockInUpdated;
  String get linkCopied;
  String get invoiceUploaded;
  String get uploadError;
  String get filePickError;
  String get quantityRequired;
  String get invalidQuantity;
  String get unitRequired;
  String get mustSelectSupplier;
  String get warehouseRequired;
  String get searching;
  String get deleteCannotUndo;
  String get searchByAdditionNumber;
  String get productIdLabel;
  String get productNameLabel;
  String get quantityLabel;
  String get unitLabel;
  String get dateLabel;
  String get notesLabel;
 
  String get productNumber;
  String get loadDataError;
  String get retryLoading;
  String get recordDeleteFailed;
  String get noStockInRecordsSubtext;
  String get firstStockInRecord;
  String get newStockInRecord;
  String get editStockInRecord;
  String get fileUploadSuccess;
  String get fileSizeLimit;
  String get pdfOnlyAllowed;
  
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
