import 'package:flutter/material.dart';

class InstallersWidget extends StatefulWidget {
  final String? driverName;
  final List<String> installers;
  final Function(String? driverName, List<String> installers) onChanged;

  const InstallersWidget({
    super.key,
    this.driverName,
    required this.installers,
    required this.onChanged,
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
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE5E5E7)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: _installers.asMap().entries.map((entry) {
                final index = entry.key;
                final name = entry.value;
                return ListTile(
                  title: Text(name),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: () => _removeInstaller(index),
                  ),
                );
              }).toList(),
            ),
          ),
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
                  '• 50% - материалы, бензин и прочее',
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
                  '• Остаток делится на монтажников',
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
