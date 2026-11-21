class UserProfile {
  const UserProfile({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.role,
    required this.language,
    this.address,
    this.areaId,
    this.areaName,
    this.kebeleCode,
    this.lat,
    this.lng,
  });

  final String id;
  final String fullName;
  final String phone;
  final String role;
  final String language;
  final String? address;
  final String? areaId;
  final String? areaName;
  final String? kebeleCode;
  final double? lat;
  final double? lng;
}
