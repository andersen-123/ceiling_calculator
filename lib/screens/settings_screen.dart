import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/company.dart';
import '../models/settings.dart';
import '../database/database_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _companyNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _addressController = TextEditingController();
  final _footerNoteController = TextEditingController();

  String? _logoPath;
  String _selectedCurrency = 'RUB';
  bool _isLoading = false;
  Company? _company;
  AppSettings? _settings;

  final List<String> _currencies = [
    'RUB',
    'USD',
    'EUR',
    'BYN',
    'KZT',
    'UZS',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    _footerNoteController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Загрузка компании
      final companyData = await DatabaseHelper.instance.query(
        'companies',
        limit: 1,
      );
      if (companyData.isNotEmpty) {
        _company = Company.fromMap(companyData.first);
        _companyNameController.text = _company!.name;
        _phoneController.text = _company!.phone ?? '';
        _emailController.text = _company!.email ?? '';
        _websiteController.text = _company!.website ?? '';
        _addressController.text = _company!.address ?? '';
        _footerNoteController.text = _company!.footerNote ?? '';
        _logoPath = _company!.logoPath;
      }

      // Загрузка настроек
      final settingsData = await DatabaseHelper.instance.query('settings');
      final settingsMap = <String, String>{};
      for (final row in settingsData) {
        settingsMap[row['setting_key'] as String] = row['setting_value'] as String;
      }
      
      _settings = AppSettings(
        currencyCode: settingsMap[SettingKey.currencyCode] ?? 'RUB',
        defaultCompanyId: int.tryParse(settingsMap[SettingKey.defaultCompanyId] ?? ''),
        language: settingsMap[SettingKey.language] ?? 'ru',
        requireAuth: settingsMap[SettingKey.requireAuth] == '1',
        pinCode: settingsMap[SettingKey.pinCode],
      );
      
      _selectedCurrency = _settings!.currencyCode;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки настроек: $e')),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      
      if (pickedFile != null) {
        setState(() {
          _logoPath = pickedFile.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка выбора изображения: $e')),
        );
      }
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);

    try {
      // Сохранение компании
      final company = Company(
        id: _company?.id,
        name: _companyNameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        website: _websiteController.text.trim().isEmpty ? null : _websiteController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        footerNote: _footerNoteController.text.trim().isEmpty ? null : _footerNoteController.text.trim(),
        logoPath: _logoPath,
      );

      if (_company?.id != null) {
        await DatabaseHelper.instance.update(
          'companies',
          company.toMap(),
          where: 'company_id = ?',
          whereArgs: [_company!.id],
        );
      } else {
        await DatabaseHelper.instance.insert('companies', company.toMap());
      }

      // Сохранение настроек
      final settings = AppSettings(
        currencyCode: _selectedCurrency,
        defaultCompanyId: _settings?.defaultCompanyId,
        language: _settings?.language ?? 'ru',
        requireAuth: _settings?.requireAuth ?? false,
        pinCode: _settings?.pinCode,
      );

      await DatabaseHelper.instance.update(
        'settings',
        {'setting_value': settings.currencyCode},
        where: 'setting_key = ?',
        whereArgs: [SettingKey.currencyCode],
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Настройки сохранены')),
        );
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

  Future<void> _createBackup() async {
    // TODO: Реализовать создание резервной копии
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Функция резервного копирования в разработке')),
    );
  }

  Future<void> _restoreBackup() async {
    // TODO: Реализовать восстановление из резервной копии
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Функция восстановления в разработке')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveSettings,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCompanySettings(),
                  const SizedBox(height: 24),
                  _buildAppSettings(),
                  const SizedBox(height: 24),
                  _buildBackupSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildCompanySettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Информация о компании', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            // Логотип
            Center(
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _logoPath != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              _logoPath!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.business, size: 50, color: Colors.grey);
                              },
                            ),
                          )
                        : const Icon(Icons.business, size: 50, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Выбрать логотип'),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            TextFormField(
              controller: _companyNameController,
              decoration: const InputDecoration(
                labelText: 'Название компании *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Телефон',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _websiteController,
              decoration: const InputDecoration(
                labelText: 'Сайт',
                border: OutlineInputBorder(),
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
            TextFormField(
              controller: _footerNoteController,
              decoration: const InputDecoration(
                labelText: 'Примечание для подвала PDF',
                border: OutlineInputBorder(),
                hintText: 'Дополнительная информация для документов',
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Настройки приложения', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            DropdownButtonFormField<String>(
              value: _selectedCurrency,
              decoration: const InputDecoration(
                labelText: 'Валюта по умолчанию',
                border: OutlineInputBorder(),
              ),
              items: _currencies.map((currency) {
                return DropdownMenuItem(
                  value: currency,
                  child: Text(currency),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCurrency = value!;
                });
              },
            ),
            
            const SizedBox(height: 12),
            const Text(
              'Язык интерфейса',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text('Русский'),
            
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Требовать аутентификацию'),
              subtitle: const Text('Запрашивать PIN-код при входе'),
              value: _settings?.requireAuth ?? false,
              onChanged: (value) {
                setState(() {
                  _settings = _settings?.copyWith(requireAuth: value);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Резервное копирование', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _createBackup,
                icon: const Icon(Icons.backup),
                label: const Text('Создать резервную копию'),
              ),
            ),
            const SizedBox(height: 12),
            
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _restoreBackup,
                icon: const Icon(Icons.restore),
                label: const Text('Восстановить из копии'),
              ),
            ),
            
            const SizedBox(height: 16),
            const Text(
              'Резервная копия содержит все коммерческие предложения, настройки и данные компании. '
              'Рекомендуется создавать копии регулярно для защиты данных.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
