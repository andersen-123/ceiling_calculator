import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../models/quote.dart';
import '../models/line_item.dart';
import '../models/company.dart';
import '../database/database_helper.dart';
import '../widgets/line_item_widget.dart';
import '../widgets/animated_button.dart';
import '../widgets/quick_add_item_dialog.dart';
import '../services/excel_service.dart';
import '../services/pdf_service.dart';

class QuoteEditScreen extends StatefulWidget {
  final Quote? quote;

  const QuoteEditScreen({super.key, this.quote});

  @override
  State<QuoteEditScreen> createState() => _QuoteEditScreenState();
}

class _QuoteEditScreenState extends State<QuoteEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _customerEmailController = TextEditingController();
  final _objectNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _areaSController = TextEditingController();
  final _perimeterPController = TextEditingController();
  final _heightHController = TextEditingController();
  final _paymentTermsController = TextEditingController();
  final _installationTermsController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedCeilingSystem;
  QuoteStatus _selectedStatus = QuoteStatus.draft;
  List<LineItem> _lineItems = [];
  bool _isLoading = false;
  Company? _company;
  int? quoteId;
  bool _isExportingExcel = false;
  bool _isExportingPdf = false;

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

  Future<void> _showQuickAddDialog(LineItemSection section) async {
    final result = await showDialog<LineItem>(
      context: context,
      builder: (context) => QuickAddItemDialog(section: section),
    );

    if (result != null) {
      setState(() {
        // Устанавливаем правильную позицию
        final itemsInSection = _lineItems.where((item) => item.section == section).toList();
        final newPosition = itemsInSection.isEmpty ? 1 : itemsInSection.last.position + 1;
        
        final itemWithPosition = result.copyWith(position: newPosition);
        _lineItems.add(itemWithPosition);
      });
    }
  }

  Future<void> _exportToPdf() async {
    if (_company == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сначала настройте информацию о компании')),
      );
      return;
    }

    setState(() => _isExportingPdf = true);
    
    try {
      // Создаем текущее предложение для экспорта
      final quote = _createQuoteFromForm();
      
      final file = await _pdfService.generateQuotePdf(
        quote,
        _lineItems,
        _company!,
      );
      
      await Share.shareXFiles([XFile(file.path)], 
        text: 'Коммерческое предложение для ${quote.customerName}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка экспорта в PDF: $e')),
        );
      }
    }
    
    setState(() => _isExportingPdf = false);
  }

  Future<void> _exportToExcel() async {
    if (_company == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сначала настройте информацию о компании')),
      );
      return;
    }

    setState(() => _isExportingExcel = true);
    
    try {
      // Создаем текущее предложение для экспорта
      final quote = _createQuoteFromForm();
      
      final file = await _excelService.generateQuoteExcel(
        quote,
        _lineItems,
        _company!,
      );
      
      await Share.shareXFiles([XFile(file.path)], 
        text: 'Коммерческое предложение для ${quote.customerName}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка экспорта в Excel: $e')),
        );
      }
    }
    
    setState(() => _isExportingExcel = false);
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

    setState(() => _isLoading = true);

    try {
      final quote = Quote(
        id: widget.quote?.id,
        companyId: _company?.id ?? 1,
        customerName: _customerNameController.text.trim(),
        customerPhone: _customerPhoneController.text.trim().isEmpty 
            ? null 
            : _customerPhoneController.text.trim(),
        customerEmail: _customerEmailController.text.trim().isEmpty 
            ? null 
            : _customerEmailController.text.trim(),
        objectName: _objectNameController.text.trim().isEmpty 
            ? null 
            : _objectNameController.text.trim(),
        address: _addressController.text.trim().isEmpty 
            ? null 
            : _addressController.text.trim(),
        areaS: double.tryParse(_areaSController.text),
        perimeterP: double.tryParse(_perimeterPController.text),
        heightH: double.tryParse(_heightHController.text),
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
      );

      // Расчёт сумм
      final workItems = _lineItems.where((item) => item.section == LineItemSection.work);
      final equipmentItems = _lineItems.where((item) => item.section == LineItemSection.equipment);
      
      final subtotalWork = workItems.fold(0.0, (sum, item) => sum + item.amount);
      final subtotalEquipment = equipmentItems.fold(0.0, (sum, item) => sum + item.amount);
      final totalAmount = subtotalWork + subtotalEquipment;

      final quoteWithTotals = quote.copyWith(
        subtotalWork: subtotalWork,
        subtotalEquipment: subtotalEquipment,
        totalAmount: totalAmount,
      );

      // Сохранение предложения
      int? savedQuoteId;
      if (widget.quote?.id != null) {
        await DatabaseHelper.instance.update(
          'quotes',
          quoteWithTotals.toMap(),
          where: 'quote_id = ?',
          whereArgs: [widget.quote!.id],
        );
        savedQuoteId = widget.quote!.id;
      } else {
        final newId = await DatabaseHelper.instance.insert('quotes', quoteWithTotals.toMap());
        savedQuoteId = newId;
        quoteId = newId;
      }

      // Сохранение позиций
      await DatabaseHelper.instance.delete(
        'line_items',
        where: 'quote_id = ?',
        whereArgs: [savedQuoteId],
      );

      for (final item in _lineItems) {
        final itemWithQuoteId = item.copyWith(quoteId: savedQuoteId);
        await DatabaseHelper.instance.insert('line_items', itemWithQuoteId.toMap());
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Предложение сохранено'),
            backgroundColor: Colors.green,
          ),
        );
        // Небольшая задержка перед закрытием для показа снэкбара
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.of(context).pop(true); // Возвращаем true чтобы обновить список
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка сохранения: $e')),
        );
      }
    }

    setState(() => _isLoading = false);
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
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCustomerInfo(),
                    const SizedBox(height: 24),
                    _buildObjectInfo(),
                    const SizedBox(height: 24),
                    _buildLineItems(),
                    const SizedBox(height: 24),
                    _buildTermsAndNotes(),
                    const SizedBox(height: 24),
                    _buildStatusSection(),
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
                                onTap: _isLoading ? null : _saveQuote,
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
                                                'Сохранить предложение',
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Клиент', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _customerNameController,
              decoration: const InputDecoration(
                labelText: 'Имя клиента *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Введите имя клиента';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _customerPhoneController,
              decoration: const InputDecoration(
                labelText: 'Телефон',
                border: OutlineInputBorder(),
                prefixText: '+7 ',
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _customerEmailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
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

  Widget _buildLineItems() {
    final workItems = _lineItems.where((item) => item.section == LineItemSection.work).toList();
    final equipmentItems = _lineItems.where((item) => item.section == LineItemSection.equipment).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Позиции', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    // Быстрые кнопки в стиле Apple
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade400, Colors.blue.shade600],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _showQuickAddDialog(LineItemSection.work),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.flash_on, color: Colors.white, size: 18),
                                SizedBox(width: 8),
                                Text('Быстрые работы', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: [Colors.orange.shade400, Colors.orange.shade600],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _showQuickAddDialog(LineItemSection.equipment),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.flash_on, color: Colors.white, size: 18),
                                SizedBox(width: 8),
                                Text('Быстрое оборудование', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (workItems.isNotEmpty) ...[
              Text('Работы', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue[700])),
              const SizedBox(height: 8),
              ...workItems.asMap().entries.map((entry) {
                final index = _lineItems.indexOf(entry.value);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: LineItemWidget(
                    item: entry.value,
                    onChanged: (item) => _updateLineItem(index, item),
                    onRemove: () => _removeLineItem(index),
                  ),
                );
              }).toList(),
              const SizedBox(height: 16),
            ],
            
            if (equipmentItems.isNotEmpty) ...[
              Text('Оборудование', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green[700])),
              const SizedBox(height: 8),
              ...equipmentItems.asMap().entries.map((entry) {
                final index = _lineItems.indexOf(entry.value);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: LineItemWidget(
                    item: entry.value,
                    onChanged: (item) => _updateLineItem(index, item),
                    onRemove: () => _removeLineItem(index),
                  ),
                );
              }).toList(),
            ],
            
            if (_lineItems.isEmpty) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('Добавьте позиции для расчёта стоимости'),
                ),
              ),
            ],
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
