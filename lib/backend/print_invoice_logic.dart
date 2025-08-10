import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart';
import '../backend/stock_in_logic.dart';
import 'dart:typed_data';

class PrintInvoiceLogic {
  static pw.Font? _amiri;
  static pw.MemoryImage? _logoImage; // <- cache logo

  Future<pw.Font> _loadArabicFont() async {
    if (_amiri != null) return _amiri!;
    final fontData = await rootBundle.load('assets/fonts/Amiri-Regular.ttf');
    _amiri = pw.Font.ttf(fontData);
    return _amiri!;
  }

  Future<pw.MemoryImage> _loadLogo() async { // <- load logo once
    if (_logoImage != null) return _logoImage!;
    final data = await rootBundle.load('assets/images/logo.png');
    _logoImage = pw.MemoryImage(data.buffer.asUint8List());
    return _logoImage!;
  }

  Future<Uint8List> generateInvoicePdf({
    required List<StockIn> records,
    required String companyName,
  }) async {
    final pdf = pw.Document();
    final arabicFont = await _loadArabicFont();
    final r0 = records.first;
    final logo = await _loadLogo(); // <- ensure bytes ready before build

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
                    child: pw.Image(logo, height: 42), // عدّل المقاس حسب الحاجة
                  ),
                  pw.SizedBox(height: 8),

                  // Header
                  pw.Text(
                    companyName,
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 12),

                  // Reworked header box: 2x2 table with proper directions
                  pw.Table(
                    border: pw.TableBorder.all(),
                    columnWidths: const {
                      0: pw.FlexColumnWidth(1),
                      1: pw.FlexColumnWidth(1),
                    },
                    children: [
                      pw.TableRow(children: [
                        // تبديل الأماكن هنا
                        _kvCell('Addition No:', r0.additionNumber),
                        _kvCell('Supplier:', r0.supplierName, valueRtl: true),
                      ]),
                      pw.TableRow(children: [
                        _kvCell('Date:', '${r0.date.day}/${r0.date.month}/${r0.date.year}'),
                        _kvCell('Warehouse:', r0.warehouseName),
                      ]),
                    ],
                  ),

                  pw.SizedBox(height: 18),

                  // Products table (من كل السجلات)
                  pw.Table(
                    border: pw.TableBorder.all(),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(2), // Record Id
                      1: const pw.FlexColumnWidth(2), // Product Id
                      2: const pw.FlexColumnWidth(4), // Product Name
                      3: const pw.FlexColumnWidth(1.5), // Qty
                      4: const pw.FlexColumnWidth(1.5), // Unit
                      5: const pw.FlexColumnWidth(3), // Notes
                    },
                    children: [
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                        children: [
                          _h('Record Id'),
                          _h('Product Id'),
                          _h('Product Name'),
                          _h('Qty'),
                          _h('Unit'),
                          _h('Notes'),
                        ],
                      ),
                      ...records.expand((rec) => rec.products.map((p) => pw.TableRow(
                        children: [
                          _c(rec.recordId, ltr: true),
                          _c(p.productId, ltr: true),
                          _c(p.productName), // RTL
                          _c(p.quantity.toString(), ltr: true),
                          _c(p.unit, ltr: true),
                          _c(rec.notes ?? ''),
                        ],
                      ))),
                    ],
                  ),

                  pw.SizedBox(height: 24),

                  // Signatures
                  pw.Container(
                    decoration: pw.BoxDecoration(border: pw.Border.all()),
                    child: pw.Row(children: [
                      _sig('Storekeeper'),
                      _sig('Review'),
                      _sig('Project Engineer'),
                    ]),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _h(String text) => pw.Padding(
        padding: const pw.EdgeInsets.all(8),
        child: pw.Text(text,
            textAlign: pw.TextAlign.center,
            textDirection: pw.TextDirection.ltr,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      );

  pw.Widget _c(String text, {bool ltr = false}) => pw.Padding(
        padding: const pw.EdgeInsets.all(8),
        child: pw.Text(
          text,
          textAlign: pw.TextAlign.center,
          textDirection: ltr ? pw.TextDirection.ltr : pw.TextDirection.rtl,
        ),
      );

  pw.Widget _sig(String title) => pw.Expanded(
        child: pw.Container(
          height: 80,
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(border: pw.Border(left: pw.BorderSide())),
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(title, textDirection: pw.TextDirection.ltr),
              pw.Container(height: 2, color: PdfColors.black, margin: const pw.EdgeInsets.symmetric(horizontal: 8)),
            ],
          ),
        ),
      );

  // label: value cell laid out LTR to keep order consistent
  pw.Widget _kvCell(String label, String value, {bool valueRtl = false}) => pw.Container(
        padding: const pw.EdgeInsets.all(10),
        child: pw.Directionality(
          textDirection: pw.TextDirection.ltr,
          child: pw.Row(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text(label,
                  textDirection: pw.TextDirection.ltr,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(width: 6),
              pw.Text(
                value,
                textDirection: valueRtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
              ),
            ],
          ),
        ),
      );
}