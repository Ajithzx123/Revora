import 'package:revora/modules/dealer/domain/entities/buy_lead.dart';
import 'package:revora/modules/dealer/domain/entities/sell_lead.dart';
import 'package:revora/modules/dealer/domain/entities/dealer_kpi.dart';
import 'package:revora/modules/dealer/domain/entities/dealer_activity.dart';
import 'package:revora/shared/domain/entities/vehicle.dart';
import 'package:revora/modules/dealer/data/mock/dealer_mock_data.dart';

class DealerRepository {
  DealerKPI getKPIs() => DealerMockData.kpis;

  List<BuyLead> getBuyLeads() => DealerMockData.buyLeads;

  List<SellLead> getSellLeads() => DealerMockData.sellLeads;

  List<Vehicle> getInventory() => DealerMockData.inventory;

  List<DealerActivity> getActivities() => DealerMockData.activities;

  void addVehicle(Vehicle vehicle) {
    DealerMockData.inventory.insert(0, vehicle);
  }
}
