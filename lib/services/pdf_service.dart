import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import '../models/quote.dart';
import '../models/line_item.dart';
import '../models/company.dart';

class PdfService {
  Future<File> generateQuotePdf(Quote quote, List<LineItem> lineItems, Company company) async {
    final pdf = await generateQuotePdfDocument(quote, lineItems, company, PdfPageFormat.a4);
    
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/Коммерческое предложение_${quote.customerName}.pdf');
    await file.writeAsBytes(await pdf.save());
    
    return file;
  }

  Future<pw.Document> generateQuotePdfDocument(
    Quote quote,
    List<LineItem> lineItems,
    Company company,
    PdfPageFormat format,
  ) async {
    final pdf = pw.Document(pageMode: PdfPageMode.outlines);

    final font = await PdfGoogleFonts.nunitoRegular();
    final boldFont = await PdfGoogleFonts.nunitoBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          _buildHeader(company, font, boldFont),
          pw.SizedBox(height: 30),
          _buildCustomerInfo(quote, font, boldFont),
          pw.SizedBox(height: 20),
          _buildTitle(font, boldFont),
          pw.SizedBox(height: 20),
          ..._buildLineItemsTable(lineItems, font, boldFont),
          pw.SizedBox(height: 20),
          _buildTotals(quote, font, boldFont),
          if (quote.paymentTerms != null || quote.installationTerms != null || quote.notes != null) ...[
            pw.SizedBox(height: 30),
            _buildTermsAndNotes(quote, font, boldFont),
          ],
          pw.SizedBox(height: 40),
          _buildFooter(company, font),
        ],
      ),
    );

    return pdf;
  }

  pw.Widget _buildHeader(Company company, pw.Font font, pw.Font boldFont) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  company.name,
                  style: pw.TextStyle(font: boldFont, fontSize: 20),
                ),
                if (company.phone != null) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(
                    company.phone!,
                    style: pw.TextStyle(font: font, fontSize: 12),
                  ),
                ],
                if (company.email != null) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(
                    company.email!,
                    style: pw.TextStyle(font: font, fontSize: 12),
                  ),
                ],
                if (company.website != null) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(
                    company.website!,
                    style: pw.TextStyle(font: font, fontSize: 12),
                  ),
                ],
              ],
            ),
            pw.Container(
              width: 80,
              height: 80,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: company.logoPath != null
                  ? pw.Image(pw.MemoryImage(File(company.logoPath!).readAsBytesSync()))
                  : pw.Center(
                      child: pw.Text(
                        'LOGO',
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 10,
                          color: PdfColors.grey,
                        ),
                      ),
                    ),
            ),
          ],
        ),
        pw.Divider(thickness: 1, color: PdfColors.grey300),
      ],
    );
  }

  pw.Widget _buildCustomerInfo(Quote quote, pw.Font font, pw.Font boldFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Информация о клиенте и объекте',
            style: pw.TextStyle(font: boldFont, fontSize: 14),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Клиент:', quote.customerName, font),
                    if (quote.customerPhone != null)
                      _buildInfoRow('Телефон:', quote.customerPhone!, font),
                    if (quote.customerEmail != null)
                      _buildInfoRow('Email:', quote.customerEmail!, font),
                  ],
                ),
              ),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (quote.objectName != null)
                      _buildInfoRow('Объект:', quote.objectName!, font),
                    if (quote.address != null)
                      _buildInfoRow('Адрес:', quote.address!, font),
                    if (quote.areaS != null)
                      _buildInfoRow('Площадь:', '${quote.areaS} м²', font),
                    if (quote.perimeterP != null)
                      _buildInfoRow('Периметр:', '${quote.perimeterP} м.п.', font),
                    if (quote.heightH != null)
                      _buildInfoRow('Высота:', '${quote.heightH} м', font),
                    if (quote.ceilingSystem != null)
                      _buildInfoRow('Система:', quote.ceilingSystem!, font),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildInfoRow(String label, String value, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 80,
            child: pw.Text(
              label,
              style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700),
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(font: font, fontSize: 10),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTitle(pw.Font font, pw.Font boldFont) {
    return pw.Center(
      child: pw.Text(
        'РАСЧЁТ СТОИМОСТИ НАТЯЖНОГО ПОТОЛКА',
        style: pw.TextStyle(font: boldFont, fontSize: 16),
      ),
    );
  }

  List<pw.Widget> _buildLineItemsTable(List<LineItem> lineItems, pw.Font font, pw.Font boldFont) {
    final workItems = lineItems.where((item) => item.section == LineItemSection.work).toList();
    final equipmentItems = lineItems.where((item) => item.section == LineItemSection.equipment).toList();

    final result = <pw.Widget>[];

    if (workItems.isNotEmpty) {
      result.add(_buildSectionTable('Работы', workItems, font, boldFont));
      result.add(pw.SizedBox(height: 20));
    }

    if (equipmentItems.isNotEmpty) {
      result.add(_buildSectionTable('Оборудование', equipmentItems, font, boldFont));
    }

    return result;
  }

  pw.Widget _buildSectionTable(String title, List<LineItem> items, pw.Font font, pw.Font boldFont) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(font: boldFont, fontSize: 14, color: PdfColors.blue800),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FixedColumnWidth(30),
            1: const pw.FlexColumnWidth(3),
            2: const pw.FlexColumnWidth(1),
            3: const pw.FlexColumnWidth(1),
            4: const pw.FlexColumnWidth(1),
            5: const pw.FlexColumnWidth(2),
          },
          children: [
            _buildTableHeader(font, boldFont),
            ...items.map((item) => _buildTableRow(item, font)),
          ],
        ),
      ],
    );
  }

  pw.TableRow _buildTableHeader(pw.Font font, pw.Font boldFont) {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
      children: [
        _buildTableCell('№', boldFont, isHeader: true),
        _buildTableCell('Описание', boldFont, isHeader: true),
        _buildTableCell('Ед.изм.', boldFont, isHeader: true),
        _buildTableCell('Кол-во', boldFont, isHeader: true),
        _buildTableCell('Цена', boldFont, isHeader: true),
        _buildTableCell('Сумма', boldFont, isHeader: true),
      ],
    );
  }

  pw.TableRow _buildTableRow(LineItem item, pw.Font font) {
    return pw.TableRow(
      children: [
        _buildTableCell(item.position.toString(), font),
        _buildTableCell(item.description, font),
        _buildTableCell(item.unit, font),
        _buildTableCell(item.quantity.toStringAsFixed(2), font, align: pw.Alignment.centerRight),
        _buildTableCell('${item.price.toStringAsFixed(2)} ${item.currencyCode}', font, align: pw.Alignment.centerRight),
        _buildTableCell('${item.amount.toStringAsFixed(2)} ${item.currencyCode}', font, align: pw.Alignment.centerRight),
      ],
    );
  }

  pw.Widget _buildTableCell(String text, pw.Font font, {bool isHeader = false, pw.Alignment? align}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      alignment: align ?? (isHeader ? pw.Alignment.center : pw.Alignment.centerLeft),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  pw.Widget _buildTotals(Quote quote, pw.Font font, pw.Font boldFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          if (quote.subtotalWork > 0) ...[
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Итого по работам:', style: pw.TextStyle(font: font, fontSize: 12)),
                pw.Text(
                  '${quote.subtotalWork.toStringAsFixed(2)} ${quote.currencyCode}',
                  style: pw.TextStyle(font: boldFont, fontSize: 12),
                ),
              ],
            ),
            pw.SizedBox(height: 8),
          ],
          if (quote.subtotalEquipment > 0) ...[
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Итого по оборудованию:', style: pw.TextStyle(font: font, fontSize: 12)),
                pw.Text(
                  '${quote.subtotalEquipment.toStringAsFixed(2)} ${quote.currencyCode}',
                  style: pw.TextStyle(font: boldFont, fontSize: 12),
                ),
              ],
            ),
            pw.SizedBox(height: 8),
          ],
          pw.Divider(color: PdfColors.grey400),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'ИТОГО:',
                style: pw.TextStyle(font: boldFont, fontSize: 14),
              ),
              pw.Text(
                '${quote.totalAmount.toStringAsFixed(2)} ${quote.currencyCode}',
                style: pw.TextStyle(font: boldFont, fontSize: 16, color: PdfColors.blue800),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTermsAndNotes(Quote quote, pw.Font font, pw.Font boldFont) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (quote.paymentTerms != null) ...[
          pw.Text(
            'Условия оплаты:',
            style: pw.TextStyle(font: boldFont, fontSize: 12),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            quote.paymentTerms!,
            style: pw.TextStyle(font: font, fontSize: 10),
          ),
          pw.SizedBox(height: 12),
        ],
        if (quote.installationTerms != null) ...[
          pw.Text(
            'Условия монтажа:',
            style: pw.TextStyle(font: boldFont, fontSize: 12),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            quote.installationTerms!,
            style: pw.TextStyle(font: font, fontSize: 10),
          ),
          pw.SizedBox(height: 12),
        ],
        if (quote.notes != null) ...[
          pw.Text(
            'Примечания:',
            style: pw.TextStyle(font: boldFont, fontSize: 12),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            quote.notes!,
            style: pw.TextStyle(font: font, fontSize: 10),
          ),
        ],
      ],
    );
  }

  pw.Widget _buildFooter(Company company, pw.Font font) {
    return pw.Column(
      children: [
        pw.Divider(thickness: 1, color: PdfColors.grey300),
        pw.SizedBox(height: 8),
        if (company.address != null)
          pw.Text(
            company.address!,
            style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey600),
          ),
        if (company.footerNote != null) ...[
          pw.SizedBox(height: 4),
          pw.Text(
            company.footerNote!,
            style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey600),
          ),
        ],
        pw.SizedBox(height: 4),
        pw.Text(
          'Документ сформирован ${DateTime.now().day.toString().padLeft(2, '0')}.${DateTime.now().month.toString().padLeft(2, '0')}.${DateTime.now().year}',
          style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey500),
        ),
      ],
    );
  }
}
