import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/domain/entities/vehicle.dart';
import '../../domain/entities/vehicle_draft.dart';
import '../../domain/repositories/inventory_repository.dart';

/// The signed-in dealer's stock. Each action stores the server's answer and
/// rethrows failures so the screen can show them.
class InventoryNotifier extends AsyncNotifier<List<Vehicle>> {
  InventoryRepository get _repo => ref.read(inventoryRepositoryProvider);

  @override
  Future<List<Vehicle>> build() => _repo.list();

  Future<void> refresh() async {
    state = await AsyncValue.guard(_repo.list);
  }

  List<Vehicle> get _current => state.valueOrNull ?? const [];

  void _put(Vehicle v) {
    final exists = _current.any((x) => x.id == v.id);
    state = AsyncData(exists ? [for (final x in _current) x.id == v.id ? v : x] : [v, ..._current]);
  }

  Future<Vehicle> create(VehicleDraft draft) async {
    final v = await _repo.create(draft);
    _put(v);
    return v;
  }

  Future<Vehicle> edit(String id, VehicleDraft draft) async {
    final v = await _repo.update(id, draft);
    _put(v);
    return v;
  }

  Future<Vehicle> setStatus(String id, String status) async {
    final v = await _repo.setStatus(id, status);
    _put(v);
    return v;
  }

  Future<void> remove(String id) async {
    await _repo.delete(id);
    state = AsyncData([for (final x in _current) if (x.id != id) x]);
  }

  Future<Vehicle> addPhoto(String id, String fileName, Uint8List bytes) async {
    final v = await _repo.addPhoto(id, fileName: fileName, bytes: bytes);
    _put(v);
    return v;
  }

  Future<Vehicle> removePhoto(String id, String photoId) async {
    final v = await _repo.removePhoto(id, photoId);
    _put(v);
    return v;
  }

  Future<Vehicle> makeCover(String id, String photoId) async {
    final current = _current.firstWhere((v) => v.id == id);
    final order = [photoId, for (final m in current.images) if (m.id != photoId) m.id];
    final v = await _repo.reorderPhotos(id, order);
    _put(v);
    return v;
  }
}

final inventoryProvider = AsyncNotifierProvider<InventoryNotifier, List<Vehicle>>(InventoryNotifier.new);
