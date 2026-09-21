import '../../domain/entities/buy_requirement.dart';
import '../../domain/entities/quote.dart';
import '../../domain/entities/sell_post.dart';
import '../../domain/entities/customer_activity.dart';
import '../../domain/repositories/customer_repository.dart';
import '../../../../shared/domain/entities/dealer_info.dart';
import '../mock/customer_mock_data.dart';

class MockCustomerRepository implements CustomerRepository {
  @override
  List<BuyRequirement> getRequirements() => CustomerMockData.requirements;

  @override
  List<Quote> getQuotesForRequirement(String reqId) =>
      CustomerMockData.quotes.where((q) => q.requirementId == reqId).toList();

  @override
  List<Quote> getAllQuotes() => CustomerMockData.quotes;

  @override
  List<SellPost> getSellPosts() => CustomerMockData.sellPosts;

  @override
  List<DealerInfo> getTopDealers() => CustomerMockData.topDealers;

  @override
  List<CustomerActivity> getActivities() => CustomerMockData.activities;

  @override
  void addRequirement(BuyRequirement req) {
    CustomerMockData.requirements.insert(0, req);
  }

  @override
  void addSellPost(SellPost post) {
    CustomerMockData.sellPosts.insert(0, post);
  }
}
