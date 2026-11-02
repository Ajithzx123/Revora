import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/mock/dealer_mock_data.dart';
import '../entities/buy_lead.dart';

abstract class BuyLeadsRepository {
  Future<List<BuyLead>> list();
}

class MockBuyLeadsRepository implements BuyLeadsRepository {
  @override
  Future<List<BuyLead>> list() async => DealerMockData.buyLeads;
}

class ApiBuyLeadsRepository implements BuyLeadsRepository {
  final Dio _dio;
  ApiBuyLeadsRepository(this._dio);

  @override
  Future<List<BuyLead>> list() async {
    final res = await _dio.get('/leads/buy');
    return [for (final j in res.data as List) BuyLead.fromJson(j as Map<String, dynamic>)];
  }
}

final buyLeadsRepositoryProvider = Provider<BuyLeadsRepository>((ref) {
  if (AppConfig.instance.useMockData) return MockBuyLeadsRepository();
  return ApiBuyLeadsRepository(ref.watch(dioProvider));
});

/// Open buyer requests a verified dealer can quote on.
final buyLeadsProvider = FutureProvider.autoDispose<List<BuyLead>>((ref) {
  return ref.watch(buyLeadsRepositoryProvider).list();
});
