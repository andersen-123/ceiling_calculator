import 'package:flutter/material.dart';
import '../models/line_item.dart';

class QuickAddItemDialog extends StatefulWidget {
  const QuickAddItemDialog({super.key});

  @override
  State<QuickAddItemDialog> createState() => _QuickAddItemDialogState();
}

class _QuickAddItemDialogState extends State<QuickAddItemDialog> {
  final List<Map<String, dynamic>> _allItems = [
    {'description': 'Гарпун', 'unit': 'м.п.', 'price': 0.0, 'section': LineItemSection.work, 'category': 'Монтаж'},
    {'description': 'Полотно MSD Premium белое матовое с установкой', 'unit': 'м²', 'price': 670.0, 'section': LineItemSection.work, 'category': 'Полотна'},
    {'description': 'Профиль стеновой/потолочный гарпунный с установкой', 'unit': 'м.п.', 'price': 340.0, 'section': LineItemSection.work, 'category': 'Профили'},
    {'description': 'Вставка по периметру гарпунная', 'unit': 'м.п.', 'price': 240.0, 'section': LineItemSection.work, 'category': 'Монтаж'},
    {'description': 'Монтаж закладных под световое оборудование, установка светильников', 'unit': 'шт.', 'price': 900.0, 'section': LineItemSection.work, 'category': 'Электромонтаж'},
    {'description': 'Монтаж закладных под сдвоенное световое оборудование, установка светильников', 'unit': 'шт.', 'price': 1500.0, 'section': LineItemSection.work, 'category': 'Электромонтаж'},
    {'description': 'Монтаж закладных под люстру', 'unit': 'шт.', 'price': 1200.0, 'section': LineItemSection.work, 'category': 'Электромонтаж'},
    {'description': 'Монтаж закладной и установка вентелятора', 'unit': 'шт.', 'price': 1450.0, 'section': LineItemSection.work, 'category': 'Электромонтаж'},
    {'description': 'Монтаж закладной под потолочный карниз', 'unit': 'м.п.', 'price': 720.0, 'section': LineItemSection.work, 'category': 'Монтаж'},
    {'description': 'Установка потолочного карниза', 'unit': 'м.п.', 'price': 300.0, 'section': LineItemSection.work, 'category': 'Монтаж'},
    {'description': 'Установка разделителей', 'unit': 'м.п.', 'price': 1900.0, 'section': LineItemSection.work, 'category': 'Монтаж'},
    {'description': 'Монтаж закладных под вcтраеваемые шкафы', 'unit': 'м.п.', 'price': 1200.0, 'section': LineItemSection.work, 'category': 'Монтаж'},
    {'description': 'Монтаж шторных карнизов (ПК-15) двухрядный', 'unit': 'м.п.', 'price': 4500.0, 'section': LineItemSection.work, 'category': 'Монтаж'},
    {'description': 'Монтаж шторных карнизов (ПК-5) трехрядный', 'unit': 'м.п.', 'price': 5000.0, 'section': LineItemSection.work, 'category': 'Монтаж'},
    {'description': 'Работы по керамической плитке/керамограниту', 'unit': 'м.п.', 'price': 450.0, 'section': LineItemSection.work, 'category': 'Отделка'},
    {'description': 'Установка вентиляционной решетки', 'unit': 'шт.', 'price': 650.0, 'section': LineItemSection.work, 'category': 'Вентиляция'},
    {'description': 'Монтаж "парящего" потолка, установка светодиодной ленты', 'unit': 'м.п.', 'price': 1750.0, 'section': LineItemSection.work, 'category': 'Монтаж'},
    {'description': 'Монтаж потолка системы "EuroKRAAB"', 'unit': 'м.п.', 'price': 1750.0, 'section': LineItemSection.work, 'category': 'Системы'},
    {'description': 'Монтаж световых линий, установка светодиодной ленты', 'unit': 'м.п.', 'price': 3750.0, 'section': LineItemSection.work, 'category': 'Электромонтаж'},
    {'description': 'Монтаж открытой ниши', 'unit': 'м.п.', 'price': 1350.0, 'section': LineItemSection.work, 'category': 'Монтаж'},
    {'description': 'Монтаж ниши с поворотом полотна', 'unit': 'м.п.', 'price': 3300.0, 'section': LineItemSection.work, 'category': 'Монтаж'},
    {'description': 'Монтаж перехода уровня', 'unit': 'м.п.', 'price': 4100.0, 'section': LineItemSection.work, 'category': 'Монтаж'},
    {'description': 'Монтаж закладных под трековое освещение (встраиваемые) с установкой', 'unit': 'м.п.', 'price': 3750.0, 'section': LineItemSection.work, 'category': 'Электромонтаж'},
    {'description': 'Монтаж закладных под трековое освещение (накладные) с установкой', 'unit': 'м.п.', 'price': 1200.0, 'section': LineItemSection.work, 'category': 'Электромонтаж'},
  ];

