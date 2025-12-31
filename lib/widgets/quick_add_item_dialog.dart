import 'package:flutter/material.dart';
import '../models/line_item.dart';

class QuickAddItemDialog extends StatefulWidget {
  final LineItemSection section;

  const QuickAddItemDialog({
    super.key,
    required this.section,
  });

  @override
  State<QuickAddItemDialog> createState() => _QuickAddItemDialogState();
}

class _QuickAddItemDialogState extends State<QuickAddItemDialog> {
  final List<Map<String, dynamic>> _commonItems = [
    // Работы
    {'description': 'Монтаж натяжного потолка', 'unit': 'м²', 'price': 350.0, 'section': LineItemSection.work},
    {'description': 'Монтаж многоуровневого потолка', 'unit': 'м²', 'price': 550.0, 'section': LineItemSection.work},
    {'description': 'Монтаж натяжного потолка с фотопечатью', 'unit': 'м²', 'price': 450.0, 'section': LineItemSection.work},
    {'description': 'Установка светильников', 'unit': 'шт.', 'price': 150.0, 'section': LineItemSection.work},
    {'description': 'Монтаж светодиодной ленты', 'unit': 'м.п.', 'price': 200.0, 'section': LineItemSection.work},
    {'description': 'Установка диммера', 'unit': 'шт.', 'price': 250.0, 'section': LineItemSection.work},
    {'description': 'Демонтаж старого потолка', 'unit': 'м²', 'price': 100.0, 'section': LineItemSection.work},
    {'description': 'Выравнивание потолка', 'unit': 'м²', 'price': 150.0, 'section': LineItemSection.work},
    
    // Оборудование
    {'description': 'Полотно ПВХ белое матовое', 'unit': 'м²', 'price': 120.0, 'section': LineItemSection.equipment},
    {'description': 'Полотно ПВХ белое сатиновое', 'unit': 'м²', 'price': 140.0, 'section': LineItemSection.equipment},
    {'description': 'Полотно с фотопечатью', 'unit': 'м²', 'price': 350.0, 'section': LineItemSection.equipment},
    {'description': 'Багет пластиковый белый', 'unit': 'м.п.', 'price': 80.0, 'section': LineItemSection.equipment},
    {'description': 'Багет алюминиевый', 'unit': 'м.п.', 'price': 120.0, 'section': LineItemSection.equipment},
    {'description': 'Профиль стартовый', 'unit': 'м.п.', 'price': 60.0, 'section': LineItemSection.equipment},
    {'description': 'Профиль направляющий', 'unit': 'м.п.', 'price': 70.0, 'section': LineItemSection.equipment},
    {'description': 'Подвес прямой', 'unit': 'шт.', 'price': 15.0, 'section': LineItemSection.equipment},
    {'description': 'Точечный светильник', 'unit': 'шт.', 'price': 250.0, 'section': LineItemSection.equipment},
    {'description': 'Светодиодная лента', 'unit': 'м.п.', 'price': 80.0, 'section': LineItemSection.equipment},
    {'description': 'Диммер', 'unit': 'шт.', 'price': 350.0, 'section': LineItemSection.equipment},
    {'description': 'Трансформатор', 'unit': 'шт.', 'price': 280.0, 'section': LineItemSection.equipment},
  ];

  @override
  Widget build(BuildContext context) {
    final filteredItems = _commonItems.where((item) => item['section'] == widget.section).toList();
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: widget.section == LineItemSection.work ? Colors.blue.shade50 : Colors.orange.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Быстрое добавление - ${widget.section == LineItemSection.work ? 'Работы' : 'Оборудование'}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: widget.section == LineItemSection.work ? Colors.blue.shade800 : Colors.orange.shade800,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            
            // Items list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredItems.length,
                itemBuilder: (context, index) {
                  final item = filteredItems[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: InkWell(
                      onTap: () => _addItem(item),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['description'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    item['unit'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${item['price'].toStringAsFixed(0)} ₽/${item['unit']}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: widget.section == LineItemSection.work ? Colors.blue.shade600 : Colors.orange.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ],
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
      quoteId: 0, // Будет установлен позже
      position: 1, // Будет установлен позже
      section: widget.section,
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
