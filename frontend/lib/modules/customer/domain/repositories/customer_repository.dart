import '../entities/buy_requirement.dart';
import '../entities/quote.dart';
import '../entities/sell_post.dart';
import '../entities/customer_activity.dart';
import '../../../../shared/domain/entities/dealer_info.dart';

abstract class CustomerRepository {
  List<BuyRequirement> getRequirements();
  List<Quote> getQuotesForRequirement(String reqId);
  List<Quote> getAllQuotes();
  List<SellPost> getSellPosts();
  List<DealerInfo> getTopDealers();
  List<CustomerActivity> getActivities();
  void addRequirement(BuyRequirement req);
  void addSellPost(SellPost post);
}
