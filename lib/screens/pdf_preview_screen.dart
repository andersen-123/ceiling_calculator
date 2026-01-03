import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../models/quote.dart';
import '../models/line_item.dart';
import '../models/company.dart';
import '../services/pdf_service.dart';

class PdfPreviewScreen extends StatefulWidget {
  final Quote quote;
  final List<LineItem> lineItems;
  final Company company;

  const PdfPreviewScreen({
    super.key,
    required this.quote,
    required this.lineItems,
    required this.company,
  });

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  final PdfService _pdfService = PdfService();
  bool _isGenerating = false;

  Future<void> _sharePdf() async {
    setState(() => _isGenerating = true);

    try {
      final file = await _pdfService.generateQuotePdf(
        widget.quote,
        widget.lineItems,
        widget.company,
      );

      // Используем SharePlus вместо Printing.sharePdf
      await Share.shareXFiles([XFile(file.path)],
          text: 'Коммерческое предложение для ${widget.quote.customerName}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка создания PDF: $e')),
        );
      }
    }

    setState(() => _isGenerating = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Предпросмотр PDF'),
        actions: [
          if (_isGenerating)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _sharePdf,
            ),
        ],
      ),
      body: PdfPreview(
        build: (format) => _pdfService.generateQuotePdfDocument(
          widget.quote,
          widget.lineItems,
          widget.company,
          format,
        ),
        allowSharing: false,
        allowPrinting: true,
        pdfFileName:
            'Коммерческое предложение_${widget.quote.customerName}.pdf',
      ),
    );
  }
}