  final TextEditingController _customDescriptionController = TextEditingController();
  final TextEditingController _customPriceController = TextEditingController();
  final TextEditingController _customUnitController = TextEditingController();

  String _searchQuery = '';
  List<Map<String, dynamic>> get _filteredItems {
    if (_searchQuery.isEmpty) return _allItems;
    return _allItems.where((item) =>
        item['description'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
        item['category'].toString().toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: MediaQuery.of(context).size.width * 0.95,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header в стиле Apple
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFFF8F9FA),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Быстрое добавление',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1D1D1F),
                          letterSpacing: -0.5,
                        ),
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: _showAddCustomItemDialog,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFF007AFF),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF007AFF).withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.add,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 18,
                                color: Color(0xFF86868B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Поиск в стиле Apple
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E5E7)),
                    ),
                    child: TextField(
                      onChanged: (value) => setState(() => _searchQuery = value),
                      decoration: const InputDecoration(
                        hintText: 'Поиск позиций...',
                        prefixIcon: Icon(Icons.search, color: Color(0xFF86868B)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Список категорий и позиций
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: _filteredItems.length,
                itemBuilder: (context, index) {
                  final item = _filteredItems[index];
                  final isWork = item['section'] == LineItemSection.work;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
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
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _addItem(item),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // Иконка категории
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: isWork ? const Color(0xFF007AFF).withOpacity(0.1) : const Color(0xFFFF9500).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  isWork ? Icons.build : Icons.inventory_2,
                                  color: isWork ? const Color(0xFF007AFF) : const Color(0xFFFF9500),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              
                              // Информация о позиции
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['description'],
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1D1D1F),
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item['category'],
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF86868B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Цена и единица
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${item['price'].toStringAsFixed(0)} ₽',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1D1D1F),
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  Text(
                                    '/${item['unit']}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF86868B),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addItem(Map<String, dynamic> itemData) {
    final item = LineItem(
      id: null,
      quoteId: 0,
      position: 1,
      section: itemData['section'],
      description: itemData['description'],
      unit: itemData['unit'],
      quantity: 1.0,
      price: itemData['price'],
      amount: itemData['price'],
      note: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    Navigator.pop(context, item);
  }

  void _showAddCustomItemDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Добавить свою позицию',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1D1D1F),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _customDescriptionController,
                decoration: const InputDecoration(
                  labelText: 'Наименование',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customPriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Цена',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _customUnitController,
                      decoration: const InputDecoration(
                        labelText: 'Ед. изм.',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Отмена'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _addCustomItem,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007AFF),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Добавить'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addCustomItem() {
    if (_customDescriptionController.text.trim().isEmpty ||
        _customPriceController.text.trim().isEmpty ||
        _customUnitController.text.trim().isEmpty) {
      return;
    }

    final item = LineItem(
      id: null,
      quoteId: 0,
      position: 1,
      section: LineItemSection.equipment,
      description: _customDescriptionController.text.trim(),
      unit: _customUnitController.text.trim(),
      quantity: 1.0,
      price: double.tryParse(_customPriceController.text) ?? 0.0,
      amount: double.tryParse(_customPriceController.text) ?? 0.0,
      note: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    Navigator.pop(context);
    Navigator.pop(context, item);
  }
}
