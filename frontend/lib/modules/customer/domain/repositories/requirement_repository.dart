import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/repositories/mock_requirement_repository.dart';
import '../entities/buy_requirement.dart';
import '../entities/requirement_draft.dart';

abstract class RequirementRepository {
  Future<List<BuyRequirement>> list();
  Future<BuyRequirement> create(RequirementDraft draft);
  Future<BuyRequirement> update(String id, RequirementDraft draft);
  Future<BuyRequirement> pause(String id);
  Future<BuyRequirement> resume(String id);
  Future<BuyRequirement> cancel(String id);
}

final requirementRepositoryProvider = Provider<RequirementRepository>((ref) {
  if (AppConfig.instance.useMockData) return MockRequirementRepository();
  return ApiRequirementRepository(ref.watch(dioProvider));
});

class ApiRequirementRepository implements RequirementRepository {
  final Dio _dio;
  ApiRequirementRepository(this._dio);

  BuyRequirement _one(Response<dynamic> res) =>
      BuyRequirement.fromJson(res.data as Map<String, dynamic>);

  @override
  Future<List<BuyRequirement>> list() async {
    final res = await _dio.get('/requirements/');
    return [
      for (final j in res.data as List)
        BuyRequirement.fromJson(j as Map<String, dynamic>),
    ];
  }

  @override
  Future<BuyRequirement> create(RequirementDraft draft) async =>
      _one(await _dio.post('/requirements/', data: draft.toJson()));

  @override
  Future<BuyRequirement> update(String id, RequirementDraft draft) async =>
      _one(await _dio.patch('/requirements/$id', data: draft.toJson()));

  @override
  Future<BuyRequirement> pause(String id) async =>
      _one(await _dio.post('/requirements/$id/pause'));

  @override
  Future<BuyRequirement> resume(String id) async =>
      _one(await _dio.post('/requirements/$id/resume'));

  @override
  Future<BuyRequirement> cancel(String id) async =>
      _one(await _dio.post('/requirements/$id/cancel'));
}
