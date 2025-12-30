class LineItem {
  final int? id;
  final int quoteId;
  final int position;
  final LineItemSection section;
  final String description;
  final String unit;
  final double quantity;
  final double price;
  final double amount;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  LineItem({
    this.id,
    required this.quoteId,
    required this.position,
    required this.section,
    required this.description,
    required this.unit,
    required this.quantity,
    required this.price,
    double? amount,
    this.note,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : amount = amount ?? (quantity * price),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'line_item_id': id,
      'quote_id': quoteId,
      'position': position,
      'section': section.name,
      'description': description,
      'unit': unit,
      'quantity': quantity,
      'price': price,
      'amount': amount,
      'note': note,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory LineItem.fromMap(Map<String, dynamic> map) {
    return LineItem(
      id: map['line_item_id']?.toInt(),
      quoteId: map['quote_id']?.toInt() ?? 0,
      position: map['position']?.toInt() ?? 0,
      section: LineItemSection.values.firstWhere(
        (s) => s.name == map['section'],
        orElse: () => LineItemSection.work,
      ),
      description: map['description'] ?? '',
      unit: map['unit'] ?? '',
      quantity: map['quantity']?.toDouble() ?? 0.0,
      price: map['price']?.toDouble() ?? 0.0,
      amount: map['amount']?.toDouble() ?? 0.0,
      note: map['note'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  LineItem copyWith({
    int? id,
    int? quoteId,
    int? position,
    LineItemSection? section,
    String? description,
    String? unit,
    double? quantity,
    double? price,
    double? amount,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LineItem(
      id: id ?? this.id,
      quoteId: quoteId ?? this.quoteId,
      position: position ?? this.position,
      section: section ?? this.section,
      description: description ?? this.description,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  LineItem withUpdatedQuantityAndPrice({
    required double quantity,
    required double price,
  }) {
    return copyWith(
      quantity: quantity,
      price: price,
      amount: quantity * price,
      updatedAt: DateTime.now(),
    );
  }
}

enum LineItemSection {
  work,
  equipment,
}

extension LineItemSectionExtension on LineItemSection {
  String get displayName {
    switch (this) {
      case LineItemSection.work:
        return 'Работы';
      case LineItemSection.equipment:
        return 'Оборудование';
    }
  }

  String get dbName {
    switch (this) {
      case LineItemSection.work:
        return 'work';
      case LineItemSection.equipment:
        return 'equipment';
    }
  }
}

class Unit {
  final String code;
  final String displayName;
  final int sortOrder;

  const Unit({
    required this.code,
    required this.displayName,
    required this.sortOrder,
  });

  static const List<Unit> defaultUnits = [
    Unit(code: 'm2', displayName: 'м²', sortOrder: 1),
    Unit(code: 'mp', displayName: 'м.п.', sortOrder: 2),
    Unit(code: 'pcs', displayName: 'шт.', sortOrder: 3),
    Unit(code: 'kg', displayName: 'кг', sortOrder: 4),
    Unit(code: 'l', displayName: 'л', sortOrder: 5),
  ];

  static Unit? findByCode(String code) {
    try {
      return defaultUnits.firstWhere((unit) => unit.code == code);
    } catch (e) {
      return null;
    }
  }
}
