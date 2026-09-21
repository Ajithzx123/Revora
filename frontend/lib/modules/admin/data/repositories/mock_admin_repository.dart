import '../../domain/entities/admin_kpi.dart';
import '../../domain/entities/dealer_verification.dart';
import '../../domain/entities/admin_activity.dart';
import '../../domain/repositories/admin_repository.dart';
import '../../../../shared/domain/entities/vehicle.dart';
import '../../../customer/domain/entities/buy_requirement.dart';
import '../mock/admin_mock_data.dart';

class MockAdminRepository implements AdminRepository {
  @override
  AdminKPI getKPIs() => AdminMockData.kpis;

  @override
  List<DealerVerification> getPendingVerifications() =>
      AdminMockData.pendingVerifications;

  @override
  List<BuyRequirement> getPlatformRequirements() =>
      AdminMockData.platformRequirements;

  @override
  List<Vehicle> getPlatformVehicles() => AdminMockData.platformVehicles;

  @override
  List<AdminActivity> getActivities() => AdminMockData.activities;

  @override
  void approveDealer(String id) {
    AdminMockData.pendingVerifications.removeWhere((v) => v.id == id);
  }

  @override
  void rejectDealer(String id) {
    AdminMockData.pendingVerifications.removeWhere((v) => v.id == id);
  }
}
