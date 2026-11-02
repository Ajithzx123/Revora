import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:revora/core/config/app_config.dart';
import 'package:revora/modules/customer/data/repositories/live_customer_repository.dart';
import 'package:revora/modules/customer/domain/repositories/customer_repository.dart';
import 'package:revora/modules/customer/presentation/providers/requirements_provider.dart';
import 'package:revora/modules/customer/data/repositories/mock_customer_repository.dart';
import 'package:revora/modules/customer/domain/entities/buy_requirement.dart';
import 'package:revora/modules/customer/domain/entities/quote.dart';
import 'package:revora/modules/customer/domain/entities/sell_post.dart';
import 'package:revora/modules/customer/domain/entities/customer_activity.dart';
import 'package:revora/shared/domain/entities/dealer_info.dart';

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  // Live accounts never see demo quotes, listings or dealers.
  return AppConfig.instance.useMockData ? MockCustomerRepository() : LiveCustomerRepository();
});

/// The buyer's requests (real data in live mode). Empty while loading; screens that
/// need loading and error states watch `requirementsProvider` directly.
final customerRequirementsProvider = Provider<List<BuyRequirement>>((ref) {
  return ref.watch(requirementsProvider).valueOrNull ?? const [];
});

final customerQuotesProvider =
    Provider.family<List<Quote>, String>((ref, reqId) {
  final repo = ref.watch(customerRepositoryProvider);
  return repo.getQuotesForRequirement(reqId);
});

final allCustomerQuotesProvider = Provider<List<Quote>>((ref) {
  final repo = ref.watch(customerRepositoryProvider);
  return repo.getAllQuotes();
});

final customerSellPostsProvider = Provider<List<SellPost>>((ref) {
  final repo = ref.watch(customerRepositoryProvider);
  return repo.getSellPosts();
});

final topDealersProvider = Provider<List<DealerInfo>>((ref) {
  final repo = ref.watch(customerRepositoryProvider);
  return repo.getTopDealers();
});

final customerActivitiesProvider = Provider<List<CustomerActivity>>((ref) {
  final repo = ref.watch(customerRepositoryProvider);
  return repo.getActivities();
});

final customerActiveTabProvider = StateProvider<int>((ref) => 0);
