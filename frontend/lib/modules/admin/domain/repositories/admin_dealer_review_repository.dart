import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/network/dio_client.dart';
import '../../../dealer/domain/entities/dealer_application.dart';
import '../../data/repositories/mock_admin_dealer_review_repository.dart';

class DealerSummary {
  final String id;
  final String businessName;
  final String city;
  final DealerStatus status;
  final DateTime? submittedAt;

  const DealerSummary({
    required this.id,
    required this.businessName,
    required this.city,
    required this.status,
    this.submittedAt,
  });

  factory DealerSummary.fromJson(Map<String, dynamic> json) => DealerSummary(
    id: json['id'] as String,
    businessName: json['business_name'] as String? ?? '',
    city: json['city'] as String? ?? '',
    status: DealerStatus.fromApi(json['status'] as String?),
    submittedAt: json['submitted_at'] == null
        ? null
        : DateTime.tryParse(json['submitted_at'] as String),
  );
}

class DocumentFile {
  final Uint8List bytes;
  final String contentType;
  const DocumentFile(this.bytes, this.contentType);
  bool get isImage => contentType.startsWith('image/');
}

abstract class AdminDealerReviewRepository {
  /// [status] null means all applications.
  Future<List<DealerSummary>> list({DealerStatus? status});
  Future<DealerApplication> detail(String dealerId);
  Future<void> reviewDocument(
    String dealerId,
    String documentId, {
    required bool accept,
    String? note,
  });
  Future<DocumentFile> documentFile(String dealerId, String documentId);
  Future<void> approve(String dealerId);
  Future<void> requestChanges(String dealerId, String reason);
  Future<void> reject(String dealerId, String reason);
  Future<void> suspend(String dealerId, String reason);
  Future<void> reactivate(String dealerId);
}

final adminDealerReviewRepositoryProvider =
    Provider<AdminDealerReviewRepository>((ref) {
      if (AppConfig.instance.useMockData) {
        return MockAdminDealerReviewRepository();
      }
      return ApiAdminDealerReviewRepository(ref.watch(dioProvider));
    });

class ApiAdminDealerReviewRepository implements AdminDealerReviewRepository {
  final Dio _dio;
  ApiAdminDealerReviewRepository(this._dio);

  static String _statusParam(DealerStatus s) => switch (s) {
    DealerStatus.draft => 'DRAFT',
    DealerStatus.pending => 'PENDING',
    DealerStatus.needsChanges => 'NEEDS_CHANGES',
    DealerStatus.approved => 'APPROVED',
    DealerStatus.rejected => 'REJECTED',
    DealerStatus.suspended => 'SUSPENDED',
  };

  @override
  Future<List<DealerSummary>> list({DealerStatus? status}) async {
    final res = await _dio.get(
      '/admin/dealers',
      queryParameters: {if (status != null) 'status': _statusParam(status)},
    );
    return [
      for (final j in res.data as List)
        DealerSummary.fromJson(j as Map<String, dynamic>),
    ];
  }

  @override
  Future<DealerApplication> detail(String dealerId) async {
    final res = await _dio.get('/admin/dealers/$dealerId');
    return DealerApplication.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<void> reviewDocument(
    String dealerId,
    String documentId, {
    required bool accept,
    String? note,
  }) async {
    await _dio.post(
      '/admin/dealers/$dealerId/documents/$documentId/review',
      data: {'status': accept ? 'ACCEPTED' : 'REJECTED', 'note': ?note},
    );
  }

  @override
  Future<DocumentFile> documentFile(String dealerId, String documentId) async {
    final res = await _dio.get<List<int>>(
      '/admin/dealers/$dealerId/documents/$documentId/file',
      options: Options(responseType: ResponseType.bytes),
    );
    return DocumentFile(
      Uint8List.fromList(res.data ?? const []),
      res.headers.value('content-type') ?? 'application/octet-stream',
    );
  }

  Future<void> _post(String dealerId, String action, [String? reason]) =>
      _dio.post(
        '/admin/dealers/$dealerId/$action',
        data: reason == null ? null : {'reason': reason},
      );

  @override
  Future<void> approve(String dealerId) => _post(dealerId, 'approve');
  @override
  Future<void> requestChanges(String dealerId, String reason) =>
      _post(dealerId, 'request-changes', reason);
  @override
  Future<void> reject(String dealerId, String reason) =>
      _post(dealerId, 'reject', reason);
  @override
  Future<void> suspend(String dealerId, String reason) =>
      _post(dealerId, 'suspend', reason);
  @override
  Future<void> reactivate(String dealerId) => _post(dealerId, 'reactivate');
}
