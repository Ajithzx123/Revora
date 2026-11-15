/// Reasons a dealer can give for lowering the price after inspecting the car.
const finalReasonLabels = {
  'ODOMETER_MISMATCH': 'Odometer does not match',
  'UNDISCLOSED_ACCIDENT': 'Undisclosed accident',
  'MECHANICAL_ISSUE': 'Mechanical issue',
  'BODY_CONDITION': 'Body or paint condition',
  'PAPERWORK_ISSUE': 'Paperwork issue',
  'OTHER': 'Other',
};

/// A drop of more than this percent needs evidence (mirrors the server rule).
const bigDropPercent = 5;

class FinalOfferRules {
  FinalOfferRules._();

  static double dropPercent(int accepted, int price) =>
      accepted <= 0 ? 0 : (accepted - price) * 100 / accepted;

  /// What is wrong with a final offer, or null when it can be sent. Same checks as the server,
  /// so the dealer is told before sending.
  static String? check({
    required int accepted,
    required int? price,
    String? reasonCode,
    List<String> evidence = const [],
  }) {
    if (price == null || price <= 0) return 'Enter the final price';
    if (price > accepted) {
      return 'A final offer cannot be higher than the accepted offer';
    }
    if (price == accepted) {
      return null; // confirms the price; nothing else needed
    }
    if (reasonCode == null) return 'Choose why the price is lower';
    if (dropPercent(accepted, price) > bigDropPercent && evidence.isEmpty) {
      return 'A drop of more than $bigDropPercent% needs evidence: add photo or report links';
    }
    return null;
  }
}
