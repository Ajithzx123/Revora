import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/network/dio_client.dart';
import '../entities/admin_ops.dart';

/// Audit log and quote monitoring. Admins can read both and void a live quote with a
/// reason; there is deliberately no way to edit a price or message.
abstract class AdminOpsRepository {
  Future<Paged<AuditEntry>> audit({
    String? entityType,
    int limit = 50,
    int offset = 0,
  });
  Future<Paged<AdminQuote>> quotes({
    String? status,
    int limit = 50,
    int offset = 0,
  });
  Future<void> voidQuote(String quoteId, String reason);
}

class ApiAdminOpsRepository implements AdminOpsRepository {
  final Dio _dio;
  ApiAdminOpsRepository(this._dio);

  @override
  Future<Paged<AuditEntry>> audit({
    String? entityType,
    int limit = 50,
    int offset = 0,
  }) async {
    final res = await _dio.get(
      '/admin/audit',
      queryParameters: {
        'entity_type': ?entityType,
        'limit': limit,
        'offset': offset,
      },
    );
    final j = res.data as Map<String, dynamic>;
    return Paged(
      items: [
        for (final e in j['items'] as List)
          AuditEntry.fromJson(e as Map<String, dynamic>),
      ],
      total: j['total'] as int,
    );
  }

  @override
  Future<Paged<AdminQuote>> quotes({
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    final res = await _dio.get(
      '/admin/quotes',
      queryParameters: {'status': ?status, 'limit': limit, 'offset': offset},
    );
    final j = res.data as Map<String, dynamic>;
    return Paged(
      items: [
        for (final e in j['items'] as List)
          AdminQuote.fromJson(e as Map<String, dynamic>),
      ],
      total: j['total'] as int,
    );
  }

  @override
  Future<void> voidQuote(String quoteId, String reason) async {
    await _dio.post('/admin/quotes/$quoteId/void', data: {'reason': reason});
  }
}

class MockAdminOpsRepository implements AdminOpsRepository {
  final List<AdminQuote> _quotes = [
    AdminQuote(
      id: 'q1',
      requestTitle: 'Hyundai i20',
      dealerName: 'Apex Motors',
      quotedPrice: 650000,
      status: 'PENDING',
      kind: 'IN_STOCK',
      revision: 1,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
  ];

  @override
  Future<Paged<AuditEntry>> audit({
    String? entityType,
    int limit = 50,
    int offset = 0,
  }) async => Paged(
    items: [
      AuditEntry(
        id: 'a1',
        actorName: 'Admin',
        actorRole: 'ADMIN',
        action: 'DEALER_SUSPENDED',
        entityType: 'dealer',
        entityId: 'd1',
        reason: 'Customer fraud report',
        before: const {'status': 'APPROVED'},
        after: const {'status': 'SUSPENDED'},
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    ].where((e) => entityType == null || e.entityType == entityType).toList(),
    total: entityType == null || entityType == 'dealer' ? 1 : 0,
  );

  @override
  Future<Paged<AdminQuote>> quotes({
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    final rows = _quotes.where((q) => status == null || q.status == status);
    return Paged(items: rows.toList(), total: rows.length);
  }

  @override
  Future<void> voidQuote(String quoteId, String reason) async {
    final i = _quotes.indexWhere((q) => q.id == quoteId);
    if (i < 0) return;
    final q = _quotes[i];
    _quotes[i] = AdminQuote(
      id: q.id,
      requestTitle: q.requestTitle,
      dealerName: q.dealerName,
      quotedPrice: q.quotedPrice,
      status: 'VOID_ADMIN',
      statusReason: reason,
      kind: q.kind,
      revision: q.revision,
      createdAt: q.createdAt,
    );
  }
}

final adminOpsRepositoryProvider = Provider<AdminOpsRepository>((ref) {
  if (AppConfig.instance.useMockData) return MockAdminOpsRepository();
  return ApiAdminOpsRepository(ref.watch(dioProvider));
});
