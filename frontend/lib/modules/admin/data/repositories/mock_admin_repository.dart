import '../../domain/entities/admin_kpi.dart';
import '../../domain/entities/admin_activity.dart';
import '../../domain/repositories/admin_repository.dart';
import '../../../../shared/domain/entities/vehicle.dart';
import '../../../customer/domain/entities/buy_requirement.dart';
import '../mock/admin_mock_data.dart';

class MockAdminRepository implements AdminRepository {
  @override
  AdminKPI getKPIs() => AdminMockData.kpis;

  @override
  List<BuyRequirement> getPlatformRequirements() =>
      AdminMockData.platformRequirements;

  @override
  List<Vehicle> getPlatformVehicles() => AdminMockData.platformVehicles;

  @override
  List<AdminActivity> getActivities() => AdminMockData.activities;
}
