import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/project.dart';
import '../models/quote.dart';
import '../models/expense.dart';
import '../models/advance.dart';
import '../database/database_helper.dart';
import '../widgets/quote_selector_widget.dart';
import '../widgets/installers_widget.dart';
import '../widgets/advances_widget.dart';

class ProjectEditScreen extends StatefulWidget {
  final Project? project;

  const ProjectEditScreen({super.key, this.project});

  @override
  State<ProjectEditScreen> createState() => _ProjectEditScreenState();
}

class _ProjectEditScreenState extends State<ProjectEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _budgetController = TextEditingController();
  final _notesController = TextEditingController();
  
  // Focus nodes для управления клавиатурой
  final _nameFocusNode = FocusNode();
  final _addressFocusNode = FocusNode();
  final _customerNameFocusNode = FocusNode();
  final _customerPhoneFocusNode = FocusNode();
  final _budgetFocusNode = FocusNode();
  final _notesFocusNode = FocusNode();

  ProjectStatus _selectedStatus = ProjectStatus.planning;
  DateTime? _startDate;
  DateTime? _endDate;
  int? _selectedQuoteId;
  String? _driverName;
  List<String> _installers = [];
  List<Advance> _advances = [];

  List<Expense> _expenses = [];
  List<SalaryPayment> _salaryPayments = [];

  bool _isLoading = false;

  @override
  void dispose() {
    // Очищаем controllers и focus nodes
    _nameController.dispose();
    _addressController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _budgetController.dispose();
    _notesController.dispose();
    
    _nameFocusNode.dispose();
    _addressFocusNode.dispose();
    _customerNameFocusNode.dispose();
    _customerPhoneFocusNode.dispose();
    _budgetFocusNode.dispose();
    _notesFocusNode.dispose();
    
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    
    if (widget.project != null) {
      _loadProjectData();
    }
    
    // Добавляем listener для автоматического пересчета зарплаты
    _budgetController.addListener(_recalculateSalary);
  }

  void _loadProjectData() {
    final project = widget.project!;
    _nameController.text = project.name;
    _addressController.text = project.address ?? '';
    _customerNameController.text = project.customerName ?? '';
    _customerPhoneController.text = project.customerPhone ?? '';
    _budgetController.text = project.plannedBudget.toString();
    _notesController.text = project.notes ?? '';
    _selectedStatus = project.status;
    _startDate = project.startDate;
    _endDate = project.endDate;
    _selectedQuoteId = project.quoteId;
    _driverName = project.driverName;
    _installers = List.from(project.installers);
    _loadExpensesAndSalary();
  }

  Future<void> _loadExpensesAndSalary() async {
    if (widget.project?.id == null) return;

    try {
      // Загрузка расходов
      final expensesData = await DatabaseHelper.instance.query(
        'expenses',
        where: 'project_id = ?',
        whereArgs: [widget.project!.id],
      );
      
      // Загрузка выплат зарплаты
      final salaryData = await DatabaseHelper.instance.query(
        'salary_payments',
        where: 'project_id = ?',
        whereArgs: [widget.project!.id],
      );
      
      setState(() {
        _expenses = expensesData.map((map) => Expense.fromMap(map)).toList();
        _salaryPayments = salaryData.map((map) => SalaryPayment.fromMap(map)).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки данных: $e')),
        );
      }
    }
  }

  Future<void> _loadQuoteData(int quoteId) async {
    try {
      final data = await DatabaseHelper.instance.query(
        'quotes',
        where: 'quote_id = ?',
        whereArgs: [quoteId],
      );
      
      if (data.isNotEmpty) {
        final quote = Quote.fromMap(data.first);
        
        setState(() {
          // Автоматически заполняем поля из предложения
          _customerNameController.text = quote.customerName;
          _customerPhoneController.text = quote.customerPhone ?? '';
          _addressController.text = quote.address ?? '';
          _budgetController.text = quote.totalAmount.toString();
          // НЕ создаем автоматически расходы на материалы - они вводятся по факту
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки предложения: $e')),
        );
      }
    }
  }

  void _recalculateSalary() {
    if (mounted) {
      setState(() {});
    }
  }

  Map<String, double> _calculateSalaryDistribution(double plannedBudget, List<String> installers, double actualExpenses) {
    if (plannedBudget <= 0 || installers.isEmpty) {
      return {
        'driver': 0.0,
        'installer': 0.0,
        'total': 0.0,
      };
    }

    // Затраты на материалы - по факту
    final materialsExpenses = actualExpenses;
    
    // Остаток после материалов
    final remainingAmount = plannedBudget - materialsExpenses;
    
    // Зарплата водителя = 5% от остатка
    final driverSalary = remainingAmount * 0.05;
    
    // Остаток делится на количество монтажников
    final installerSalary = installers.isNotEmpty ? (remainingAmount - driverSalary) / installers.length : 0.0;

    return {
      'driver': driverSalary,
      'installer': installerSalary,
      'total': driverSalary + (installerSalary * installers.length),
    };
  }

  Future<void> _saveProject() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Расчитываем зарплату по новой формуле
      final plannedBudget = double.tryParse(_budgetController.text) ?? 0.0;
      final actualExpenses = _expenses.fold(0.0, (sum, expense) => sum + expense.amount);
      final salaryDistribution = _calculateSalaryDistribution(plannedBudget, _installers, actualExpenses);
      
      final project = Project(
        id: widget.project?.id,
        name: _nameController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        customerName: _customerNameController.text.trim().isEmpty ? null : _customerNameController.text.trim(),
        customerPhone: _customerPhoneController.text.trim().isEmpty ? null : _customerPhoneController.text.trim(),
        status: _selectedStatus,
        startDate: _startDate,
        endDate: _endDate,
        plannedBudget: plannedBudget,
        actualExpenses: _expenses.fold(0.0, (sum, expense) => sum + expense.amount),
        totalSalary: _salaryPayments.fold(0.0, (sum, payment) => sum + payment.amount),
        profit: plannedBudget - _expenses.fold(0.0, (sum, expense) => sum + expense.amount) - _salaryPayments.fold(0.0, (sum, payment) => sum + payment.amount),
        quoteId: _selectedQuoteId,
        driverName: _driverName?.trim().isEmpty ?? true ? null : _driverName?.trim(),
        installers: _installers,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        createdAt: widget.project?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Рассчитываем прибыль
      final totalExpenses = project.actualExpenses + project.totalSalary;
      final profit = project.plannedBudget - totalExpenses;
      final projectWithProfit = project.copyWith(profit: profit);

      // Сохранение проекта
      int? projectId;
      if (widget.project?.id != null) {
        await DatabaseHelper.instance.update(
          'projects',
          projectWithProfit.toMap(),
          where: 'project_id = ?',
          whereArgs: [widget.project!.id],
        );
        projectId = widget.project!.id;
      } else {
        projectId = await DatabaseHelper.instance.insert('projects', projectWithProfit.toMap());
      }

      // Сохранение расходов
      await DatabaseHelper.instance.delete(
        'expenses',
        where: 'project_id = ?',
        whereArgs: [projectId],
      );
      for (final expense in _expenses) {
        final expenseWithProjectId = expense.copyWith(projectId: projectId!);
        await DatabaseHelper.instance.insert('expenses', expenseWithProjectId.toMap());
      }

      // Сохранение зарплат
      await DatabaseHelper.instance.delete(
        'salary_payments',
        where: 'project_id = ?',
        whereArgs: [projectId],
      );
      for (final payment in _salaryPayments) {
        final paymentWithProjectId = payment.copyWith(projectId: projectId!);
        await DatabaseHelper.instance.insert('salary_payments', paymentWithProjectId.toMap());
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Проект сохранен'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
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

  void _addExpense() {
    showDialog(
      context: context,
      builder: (context) => _AddExpenseDialog(
        onAdd: (expense) {
          setState(() {
            _expenses.add(expense);
            _recalculateSalary(); // Автоматический пересчет
          });
        },
      ),
    );
  }

  void _addSalaryPayment() {
    showDialog(
      context: context,
      builder: (context) => _AddSalaryDialog(
        onAdd: (payment) {
          setState(() {
            _salaryPayments.add(payment);
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalExpenses = _expenses.fold(0.0, (sum, expense) => sum + expense.amount);
    final totalSalary = _salaryPayments.fold(0.0, (sum, payment) => sum + payment.amount);
    final plannedBudget = double.tryParse(_budgetController.text) ?? 0.0;
    final profit = plannedBudget - totalExpenses - totalSalary;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(widget.project == null ? 'Новый проект' : 'Редактировать проект'),
        backgroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: Color(0xFF1D1D1F),
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
        iconTheme: const IconThemeData(color: Color(0xFF007AFF)),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBasicInfo(),
              const SizedBox(height: 24),
              _buildFinancialSummary(plannedBudget, totalExpenses, totalSalary, profit),
              const SizedBox(height: 24),
              _buildExpensesSection(),
              const SizedBox(height: 24),
              _buildSalarySection(),
              const SizedBox(height: 32),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfo() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E5E7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Основная информация',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1D1D1F),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              focusNode: _nameFocusNode,
              autofocus: false,
              decoration: const InputDecoration(
                labelText: 'Название проекта *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Введите название проекта';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              focusNode: _addressFocusNode,
              autofocus: false,
              decoration: const InputDecoration(
                labelText: 'Адрес',
                border: OutlineInputBorder(),
                floatingLabelStyle: TextStyle(color: Color(0xFF007AFF)),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _customerNameController,
              focusNode: _customerNameFocusNode,
              autofocus: false,
              decoration: const InputDecoration(
                labelText: 'Имя клиента',
                border: OutlineInputBorder(),
                floatingLabelStyle: TextStyle(color: Color(0xFF007AFF)),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _customerPhoneController,
              focusNode: _customerPhoneFocusNode,
              autofocus: false,
              decoration: const InputDecoration(
                labelText: 'Телефон клиента',
                border: OutlineInputBorder(),
                floatingLabelStyle: TextStyle(color: Color(0xFF007AFF)),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ProjectStatus>(
              value: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Статус',
                border: OutlineInputBorder(),
                floatingLabelStyle: TextStyle(color: Color(0xFF007AFF)),
              ),
              items: ProjectStatus.values.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: status.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(status.label),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _startDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (date != null) {
                        setState(() {
                          _startDate = date;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Дата начала',
                        border: OutlineInputBorder(),
                        floatingLabelStyle: TextStyle(color: Color(0xFF007AFF)),
                      ),
                      child: Text(
                        _startDate != null
                            ? '${_startDate!.day}.${_startDate!.month}.${_startDate!.year}'
                            : 'Выберите дату',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _endDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (date != null) {
                        setState(() {
                          _endDate = date;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Дата окончания',
                        border: OutlineInputBorder(),
                        floatingLabelStyle: TextStyle(color: Color(0xFF007AFF)),
                      ),
                      child: Text(
                        _endDate != null
                            ? '${_endDate!.day}.${_endDate!.month}.${_endDate!.year}'
                            : 'Выберите дату',
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Выбор предложения
            QuoteSelectorWidget(
              selectedQuoteId: _selectedQuoteId,
              onChanged: (quoteId) {
                setState(() {
                  _selectedQuoteId = quoteId;
                });
                if (quoteId != null) {
                  _loadQuoteData(quoteId!);
                }
              },
            ),
            const SizedBox(height: 20),
            
            // Монтажники и водитель
            InstallersWidget(
              driverName: _driverName,
              installers: _installers,
              salaryDistribution: _calculateSalaryDistribution(
                double.tryParse(_budgetController.text) ?? 0.0,
                _installers,
                _expenses.fold(0.0, (sum, expense) => sum + expense.amount),
              ),
              onChanged: (driverName, installers) {
                setState(() {
                  _driverName = driverName;
                  _installers = installers;
                  _recalculateSalary(); // Автоматический пересчет
                });
              },
            ),
            const SizedBox(height: 20),
            
            // Авансы
            AdvancesWidget(
              advances: _advances,
              installers: _installers,
              onAddAdvance: (advance) {
                setState(() {
                  _advances.add(advance.copyWith(projectId: widget.project?.id ?? 0));
                });
              },
              onDeleteAdvance: (advanceId) {
                setState(() {
                  _advances.removeWhere((a) => a.id == advanceId);
                });
              },
            ),
            const SizedBox(height: 20),
            
            TextFormField(
              controller: _budgetController,
              focusNode: _budgetFocusNode,
              autofocus: false,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Планируемый бюджет *',
                border: OutlineInputBorder(),
                prefixText: '₽ ',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Введите бюджет';
                }
                if (double.tryParse(value) == null || double.tryParse(value)! <= 0) {
                  return 'Введите корректную сумму';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              focusNode: _notesFocusNode,
              autofocus: false,
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

  Widget _buildFinancialSummary(double budget, double expenses, double salary, double profit) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E5E7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Финансовый итог',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1D1D1F),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem('Бюджет', budget, const Color(0xFF007AFF)),
                ),
                Expanded(
                  child: _buildSummaryItem('Расходы', expenses, const Color(0xFFFF9500)),
                ),
                Expanded(
                  child: _buildSummaryItem('Зарплата', salary, const Color(0xFF34C759)),
                ),
                Expanded(
                  child: _buildSummaryItem('Прибыль', profit, profit >= 0 ? const Color(0xFF34C759) : const Color(0xFFFF3B30)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF86868B),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${value.toStringAsFixed(0)} ₽',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildExpensesSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E5E7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Расходы',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1D1D1F),
                    letterSpacing: -0.5,
                  ),
                ),
                TextButton.icon(
                  onPressed: _addExpense,
                  icon: const Icon(Icons.add),
                  label: const Text('Добавить'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_expenses.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    'Нет расходов',
                    style: TextStyle(
                      color: const Color(0xFF86868B),
                    ),
                  ),
                ),
              )
            else
              ..._expenses.asMap().entries.map((entry) {
                final index = entry.key;
                final expense = entry.value;
                return _buildExpenseItem(expense, index);
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseItem(Expense expense, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E7)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: expense.type.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getExpenseIcon(expense.type),
              color: expense.type.color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.description,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1D1D1F),
                  ),
                ),
                Text(
                  expense.type.label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF86868B),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${expense.amount.toStringAsFixed(0)} ₽',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              setState(() {
                _expenses.removeAt(index);
                _recalculateSalary(); // Автоматический пересчет
              });
            },
            icon: const Icon(Icons.delete_outline, color: Color(0xFFFF3B30)),
          ),
        ],
      ),
    );
  }

  Widget _buildSalarySection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E5E7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Зарплаты',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1D1D1F),
                    letterSpacing: -0.5,
                  ),
                ),
                TextButton.icon(
                  onPressed: _addSalaryPayment,
                  icon: const Icon(Icons.add),
                  label: const Text('Добавить'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_salaryPayments.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    'Нет зарплат',
                    style: TextStyle(
                      color: const Color(0xFF86868B),
                    ),
                  ),
                ),
              )
            else
              ..._salaryPayments.asMap().entries.map((entry) {
                final index = entry.key;
                final payment = entry.value;
                return _buildSalaryItem(payment, index);
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSalaryItem(SalaryPayment payment, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E7)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF34C759).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.person,
              color: Color(0xFF34C759),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.employeeName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1D1D1F),
                  ),
                ),
                if (payment.workDescription != null)
                  Text(
                    payment.workDescription!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF86868B),
                    ),
                  ),
                Text(
                  '${payment.date.day}.${payment.date.month}.${payment.date.year}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF86868B),
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '${payment.amount.toStringAsFixed(0)} ₽',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              setState(() {
                _salaryPayments.removeAt(index);
              });
            },
            icon: const Icon(Icons.delete_outline, color: Color(0xFFFF3B30)),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF007AFF), Color(0xFF0056CC)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF007AFF).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _saveProject,
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
                  : const Text(
                      'Сохранить проект',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getExpenseIcon(ExpenseType type) {
    switch (type) {
      case ExpenseType.materials:
        return Icons.inventory_2;
      case ExpenseType.salary:
        return Icons.person;
      case ExpenseType.transport:
        return Icons.directions_car;
      case ExpenseType.tools:
        return Icons.build;
      case ExpenseType.other:
        return Icons.more_horiz;
    }
  }
}

