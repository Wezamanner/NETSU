class GarbageReport {
  const GarbageReport({
    required this.id,
    required this.description,
    required this.status,
    required this.createdAt,
    this.address,
    this.lat,
    this.lng,
  });

  final String id;
  final String description;
  final String status;
  final DateTime createdAt;
  final String? address;
  final double? lat;
  final double? lng;
}
