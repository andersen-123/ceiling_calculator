import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import '../models/quote.dart';
import '../models/line_item.dart';
import '../models/company.dart';

class ExcelService {
  Future<File> generateQuoteExcel(Quote quote, List<LineItem> lineItems, Company company) async {
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
    final file = File('${output.path}/Коммерческое предложение_${quote.customerName}.xlsx');
    
    final bytes = excel.save();
    await file.writeAsBytes(bytes!);
    
    return file;
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
      cell.value = values[col];
    }
  }
}
