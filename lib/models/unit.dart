class Unit {
  final String id;
  final String name;
  final String symbol;
  final String code;
  final String displayName;
  final int sortOrder;

  Unit({
    required this.id,
    required this.name,
    required this.symbol,
    this.code = '',
    this.displayName = '',
    this.sortOrder = 0,
  });

  static List<Unit> defaultUnits = [
    Unit(id: 'sqm', name: 'Квадратный метр', symbol: 'м²', code: 'sqm', displayName: 'Квадратный метр', sortOrder: 1),
    Unit(id: 'pcs', name: 'Штука', symbol: 'шт', code: 'pcs', displayName: 'Штука', sortOrder: 2),
    Unit(id: 'meter', name: 'Метр', symbol: 'м', code: 'meter', displayName: 'Метр', sortOrder: 3),
    Unit(id: 'kg', name: 'Килограмм', symbol: 'кг', code: 'kg', displayName: 'Килограмм', sortOrder: 4),
  ];
}
