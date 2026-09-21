class DealerActivity {
  final String id;
  final String title;
  final String subtitle;
  final String time;
  final String type; // 'lead', 'quote_accepted', 'inventory', 'offer'
  final DateTime timestamp;

  const DealerActivity({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.type,
    required this.timestamp,
  });
}
