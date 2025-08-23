import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import '../backend/stock_out_logic.dart';
import '../backend/print_stock_out_logic.dart';

class PrintStockOutScreen extends StatefulWidget {
  final StockOut stockOut;

  const PrintStockOutScreen({
    Key? key,
    required this.stockOut,
  }) : super(key: key);

  @override
  State<PrintStockOutScreen> createState() => _PrintStockOutScreenState();
}

class _PrintStockOutScreenState extends State<PrintStockOutScreen> {
  final PrintStockOutLogic _printLogic = PrintStockOutLogic();
  late Future<Uint8List> _pdfFuture;

  @override
  void initState() {
    super.initState();
    _pdfFuture = _printLogic.generateStockOutPdf(
      stockOut: widget.stockOut,
      companyName: 'VA - TECH WABAG CO.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRTL = Localizations.localeOf(context).languageCode == 'ar';
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isRTL 
            ? 'معاينة إذن الصرف - ${widget.stockOut.exchangeNumber}'
            : 'Stock Out Preview - ${widget.stockOut.exchangeNumber}'
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _printDocument,
            tooltip: isRTL ? 'طباعة' : 'Print',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _downloadPdf,
            tooltip: isRTL ? 'تحميل PDF' : 'Download PDF',
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) => _pdfFuture,
        pdfFileName: 'stock_out_${widget.stockOut.exchangeNumber}.pdf',
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
            SnackBar(
              content: Text(
                isRTL ? 'تم إرسال إذن الصرف للطباعة' : 'Stock out sent to printer'
              ),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  Future<void> _printDocument() async {
    try {
      final pdfBytes = await _pdfFuture;
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: 'stock_out_${widget.stockOut.exchangeNumber}',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error printing: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _downloadPdf() async {
    try {
      final pdfBytes = await _pdfFuture;
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'stock_out_${widget.stockOut.exchangeNumber}.pdf',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ الملف بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}