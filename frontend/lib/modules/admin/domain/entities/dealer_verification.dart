class DealerVerification {
  final String id;
  final String dealerId;
  final String businessName;
  final String ownerName;
  final String city;
  final String phone;
  final String gstin;
  final String tradeLicenseNumber;
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime appliedAt;

  const DealerVerification({
    required this.id,
    required this.dealerId,
    required this.businessName,
    required this.ownerName,
    required this.city,
    required this.phone,
    required this.gstin,
    required this.tradeLicenseNumber,
    this.status = 'pending',
    required this.appliedAt,
  });
}
