import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/media_url.dart';
import '../../../../shared/domain/entities/vehicle.dart';
import '../../data/repositories/mock_inventory_repository.dart';
import '../entities/vehicle_draft.dart';

abstract class InventoryRepository {
  Future<List<Vehicle>> list();
  Future<Vehicle> create(VehicleDraft draft);
  Future<Vehicle> update(String id, VehicleDraft draft);
  Future<Vehicle> setStatus(String id, String status); // available | reserved | sold
  Future<void> delete(String id);
  Future<Vehicle> addPhoto(String vehicleId, {required String fileName, required Uint8List bytes});
  Future<Vehicle> removePhoto(String vehicleId, String photoId);

  /// The first id becomes the cover photo.
  Future<Vehicle> reorderPhotos(String vehicleId, List<String> orderedIds);
}

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  if (AppConfig.instance.useMockData) return MockInventoryRepository();
  return ApiInventoryRepository(ref.watch(dioProvider));
});

class ApiInventoryRepository implements InventoryRepository {
  final Dio _dio;
  ApiInventoryRepository(this._dio);

  Vehicle _one(Response<dynamic> res) => Vehicle.fromJson(res.data as Map<String, dynamic>, resolveMediaUrl);

  @override
  Future<List<Vehicle>> list() async {
    final res = await _dio.get('/inventory');
    return [for (final j in res.data as List) Vehicle.fromJson(j as Map<String, dynamic>, resolveMediaUrl)];
  }

  @override
  Future<Vehicle> create(VehicleDraft draft) async => _one(await _dio.post('/inventory', data: draft.toJson()));

  @override
  Future<Vehicle> update(String id, VehicleDraft draft) async =>
      _one(await _dio.patch('/inventory/$id', data: draft.toJson()));

  @override
  Future<Vehicle> setStatus(String id, String status) async =>
      _one(await _dio.patch('/inventory/$id', data: {'status': status.toUpperCase()}));

  @override
  Future<void> delete(String id) async {
    await _dio.delete('/inventory/$id');
  }

  @override
  Future<Vehicle> addPhoto(String vehicleId, {required String fileName, required Uint8List bytes}) async {
    final form = FormData.fromMap({'file': MultipartFile.fromBytes(bytes, filename: fileName)});
    return _one(await _dio.post(
      '/inventory/$vehicleId/media',
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    ));
  }

  @override
  Future<Vehicle> removePhoto(String vehicleId, String photoId) async =>
      _one(await _dio.delete('/inventory/$vehicleId/media/$photoId'));

  @override
  Future<Vehicle> reorderPhotos(String vehicleId, List<String> orderedIds) async =>
      _one(await _dio.put('/inventory/$vehicleId/media/order', data: {'ids': orderedIds}));
}
