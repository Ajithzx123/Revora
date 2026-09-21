import '../../domain/entities/buy_lead.dart';
import '../../domain/entities/sell_lead.dart';
import '../../domain/entities/dealer_kpi.dart';
import '../../domain/entities/dealer_activity.dart';
import '../../domain/repositories/dealer_repository.dart';
import '../../../../shared/domain/entities/vehicle.dart';
import '../mock/dealer_mock_data.dart';

class MockDealerRepository implements DealerRepository {
  @override
  DealerKPI getKPIs() => DealerMockData.kpis;

  @override
  List<BuyLead> getBuyLeads() => DealerMockData.buyLeads;

  @override
  List<SellLead> getSellLeads() => DealerMockData.sellLeads;

  @override
  List<Vehicle> getInventory() => DealerMockData.inventory;

  @override
  List<DealerActivity> getActivities() => DealerMockData.activities;

  @override
  void addVehicle(Vehicle vehicle) {
    DealerMockData.inventory.insert(0, vehicle);
  }
}
