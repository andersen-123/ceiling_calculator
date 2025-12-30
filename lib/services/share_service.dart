import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';

class ShareService {
  static Future<void> shareFile(File file, {String? subject, String? text}) async {
    try {
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: subject,
        text: text,
      );
    } catch (e) {
      throw Exception('Ошибка при отправке файла: $e');
    }
  }
  
  static Future<File?> pickFileForRestore() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['db', 'backup'],
      );
      
      if (result != null && result.files.single.path != null) {
        return File(result.files.single.path!);
      }
      
      return null;
    } catch (e) {
      throw Exception('Ошибка при выборе файла: $e');
    }
  }
  
  static Future<void> shareQuote({
    required File pdfFile,
    required File? excelFile,
    required String customerName,
    required double totalAmount,
    required String currency,
  }) async {
    final files = <XFile>[XFile(pdfFile.path)];
    
    if (excelFile != null) {
      files.add(XFile(excelFile.path));
    }
    
    final subject = 'Коммерческое предложение: $customerName';
    final text = 'Добрый день!\n\n'
        'Направляю Вам коммерческое предложение на натяжные потолки.\n'
        'Общая сумма: ${totalAmount.toStringAsFixed(2)} $currency\n\n'
        'С уважением,\n'
        'Ваша компания';
    
    try {
      await Share.shareXFiles(
        files,
        subject: subject,
        text: text,
      );
    } catch (e) {
      throw Exception('Ошибка при отправке предложения: $e');
    }
  }
}
