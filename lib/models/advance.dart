enum AdvanceType {
  project,
  installer,
}

class Advance {
  final int? id;
  final int projectId;
  final AdvanceType type;
  final String? installerName; // Только для installer типа
  final double amount;
  final String description;
  final DateTime date;
  final DateTime createdAt;

  Advance({
    this.id,
    required this.projectId,
    required this.type,
    this.installerName,
    required this.amount,
    required this.description,
    required this.date,
    required this.createdAt,
  });

  Advance copyWith({
    int? id,
    int? projectId,
    AdvanceType? type,
    String? installerName,
    double? amount,
    String? description,
    DateTime? date,
    DateTime? createdAt,
  }) {
    return Advance(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      type: type ?? this.type,
      installerName: installerName ?? this.installerName,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'advance_id': id,
      'project_id': projectId,
      'type': type.toString().split('.').last,
      'installer_name': installerName,
      'amount': amount,
      'description': description,
      'date': date.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Advance.fromMap(Map<String, dynamic> map) {
    return Advance(
      id: map['advance_id'] as int?,
      projectId: map['project_id'] as int,
      type: AdvanceType.values.firstWhere(
        (e) => e.toString() == 'AdvanceType.${map['type']}',
        orElse: () => AdvanceType.project,
      ),
      installerName: map['installer_name'] as String?,
      amount: map['amount'] as double? ?? 0.0,
      description: map['description'] as String? ?? '',
      date: DateTime.parse(map['date']),
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
