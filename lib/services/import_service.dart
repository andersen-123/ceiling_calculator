import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import '../models/quote.dart';
import '../models/line_item.dart';
import '../models/company.dart';
import 'package:sqflite/sqflite.dart';

class ImportService {
  static Future<List<Map<String, dynamic>>> importExcelFile(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      
      final List<Map<String, dynamic>> quotes = [];
      
      // Проходим по всем листам
      for (final sheetName in excel.tables.keys) {
        final sheet = excel.tables[sheetName]!;
        
        if (sheet.rows.isEmpty) continue;
        
        // Пропускаем заголовок (первая строка)
        if (sheet.rows.length < 2) continue;
        
        final List<LineItem> lineItems = [];
        String? customerName;
        String? objectName;
        String? address;
        
        // Анализируем строки
        for (int i = 1; i < sheet.rows.length; i++) {
          final row = sheet.rows[i];
          if (row.isEmpty) continue;
          
          // Получаем значения ячеек
          final description = _getCellValue(row[0]);
          final quantity = _getNumericValue(row[1]);
          final unit = _getCellValue(row[2]) ?? 'шт.';
          final price = _getNumericValue(row[3]);
          final note = _getCellValue(row[4]);
          
          // Проверяем, это строка с данными клиента или с позицией
          if (description?.toLowerCase().contains('клиент') == true || 
              description?.toLowerCase().contains('заказчик') == true) {
            customerName = _getCellValue(row[1]);
          } else if (description?.toLowerCase().contains('объект') == true) {
            objectName = _getCellValue(row[1]);
          } else if (description?.toLowerCase().contains('адрес') == true) {
            address = _getCellValue(row[1]);
          } else if (description != null && quantity != null && price != null) {
            // Это позиция для добавления
            final lineItem = LineItem(
              id: null,
              quoteId: 0,
              position: lineItems.length + 1,
              section: LineItemSection.equipment, // По умолчанию оборудование
              description: description,
              unit: unit,
              quantity: quantity,
              price: price,
              amount: quantity * price,
              note: note,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
            lineItems.add(lineItem);
          }
        }
        
        if (lineItems.isNotEmpty) {
          // Создаем предложение
          final subtotalWork = 0.0;
          final subtotalEquipment = lineItems.fold(0.0, (sum, item) => sum + item.amount);
          final totalAmount = subtotalWork + subtotalEquipment;
          
          final quote = Quote(
            id: null,
            companyId: 1,
            customerName: customerName ?? 'Клиент из ${sheetName}',
            customerPhone: null,
            customerEmail: null,
            objectName: objectName,
            address: address,
            areaS: null,
            perimeterP: null,
            heightH: null,
            ceilingSystem: null,
            status: QuoteStatus.draft,
            paymentTerms: null,
            installationTerms: null,
            notes: null,
            subtotalWork: subtotalWork,
            subtotalEquipment: subtotalEquipment,
            totalAmount: totalAmount,
            currencyCode: 'RUB',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          
          quotes.add({
            'quote': quote,
            'lineItems': lineItems,
            'sheetName': sheetName,
          });
        }
      }
      
      return quotes;
    } catch (e) {
      throw Exception('Ошибка импорта Excel файла: $e');
    }
  }
  
  static String? _getCellValue(dynamic cell) {
    if (cell == null) return null;
    return cell.value?.toString();
  }
  
  static double? _getNumericValue(dynamic cell) {
    if (cell == null) return null;
    final value = cell.value;
    if (value == null) return null;
    
    if (value is num) {
      return value.toDouble();
    } else if (value is String) {
      return double.tryParse(value.replaceAll(RegExp(r'[^\d.,]'), '').replaceAll(',', '.'));
    }
    
    return null;
  }
  
  static Future<File> saveImportedQuotes(List<Map<String, dynamic>> importedQuotes) async {
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/imported_quotes_summary.txt');
    
    final buffer = StringBuffer();
    buffer.writeln('Импортированные предложения:');
    buffer.writeln('=' * 50);
    
    for (int i = 0; i < importedQuotes.length; i++) {
      final data = importedQuotes[i];
      final quote = data['quote'] as Quote;
      final lineItems = data['lineItems'] as List<LineItem>;
      final sheetName = data['sheetName'] as String;
      
      buffer.writeln('\n${i + 1}. Лист: $sheetName');
      buffer.writeln('   Клиент: ${quote.customerName}');
      buffer.writeln('   Объект: ${quote.objectName ?? "не указан"}');
      buffer.writeln('   Сумма: ${quote.totalAmount.toStringAsFixed(2)} ₽');
      buffer.writeln('   Позиций: ${lineItems.length}');
      
      for (final item in lineItems) {
        buffer.writeln('   - ${item.description} (${item.quantity} ${item.unit} × ${item.price} ₽ = ${item.amount} ₽)');
      }
    }
    
    await file.writeAsString(buffer.toString());
    return file;
  }
}