class _AddExpenseDialog extends StatefulWidget {
  final Function(Expense) onAdd;

  const _AddExpenseDialog({required this.onAdd});

  @override
  State<_AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<_AddExpenseDialog> {
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  ExpenseType _selectedType = ExpenseType.materials;
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Добавить расход',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1D1D1F),
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<ExpenseType>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Тип расхода',
                border: OutlineInputBorder(),
              ),
              items: ExpenseType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: type.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(type.label),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Описание',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Сумма',
                border: OutlineInputBorder(),
                prefixText: '₽ ',
              ),
            ),
            const SizedBox(height: 16),
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
                  '${_selectedDate.day}.${_selectedDate.month}.${_selectedDate.year}',
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Примечания',
                border: OutlineInputBorder(),
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
                  onPressed: _addExpense,
                  child: const Text('Добавить'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _addExpense() {
    final description = _descriptionController.text.trim();
    final amount = double.tryParse(_amountController.text);

    if (description.isEmpty || amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заполните все поля')),
      );
      return;
    }

    final expense = Expense(
      projectId: 0, // Будет установлен позже
      type: _selectedType,
      description: description,
      amount: amount,
      date: _selectedDate,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      createdAt: DateTime.now(),
    );

    widget.onAdd(expense);
    Navigator.pop(context);
  }
}

