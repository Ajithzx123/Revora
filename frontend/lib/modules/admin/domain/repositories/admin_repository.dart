import '../entities/admin_kpi.dart';
import '../entities/admin_activity.dart';
import '../../../../shared/domain/entities/vehicle.dart';
import '../../../customer/domain/entities/buy_requirement.dart';

abstract class AdminRepository {
  AdminKPI getKPIs();
  List<BuyRequirement> getPlatformRequirements();
  List<Vehicle> getPlatformVehicles();
  List<AdminActivity> getActivities();
}
