import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:revora/modules/dealer/data/repositories/dealer_repository.dart';
import 'package:revora/modules/dealer/domain/entities/buy_lead.dart';
import 'package:revora/modules/dealer/domain/entities/sell_lead.dart';
import 'package:revora/modules/dealer/domain/entities/dealer_kpi.dart';
import 'package:revora/modules/dealer/domain/entities/dealer_activity.dart';
import 'package:revora/shared/domain/entities/vehicle.dart';

final dealerRepositoryProvider = Provider<DealerRepository>((ref) {
  return DealerRepository();
});

final dealerKPIsProvider = Provider<DealerKPI>((ref) {
  final repo = ref.watch(dealerRepositoryProvider);
  return repo.getKPIs();
});

final dealerBuyLeadsProvider = Provider<List<BuyLead>>((ref) {
  final repo = ref.watch(dealerRepositoryProvider);
  return repo.getBuyLeads();
});

final dealerSellLeadsProvider = Provider<List<SellLead>>((ref) {
  final repo = ref.watch(dealerRepositoryProvider);
  return repo.getSellLeads();
});

final dealerInventoryProvider = Provider<List<Vehicle>>((ref) {
  final repo = ref.watch(dealerRepositoryProvider);
  return repo.getInventory();
});

final dealerActivitiesProvider = Provider<List<DealerActivity>>((ref) {
  final repo = ref.watch(dealerRepositoryProvider);
  return repo.getActivities();
});

final dealerActiveTabProvider = StateProvider<int>((ref) => 0);
