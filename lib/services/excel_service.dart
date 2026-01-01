import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import '../models/quote.dart';
import '../models/line_item.dart';
import '../models/company.dart';

class ExcelImportData {
  final List<LineItem> workItems;
  final List<LineItem> equipmentItems;
  final Map<String, dynamic> summaryData;

  ExcelImportData({
    required this.workItems,
    required this.equipmentItems,
    required this.summaryData,
  });
}

class ExcelService {
  Future<File> generateQuoteExcel(Quote quote, List<LineItem> lineItems, Company company) async {
    try {
      final excel = Excel.createExcel();
      
      // Удаляем стандартный лист
      excel.delete('Sheet1');
      
      // Создаём один лист как в примере
      final sheet = excel['Коммерческое предложение'];
      
      // Заполняем шапку как в примере
      _fillHeader(sheet, quote, company);
      
      // Заполняем все позиции в одной таблице
      _fillAllItems(sheet, lineItems);
      
      // Сохраняем файл
      final output = await getTemporaryDirectory();
      final fileName = 'Коммерческое_предложение_${quote.customerName.replaceAll(RegExp(r'[^\w\s-]'), '_')}.xlsx';
      final file = File('${output.path}/$fileName');
      
      final bytes = excel.save();
      if (bytes != null && bytes.isNotEmpty) {
        await file.writeAsBytes(bytes);
        return file;
      } else {
        throw Exception('Не удалось создать Excel файл - пустые данные');
      }
    } catch (e) {
      throw Exception('Ошибка создания Excel файла: $e');
    }
  }
  
  void _fillHeader(Sheet sheet, Quote quote, Company company) {
    // Шапка как в примере
    _appendRow(sheet, ['ООО "ВЕКТОР"']);
    _appendRow(sheet, ['ИНН 1650326450 КПП 165001001']);
    _appendRow(sheet, ['ОГРН 1181690098364']);
    _appendRow(sheet, ['Юридический адрес: 424000, г. Йошкар-Ола, ул. Якимова, д. 1']);
    _appendRow(sheet, ['Тел.: +7 (927) 880-11-22']);
    _appendRow(sheet, ['E-mail: mail@mail.ru']);
    _appendRow(sheet, ['']);
    
    // Информация о предложении
    _appendRow(sheet, ['Коммерческое предложение']);
    _appendRow(sheet, ['от ${DateTime.now().day.toString().padLeft(2, '0')}.${DateTime.now().month.toString().padLeft(2, '0')}.${DateTime.now().year} г.']);
    _appendRow(sheet, ['']);
    
    // Информация о клиенте
    _appendRow(sheet, ['Заказчик: ${quote.customerName}']);
    if (quote.objectName != null) {
      _appendRow(sheet, ['Объект: ${quote.objectName}']);
    }
    if (quote.address != null) {
      _appendRow(sheet, ['Адрес: ${quote.address}']);
    }
    _appendRow(sheet, ['']);
  }
  
  void _fillAllItems(Sheet sheet, List<LineItem> lineItems) {
    // Заголовки таблицы как в примере
    _appendRow(sheet, ['№', 'Наименование работ', 'Ед. изм.', 'Кол-во', 'Цена за ед., руб.', 'Стоимость, руб.']);
    
    // Сортируем позиции: сначала работы, потом оборудование
    final workItems = lineItems.where((item) => item.section == LineItemSection.work).toList();
    final equipmentItems = lineItems.where((item) => item.section == LineItemSection.equipment).toList();
    
    final allItems = [...workItems, ...equipmentItems];
    
    // Заполняем позиции
    for (int i = 0; i < allItems.length; i++) {
      final item = allItems[i];
      _appendRow(sheet, [
        i + 1,
        item.description,
        item.unit,
        item.quantity,
        item.price,
        item.amount,
      ]);
    }
    
    // Итого
    final totalAmount = lineItems.fold(0.0, (sum, item) => sum + item.amount);
    _appendRow(sheet, []);
    _appendRow(sheet, ['', '', '', '', 'Итого:', totalAmount]);
    
    // Форматирование
    _formatSheet(sheet);
  }
  
