import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import '../models/quote.dart';
import '../models/line_item.dart';
import '../models/company.dart';
import '../models/quote_attachment.dart';
import '../database/database_helper.dart';
import '../widgets/line_item_widget.dart';
import '../widgets/animated_button.dart';
import '../widgets/quick_add_item_dialog.dart';
import '../widgets/quote_attachments_widget.dart';
import '../services/excel_service.dart';
import '../services/pdf_service.dart';
import 'home_screen.dart';

class QuoteEditScreen extends StatefulWidget {
  final Quote? quote;

  const QuoteEditScreen({super.key, this.quote});

  @override
  State<QuoteEditScreen> createState() => _QuoteEditScreenState();
}

class _QuoteEditScreenState extends State<QuoteEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();
  
  // Controllers
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerPhoneController = TextEditingController();
  final TextEditingController _customerEmailController = TextEditingController();
  final TextEditingController _objectNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _areaSController = TextEditingController();
  final TextEditingController _perimeterPController = TextEditingController();
  final TextEditingController _heightHController = TextEditingController();
  final TextEditingController _paymentTermsController = TextEditingController();
  final TextEditingController _installationTermsController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  // State variables
  String? _selectedCeilingSystem;
  QuoteStatus _selectedStatus = QuoteStatus.draft;
  List<LineItem> _lineItems = [];
  List<QuoteAttachment> _attachments = [];
  bool _isLoading = false;
  Company? _company;
  int? quoteId;
  bool _isExportingExcel = false;
  bool _isExportingPdf = false;
  bool _isImporting = false;
  
  // Key для принудительного обновления
  final GlobalKey _lineItemsKey = GlobalKey();
  final ExcelService _excelService = ExcelService();
  final PdfService _pdfService = PdfService();

  final List<String> _ceilingSystems = [
    'Гарпун',
    'Вставка по периметру',
    'Теневой',
    'Парящий',
    'Клипсовая',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _customerEmailController.dispose();
    _objectNameController.dispose();
    _addressController.dispose();
    _areaSController.dispose();
    _perimeterPController.dispose();
    _heightHController.dispose();
    _paymentTermsController.dispose();
    _installationTermsController.dispose();
    _notesController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Загрузка компании по умолчанию
      final companyData = await DatabaseHelper.instance.query(
        'companies',
        limit: 1,
      );
      if (companyData.isNotEmpty) {
        _company = Company.fromMap(companyData.first);
      }

      // Загрузка данных предложения
      if (widget.quote != null) {
        final quote = widget.quote!;
        quoteId = quote.id;
        _customerNameController.text = quote.customerName;
        _customerPhoneController.text = quote.customerPhone ?? '';
        _customerEmailController.text = quote.customerEmail ?? '';
        _objectNameController.text = quote.objectName ?? '';
        _addressController.text = quote.address ?? '';
        _areaSController.text = quote.areaS?.toString() ?? '';
        _perimeterPController.text = quote.perimeterP?.toString() ?? '';
        _heightHController.text = quote.heightH?.toString() ?? '';
        _selectedCeilingSystem = quote.ceilingSystem;
        _selectedStatus = quote.status;
        _paymentTermsController.text = quote.paymentTerms ?? '';
        _installationTermsController.text = quote.installationTerms ?? '';
        _notesController.text = quote.notes ?? '';

        // Загрузка позиций
        final itemsData = await DatabaseHelper.instance.query(
          'line_items',
          where: 'quote_id = ?',
          whereArgs: [quote.id],
          orderBy: 'position',
        );
        _lineItems = itemsData.map((map) => LineItem.fromMap(map)).toList();

        // Загрузка вложений
        final attachmentsData = await DatabaseHelper.instance.query(
          'quote_attachments',
          where: 'quote_id = ?',
          whereArgs: [quote.id],
          orderBy: 'created_at DESC',
        );
        _attachments = attachmentsData.map((map) => QuoteAttachment.fromMap(map)).toList();
      } else {
        // Новое предложение - добавляем пустые позиции
        _lineItems = [
          LineItem(
            quoteId: 0,
            position: 1,
            section: LineItemSection.work,
            description: '',
            unit: 'м²',
            quantity: 0,
            price: 0,
          ),
        ];
        _attachments = [];
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки данных: $e')),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  void _addLineItem(LineItemSection section) {
    final newPosition = _lineItems.isEmpty 
        ? 1 
        : _lineItems.map((item) => item.position).reduce((a, b) => a > b ? a : b) + 1;
    
    setState(() {
      _lineItems.add(LineItem(
        quoteId: widget.quote?.id ?? 0,
        position: newPosition,
        section: section,
        description: '',
        unit: section == LineItemSection.work ? 'м²' : 'шт.',
        quantity: 0,
        price: 0,
      ));
    });
  }

  void _removeLineItem(int index) {
    setState(() {
      _lineItems.removeAt(index);
      // Обновляем позиции
      for (int i = 0; i < _lineItems.length; i++) {
        _lineItems[i] = _lineItems[i].copyWith(position: i + 1);
      }
    });
  }

  void _updateLineItem(int index, LineItem item) {
    setState(() {
      _lineItems[index] = item;
    });
  }

  Future<void> _showQuickAddDialog() async {
    final result = await showDialog<LineItem>(
      context: context,
      builder: (context) => const QuickAddItemDialog(),
    );

    if (result != null) {
      setState(() {
        // Устанавливаем правильную позицию
        final itemsInSection = _lineItems.where((item) => item.section == result.section).toList();
        final newPosition = itemsInSection.isEmpty ? 1 : itemsInSection.last.position + 1;
        
        final itemWithPosition = result.copyWith(position: newPosition);
        _lineItems.add(itemWithPosition);
      });
    }
  }

  Future<void> _exportToExcel() async {
    if (_lineItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нет позиций для экспорта')),
      );
      return;
    }

    setState(() => _isExportingExcel = true);

    try {
      final quote = _getCurrentQuote();
      final filePath = await _excelService.exportToExcel(quote, _lineItems);
      
      // Открываем файл напрямую в Excel
      final result = await OpenFile.open(filePath);
      
      if (result.type == ResultType.done) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Excel файл открыт'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка открытия Excel: ${result.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка экспорта: $e')),
        );
      }
    } finally {
      setState(() => _isExportingExcel = false);
    }
  }

  Future<void> _exportToPdf() async {
    if (_lineItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нет позиций для экспорта')),
      );
      return;
    }

    setState(() => _isExportingPdf = true);

    try {
      final quote = _getCurrentQuote();
      final company = await _getCompany();
      final filePath = await _pdfService.generatePdf(quote, _lineItems, company);
      
      // Открываем файл напрямую в PDF просмотрщике
      final result = await OpenFile.open(filePath);
      
      if (result.type == ResultType.done) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PDF файл открыт'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка открытия PDF: ${result.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка экспорта: $e')),
        );
      }
    } finally {
      setState(() => _isExportingPdf = false);
    }
  }

  Future<void> _importFromExcel() async {
    setState(() => _isImporting = true);
    
    try {
      final importData = await _excelService.importFromExcel();
      
      if (importData == null) {
        return; // Пользователь отменил выбор файла
      }

      setState(() {
        // Добавляем импортированные позиции к существующим
        _lineItems.addAll(importData.workItems);
        _lineItems.addAll(importData.equipmentItems);
        
        // Обновляем позиции
        _updatePositions();
      });

      // Прокрутка к новым позициям после полного рендеринга
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && _scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Импортировано: ${importData.workItems.length} работ, ${importData.equipmentItems.length} оборудования'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка импорта: $e')),
        );
      }
    }
    
    setState(() => _isImporting = false);
  }

  void _addNewLineItem() {
    final newItem = LineItem(
      id: null,
      quoteId: widget.quote?.id ?? 0,
      position: _lineItems.length + 1,
      section: LineItemSection.work,
      description: '',
      unit: 'шт.',
      quantity: 1.0,
      price: 0.0,
      amount: 0.0,
      note: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    setState(() {
      _lineItems.add(newItem);
    });
    
    // Более надежная прокрутка
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _scrollToNewItem();
      }
    });
  }

  void _scrollToNewItem() {
    // Найдем индекс последнего элемента
    final lastIndex = _lineItems.length - 1;
    if (lastIndex >= 0 && _scrollController.hasClients) {
      // Прокрутим к последнему элементу с небольшим отступом
      final targetPosition = (lastIndex * 200.0); // Примерная высота одного элемента
      _scrollController.animateTo(
        targetPosition,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    }
  }

  void _updatePositions() {
    // Обновляем позиции для работ
    final workItems = _lineItems.where((item) => item.section == LineItemSection.work).toList();
    for (int i = 0; i < workItems.length; i++) {
      final index = _lineItems.indexOf(workItems[i]);
      _lineItems[index] = workItems[i].copyWith(position: i + 1);
    }
    
    // Обновляем позиции для оборудования
    final equipmentItems = _lineItems.where((item) => item.section == LineItemSection.equipment).toList();
    for (int i = 0; i < equipmentItems.length; i++) {
      final index = _lineItems.indexOf(equipmentItems[i]);
      _lineItems[index] = equipmentItems[i].copyWith(position: i + 1);
    }
  }

  Quote _createQuoteFromForm() {
    final subtotalWork = _lineItems
        .where((item) => item.section == LineItemSection.work)
        .fold(0.0, (sum, item) => sum + item.amount);
    final subtotalEquipment = _lineItems
        .where((item) => item.section == LineItemSection.equipment)
        .fold(0.0, (sum, item) => sum + item.amount);
    final totalAmount = subtotalWork + subtotalEquipment;

    return Quote(
      id: widget.quote?.id ?? 0,
      companyId: _company?.id ?? 1,
      customerName: _customerNameController.text,
      customerPhone: _customerPhoneController.text.isEmpty ? null : _customerPhoneController.text,
      customerEmail: _customerEmailController.text.isEmpty ? null : _customerEmailController.text,
      objectName: _objectNameController.text.isEmpty ? null : _objectNameController.text,
      address: _addressController.text.isEmpty ? null : _addressController.text,
      areaS: _areaSController.text.isEmpty ? null : double.tryParse(_areaSController.text),
      perimeterP: _perimeterPController.text.isEmpty ? null : double.tryParse(_perimeterPController.text),
      heightH: _heightHController.text.isEmpty ? null : double.tryParse(_heightHController.text),
      ceilingSystem: _selectedCeilingSystem,
      status: _selectedStatus,
      paymentTerms: _paymentTermsController.text.isEmpty ? null : _paymentTermsController.text,
      installationTerms: _installationTermsController.text.isEmpty ? null : _installationTermsController.text,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      subtotalWork: subtotalWork,
      subtotalEquipment: subtotalEquipment,
      totalAmount: totalAmount,
      currencyCode: 'RUB',
      createdAt: widget.quote?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Future<void> _saveQuote() async {
  if (!_formKey.currentState!.validate()) return;

  try {
    final quote = Quote(
      id: widget.quote?.id,
      companyId: 1,
      customerName: _customerNameController.text.trim(),
      customerPhone: _customerPhoneController.text.trim(),
      customerEmail: _customerEmailController.text.trim(),
      objectName: _objectNameController.text.trim(),
      address: _addressController.text.trim(),
      areaS: double.tryParse(_areaSController.text) ?? 0,
      perimeterP: double.tryParse(_perimeterPController.text) ?? 0,
      heightH: double.tryParse(_heightHController.text) ?? 0,
      ceilingSystem: _selectedCeilingSystem,
      status: _selectedStatus,
      paymentTerms: _paymentTermsController.text.trim().isEmpty 
          ? null 
          : _paymentTermsController.text.trim(),
      installationTerms: _installationTermsController.text.trim().isEmpty 
          ? null 
          : _installationTermsController.text.trim(),
      notes: _notesController.text.trim().isEmpty 
          ? null 
          : _notesController.text.trim(),
      currencyCode: 'RUB',
      subtotalWork: 0, // TODO: Calculate from line items
      subtotalEquipment: 0, // TODO: Calculate from line items
      totalAmount: 0, // TODO: Calculate from line items
      createdAt: widget.quote?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    int savedQuoteId;
    if (widget.quote == null) {
      savedQuoteId = await DatabaseHelper.instance.insert('quotes', quote.toMap());
      quoteId = savedQuoteId;
    } else {
      await DatabaseHelper.instance.update(
        'quotes',
        quote.toMap(),
        where: 'quote_id = ?',
        whereArgs: [quote.id],
      );
      savedQuoteId = quote.id!;
    }

    await DatabaseHelper.instance.delete(
      'line_items',
      where: 'quote_id = ?',
      whereArgs: [savedQuoteId],
    );

    for (final item in _lineItems) {
      final itemWithQuoteId = item.copyWith(quoteId: savedQuoteId);
      await DatabaseHelper.instance.insert('line_items', itemWithQuoteId.toMap());
    }

    await DatabaseHelper.instance.delete(
      'quote_attachments',
      where: 'quote_id = ?',
      whereArgs: [savedQuoteId],
    );

    for (final attachment in _attachments) {
      final attachmentWithQuoteId = attachment.copyWith(quoteId: savedQuoteId);
      await DatabaseHelper.instance.insert('quote_attachments', attachmentWithQuoteId.toMap());
    }

    // Используем pushReplacement для избежания черного экрана
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const HomeScreen(),
      ),
    );
    
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка сохранения: $e')),
      );
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quote == null ? 'Новое предложение' : 'Редактирование'),
        actions: [
          AnimatedIconButton(
            icon: Icons.table_chart,
            onPressed: _exportToExcel,
            tooltip: 'Экспорт в Excel',
          ),
          AnimatedIconButton(
            icon: Icons.picture_as_pdf,
            onPressed: _exportToPdf,
            tooltip: 'Экспорт в PDF',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCustomerInfo(),
                    const SizedBox(height: 24),
                    _buildObjectInfo(),
                    const SizedBox(height: 24),
                    _buildActionButtons(),
                    const SizedBox(height: 24),
                    _buildLineItems(),
                    const SizedBox(height: 24),
                    _buildTermsAndNotes(),
                    const SizedBox(height: 24),
                    _buildStatusSection(),
                    const SizedBox(height: 24),
                    QuoteAttachmentsWidget(
                      quoteId: widget.quote?.id ?? 0,
                      attachments: _attachments,
                      onChanged: (attachments) {
                        setState(() {
                          _attachments = attachments;
                        });
                      },
                    ),
                    const SizedBox(height: 32),
                    // Кнопки в стиле Apple
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                colors: [Colors.blue.shade500, Colors.blue.shade700],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _saveQuote,
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  child: Center(
                                    child: Text(
                                      'Сохранить',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              colors: [Colors.red.shade500, Colors.red.shade700],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _isExportingPdf ? () {} : _exportToPdf,
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                child: _isExportingPdf
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Icon(Icons.picture_as_pdf, color: Colors.white, size: 20),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              colors: [Colors.green.shade500, Colors.green.shade700],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _isExportingExcel ? () {} : _exportToExcel,
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                child: _isExportingExcel
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Icon(Icons.table_chart, color: Colors.white, size: 20),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCustomerInfo() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
            Text(
              'Информация о клиенте',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1D1D1F),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _customerNameController,
              decoration: const InputDecoration(
                labelText: 'Имя клиента *',
                border: OutlineInputBorder(),
                floatingLabelStyle: TextStyle(color: Color(0xFF007AFF)),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Введите имя клиента';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _customerPhoneController,
              decoration: const InputDecoration(
                labelText: 'Телефон',
                border: OutlineInputBorder(),
                prefixText: '+7 ',
                floatingLabelStyle: TextStyle(color: Color(0xFF007AFF)),
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _customerEmailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                floatingLabelStyle: TextStyle(color: Color(0xFF007AFF)),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildObjectInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Объект', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _objectNameController,
              decoration: const InputDecoration(
                labelText: 'Название объекта',
                border: OutlineInputBorder(),
                hintText: 'Квартира, офис и т.д.',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Адрес',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _areaSController,
                    decoration: const InputDecoration(
                      labelText: 'Площадь S, м²',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$'))],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _perimeterPController,
                    decoration: const InputDecoration(
                      labelText: 'Периметр P, м.п.',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$'))],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _heightHController,
                    decoration: const InputDecoration(
                      labelText: 'Высота h, м',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$'))],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCeilingSystem,
                    decoration: const InputDecoration(
                      labelText: 'Система крепления',
                      border: OutlineInputBorder(),
                    ),
                    items: _ceilingSystems.map((system) {
                      return DropdownMenuItem(
                        value: system,
                        child: Text(system),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCeilingSystem = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
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
          Text(
            'Действия',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1D1D1F),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Ряд с основными кнопками
              Row(
                children: [
                  // Кнопка добавления новой позиции
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _addNewLineItem,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Добавить позицию', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Простая кнопка быстрого добавления
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _showQuickAddDialog,
                      icon: const Icon(Icons.flash_on, size: 16),
                      label: const Text('Быстрое добавление', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Простая кнопка импорта Excel
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isImporting ? null : _importFromExcel,
                      icon: _isImporting 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.file_upload, size: 16),
                      label: Text(_isImporting ? 'Загрузка...' : 'Импорт Excel', style: const TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget _buildLineItems() {
    final workItems = _lineItems.where((item) => item.section == LineItemSection.work).toList();
    final equipmentItems = _lineItems.where((item) => item.section == LineItemSection.equipment).toList();

    return Container(
      key: ValueKey(_lineItems.length), // Ключ для обновления при изменении количества
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
            Text(
              'Позиции',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1D1D1F),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 20),
            
            if (workItems.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Работы',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF007AFF),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ...workItems.asMap().entries.map((entry) {
                final index = _lineItems.indexOf(entry.value);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: LineItemWidget(
                    item: entry.value,
                    onChanged: (item) => _updateLineItem(index, item),
                    onRemove: () => _removeLineItem(index),
                  ),
                );
              }).toList(),
              const SizedBox(height: 20),
            ],
            
            if (equipmentItems.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9500).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Оборудование',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFFF9500),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ...equipmentItems.asMap().entries.map((entry) {
                final index = _lineItems.indexOf(entry.value);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: LineItemWidget(
                    item: entry.value,
                    onChanged: (item) => _updateLineItem(index, item),
                    onRemove: () => _removeLineItem(index),
                  ),
                );
              }).toList(),
            ],
            
            if (_lineItems.isEmpty)
              Container(
                padding: const EdgeInsets.all(40),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 48,
                        color: const Color(0xFF86868B),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Нет позиций',
                        style: TextStyle(
                          fontSize: 16,
                          color: const Color(0xFF86868B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Нажмите "Быстрое добавление" для начала',
                        style: TextStyle(
                          fontSize: 14,
                          color: const Color(0xFF86868B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsAndNotes() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Условия и примечания', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _paymentTermsController,
              decoration: const InputDecoration(
                labelText: 'Условия оплаты',
                border: OutlineInputBorder(),
                hintText: '50% предоплата за 3 дня до начала работ',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _installationTermsController,
              decoration: const InputDecoration(
                labelText: 'Даты и условия монтажа',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Примечания',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Статус', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: QuoteStatus.values.map((status) {
                return ChoiceChip(
                  label: Text(status.displayName),
                  selected: _selectedStatus == status,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedStatus = status;
                      });
                    }
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
