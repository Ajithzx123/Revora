/// What a dealer needs to work out whether an offer on a used car leaves a margin.
///
/// The offer price is what the dealer pays for the car. A running loan and pending challans are
/// the seller's liabilities: they are settled out of that price, so they lower what the seller
/// receives but do not add to the dealer's cost. Refurbishment, transfer / RTO and holding cost do.
class ProcurementInputs {
  final int offer;
  final int refurbishment;
  final int transferRto;
  final int holding;
  final int expectedResale;
  final int loanSettlement;
  final int challans;

  const ProcurementInputs({
    required this.offer,
    this.refurbishment = 0,
    this.transferRto = 0,
    this.holding = 0,
    required this.expectedResale,
    this.loanSettlement = 0,
    this.challans = 0,
  });
}

class ProcurementResult {
  final int totalCost;
  final int grossMargin;
  final double marginPercent;

  /// What the seller takes home after settling the loan and challans out of the offer.
  final int sellerReceives;

  const ProcurementResult({
    required this.totalCost,
    required this.grossMargin,
    required this.marginPercent,
    required this.sellerReceives,
  });

  bool get profitable => grossMargin > 0;
}

class ProcurementCalculator {
  ProcurementCalculator._();

  static ProcurementResult calculate(ProcurementInputs i) {
    final cost = i.offer + i.refurbishment + i.transferRto + i.holding;
    final margin = i.expectedResale - cost;
    return ProcurementResult(
      totalCost: cost,
      grossMargin: margin,
      marginPercent: i.expectedResale <= 0
          ? 0
          : margin * 100 / i.expectedResale,
      sellerReceives: i.offer - i.loanSettlement - i.challans,
    );
  }

  /// The highest offer that still leaves [targetPercent] of the resale price as margin.
  /// Zero when even a free car would miss the target.
  static int maxOfferForMargin(ProcurementInputs i, double targetPercent) {
    final keep = (i.expectedResale * targetPercent / 100).round();
    final max =
        i.expectedResale - keep - i.refurbishment - i.transferRto - i.holding;
    return max < 0 ? 0 : max;
  }
}