  void _formatSheet(Sheet sheet) {
    // Форматирование заголовков
    for (int row = 0; row < sheet.maxRows; row++) {
      for (int col = 0; col < sheet.maxCols; col++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
        
        // Заголовки таблицы
        if (row == 7) { // Строка с заголовками таблицы
          cell.cellStyle = CellStyle(
            bold: true,
            horizontalAlign: HorizontalAlign.Center,
            verticalAlign: VerticalAlign.Center,
          );
        }
        
        // Итоговая строка
        if (row == sheet.maxRows - 1) {
          cell.cellStyle = CellStyle(
            bold: true,
            horizontalAlign: HorizontalAlign.Right,
          );
        }
        
        // Широкие колонки
        if (col == 1) { // Наименование работ
          sheet.setColWidth(col, 50);
        } else if (col == 4 || col == 5) { // Цена и стоимость
          sheet.setColWidth(col, 15);
        } else {
          sheet.setColWidth(col, 10);
        }
      }
    }
  }
  
  void _appendRow(Sheet sheet, List<dynamic> values) {
    final rowIndex = sheet.maxRows;
    for (int col = 0; col < values.length; col++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIndex));
      final value = values[col];
      
      // Правильное присвоение значения в зависимости от типа
      if (value == null) {
        cell.value = TextCellValue('');
      } else if (value is String) {
        cell.value = TextCellValue(value);
      } else if (value is int) {
        cell.value = IntCellValue(value);
      } else if (value is double) {
        cell.value = DoubleCellValue(value);
      } else {
        cell.value = TextCellValue(value.toString());
      }
    }
  }

  Future<ExcelImportData?> importFromExcel() async {
    try {
      // Выбор файла
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result == null || result.files.isEmpty) {
        return null;
      }

      final file = File(result.files.first.path!);
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);

      final workItems = <LineItem>[];
      final equipmentItems = <LineItem>[];
      final summaryData = <String, dynamic>{};

      // Импорт из листов
      for (final sheetName in excel.tables.keys) {
        final sheet = excel.tables[sheetName]!;
        
        if (sheetName == 'Работы') {
          workItems.addAll(_parseItemsSheet(sheet, LineItemSection.work));
        } else if (sheetName == 'Оборудование') {
          equipmentItems.addAll(_parseItemsSheet(sheet, LineItemSection.equipment));
        } else if (sheetName == 'Сводка') {
          summaryData.addAll(_parseSummarySheet(sheet));
        }
      }

      return ExcelImportData(
        workItems: workItems,
        equipmentItems: equipmentItems,
        summaryData: summaryData,
      );
    } catch (e) {
      throw Exception('Ошибка импорта из Excel: $e');
    }
  }

  List<LineItem> _parseItemsSheet(Sheet sheet, LineItemSection section) {
    final items = <LineItem>[];
    
    // Пропускаем заголовок (первая строка)
    for (int row = 1; row < sheet.maxRows; row++) {
      try {
        final positionCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
        final descriptionCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row));
        final unitCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row));
        final quantityCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row));
        final priceCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row));
        final amountCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row));
        final noteCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row));

        final description = _getCellValue(descriptionCell);
        if (description.isEmpty) continue;

        final item = LineItem(
          id: null,
          quoteId: 0,
          position: _getCellValue(positionCell).isEmpty ? 1 : int.tryParse(_getCellValue(positionCell)) ?? 1,
          section: section,
          description: description,
          unit: _getCellValue(unitCell).isEmpty ? 'шт.' : _getCellValue(unitCell),
          quantity: double.tryParse(_getCellValue(quantityCell)) ?? 1.0,
          price: double.tryParse(_getCellValue(priceCell)) ?? 0.0,
          amount: double.tryParse(_getCellValue(amountCell)) ?? 0.0,
          note: _getCellValue(noteCell).isEmpty ? null : _getCellValue(noteCell),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        items.add(item);
      } catch (e) {
        // Пропускаем строки с ошибками
        continue;
      }
    }

    return items;
  }

  Map<String, dynamic> _parseSummarySheet(Sheet sheet) {
    final data = <String, dynamic>{};
    
    for (int row = 0; row < sheet.maxRows; row++) {
      try {
        final keyCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
        final valueCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row));
        
        final key = _getCellValue(keyCell);
        final value = _getCellValue(valueCell);
        
        if (key.endsWith(':')) {
          final cleanKey = key.substring(0, key.length - 1);
          data[cleanKey] = value;
        }
      } catch (e) {
        continue;
      }
    }
    
    return data;
  }

  String _getCellValue(dynamic cell) {
    if (cell == null || cell.value == null) return '';
    
    if (cell.value is TextCellValue) {
      return (cell.value as TextCellValue).value.toString();
    } else if (cell.value is IntCellValue) {
      return (cell.value as IntCellValue).value.toString();
    } else if (cell.value is DoubleCellValue) {
      return (cell.value as DoubleCellValue).value.toString();
    }
    
    return cell.value?.toString() ?? '';
  }
}
