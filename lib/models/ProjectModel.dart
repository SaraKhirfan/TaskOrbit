class Project {
  final String name;
  final String id;
  final String startDate;
  final String endDate;
  final String? description;

  Project({
    required this.name,
    required this.id,
    required this.startDate,
    required this.endDate,
    this.description,
  });
}