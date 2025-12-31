import 'package:flutter/material.dart';
import '../models/line_item.dart';

class QuickAddItemDialog extends StatefulWidget {
  const QuickAddItemDialog({super.key});

  @override
  State<QuickAddItemDialog> createState() => _QuickAddItemDialogState();
}

class _QuickAddItemDialogState extends State<QuickAddItemDialog> {
  final List<Map<String, dynamic>> _allItems = [
    {'description': 'Полотно MSD Premium белое матовое с установкой по цене 650 за кв.м.', 'unit': 'м²', 'price': 650.0, 'section': LineItemSection.equipment, 'category': 'Полотна'},
    {'description': 'Полотно MSD Premium белое сатиновое с установкой по цене 680 за кв.м.', 'unit': 'м²', 'price': 680.0, 'section': LineItemSection.equipment, 'category': 'Полотна'},
    {'description': 'Полотно MSD Premium цветное с установкой по цене 750 за кв.м.', 'unit': 'м²', 'price': 750.0, 'section': LineItemSection.equipment, 'category': 'Полотна'},
    {'description': 'Полотно MSD Premium с фотопечатью с установкой по цене 850 за кв.м.', 'unit': 'м²', 'price': 850.0, 'section': LineItemSection.equipment, 'category': 'Полотна'},
    {'description': 'Багет пластиковый белый с установкой по цене 120 за м.п.', 'unit': 'м.п.', 'price': 120.0, 'section': LineItemSection.equipment, 'category': 'Багеты'},
    {'description': 'Багет пластиковый цветной с установкой по цене 140 за м.п.', 'unit': 'м.п.', 'price': 140.0, 'section': LineItemSection.equipment, 'category': 'Багеты'},
    {'description': 'Багет алюминиевый с установкой по цене 180 за м.п.', 'unit': 'м.п.', 'price': 180.0, 'section': LineItemSection.equipment, 'category': 'Багеты'},
    {'description': 'Профиль стартовый с установкой по цене 90 за м.п.', 'unit': 'м.п.', 'price': 90.0, 'section': LineItemSection.equipment, 'category': 'Профили'},
    {'description': 'Профиль направляющий с установкой по цене 100 за м.п.', 'unit': 'м.п.', 'price': 100.0, 'section': LineItemSection.equipment, 'category': 'Профили'},
    {'description': 'Подвес прямой с установкой по цене 25 за шт.', 'unit': 'шт.', 'price': 25.0, 'section': LineItemSection.equipment, 'category': 'Крепеж'},
    {'description': 'Точечный светильник с установкой по цене 350 за шт.', 'unit': 'шт.', 'price': 350.0, 'section': LineItemSection.equipment, 'category': 'Освещение'},
    {'description': 'Точечный светильник поворотный с установкой по цене 420 за шт.', 'unit': 'шт.', 'price': 420.0, 'section': LineItemSection.equipment, 'category': 'Освещение'},
    {'description': 'Светодиодная лента с установкой по цене 150 за м.п.', 'unit': 'м.п.', 'price': 150.0, 'section': LineItemSection.equipment, 'category': 'Освещение'},
    {'description': 'Диммер с установкой по цене 450 за шт.', 'unit': 'шт.', 'price': 450.0, 'section': LineItemSection.equipment, 'category': 'Освещение'},
    {'description': 'Трансформатор с установкой по цене 380 за шт.', 'unit': 'шт.', 'price': 380.0, 'section': LineItemSection.equipment, 'category': 'Освещение'},
    {'description': 'Монтаж натяжного потолка по цене 350 за кв.м.', 'unit': 'м²', 'price': 350.0, 'section': LineItemSection.work, 'category': 'Монтаж'},
    {'description': 'Монтаж многоуровневого потолка по цене 550 за кв.м.', 'unit': 'м²', 'price': 550.0, 'section': LineItemSection.work, 'category': 'Монтаж'},
    {'description': 'Монтаж натяжного потолка с фотопечатью по цене 450 за кв.м.', 'unit': 'м²', 'price': 450.0, 'section': LineItemSection.work, 'category': 'Монтаж'},
    {'description': 'Установка светильников по цене 150 за шт.', 'unit': 'шт.', 'price': 150.0, 'section': LineItemSection.work, 'category': 'Электромонтаж'},
    {'description': 'Монтаж светодиодной ленты по цене 200 за м.п.', 'unit': 'м.п.', 'price': 200.0, 'section': LineItemSection.work, 'category': 'Электромонтаж'},
    {'description': 'Установка диммера по цене 250 за шт.', 'unit': 'шт.', 'price': 250.0, 'section': LineItemSection.work, 'category': 'Электромонтаж'},
    {'description': 'Демонтаж старого потолка по цене 100 за кв.м.', 'unit': 'м²', 'price': 100.0, 'section': LineItemSection.work, 'category': 'Подготовка'},
    {'description': 'Выравнивание потолка по цене 150 за кв.м.', 'unit': 'м²', 'price': 150.0, 'section': LineItemSection.work, 'category': 'Подготовка'},
  ];

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
                      const Text(
                        'Быстрое добавление',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1D1D1F),
                          letterSpacing: -0.5,
                        ),
                      ),
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
}
