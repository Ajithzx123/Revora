import '../../../../shared/domain/entities/dealer_info.dart';
import '../../domain/entities/buy_requirement.dart';
import '../../domain/entities/customer_activity.dart';
import '../../domain/entities/quote.dart';
import '../../domain/entities/sell_post.dart';
import '../../domain/repositories/customer_repository.dart';

/// Used against the real backend until quotes, listings and activity are connected
/// in their own slices. Empty on purpose: a live account must never show demo data.
class LiveCustomerRepository implements CustomerRepository {
  @override
  List<BuyRequirement> getRequirements() => const [];
  @override
  List<Quote> getQuotesForRequirement(String reqId) => const [];
  @override
  List<Quote> getAllQuotes() => const [];
  @override
  List<SellPost> getSellPosts() => const [];
  @override
  List<DealerInfo> getTopDealers() => const [];
  @override
  List<CustomerActivity> getActivities() => const [];
  @override
  void addRequirement(BuyRequirement req) {}
  @override
  void addSellPost(SellPost post) {}
}
