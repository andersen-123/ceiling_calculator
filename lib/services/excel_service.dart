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
      
      // Создаём листы
      final summarySheet = excel['Сводка'];
      final workSheet = excel['Работы'];
      final equipmentSheet = excel['Оборудование'];
      
      // Заполняем сводку
      _fillSummarySheet(summarySheet, quote, company);
      
      // Разделяем позиции по разделам
      final workItems = lineItems.where((item) => item.section == LineItemSection.work).toList();
      final equipmentItems = lineItems.where((item) => item.section == LineItemSection.equipment).toList();
      
      // Заполняем листы
      if (workItems.isNotEmpty) {
        _fillItemsSheet(workSheet, workItems, quote.currencyCode);
      }
      
      if (equipmentItems.isNotEmpty) {
        _fillItemsSheet(equipmentSheet, equipmentItems, quote.currencyCode);
      }
      
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
  
  void _fillSummarySheet(Sheet sheet, Quote quote, Company company) {
    // Информация о компании
    _appendRow(sheet, ['ИНФОРМАЦИЯ О КОМПАНИИ']);
    _appendRow(sheet, ['Название:', company.name]);
    if (company.phone != null) _appendRow(sheet, ['Телефон:', company.phone!]);
    if (company.email != null) _appendRow(sheet, ['Email:', company.email!]);
    if (company.website != null) _appendRow(sheet, ['Сайт:', company.website!]);
    if (company.address != null) _appendRow(sheet, ['Адрес:', company.address!]);
    _appendRow(sheet, []);
    
    // Информация о клиенте и объекте
    _appendRow(sheet, ['ИНФОРМАЦИЯ О КЛИЕНТЕ И ОБЪЕКТЕ']);
    _appendRow(sheet, ['Клиент:', quote.customerName]);
    if (quote.customerPhone != null) _appendRow(sheet, ['Телефон:', quote.customerPhone!]);
    if (quote.customerEmail != null) _appendRow(sheet, ['Email:', quote.customerEmail!]);
    if (quote.objectName != null) _appendRow(sheet, ['Объект:', quote.objectName!]);
    if (quote.address != null) _appendRow(sheet, ['Адрес:', quote.address!]);
    if (quote.areaS != null) _appendRow(sheet, ['Площадь:', '${quote.areaS} м²']);
    if (quote.perimeterP != null) _appendRow(sheet, ['Периметр:', '${quote.perimeterP} м.п.']);
    if (quote.heightH != null) _appendRow(sheet, ['Высота:', '${quote.heightH} м']);
    if (quote.ceilingSystem != null) _appendRow(sheet, ['Система:', quote.ceilingSystem!]);
    _appendRow(sheet, []);
    
    // Итоги
    _appendRow(sheet, ['ИТОГИ']);
    _appendRow(sheet, ['Итого по работам:', quote.subtotalWork, quote.currencyCode]);
    _appendRow(sheet, ['Итого по оборудованию:', quote.subtotalEquipment, quote.currencyCode]);
    _appendRow(sheet, ['ОБЩАЯ СУММА:', quote.totalAmount, quote.currencyCode]);
    _appendRow(sheet, []);
    
    // Условия и примечания
    if (quote.paymentTerms != null || quote.installationTerms != null || quote.notes != null) {
      _appendRow(sheet, ['УСЛОВИЯ И ПРИМЕЧАНИЯ']);
      if (quote.paymentTerms != null) _appendRow(sheet, ['Условия оплаты:', quote.paymentTerms!]);
      if (quote.installationTerms != null) _appendRow(sheet, ['Условия монтажа:', quote.installationTerms!]);
      if (quote.notes != null) _appendRow(sheet, ['Примечания:', quote.notes!]);
    }
    
    // Форматирование заголовков
    for (int row = 0; row < sheet.maxRows; row++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
      if (cell.value?.toString().contains('ИНФОРМАЦИЯ') == true ||
          cell.value?.toString().contains('ИТОГИ') == true ||
          cell.value?.toString().contains('УСЛОВИЯ') == true) {
        cell.cellStyle = CellStyle(
          bold: true,
        );
      }
    }
  }
  
  void _fillItemsSheet(Sheet sheet, List<LineItem> items, String currency) {
    // Заголовки таблицы
    _appendRow(sheet, ['№', 'Описание', 'Ед.изм.', 'Кол-во', 'Цена', 'Сумма', 'Примечание']);
    
    // Данные
    for (final item in items) {
      _appendRow(sheet, [
        item.position,
        item.description,
        item.unit,
        item.quantity,
        item.price,
        item.amount,
        item.note ?? '',
      ]);
    }
    
    // Итого по разделу
    final subtotal = items.fold(0.0, (sum, item) => sum + item.amount);
    _appendRow(sheet, []);
    _appendRow(sheet, ['ИТОГО:', '', '', '', '', subtotal, currency]);
    
    // Форматирование
    // Заголовки
    for (int col = 0; col <= 6; col++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
      cell.cellStyle = CellStyle(
        bold: true,
      );
    }
    
    // Итоговая строка
    final totalRow = sheet.maxRows - 1;
    for (int col = 0; col <= 6; col++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: totalRow));
      cell.cellStyle = CellStyle(
        bold: true,
      );
    }
    
    // Автоширина колонок (удалено - метод не поддерживается)
    // for (int col = 0; col <= 6; col++) {
    //   sheet.setColWidth(col, 20);
    // }
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

  String _getCellValue(Cell cell) {
    if (cell.value == null) return '';
    
    if (cell.value is TextCellValue) {
      return (cell.value as TextCellValue).value;
    } else if (cell.value is IntCellValue) {
      return (cell.value as IntCellValue).value.toString();
    } else if (cell.value is DoubleCellValue) {
      return (cell.value as DoubleCellValue).value.toString();
    }
    
    return cell.value.toString();
  }
}
