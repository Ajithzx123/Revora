class AdminKPI {
  final int totalDealers;
  final int pendingVerifications;
  final int activeRequirements;
  final int activeVehicles;
  final int monthlyDealsCompleted;
  final double grossMarketplaceValue;

  const AdminKPI({
    required this.totalDealers,
    required this.pendingVerifications,
    required this.activeRequirements,
    required this.activeVehicles,
    required this.monthlyDealsCompleted,
    required this.grossMarketplaceValue,
  });

  String get formattedGmv => '₹${(grossMarketplaceValue / 10000000).toStringAsFixed(2)} Cr';
}
