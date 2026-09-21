import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:revora/modules/admin/domain/repositories/admin_repository.dart';
import 'package:revora/modules/admin/data/repositories/mock_admin_repository.dart';
import 'package:revora/modules/admin/domain/entities/admin_kpi.dart';
import 'package:revora/modules/admin/domain/entities/dealer_verification.dart';
import 'package:revora/modules/admin/domain/entities/admin_activity.dart';
import 'package:revora/shared/domain/entities/vehicle.dart';
import 'package:revora/modules/customer/domain/entities/buy_requirement.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return MockAdminRepository();
});

final adminKPIsProvider = Provider<AdminKPI>((ref) {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.getKPIs();
});

final pendingVerificationsProvider =
    StateProvider<List<DealerVerification>>((ref) {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.getPendingVerifications();
});

final platformRequirementsProvider = Provider<List<BuyRequirement>>((ref) {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.getPlatformRequirements();
});

final platformVehiclesProvider = Provider<List<Vehicle>>((ref) {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.getPlatformVehicles();
});

final adminActivitiesProvider = Provider<List<AdminActivity>>((ref) {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.getActivities();
});

final adminActiveNavIndexProvider = StateProvider<int>((ref) => 0);
