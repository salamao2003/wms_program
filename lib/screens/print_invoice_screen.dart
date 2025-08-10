import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import '../backend/stock_in_logic.dart';
import '../backend/print_invoice_logic.dart';

class PrintInvoiceScreen extends StatefulWidget {
  final List<StockIn> records;

  const PrintInvoiceScreen({
    Key? key,
    required this.records,
  }) : super(key: key);

  @override
  State<PrintInvoiceScreen> createState() => _PrintInvoiceScreenState();
}

class _PrintInvoiceScreenState extends State<PrintInvoiceScreen> {
  final PrintInvoiceLogic _printLogic = PrintInvoiceLogic();
  late Future<Uint8List> _pdfFuture;

  @override
  void initState() {
    super.initState();
    _pdfFuture = _printLogic.generateInvoicePdf(
      records: widget.records,
      companyName: 'VA - TECH WABAG CO.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final additionNumber = widget.records.first.additionNumber;
    return Scaffold(
      appBar: AppBar(
        title: Text('معاينة الفاتورة - $additionNumber'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _printInvoice,
            tooltip: 'طباعة',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _downloadPdf,
            tooltip: 'تحميل PDF',
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) => _pdfFuture,
        pdfFileName: 'invoice_$additionNumber.pdf',
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        initialPageFormat: PdfPageFormat.a4,
        previewPageMargin: const EdgeInsets.all(16),
        actions: [
          PdfPreviewAction(
            icon: const Icon(Icons.save_alt, color: Colors.white),
            onPressed: (context, build, pageFormat) async {
              await _downloadPdf();
            },
          ),
        ],
        onPrinted: (context) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إرسال الفاتورة للطباعة'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  Future<void> _printInvoice() async {
    try {
      final pdfBytes = await _pdfFuture;
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: 'invoice_${widget.records.first.additionNumber}',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في الطباعة: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _downloadPdf() async {
    try {
      final pdfBytes = await _pdfFuture;
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'invoice_${widget.records.first.additionNumber}.pdf',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ الفاتورة بنجاح'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في الحفظ: $e'), backgroundColor: Colors.red),
      );
    }
  }
}