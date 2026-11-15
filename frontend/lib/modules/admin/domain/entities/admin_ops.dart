/// One row of the append-only audit log (`GET /admin/audit`).
class AuditEntry {
  final String id;
  final String? actorName;
  final String? actorRole;
  final String action;
  final String entityType;
  final String entityId;
  final String? detail;
  final String? reason;
  final Map<String, dynamic>? before;
  final Map<String, dynamic>? after;
  final DateTime createdAt;

  const AuditEntry({
    required this.id,
    this.actorName,
    this.actorRole,
    required this.action,
    required this.entityType,
    required this.entityId,
    this.detail,
    this.reason,
    this.before,
    this.after,
    required this.createdAt,
  });

  factory AuditEntry.fromJson(Map<String, dynamic> j) => AuditEntry(
    id: j['id'] as String,
    actorName: j['actor_name'] as String?,
    actorRole: j['actor_role'] as String?,
    action: j['action'] as String,
    entityType: j['entity_type'] as String,
    entityId: j['entity_id'] as String,
    detail: j['detail'] as String?,
    reason: j['reason'] as String?,
    before: (j['before'] as Map?)?.cast<String, dynamic>(),
    after: (j['after'] as Map?)?.cast<String, dynamic>(),
    createdAt: parseUtc(j['created_at'] as String),
  );
}

/// A quote as the admin monitors it: prices are visible to admins, never editable.
class AdminQuote {
  final String id;
  final String requestTitle;
  final String dealerName;
  final int quotedPrice;
  final String status;
  final String? statusReason;
  final String kind;
  final int revision;
  final DateTime createdAt;

  const AdminQuote({
    required this.id,
    required this.requestTitle,
    required this.dealerName,
    required this.quotedPrice,
    required this.status,
    this.statusReason,
    required this.kind,
    required this.revision,
    required this.createdAt,
  });

  /// Only live quotes can be voided; an accepted deal continues under admin watch.
  bool get canVoid => status == 'PENDING' || status == 'REQUOTE_REQUESTED';

  factory AdminQuote.fromJson(Map<String, dynamic> j) => AdminQuote(
    id: j['id'] as String,
    requestTitle: (j['request_title'] as String?) ?? '',
    dealerName: (j['dealer_name'] as String?) ?? 'Dealer',
    quotedPrice: j['quoted_price'] as int,
    status: j['status'] as String,
    statusReason: j['status_reason'] as String?,
    kind: (j['kind'] as String?) ?? '',
    revision: (j['revision'] as int?) ?? 1,
    createdAt: parseUtc(j['created_at'] as String),
  );
}

/// Headline numbers for the admin overview, all counted by the server. Money is whole rupees.
class AdminKpis {
  final int activeDealers;
  final int pendingDealerApplications;
  final int openRequirements;
  final int openListings;
  final int activeVehicles;
  final int dealsLast30Days;
  final int dealValueLast30Days;

  const AdminKpis({
    required this.activeDealers,
    required this.pendingDealerApplications,
    required this.openRequirements,
    required this.openListings,
    required this.activeVehicles,
    required this.dealsLast30Days,
    required this.dealValueLast30Days,
  });

  factory AdminKpis.fromJson(Map<String, dynamic> j) => AdminKpis(
    activeDealers: (j['active_dealers'] as int?) ?? 0,
    pendingDealerApplications: (j['pending_dealer_applications'] as int?) ?? 0,
    openRequirements: (j['open_requirements'] as int?) ?? 0,
    openListings: (j['open_listings'] as int?) ?? 0,
    activeVehicles: (j['active_vehicles'] as int?) ?? 0,
    dealsLast30Days: (j['deals_last_30_days'] as int?) ?? 0,
    dealValueLast30Days: (j['deal_value_last_30_days'] as int?) ?? 0,
  );
}

/// A buy request as the admin sees it, with how many dealers saw it and quoted.
class AdminRequirementRow {
  final String id;
  final String title;
  final String city;
  final int budgetMin;
  final int budgetMax;
  final String status;
  final String customerName;
  final int quotesCount;
  final int matchesCount;
  final DateTime createdAt;

  const AdminRequirementRow({
    required this.id,
    required this.title,
    required this.city,
    required this.budgetMin,
    required this.budgetMax,
    required this.status,
    required this.customerName,
    required this.quotesCount,
    required this.matchesCount,
    required this.createdAt,
  });

  factory AdminRequirementRow.fromJson(Map<String, dynamic> j) =>
      AdminRequirementRow(
        id: j['id'] as String,
        title: j['title'] as String,
        city: j['city'] as String,
        budgetMin: j['budget_min'] as int,
        budgetMax: j['budget_max'] as int,
        status: j['status'] as String,
        customerName: (j['customer_name'] as String?) ?? '',
        quotesCount: (j['quotes_count'] as int?) ?? 0,
        matchesCount: (j['matches_count'] as int?) ?? 0,
        createdAt: parseUtc(j['created_at'] as String),
      );
}

/// A car in a dealer's stock. The dealer's private minimum price is never part of this.
class AdminVehicleRow {
  final String id;
  final String title;
  final String registrationNo;
  final String dealerName;
  final int price;
  final int km;
  final String fuel;
  final String city;
  final String status;

  const AdminVehicleRow({
    required this.id,
    required this.title,
    required this.registrationNo,
    required this.dealerName,
    required this.price,
    required this.km,
    required this.fuel,
    required this.city,
    required this.status,
  });

  factory AdminVehicleRow.fromJson(Map<String, dynamic> j) => AdminVehicleRow(
    id: j['id'] as String,
    title: j['title'] as String,
    registrationNo: j['registration_no'] as String,
    dealerName: (j['dealer_name'] as String?) ?? 'Dealer',
    price: j['price'] as int,
    km: j['km'] as int,
    fuel: j['fuel'] as String,
    city: (j['city'] as String?) ?? '',
    status: j['status'] as String,
  );
}

class Paged<T> {
  final List<T> items;
  final int total;
  const Paged({required this.items, required this.total});
  bool get hasMore => items.length < total;
}

/// The API sends UTC timestamps without an offset.
DateTime parseUtc(String s) =>
    DateTime.parse(s.endsWith('Z') ? s : '${s}Z').toLocal();

/// "DEALER_SUSPENDED" -> "Dealer Suspended".
String humanizeAction(String action) => action
    .split('_')
    .map((w) => w.isEmpty ? w : w[0] + w.substring(1).toLowerCase())
    .join(' ');
