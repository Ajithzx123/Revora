import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/admin_ops.dart';
import '../../domain/repositories/admin_ops_repository.dart';

/// Entity type the audit log is filtered to. Null shows everything.
final adminAuditFilterProvider = StateProvider<String?>((ref) => null);

class AdminAuditNotifier extends AutoDisposeAsyncNotifier<Paged<AuditEntry>> {
  @override
  Future<Paged<AuditEntry>> build() {
    final filter = ref.watch(adminAuditFilterProvider);
    return ref.watch(adminOpsRepositoryProvider).audit(entityType: filter);
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore) return;
    final next = await ref
        .read(adminOpsRepositoryProvider)
        .audit(
          entityType: ref.read(adminAuditFilterProvider),
          offset: current.items.length,
        );
    state = AsyncData(
      Paged(items: [...current.items, ...next.items], total: next.total),
    );
  }
}

final adminAuditProvider =
    AsyncNotifierProvider.autoDispose<AdminAuditNotifier, Paged<AuditEntry>>(
      AdminAuditNotifier.new,
    );

/// Quote status the monitor is filtered to. Null shows everything.
final adminQuoteStatusFilterProvider = StateProvider<String?>((ref) => null);

class AdminQuotesNotifier extends AutoDisposeAsyncNotifier<Paged<AdminQuote>> {
  @override
  Future<Paged<AdminQuote>> build() {
    final filter = ref.watch(adminQuoteStatusFilterProvider);
    return ref.watch(adminOpsRepositoryProvider).quotes(status: filter);
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore) return;
    final next = await ref
        .read(adminOpsRepositoryProvider)
        .quotes(
          status: ref.read(adminQuoteStatusFilterProvider),
          offset: current.items.length,
        );
    state = AsyncData(
      Paged(items: [...current.items, ...next.items], total: next.total),
    );
  }

  /// Voids a live quote, then reloads so the row shows its new status.
  Future<void> voidQuote(String id, String reason) async {
    await ref.read(adminOpsRepositoryProvider).voidQuote(id, reason);
    ref.invalidateSelf();
    ref.invalidate(adminAuditProvider);
  }
}

final adminQuotesProvider =
    AsyncNotifierProvider.autoDispose<AdminQuotesNotifier, Paged<AdminQuote>>(
      AdminQuotesNotifier.new,
    );
