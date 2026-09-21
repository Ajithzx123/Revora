class CustomerActivity {
  final String id;
  final String title;
  final String subtitle;
  final String time;
  final String type; // 'quote', 'requirement', 'offer', 'deal'
  final DateTime timestamp;

  const CustomerActivity({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.type,
    required this.timestamp,
  });
}