class _AddSalaryDialog extends StatefulWidget {
  final Function(SalaryPayment) onAdd;

  const _AddSalaryDialog({required this.onAdd});

  @override
  State<_AddSalaryDialog> createState() => _AddSalaryDialogState();
}

class _AddSalaryDialogState extends State<_AddSalaryDialog> {
  final _employeeNameController = TextEditingController();
  final _amountController = TextEditingController();
  final _workDescriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Добавить зарплату',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1D1D1F),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _employeeNameController,
              decoration: const InputDecoration(
                labelText: 'Имя сотрудника',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Сумма',
                border: OutlineInputBorder(),
                prefixText: '₽ ',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _workDescriptionController,
              decoration: const InputDecoration(
                labelText: 'Описание работ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
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
                  '${_selectedDate.day}.${_selectedDate.month}.${_selectedDate.year}',
                ),
              ),
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
                  onPressed: _addSalary,
                  child: const Text('Добавить'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _addSalary() {
    final employeeName = _employeeNameController.text.trim();
    final amount = double.tryParse(_amountController.text);

    if (employeeName.isEmpty || amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заполните все поля')),
      );
      return;
    }

    final payment = SalaryPayment(
      projectId: 0, // Будет установлен позже
      employeeName: employeeName,
      amount: amount,
      date: _selectedDate,
      workDescription: _workDescriptionController.text.trim().isEmpty ? null : _workDescriptionController.text.trim(),
      createdAt: DateTime.now(),
    );

    widget.onAdd(payment);
    Navigator.pop(context);
  }
}
