import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart';
import '../backend/stock_out_logic.dart';
import 'dart:typed_data';

class PrintStockOutLogic {
  static pw.Font? _amiri;
  static pw.MemoryImage? _logoImage;

  Future<pw.Font> _loadArabicFont() async {
    if (_amiri != null) return _amiri!;
    final fontData = await rootBundle.load('assets/fonts/Amiri-Regular.ttf');
    _amiri = pw.Font.ttf(fontData);
    return _amiri!;
  }

  Future<pw.MemoryImage> _loadLogo() async {
    if (_logoImage != null) return _logoImage!;
    final data = await rootBundle.load('assets/images/logo.png');
    _logoImage = pw.MemoryImage(data.buffer.asUint8List());
    return _logoImage!;
  }

  Future<Uint8List> generateStockOutPdf({
    required StockOut stockOut,
    required String companyName,
  }) async {
    final pdf = pw.Document();
    final arabicFont = await _loadArabicFont();
    final logo = await _loadLogo();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(
          base: arabicFont,
          bold: arabicFont,
          italic: arabicFont,
          boldItalic: arabicFont,
        ),
        build: (context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Padding(
              padding: const pw.EdgeInsets.all(24),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
              // Logo at top-right
              pw.Align(
                alignment: pw.Alignment.topRight,
                child: pw.Image(logo, height: 50),
              ),
              pw.SizedBox(height: 8),

              // Company Name
              pw.Text(
                companyName,
                textAlign: pw.TextAlign.center,
                textDirection: pw.TextDirection.ltr,
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
              ),
              
              // Title
              pw.Text(
                'Exchange Permit',
                textAlign: pw.TextAlign.center,
                textDirection: pw.TextDirection.ltr,
                style: pw.TextStyle(fontSize: 16),
              ),
              pw.SizedBox(height: 12),

              // Exchange Number
              pw.Text(
                'Exchange No: ${stockOut.exchangeNumber}',
                textDirection: pw.TextDirection.ltr,
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 12),

              // Header Info Table
              _buildHeaderTable(stockOut),
              
              pw.SizedBox(height: 20),

              // Products Table
              _buildProductsTable(stockOut),

              pw.Spacer(),

              // Signatures
              _buildSignatures(),
                ],
              ),
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeaderTable(StockOut stockOut) {
    final rows = <pw.TableRow>[];
    
    // Type row
    rows.add(pw.TableRow(children: [
      _buildCell('Type /', true),
      _buildCell(stockOut.type, false),
    ]));

    // Based on type, add different rows
    if (stockOut.type == 'transfer') {
      rows.add(pw.TableRow(children: [
        _buildCell('From Warehouse /', true),
        _buildCell(stockOut.fromWarehouseName ?? '', false, isArabic: false),
      ]));
      rows.add(pw.TableRow(children: [
        _buildCell('To Warehouse/', true),
        _buildCell(stockOut.toWarehouseName ?? '', false, isArabic: false),
      ]));
    } else {
      rows.add(pw.TableRow(children: [
        _buildCell('Warehouse /', true),
        _buildCell(stockOut.warehouseName, false, isArabic: false),
      ]));
    }

    // Usage Location
    rows.add(pw.TableRow(children: [
      _buildCell('Usage Location/', true),
      _buildCell(stockOut.usageLocation ?? '', false, isArabic: false),
    ]));

    // Date
    rows.add(pw.TableRow(children: [
      _buildCell('Date /', true),
      _buildCell('${stockOut.date.day}/${stockOut.date.month}/${stockOut.date.year}', false),
    ]));

    return pw.Table(
      border: pw.TableBorder.all(),
      columnWidths: {
        0: const pw.FlexColumnWidth(1),
        1: const pw.FlexColumnWidth(2),
      },
      children: rows,
    );
  }

  pw.Widget _buildProductsTable(StockOut stockOut) {
    return pw.Table(
      border: pw.TableBorder.all(),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.5),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(3),
        3: const pw.FlexColumnWidth(1),
        4: const pw.FlexColumnWidth(1),
        5: const pw.FlexColumnWidth(2),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _buildHeaderCell('Record id'),
            _buildHeaderCell('Product id'),
            _buildHeaderCell('Product Name'),
            _buildHeaderCell('Qty'),
            _buildHeaderCell('unit'),
            _buildHeaderCell('Notes'),
          ],
        ),
        // Data rows
        ...stockOut.items.map((item) => pw.TableRow(
          children: [
            _buildCell(item.recordId ?? '', false),
            _buildCell(item.productId, false),
            _buildCell(item.productName, false, isArabic: true), // النص العربي
            _buildCell(item.quantity.toString(), false),
            _buildCell(item.unit, false),
            _buildCell(stockOut.notes ?? '-', false, isArabic: true), // النص العربي
          ],
        )),
      ],
    );
  }

  pw.Widget _buildSignatures() {
    return pw.Container(
      decoration: pw.BoxDecoration(border: pw.Border.all()),
      child: pw.Row(
        children: [
          _buildSignatureBox('Storekeeper'),
          _buildSignatureBox('Review'),
          _buildSignatureBox('Project Engineer'),
        ],
      ),
    );
  }

  pw.Widget _buildCell(String text, bool isHeader, {bool isArabic = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        textAlign: isArabic ? pw.TextAlign.right : pw.TextAlign.center,
        style: isHeader ? pw.TextStyle(fontWeight: pw.FontWeight.bold) : null,
      ),
    );
  }

  pw.Widget _buildHeaderCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        textDirection: pw.TextDirection.ltr,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  pw.Widget _buildSignatureBox(String title) {
    return pw.Expanded(
      child: pw.Container(
        height: 80,
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          border: pw.Border(left: pw.BorderSide()),
        ),
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              title,
              textDirection: pw.TextDirection.ltr,
            ),
            pw.Container(
              height: 1,
              color: PdfColors.black,
              margin: const pw.EdgeInsets.symmetric(horizontal: 8),
            ),
          ],
        ),
      ),
    );
  }
}