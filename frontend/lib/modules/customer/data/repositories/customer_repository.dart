import 'package:revora/modules/customer/domain/entities/buy_requirement.dart';
import 'package:revora/modules/customer/domain/entities/quote.dart';
import 'package:revora/modules/customer/domain/entities/sell_post.dart';
import 'package:revora/modules/customer/domain/entities/customer_activity.dart';
import 'package:revora/shared/domain/entities/dealer_info.dart';
import 'package:revora/modules/customer/data/mock/customer_mock_data.dart';

class CustomerRepository {
  List<BuyRequirement> getRequirements() => CustomerMockData.requirements;

  List<Quote> getQuotesForRequirement(String reqId) =>
      CustomerMockData.quotes.where((q) => q.requirementId == reqId).toList();

  List<Quote> getAllQuotes() => CustomerMockData.quotes;

  List<SellPost> getSellPosts() => CustomerMockData.sellPosts;

  List<DealerInfo> getTopDealers() => CustomerMockData.topDealers;

  List<CustomerActivity> getActivities() => CustomerMockData.activities;

  void addRequirement(BuyRequirement req) {
    CustomerMockData.requirements.insert(0, req);
  }

  void addSellPost(SellPost post) {
    CustomerMockData.sellPosts.insert(0, post);
  }
}
