class Unit {
  final String id;
  final String name;
  final String symbol;

  Unit({
    required this.id,
    required this.name,
    required this.symbol,
  });

  static List<Unit> defaultUnits = [
    Unit(id: 'sqm', name: 'Квадратный метр', symbol: 'м²'),
    Unit(id: 'pcs', name: 'Штука', symbol: 'шт'),
    Unit(id: 'meter', name: 'Метр', symbol: 'м'),
    Unit(id: 'kg', name: 'Килограмм', symbol: 'кг'),
  ];
}
