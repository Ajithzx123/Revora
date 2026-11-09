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

class Paged<T> {
  final List<T> items;
  final int total;
  const Paged({required this.items, required this.total});
  bool get hasMore => items.length < total;
}

/// The API sends UTC timestamps without an offset.
DateTime parseUtc(String s) =>
    DateTime.parse(s.endsWith('Z') ? s : '${s}Z').toLocal();
