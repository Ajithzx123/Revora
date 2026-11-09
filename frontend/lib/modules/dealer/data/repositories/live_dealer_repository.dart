import '../../../../shared/domain/entities/vehicle.dart';
import '../../domain/entities/buy_lead.dart';
import '../../domain/entities/dealer_activity.dart';
import '../../domain/entities/dealer_kpi.dart';
import '../../domain/entities/sell_lead.dart';
import '../../domain/repositories/dealer_repository.dart';

/// Used against the real backend for the parts that are not connected yet
/// (KPIs, sell leads, activity). Zeroes and empty lists on purpose: a live
/// dealer must never see demo numbers. Inventory and buyer leads have their own
/// real providers.
class LiveDealerRepository implements DealerRepository {
  @override
  DealerKPI getKPIs() => const DealerKPI(
    activeInventory: 0,
    buyLeadsMatching: 0,
    quotesSent: 0,
    quotesAccepted: 0,
    monthlyRevenue: 0,
    carsSold: 0,
  );
  @override
  List<BuyLead> getBuyLeads() => const [];
  @override
  List<SellLead> getSellLeads() => const [];
  @override
  List<Vehicle> getInventory() => const [];
  @override
  List<DealerActivity> getActivities() => const [];
  @override
  void addVehicle(Vehicle vehicle) {}
}
