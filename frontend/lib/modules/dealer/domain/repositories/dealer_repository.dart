import '../entities/buy_lead.dart';
import '../entities/sell_lead.dart';
import '../entities/dealer_kpi.dart';
import '../entities/dealer_activity.dart';
import '../../../../shared/domain/entities/vehicle.dart';

abstract class DealerRepository {
  DealerKPI getKPIs();
  List<BuyLead> getBuyLeads();
  List<SellLead> getSellLeads();
  List<Vehicle> getInventory();
  List<DealerActivity> getActivities();
  void addVehicle(Vehicle vehicle);
}
