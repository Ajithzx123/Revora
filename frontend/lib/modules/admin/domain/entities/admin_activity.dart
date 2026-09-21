class AdminActivity {
  final String id;
  final String title;
  final String subtitle;
  final String time;
  final String type; // 'verification', 'deal', 'flagged', 'dealer'
  final DateTime timestamp;

  const AdminActivity({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.type,
    required this.timestamp,
  });
}
