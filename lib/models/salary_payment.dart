class SalaryPayment {
  final int? id;
  final int projectId;
  final String employeeName;
  final double amount;
  final String description;
  final DateTime date;
  final DateTime createdAt;

  SalaryPayment({
    this.id,
    required this.projectId,
    required this.employeeName,
    required this.amount,
    required this.description,
    required this.date,
    required this.createdAt,
  });

  SalaryPayment copyWith({
    int? id,
    int? projectId,
    String? employeeName,
    double? amount,
    String? description,
    DateTime? date,
    DateTime? createdAt,
  }) {
    return SalaryPayment(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      employeeName: employeeName ?? this.employeeName,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'payment_id': id,
      'project_id': projectId,
      'employee_name': employeeName,
      'amount': amount,
      'description': description,
      'date': date.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SalaryPayment.fromMap(Map<String, dynamic> map) {
    return SalaryPayment(
      id: map['payment_id'] as int?,
      projectId: map['project_id'] as int,
      employeeName: map['employee_name'] as String,
      amount: map['amount'] as double? ?? 0.0,
      description: map['description'] as String? ?? '',
      date: DateTime.parse(map['date']),
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
