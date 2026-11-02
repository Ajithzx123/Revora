import 'dart:typed_data';
import '../../../../shared/domain/entities/vehicle.dart';
import '../../domain/entities/vehicle_draft.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../mock/dealer_mock_data.dart';

/// In-memory stand-in for demos and tests. Mirrors the API's rules.
class MockInventoryRepository implements InventoryRepository {
  final List<Vehicle> _items = [...DealerMockData.inventory];
  int _next = 500;
  int _photo = 0;

  int _index(String id) {
    final i = _items.indexWhere((v) => v.id == id);
    if (i < 0) throw Exception('Vehicle not found');
    return i;
  }

  Vehicle _build(String id, VehicleDraft d, {String status = 'available', List<VehicleImage> images = const []}) {
    final variant = (d.variant ?? '').trim();
    return Vehicle(
      id: id,
      title: '${d.year} ${d.make} ${d.model}${variant.isEmpty ? '' : ' $variant'}',
      make: d.make!,
      model: d.model!,
      year: d.year!,
      price: d.price!.toDouble(),
      fuelType: d.fuel!,
      transmission: d.transmission!,
      mileage: d.km!,
      city: 'Mumbai',
      imageUrl: images.isEmpty ? '' : images.first.url,
      status: status,
      registrationNo: d.registrationNo,
      variant: variant.isEmpty ? null : variant,
      owners: d.owners,
      color: d.color,
      bodyType: d.bodyType,
      minPrice: d.minPrice?.toDouble(),
      description: d.description,
      images: images,
    );
  }

  String _normal(String? reg) => (reg ?? '').replaceAll(RegExp(r'[\s-]'), '').toUpperCase();

  @override
  Future<List<Vehicle>> list() async => List.of(_items);

  @override
  Future<Vehicle> create(VehicleDraft draft) async {
    final reg = _normal(draft.registrationNo);
    if (_items.any((v) => _normal(v.registrationNo) == reg && reg.isNotEmpty)) {
      throw Exception('A vehicle with this registration number is already listed.');
    }
    draft.registrationNo = reg;
    final created = _build('VEH-${_next++}', draft);
    _items.insert(0, created);
    return created;
  }

  @override
  Future<Vehicle> update(String id, VehicleDraft draft) async {
    final i = _index(id);
    final reg = _normal(draft.registrationNo);
    if (_items.any((v) => v.id != id && _normal(v.registrationNo) == reg && reg.isNotEmpty)) {
      throw Exception('A vehicle with this registration number is already listed.');
    }
    draft.registrationNo = reg;
    final old = _items[i];
    return _items[i] = _build(id, draft, status: old.status, images: old.images);
  }

  Vehicle _withImages(int i, List<VehicleImage> images) {
    final v = _items[i];
    return _items[i] = _build(v.id, VehicleDraft.from(v), status: v.status, images: images);
  }

  @override
  Future<Vehicle> setStatus(String id, String status) async {
    final i = _index(id);
    final v = _items[i];
    return _items[i] = _build(id, VehicleDraft.from(v), status: status.toLowerCase(), images: v.images);
  }

  @override
  Future<void> delete(String id) async => _items.removeAt(_index(id));

  @override
  Future<Vehicle> addPhoto(String vehicleId, {required String fileName, required Uint8List bytes}) async {
    final i = _index(vehicleId);
    final current = _items[i].images;
    if (current.length >= 8) throw Exception('A vehicle can have at most 8 photos');
    // Demo mode has no file server: reuse a stock photo so the UI still shows something.
    final n = _photo++;
    return _withImages(i, [
      ...current,
      VehicleImage(id: 'IMG-$n', url: 'https://images.unsplash.com/photo-1549399542-7e3f8b79c341?w=500&sig=$n'),
    ]);
  }

  @override
  Future<Vehicle> removePhoto(String vehicleId, String photoId) async {
    final i = _index(vehicleId);
    return _withImages(i, [for (final m in _items[i].images) if (m.id != photoId) m]);
  }

  @override
  Future<Vehicle> reorderPhotos(String vehicleId, List<String> orderedIds) async {
    final i = _index(vehicleId);
    final byId = {for (final m in _items[i].images) m.id: m};
    return _withImages(i, [for (final id in orderedIds) byId[id]!]);
  }
}
