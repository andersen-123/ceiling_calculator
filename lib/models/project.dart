class Project {
  final String id;
  final String name;
  final String clientName;
  final DateTime createdAt;
  final double totalArea;
  final double totalCost;

  Project({
    required this.id,
    required this.name,
    required this.clientName,
    required this.createdAt,
    required this.totalArea,
    required this.totalCost,
  });
}
