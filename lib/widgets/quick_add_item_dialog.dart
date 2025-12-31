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
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _priceController = TextEditingController();
  final _unitController = TextEditingController(text: 'м²');
  final _noteController = TextEditingController();

  final List<String> _commonDescriptions = [
    'Монтаж натяжного потолка',
    'Полотно ПВХ белое',
    'Полотно сатиновое',
    'Полотно матовое',
    'Багет пластиковый',
    'Багет алюминиевый',
    'Профиль стартовый',
    'Профиль направляющий',
    'Подвес прямой',
    'Точечный светильник',
    'Светодиодная лента',
    'Диммер',
    'Трансформатор',
  ];

  final List<String> _commonUnits = ['м²', 'м.п.', 'шт.', 'компл.'];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Быстрое добавление - ${widget.section == LineItemSection.work ? 'Работы' : 'Оборудование'}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Быстрые описания
            const Text('Быстрые описания:', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _commonDescriptions.map((desc) {
                return ActionChip(
                  label: Text(desc, style: const TextStyle(fontSize: 12)),
                  onPressed: () {
                    _descriptionController.text = desc;
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            
            // Описание
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Описание *',
                border: OutlineInputBorder(),
                hintText: 'Введите описание позиции',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _quantityController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Количество *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 100,
                  child: DropdownButtonFormField<String>(
                    value: _unitController.text,
                    decoration: const InputDecoration(
                      labelText: 'Ед.изм.',
                      border: OutlineInputBorder(),
                    ),
                    items: _commonUnits.map((unit) {
                      return DropdownMenuItem(
                        value: unit,
                        child: Text(unit),
                      );
                    }).toList(),
                    onChanged: (value) {
                      _unitController.text = value ?? 'м²';
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            TextFormField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Цена за единицу *',
                border: OutlineInputBorder(),
                prefixText: '₽ ',
              ),
            ),
            const SizedBox(height: 12),
            
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Примечание',
                border: OutlineInputBorder(),
                hintText: 'Дополнительная информация',
              ),
              maxLines: 2,
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
                  onPressed: _addItem,
                  child: const Text('Добавить'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _addItem() {
    final description = _descriptionController.text.trim();
    final quantity = double.tryParse(_quantityController.text);
    final price = double.tryParse(_priceController.text);

    if (description.isEmpty || quantity == null || price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заполните все обязательные поля')),
      );
      return;
    }

    final amount = quantity * price;
    
    final item = LineItem(
      id: null,
      quoteId: 0, // Будет установлен позже
      position: 1, // Будет установлен позже
      section: widget.section,
      description: description,
      unit: _unitController.text,
      quantity: quantity,
      price: price,
      amount: amount,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    Navigator.pop(context, item);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _unitController.dispose();
    _noteController.dispose();
    super.dispose();
  }
}
