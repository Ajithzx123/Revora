class DealerKPI {
  final int activeInventory;
  final int buyLeadsMatching;
  final int quotesSent;
  final int quotesAccepted;
  final double monthlyRevenue;
  final int carsSold;

  const DealerKPI({
    required this.activeInventory,
    required this.buyLeadsMatching,
    required this.quotesSent,
    required this.quotesAccepted,
    required this.monthlyRevenue,
    required this.carsSold,
  });

  String get formattedRevenue => '₹${(monthlyRevenue / 100000).toStringAsFixed(1)}L';
  double get conversionRate => quotesSent > 0 ? (quotesAccepted / quotesSent) * 100 : 0.0;
}
