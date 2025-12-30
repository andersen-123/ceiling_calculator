import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/line_item.dart';
import '../models/quote.dart';

class LineItemWidget extends StatefulWidget {
  final LineItem item;
  final Function(LineItem) onChanged;
  final VoidCallback onRemove;

  const LineItemWidget({
    super.key,
    required this.item,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  State<LineItemWidget> createState() => _LineItemWidgetState();
}

class _LineItemWidgetState extends State<LineItemWidget> {
  late TextEditingController _descriptionController;
  late TextEditingController _quantityController;
  late TextEditingController _priceController;
  late TextEditingController _noteController;
  late String _selectedUnit;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: widget.item.description);
    _quantityController = TextEditingController(text: widget.item.quantity.toString());
    _priceController = TextEditingController(text: widget.item.price.toString());
    _noteController = TextEditingController(text: widget.item.note ?? '');
    _selectedUnit = widget.item.unit;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _updateItem() {
    final quantity = double.tryParse(_quantityController.text) ?? 0.0;
    final price = double.tryParse(_priceController.text) ?? 0.0;
    
    final updatedItem = widget.item.copyWith(
      description: _descriptionController.text,
      unit: _selectedUnit,
      quantity: quantity,
      price: price,
      amount: quantity * price,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );
    
    widget.onChanged(updatedItem);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: widget.item.section == LineItemSection.work 
                        ? Colors.blue[100] 
                        : Colors.green[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      widget.item.position.toString(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: widget.item.section == LineItemSection.work 
                            ? Colors.blue[800] 
                            : Colors.green[800],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.item.section.displayName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: widget.item.section == LineItemSection.work 
                          ? Colors.blue[700] 
                          : Colors.green[700],
                    ),
                  ),
                ),
                IconButton(
                  onPressed: widget.onRemove,
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  iconSize: 20,
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Описание *',
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onChanged: (_) => _updateItem(),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: _selectedUnit,
                    decoration: const InputDecoration(
                      labelText: 'Ед.изм.',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: Unit.defaultUnits.map((unit) {
                      return DropdownMenuItem(
                        value: unit.code,
                        child: Text(unit.displayName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedUnit = value;
                        });
                        _updateItem();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Кол-во',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$'))],
                    onChanged: (_) => _updateItem(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Цена',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$'))],
                    onChanged: (_) => _updateItem(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _noteController,
                    decoration: const InputDecoration(
                      labelText: 'Примечание',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onChanged: (_) => _updateItem(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.grey[100],
                  ),
                  child: Text(
                    '${widget.item.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
