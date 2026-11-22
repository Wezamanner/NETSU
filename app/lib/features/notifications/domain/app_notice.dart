class AppNotice {
  const AppNotice({
    required this.id,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.type = '',
  });

  final String id;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final String type;
}
