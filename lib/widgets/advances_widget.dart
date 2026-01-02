import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/advance.dart';

class AdvancesWidget extends StatelessWidget {
  final List<Advance> advances;
  final List<String> installers;
  final Function(Advance) onAddAdvance;
  final Function(int) onDeleteAdvance;

  const AdvancesWidget({
    super.key,
    required this.advances,
    required this.installers,
    required this.onAddAdvance,
    required this.onDeleteAdvance,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'ru_RU',
      symbol: '₽',
      decimalDigits: 0,
    );

    // Разделяем авансы по типам
    final projectAdvances = advances.where((a) => a.type == AdvanceType.project).toList();
    final installerAdvances = advances.where((a) => a.type == AdvanceType.installer).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок с кнопкой добавления
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance_wallet, color: const Color(0xFF007AFF)),
                const SizedBox(width: 8),
                Text(
                  'Авансы',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1D1D1F),
                  ),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: () => _showAddAdvanceDialog(context),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Добавить'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007AFF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Авансы по объекту
        if (projectAdvances.isNotEmpty) ...[
          Text(
            'По объекту',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          ...projectAdvances.map((advance) => _buildAdvanceCard(advance, currencyFormat, onDeleteAdvance)).toList(),
          const SizedBox(height: 16),
        ],

        // Авансы монтажникам
        if (installerAdvances.isNotEmpty) ...[
          Text(
            'Монтажникам',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          ...installerAdvances.map((advance) => _buildAdvanceCard(advance, currencyFormat, onDeleteAdvance)).toList(),
          const SizedBox(height: 16),
        ],

        // Итоговая информация
        if (advances.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF007AFF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF007AFF).withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Итого по авансам:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF007AFF),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '• По объекту: ${currencyFormat.format(projectAdvances.fold(0.0, (sum, a) => sum + a.amount))}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  '• Монтажникам: ${currencyFormat.format(installerAdvances.fold(0.0, (sum, a) => sum + a.amount))}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  '• Всего: ${currencyFormat.format(advances.fold(0.0, (sum, a) => sum + a.amount))}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF007AFF),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Если авансов еще нет
        if (advances.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                Icon(Icons.account_balance_wallet_outlined, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Авансов еще нет',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Нажмите "Добавить" чтобы выдать аванс',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAdvanceCard(Advance advance, NumberFormat currencyFormat, Function(int) onDelete) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      advance.type == AdvanceType.project ? Icons.business : Icons.person,
                      size: 16,
                      color: advance.type == AdvanceType.project ? Colors.blue : Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      advance.type == AdvanceType.project 
                          ? 'Аванс по объекту'
                          : 'Аванс: ${advance.installerName ?? "Неизвестно"}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (advance.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    advance.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd.MM.yyyy').format(advance.date),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currencyFormat.format(advance.amount),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: advance.type == AdvanceType.project ? Colors.blue : Colors.green,
                ),
              ),
              const SizedBox(height: 4),
              IconButton(
                onPressed: () => onDelete(advance.id!),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddAdvanceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _AddAdvanceDialog(
        installers: installers,
        onAdd: onAddAdvance,
      ),
    );
  }
}

class _AddAdvanceDialog extends StatefulWidget {
  final List<String> installers;
  final Function(Advance) onAdd;

  const _AddAdvanceDialog({
    required this.installers,
    required this.onAdd,
  });

  @override
  State<_AddAdvanceDialog> createState() => _AddAdvanceDialogState();
}

class _AddAdvanceDialogState extends State<_AddAdvanceDialog> {
  AdvanceType _selectedType = AdvanceType.project;
  String? _selectedInstaller;
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Добавить аванс'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Тип аванса
            DropdownButtonFormField<AdvanceType>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Тип аванса',
                border: OutlineInputBorder(),
              ),
              items: AdvanceType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type == AdvanceType.project ? 'По объекту' : 'Монтажнику'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                  if (value == AdvanceType.project) {
                    _selectedInstaller = null;
                  }
                });
              },
            ),

            const SizedBox(height: 16),

            // Выбор монтажника (если тип - монтажнику)
            if (_selectedType == AdvanceType.installer) ...[
              DropdownButtonFormField<String>(
                value: _selectedInstaller,
                decoration: const InputDecoration(
                  labelText: 'Монтажник',
                  border: OutlineInputBorder(),
                ),
                items: widget.installers.map((installer) {
                  return DropdownMenuItem(
                    value: installer,
                    child: Text(installer),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedInstaller = value;
                  });
                },
              ),
              const SizedBox(height: 16),
            ],

            // Сумма
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Сумма',
                prefixText: '₽ ',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Введите сумму';
                }
                if (double.tryParse(value) == null || double.tryParse(value)! <= 0) {
                  return 'Введите корректную сумму';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Описание
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Описание',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // Дата
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (date != null) {
                  setState(() {
                    _selectedDate = date;
                  });
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Дата',
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  DateFormat('dd.MM.yyyy').format(_selectedDate),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _addAdvance,
          child: const Text('Добавить'),
        ),
      ],
    );
  }

  void _addAdvance() {
    if (_amountController.text.trim().isEmpty) return;
    if (_selectedType == AdvanceType.installer && _selectedInstaller == null) return;

    final advance = Advance(
      projectId: 0, // Будет установлено в parent
      type: _selectedType,
      installerName: _selectedType == AdvanceType.installer ? _selectedInstaller : null,
      amount: double.tryParse(_amountController.text) ?? 0.0,
      description: _descriptionController.text.trim(),
      date: _selectedDate,
      createdAt: DateTime.now(),
    );

    widget.onAdd(advance);
    Navigator.pop(context);
  }
}
