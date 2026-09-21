import '../entities/admin_kpi.dart';
import '../entities/dealer_verification.dart';
import '../entities/admin_activity.dart';
import '../../../../shared/domain/entities/vehicle.dart';
import '../../../customer/domain/entities/buy_requirement.dart';

abstract class AdminRepository {
  AdminKPI getKPIs();
  List<DealerVerification> getPendingVerifications();
  List<BuyRequirement> getPlatformRequirements();
  List<Vehicle> getPlatformVehicles();
  List<AdminActivity> getActivities();
  void approveDealer(String id);
  void rejectDealer(String id);
}
