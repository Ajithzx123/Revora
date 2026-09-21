import 'package:revora/modules/admin/domain/entities/admin_kpi.dart';
import 'package:revora/modules/admin/domain/entities/dealer_verification.dart';
import 'package:revora/modules/admin/domain/entities/admin_activity.dart';
import 'package:revora/shared/domain/entities/vehicle.dart';
import 'package:revora/modules/customer/domain/entities/buy_requirement.dart';
import 'package:revora/modules/admin/data/mock/admin_mock_data.dart';

class AdminRepository {
  AdminKPI getKPIs() => AdminMockData.kpis;

  List<DealerVerification> getPendingVerifications() =>
      AdminMockData.pendingVerifications;

  List<BuyRequirement> getPlatformRequirements() =>
      AdminMockData.platformRequirements;

  List<Vehicle> getPlatformVehicles() => AdminMockData.platformVehicles;

  List<AdminActivity> getActivities() => AdminMockData.activities;

  void approveDealer(String id) {
    AdminMockData.pendingVerifications.removeWhere((v) => v.id == id);
  }

  void rejectDealer(String id) {
    AdminMockData.pendingVerifications.removeWhere((v) => v.id == id);
  }
}
