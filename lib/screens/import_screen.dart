import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import '../services/import_service.dart';
import '../models/quote.dart';
import '../models/line_item.dart';
import '../database/database_helper.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _importedQuotes = [];
  String? _fileName;

  Future<void> _pickAndImportFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        setState(() {
          _isLoading = true;
          _fileName = result.files.single.name;
        });

        final importedQuotes = await ImportService.importExcelFile(file);
        
        setState(() {
          _isLoading = false;
          _importedQuotes = importedQuotes;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Импортировано ${importedQuotes.length} предложений'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка импорта: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveAllQuotes() async {
    if (_importedQuotes.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      for (final quoteData in _importedQuotes) {
        final quote = quoteData['quote'] as Quote;
        final lineItems = quoteData['lineItems'] as List<LineItem>;

        // Сохраняем предложение
        final newQuoteId = await DatabaseHelper.instance.insert('quotes', quote.toMap());

        // Сохраняем позиции
        for (final item in lineItems) {
          final itemWithQuoteId = item.copyWith(quoteId: newQuoteId);
          await DatabaseHelper.instance.insert('line_items', itemWithQuoteId.toMap());
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Все предложения успешно сохранены'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Возвращаем true для обновления списка
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка сохранения: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Импорт предложений',
          style: TextStyle(
            color: Color(0xFF1D1D1F),
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF007AFF)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Кнопка импорта
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xFF007AFF), Color(0xFF0056CC)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF007AFF).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isLoading ? null : _pickAndImportFile,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      children: [
                        Icon(
                          Icons.cloud_upload_outlined,
                          size: 48,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _isLoading ? 'Импортирование...' : 'Выбрать XLSX файл',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_fileName != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Файл: $_fileName',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Список импортированных предложений
            Expanded(
              child: _importedQuotes.isEmpty
                  ? _buildEmptyState()
                  : _buildImportedQuotesList(),
            ),
            
            // Кнопка сохранения
            if (_importedQuotes.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF34C759), Color(0xFF28A745)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF34C759).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isLoading ? null : _saveAllQuotes,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.save, color: Colors.white, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Сохранить все предложения',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 64,
              color: const Color(0xFF86868B),
            ),
            const SizedBox(height: 16),
            Text(
              'Нет импортированных данных',
              style: TextStyle(
                fontSize: 18,
                color: const Color(0xFF86868B),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Выберите XLSX файл для импорта предложений',
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF86868B),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportedQuotesList() {
    return ListView.builder(
      itemCount: _importedQuotes.length,
      itemBuilder: (context, index) {
        final quoteData = _importedQuotes[index];
        final quote = quoteData['quote'] as Quote;
        final lineItems = quoteData['lineItems'] as List<LineItem>;
        final sheetName = quoteData['sheetName'] as String;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E5E7)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Лист: $sheetName',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1D1D1F),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF007AFF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${lineItems.length} позиций',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF007AFF),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Клиент: ${quote.customerName}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF86868B),
                  ),
                ),
                if (quote.objectName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Объект: ${quote.objectName}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF86868B),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'Сумма: ${quote.totalAmount.toStringAsFixed(2)} ₽',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF34C759),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
