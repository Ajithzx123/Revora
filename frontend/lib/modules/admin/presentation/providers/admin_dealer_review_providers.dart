import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../dealer/domain/entities/dealer_application.dart';
import '../../domain/repositories/admin_dealer_review_repository.dart';

/// Which applications the admin is looking at. Null means all.
final adminDealerStatusFilterProvider = StateProvider<DealerStatus?>(
  (ref) => DealerStatus.pending,
);

final adminDealerListProvider = FutureProvider.autoDispose<List<DealerSummary>>(
  (ref) {
    final status = ref.watch(adminDealerStatusFilterProvider);
    return ref.watch(adminDealerReviewRepositoryProvider).list(status: status);
  },
);

final adminDealerDetailProvider = FutureProvider.autoDispose
    .family<DealerApplication, String>((ref, id) {
      return ref.watch(adminDealerReviewRepositoryProvider).detail(id);
    });

/// Applications waiting for review, for the dashboard (independent of the queue filter).
final adminPendingDealersProvider =
    FutureProvider.autoDispose<List<DealerSummary>>((ref) {
      return ref
          .watch(adminDealerReviewRepositoryProvider)
          .list(status: DealerStatus.pending);
    });
