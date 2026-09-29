import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:revora/modules/customer/domain/repositories/customer_repository.dart';
import 'package:revora/modules/customer/data/repositories/mock_customer_repository.dart';
import 'package:revora/modules/customer/domain/entities/buy_requirement.dart';
import 'package:revora/modules/customer/domain/entities/quote.dart';
import 'package:revora/modules/customer/domain/entities/sell_post.dart';
import 'package:revora/modules/customer/domain/entities/customer_activity.dart';
import 'package:revora/shared/domain/entities/dealer_info.dart';

import '../../../../core/config/app_config.dart';

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  if (AppConfig.instance.useMockData) {
    return MockCustomerRepository();
  }
  // When remote API repository is implemented, return it here.
  return MockCustomerRepository();
});

final customerRequirementsProvider = Provider<List<BuyRequirement>>((ref) {
  final repo = ref.watch(customerRepositoryProvider);
  return repo.getRequirements();
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
