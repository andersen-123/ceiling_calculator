import 'package:flutter/material.dart';

enum ProjectStatus {
  planning('Планирование', Colors.blue),
  inProgress('В работе', Colors.orange),
  completed('Завершен', Colors.green),
  suspended('Приостановлен', Colors.grey),
  cancelled('Отменен', Colors.red);

  const ProjectStatus(this.label, this.color);
  final String label;
  final Color color;
}

enum ExpenseType {
  materials('Материалы', Colors.purple),
  salary('Зарплата', Colors.green),
  transport('Транспорт', Colors.blue),
  tools('Инструменты', Colors.orange),
  other('Прочее', Colors.grey);

  const ExpenseType(this.label, this.color);
  final String label;
  final Color color;
}

class Project {
  final int? id;
  final String name;
  final String? address;
  final String? customerName;
  final String? customerPhone;
  final ProjectStatus status;
  final DateTime? startDate;
  final DateTime? endDate;
  final double plannedBudget;
  final double actualExpenses;
  final double totalSalary;
  final double profit;
  final int? quoteId;
  final String? driverName;
  final List<String> installers;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Project({
    this.id,
    required this.name,
    this.address,
    this.customerName,
    this.customerPhone,
    required this.status,
    this.startDate,
    this.endDate,
    required this.plannedBudget,
    this.actualExpenses = 0.0,
    this.totalSalary = 0.0,
    this.profit = 0.0,
    this.quoteId,
    this.driverName,
    this.installers = const [],
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  Project copyWith({
    int? id,
    String? name,
    String? address,
    String? customerName,
    String? customerPhone,
    ProjectStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    double? plannedBudget,
    double? actualExpenses,
    double? totalSalary,
    double? profit,
    int? quoteId,
    String? driverName,
    List<String>? installers,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      plannedBudget: plannedBudget ?? this.plannedBudget,
      actualExpenses: actualExpenses ?? this.actualExpenses,
      totalSalary: totalSalary ?? this.totalSalary,
      profit: profit ?? this.profit,
      quoteId: quoteId ?? this.quoteId,
      driverName: driverName ?? this.driverName,
      installers: installers ?? this.installers,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'project_id': id,
      'name': name,
      'address': address,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'status': status.toString().split('.').last,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'planned_budget': plannedBudget,
      'actual_expenses': actualExpenses,
      'total_salary': totalSalary,
      'profit': profit,
      'quote_id': quoteId,
      'driver_name': driverName,
      'installers': installers.join(','),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['project_id'] as int?,
      name: map['name'] as String,
      address: map['address'] as String?,
      customerName: map['customer_name'] as String?,
      customerPhone: map['customer_phone'] as String?,
      status: ProjectStatus.values.firstWhere(
        (e) => e.toString() == 'ProjectStatus.${map['status']}',
        orElse: () => ProjectStatus.planning,
      ),
      startDate: map['start_date'] != null ? DateTime.parse(map['start_date']) : null,
      endDate: map['end_date'] != null ? DateTime.parse(map['end_date']) : null,
      plannedBudget: map['planned_budget'] as double? ?? 0.0,
      actualExpenses: map['actual_expenses'] as double? ?? 0.0,
      totalSalary: map['total_salary'] as double? ?? 0.0,
      profit: map['profit'] as double? ?? 0.0,
      quoteId: map['quote_id'] as int?,
      driverName: map['driver_name'] as String?,
      installers: (map['installers'] as String? ?? '').isEmpty ? [] : (map['installers'] as String).split(','),
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }

  // Метод расчета зарплаты по новой формуле
  Map<String, double> calculateSalaryDistribution() {
    if (plannedBudget <= 0 || installers.isEmpty) {
      return {
        'driver': 0.0,
        'installer': 0.0,
        'total': 0.0,
      };
    }

    // Затраты на материалы - по факту (из actualExpenses)
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
}

class Expense {
  final int? id;
  final int projectId;
  final ExpenseType type;
  final String description;
  final double amount;
  final DateTime date;
  final String? notes;
  final DateTime createdAt;

  Expense({
    this.id,
    required this.projectId,
    required this.type,
    required this.description,
    required this.amount,
    required this.date,
    this.notes,
    required this.createdAt,
  });

  Expense copyWith({
    int? id,
    int? projectId,
    ExpenseType? type,
    String? description,
    double? amount,
    DateTime? date,
    String? notes,
    DateTime? createdAt,
  }) {
    return Expense(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      type: type ?? this.type,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'expense_id': id,
      'project_id': projectId,
      'type': type.name,
      'description': description,
      'amount': amount,
      'date': date.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['expense_id'],
      projectId: map['project_id'],
      type: ExpenseType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => ExpenseType.other,
      ),
      description: map['description'],
      amount: map['amount']?.toDouble() ?? 0.0,
      date: DateTime.parse(map['date']),
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}

class SalaryPayment {
  final int? id;
  final int projectId;
  final String employeeName;
  final double amount;
  final DateTime date;
  final String? workDescription;
  final DateTime createdAt;

  SalaryPayment({
    this.id,
    required this.projectId,
    required this.employeeName,
    required this.amount,
    required this.date,
    this.workDescription,
    required this.createdAt,
  });

  SalaryPayment copyWith({
    int? id,
    int? projectId,
    String? employeeName,
    double? amount,
    DateTime? date,
    String? workDescription,
    DateTime? createdAt,
  }) {
    return SalaryPayment(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      employeeName: employeeName ?? this.employeeName,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      workDescription: workDescription ?? this.workDescription,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'salary_id': id,
      'project_id': projectId,
      'employee_name': employeeName,
      'amount': amount,
      'date': date.toIso8601String(),
      'work_description': workDescription,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SalaryPayment.fromMap(Map<String, dynamic> map) {
    return SalaryPayment(
      id: map['salary_id'],
      projectId: map['project_id'],
      employeeName: map['employee_name'],
      amount: map['amount']?.toDouble() ?? 0.0,
      date: DateTime.parse(map['date']),
      workDescription: map['work_description'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
