/// Verification status of a dealer, as decided by the backend.
enum DealerStatus {
  draft,
  pending,
  needsChanges,
  approved,
  rejected,
  suspended;

  static DealerStatus fromApi(String? value) {
    switch (value) {
      case 'PENDING':
        return DealerStatus.pending;
      case 'NEEDS_CHANGES':
        return DealerStatus.needsChanges;
      case 'APPROVED':
        return DealerStatus.approved;
      case 'REJECTED':
        return DealerStatus.rejected;
      case 'SUSPENDED':
        return DealerStatus.suspended;
      case 'DRAFT':
      default:
        return DealerStatus.draft;
    }
  }
}

enum DocumentStatus {
  pending,
  accepted,
  rejected;

  static DocumentStatus fromApi(String? value) {
    switch (value) {
      case 'ACCEPTED':
        return DocumentStatus.accepted;
      case 'REJECTED':
        return DocumentStatus.rejected;
      default:
        return DocumentStatus.pending;
    }
  }
}

/// Document types a dealer can upload. [required] ones must be present to submit.
enum DocumentType {
  ownerId('OWNER_ID', 'Owner ID proof', 'Aadhaar, PAN, passport or driving licence', true),
  businessProof('BUSINESS_PROOF', 'Business registration', 'Trade licence, shop registration or GST registration', true),
  addressProof('ADDRESS_PROOF', 'Business address proof', 'Rent agreement, utility bill or property document', true),
  gstCertificate('GST_CERTIFICATE', 'GST certificate', 'Optional', false),
  brandAuthorisation('BRAND_AUTHORISATION', 'Brand authorisation', 'Only if you are an authorised dealer', false),
  showroomPhoto('SHOWROOM_PHOTO', 'Showroom photo', 'Optional', false);

  final String api;
  final String label;
  final String hint;
  final bool required;
  const DocumentType(this.api, this.label, this.hint, this.required);

  static DocumentType? fromApi(String? value) {
    for (final t in DocumentType.values) {
      if (t.api == value) return t;
    }
    return null;
  }
}

class DealerDocument {
  final String id;
  final DocumentType? type;
  final String originalName;
  final DocumentStatus status;
  final String? reviewNote;

  const DealerDocument({
    required this.id,
    required this.type,
    required this.originalName,
    required this.status,
    this.reviewNote,
  });

  factory DealerDocument.fromJson(Map<String, dynamic> json) => DealerDocument(
        id: json['id'] as String,
        type: DocumentType.fromApi(json['doc_type'] as String?),
        originalName: json['original_name'] as String? ?? 'document',
        status: DocumentStatus.fromApi(json['status'] as String?),
        reviewNote: json['review_note'] as String?,
      );
}

class DealerApplication {
  final String id;
  final String businessName;
  final String? gstin;
  final String? address;
  final String city;
  final DealerStatus status;
  final String? statusReason;
  final List<DealerDocument> documents;
  final List<String> missingDocuments;
  final bool canSubmit;
  final bool editable;

  const DealerApplication({
    required this.id,
    required this.businessName,
    this.gstin,
    this.address,
    required this.city,
    required this.status,
    this.statusReason,
    this.documents = const [],
    this.missingDocuments = const [],
    this.canSubmit = false,
    this.editable = true,
  });

  DealerDocument? documentOf(DocumentType type) {
    for (final d in documents) {
      if (d.type == type) return d;
    }
    return null;
  }

  factory DealerApplication.fromJson(Map<String, dynamic> json) => DealerApplication(
        id: json['id'] as String,
        businessName: json['business_name'] as String? ?? '',
        gstin: json['gstin'] as String?,
        address: json['address'] as String?,
        city: json['city'] as String? ?? '',
        status: DealerStatus.fromApi(json['status'] as String?),
        statusReason: json['status_reason'] as String?,
        documents: [
          for (final d in (json['documents'] as List? ?? const []))
            DealerDocument.fromJson(d as Map<String, dynamic>),
        ],
        missingDocuments: [
          for (final m in (json['missing_documents'] as List? ?? const [])) m as String,
        ],
        canSubmit: json['can_submit'] as bool? ?? false,
        editable: json['editable'] as bool? ?? false,
      );
}
