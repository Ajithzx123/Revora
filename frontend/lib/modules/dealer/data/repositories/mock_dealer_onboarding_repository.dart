import 'dart:typed_data';
import '../../domain/entities/dealer_application.dart';
import '../../domain/repositories/dealer_onboarding_repository.dart';

/// In-memory stand-in for demos and tests. Mirrors the backend's rules.
class MockDealerOnboardingRepository implements DealerOnboardingRepository {
  DealerStatus _status = DealerStatus.draft;
  String _business = 'Demo Motors';
  String? _gstin;
  String? _address;
  String _city = 'Bengaluru';
  final Map<DocumentType, DealerDocument> _docs = {};
  int _next = 1;

  DealerApplication _snapshot() {
    final missing = [
      for (final t in DocumentType.values)
        if (t.required && !_docs.containsKey(t)) t.api,
    ];
    final editable =
        _status == DealerStatus.draft || _status == DealerStatus.needsChanges;
    return DealerApplication(
      id: 'mock-dealer',
      businessName: _business,
      gstin: _gstin,
      address: _address,
      city: _city,
      status: _status,
      documents: _docs.values.toList(),
      missingDocuments: missing,
      canSubmit: editable && missing.isEmpty && (_address ?? '').isNotEmpty,
      editable: editable,
    );
  }

  void _requireEditable() {
    if (!_snapshot().editable) {
      throw Exception('Your application cannot be edited now.');
    }
  }

  @override
  Future<DealerApplication> fetch() async => _snapshot();

  @override
  Future<DealerApplication> updateDetails({
    String? businessName,
    String? gstin,
    String? address,
    String? city,
  }) async {
    _requireEditable();
    _business = businessName ?? _business;
    _gstin = gstin ?? _gstin;
    _address = address ?? _address;
    _city = city ?? _city;
    return _snapshot();
  }

  @override
  Future<DealerApplication> uploadDocument(
    DocumentType type, {
    required String fileName,
    required Uint8List bytes,
  }) async {
    _requireEditable();
    _docs[type] = DealerDocument(
      id: 'doc-${_next++}',
      type: type,
      originalName: fileName,
      status: DocumentStatus.pending,
    );
    return _snapshot();
  }

  @override
  Future<DealerApplication> deleteDocument(String documentId) async {
    _requireEditable();
    _docs.removeWhere((_, d) => d.id == documentId);
    return _snapshot();
  }

  @override
  Future<DealerApplication> submit() async {
    final snap = _snapshot();
    if (!snap.canSubmit) {
      throw Exception('Add your address and all required documents first.');
    }
    _status = DealerStatus.pending;
    return _snapshot();
  }
}
