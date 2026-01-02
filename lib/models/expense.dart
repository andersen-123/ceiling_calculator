class Expense {
  final int? id;
  final int projectId;
  final String description;
  final double amount;
  final DateTime date;
  final String? notes;
  final DateTime createdAt;

  Expense({
    this.id,
    required this.projectId,
    required this.description,
    required this.amount,
    required this.date,
    this.notes,
    required this.createdAt,
  });

  Expense copyWith({
    int? id,
    int? projectId,
    String? description,
    double? amount,
    DateTime? date,
    String? notes,
    DateTime? createdAt,
  }) {
    return Expense(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
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
      'description': description,
      'amount': amount,
      'date': date.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['expense_id'] as int?,
      projectId: map['project_id'] as int,
      description: map['description'] as String,
      amount: map['amount'] as double? ?? 0.0,
      date: DateTime.parse(map['date']),
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
