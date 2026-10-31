import 'dart:typed_data';
import '../../../dealer/domain/entities/dealer_application.dart';
import '../../domain/repositories/admin_dealer_review_repository.dart';

/// In-memory stand-in for demos and tests. Follows the backend's rules.
class MockAdminDealerReviewRepository implements AdminDealerReviewRepository {
  final Map<String, _Dealer> _dealers = {
    'd1': _Dealer('d1', 'Apex Motor Corp', 'Bengaluru', DealerStatus.pending, withDocs: true),
    'd2': _Dealer('d2', 'Sunrise Cars', 'Pune', DealerStatus.pending, withDocs: true),
    'd3': _Dealer('d3', 'City Wheels', 'Delhi', DealerStatus.approved, withDocs: true, accepted: true),
  };

  _Dealer _get(String id) {
    final d = _dealers[id];
    if (d == null) throw Exception('Dealer not found');
    return d;
  }

  void _move(String id, DealerStatus to, Set<DealerStatus> from, {String? reason}) {
    final d = _get(id);
    if (!from.contains(d.status)) {
      throw Exception('A dealer in ${d.status.name} cannot move to ${to.name}');
    }
    d.status = to;
    d.reason = reason;
  }

  @override
  Future<List<DealerSummary>> list({DealerStatus? status}) async => [
        for (final d in _dealers.values)
          if (status == null || d.status == status)
            DealerSummary(
              id: d.id,
              businessName: d.name,
              city: d.city,
              status: d.status,
              submittedAt: DateTime(2026, 10, 30),
            ),
      ];

  @override
  Future<DealerApplication> detail(String dealerId) async => _get(dealerId).toApplication();

  @override
  Future<void> reviewDocument(String dealerId, String documentId,
      {required bool accept, String? note}) async {
    final doc = _get(dealerId).docs.firstWhere((d) => d.id == documentId);
    if (!accept && (note ?? '').trim().isEmpty) {
      throw Exception('A note is required when rejecting a document');
    }
    _get(dealerId).docs[_get(dealerId).docs.indexOf(doc)] = DealerDocument(
      id: doc.id,
      type: doc.type,
      originalName: doc.originalName,
      status: accept ? DocumentStatus.accepted : DocumentStatus.rejected,
      reviewNote: note,
    );
  }

  @override
  Future<DocumentFile> documentFile(String dealerId, String documentId) async =>
      DocumentFile(Uint8List(0), 'application/pdf');

  @override
  Future<void> approve(String dealerId) async {
    final d = _get(dealerId);
    final unaccepted = d.docs.where((x) => x.type?.required == true && x.status != DocumentStatus.accepted);
    if (d.status == DealerStatus.pending && unaccepted.isNotEmpty) {
      throw Exception('Accept these documents first: ${unaccepted.map((x) => x.type!.api).join(', ')}');
    }
    _move(dealerId, DealerStatus.approved, {DealerStatus.pending, DealerStatus.suspended});
  }

  @override
  Future<void> requestChanges(String dealerId, String reason) async =>
      _move(dealerId, DealerStatus.needsChanges, {DealerStatus.pending}, reason: reason);

  @override
  Future<void> reject(String dealerId, String reason) async =>
      _move(dealerId, DealerStatus.rejected, {DealerStatus.pending}, reason: reason);

  @override
  Future<void> suspend(String dealerId, String reason) async =>
      _move(dealerId, DealerStatus.suspended, {DealerStatus.approved}, reason: reason);

  @override
  Future<void> reactivate(String dealerId) async =>
      _move(dealerId, DealerStatus.approved, {DealerStatus.suspended});
}

class _Dealer {
  final String id;
  final String name;
  final String city;
  DealerStatus status;
  String? reason;
  final List<DealerDocument> docs = [];

  _Dealer(this.id, this.name, this.city, this.status, {bool withDocs = false, bool accepted = false}) {
    if (withDocs) {
      var n = 0;
      for (final t in [DocumentType.ownerId, DocumentType.businessProof, DocumentType.addressProof]) {
        docs.add(DealerDocument(
          id: '$id-doc${n++}',
          type: t,
          originalName: '${t.api.toLowerCase()}.pdf',
          status: accepted ? DocumentStatus.accepted : DocumentStatus.pending,
        ));
      }
    }
  }

  DealerApplication toApplication() => DealerApplication(
        id: id,
        businessName: name,
        city: city,
        address: '12 MG Road',
        status: status,
        statusReason: reason,
        documents: List.of(docs),
        editable: false,
      );
}
