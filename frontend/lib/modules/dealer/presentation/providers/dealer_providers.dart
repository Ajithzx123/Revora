import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:revora/core/config/app_config.dart';
import 'package:revora/modules/dealer/data/repositories/live_dealer_repository.dart';
import 'package:revora/modules/dealer/domain/repositories/buy_leads_repository.dart';
import 'package:revora/modules/dealer/presentation/providers/inventory_provider.dart';
import 'package:revora/modules/dealer/domain/repositories/dealer_repository.dart';
import 'package:revora/modules/dealer/data/repositories/mock_dealer_repository.dart';
import 'package:revora/modules/dealer/domain/entities/buy_lead.dart';
import 'package:revora/modules/dealer/domain/entities/sell_lead.dart';
import 'package:revora/modules/dealer/domain/entities/dealer_kpi.dart';
import 'package:revora/modules/dealer/domain/entities/dealer_activity.dart';
import 'package:revora/shared/domain/entities/vehicle.dart';

final dealerRepositoryProvider = Provider<DealerRepository>((ref) {
  // Live accounts never see demo numbers.
  return AppConfig.instance.useMockData ? MockDealerRepository() : LiveDealerRepository();
});

final dealerKPIsProvider = Provider<DealerKPI>((ref) {
  final repo = ref.watch(dealerRepositoryProvider);
  final base = repo.getKPIs();
  if (AppConfig.instance.useMockData) return base;
  // Real counts where the data exists; the rest stay zero until their slices land.
  return DealerKPI(
    activeInventory: ref.watch(dealerInventoryProvider).where((v) => v.isAvailable).length,
    buyLeadsMatching: ref.watch(dealerBuyLeadsProvider).length,
    quotesSent: base.quotesSent,
    quotesAccepted: base.quotesAccepted,
    monthlyRevenue: base.monthlyRevenue,
    carsSold: ref.watch(dealerInventoryProvider).where((v) => v.isSold).length,
  );
});

/// Open buyer requests (real data in live mode). Empty while loading; screens that
/// need loading and error states watch `buyLeadsProvider` directly.
final dealerBuyLeadsProvider = Provider<List<BuyLead>>((ref) {
  return ref.watch(buyLeadsProvider).valueOrNull ?? const [];
});

final dealerSellLeadsProvider = Provider<List<SellLead>>((ref) {
  final repo = ref.watch(dealerRepositoryProvider);
  return repo.getSellLeads();
});

/// The dealer's stock (real data in live mode). Empty while loading; screens that
/// need loading and error states watch `inventoryProvider` directly.
final dealerInventoryProvider = Provider<List<Vehicle>>((ref) {
  return ref.watch(inventoryProvider).valueOrNull ?? const [];
});

final dealerActivitiesProvider = Provider<List<DealerActivity>>((ref) {
  final repo = ref.watch(dealerRepositoryProvider);
  return repo.getActivities();
});

final dealerActiveTabProvider = StateProvider<int>((ref) => 0);
