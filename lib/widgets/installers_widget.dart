import 'package:flutter/material.dart';

class InstallersWidget extends StatefulWidget {
  final String? driverName;
  final List<String> installers;
  final Function(String? driverName, List<String> installers) onChanged;
  final Map<String, double>? salaryDistribution; // Добавляем параметр для зарплаты

  const InstallersWidget({
    super.key,
    this.driverName,
    required this.installers,
    required this.onChanged,
    this.salaryDistribution, // Опциональный параметр
  });

  @override
  State<InstallersWidget> createState() => _InstallersWidgetState();
}

class _InstallersWidgetState extends State<InstallersWidget> {
  late TextEditingController _driverController;
  late List<String> _installers;
  late TextEditingController _newInstallerController;

  @override
  void initState() {
    super.initState();
    _driverController = TextEditingController(text: widget.driverName ?? '');
    _installers = List.from(widget.installers);
    _newInstallerController = TextEditingController();
  }

  @override
  void dispose() {
    _driverController.dispose();
    _newInstallerController.dispose();
    super.dispose();
  }

  void _addInstaller() {
    final name = _newInstallerController.text.trim();
    if (name.isNotEmpty && !_installers.contains(name)) {
      setState(() {
        _installers.add(name);
        _newInstallerController.clear();
      });
      _notifyChanged();
    }
  }

  void _removeInstaller(int index) {
    setState(() {
      _installers.removeAt(index);
    });
    _notifyChanged();
  }

  void _notifyChanged() {
    widget.onChanged(
      _driverController.text.trim().isEmpty ? null : _driverController.text.trim(),
      _installers,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Водитель
        Text(
          'Водитель (кто на машине)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1D1D1F),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _driverController,
          decoration: InputDecoration(
            hintText: 'Введите имя водителя',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: const Color(0xFFF5F5F7),
          ),
          onChanged: (value) => _notifyChanged(),
        ),
        
        // Зарплата водителя
        if (widget.salaryDistribution != null && 
            widget.salaryDistribution!['driver'] != null && 
            widget.salaryDistribution!['driver']! > 0 &&
            _driverController.text.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.account_balance_wallet, size: 16, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  'Зарплата водителя: ${widget.salaryDistribution!['driver']!.toStringAsFixed(0)} ₽',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),

        // Монтажники
        Text(
          'Монтажники',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1D1D1F),
          ),
        ),
        const SizedBox(height: 8),
        
        // Добавление монтажника
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _newInstallerController,
                decoration: InputDecoration(
                  hintText: 'Имя монтажника',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F7),
                ),
                onSubmitted: (_) => _addInstaller(),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _addInstaller,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007AFF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Добавить'),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Список монтажников
        if (_installers.isNotEmpty) ...[
          const SizedBox(height: 12),
          ..._installers.asMap().entries.map((entry) {
            final index = entry.key;
            final installer = entry.value;
            final salary = widget.salaryDistribution != null 
                ? widget.salaryDistribution!['installer'] ?? 0.0
                : 0.0;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.person, size: 20, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text(
                          installer,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.salaryDistribution != null && salary > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Text(
                        '${salary.toStringAsFixed(0)} ₽',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.green[700],
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _installers.removeAt(index);
                        widget.onChanged(_driverController.text.trim().isEmpty ? null : _driverController.text.trim(), _installers);
                      });
                    },
                    icon: Icon(Icons.remove_circle_outline, color: Colors.red[400]),
                    iconSize: 20,
                  ),
                ],
              ),
            );
          }).toList(),
        ],

        // Информация о расчете
        if (_installers.isNotEmpty) ...[
          const SizedBox(height: 16),
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
                  'Расчет зарплаты:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF007AFF),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '• Затраты на материалы - по факту',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  '• Бензин - по факту (в расходах)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  '• 5% от остатка - водителю',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  '• Остаток (95%) делится на монтажников',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
