import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/repositories/mock_dealer_onboarding_repository.dart';
import '../entities/dealer_application.dart';

abstract class DealerOnboardingRepository {
  Future<DealerApplication> fetch();

  Future<DealerApplication> updateDetails({
    String? businessName,
    String? gstin,
    String? address,
    String? city,
  });

  Future<DealerApplication> uploadDocument(
    DocumentType type, {
    required String fileName,
    required Uint8List bytes,
  });

  Future<DealerApplication> deleteDocument(String documentId);

  Future<DealerApplication> submit();
}

final dealerOnboardingRepositoryProvider = Provider<DealerOnboardingRepository>((ref) {
  if (AppConfig.instance.useMockData) {
    return MockDealerOnboardingRepository();
  }
  return ApiDealerOnboardingRepository(ref.watch(dioProvider));
});

class ApiDealerOnboardingRepository implements DealerOnboardingRepository {
  final Dio _dio;
  ApiDealerOnboardingRepository(this._dio);

  DealerApplication _parse(Response<dynamic> res) =>
      DealerApplication.fromJson(res.data as Map<String, dynamic>);

  @override
  Future<DealerApplication> fetch() async => _parse(await _dio.get('/dealers/me'));

  @override
  Future<DealerApplication> updateDetails({
    String? businessName,
    String? gstin,
    String? address,
    String? city,
  }) async {
    return _parse(await _dio.patch('/dealers/me', data: {
      'business_name': ?businessName,
      'gstin': ?gstin,
      'address': ?address,
      'city': ?city,
    }));
  }

  @override
  Future<DealerApplication> uploadDocument(
    DocumentType type, {
    required String fileName,
    required Uint8List bytes,
  }) async {
    final form = FormData.fromMap({
      'doc_type': type.api,
      'file': MultipartFile.fromBytes(bytes, filename: fileName),
    });
    await _dio.post(
      '/dealers/me/documents',
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );
    return fetch();
  }

  @override
  Future<DealerApplication> deleteDocument(String documentId) async {
    await _dio.delete('/dealers/me/documents/$documentId');
    return fetch();
  }

  @override
  Future<DealerApplication> submit() async => _parse(await _dio.post('/dealers/me/submit'));
}
