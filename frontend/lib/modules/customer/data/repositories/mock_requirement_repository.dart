import '../../domain/entities/buy_requirement.dart';
import '../../domain/entities/requirement_draft.dart';
import '../../domain/repositories/requirement_repository.dart';
import '../mock/customer_mock_data.dart';

/// In-memory stand-in for demos and tests. Enforces the same lifecycle rules as the API.
class MockRequirementRepository implements RequirementRepository {
  final List<BuyRequirement> _items = [...CustomerMockData.requirements];
  int _next = 200;

  int _index(String id) {
    final i = _items.indexWhere((r) => r.id == id);
    if (i < 0) throw Exception('Requirement not found');
    return i;
  }

  BuyRequirement _build(
    String id,
    RequirementDraft d, {
    required String status,
    required DateTime createdAt,
    int quotes = 0,
  }) {
    final year = DateTime.now().year;
    return BuyRequirement(
      id: id,
      make: d.make!,
      model: d.model ?? '',
      minYear: d.yearMin,
      maxYear: d.yearMax ?? year + 1,
      minBudget: d.budgetMin.toDouble(),
      maxBudget: d.budgetMax.toDouble(),
      fuelType: d.fuel ?? 'Any',
      transmission: d.transmission ?? 'Any',
      preferredCity: d.city!,
      status: status,
      quotesReceived: quotes,
      createdAt: createdAt,
      bodyType: d.bodyType,
      maxKm: d.maxKm,
      maxOwners: d.maxOwners,
      radiusKm: d.radiusKm,
      urgency: d.urgency,
      needsFinance: d.needsFinance,
      hasExchange: d.hasExchange,
      mustHave: d.mustHave.toList()..sort(),
      notes: d.notes,
      expiresAt: createdAt.add(const Duration(days: 14)),
    );
  }

  @override
  Future<List<BuyRequirement>> list() async => List.of(_items);

  @override
  Future<BuyRequirement> create(RequirementDraft draft) async {
    final open = _items.where((r) => r.isEditable).length;
    if (open >= 5) {
      throw Exception(
        'You already have 5 open requests. Close one to post another.',
      );
    }
    final created = _build(
      'REQ-${_next++}',
      draft,
      status: 'open',
      createdAt: DateTime.now(),
    );
    _items.insert(0, created);
    return created;
  }

  @override
  Future<BuyRequirement> update(String id, RequirementDraft draft) async {
    final i = _index(id);
    final old = _items[i];
    if (!old.isEditable) {
      throw Exception('This request can no longer be edited.');
    }
    final updated = _build(
      id,
      draft,
      status: old.status,
      createdAt: old.createdAt,
      quotes: old.quotesReceived,
    );
    _items[i] = updated;
    return updated;
  }

  Future<BuyRequirement> _setStatus(
    String id,
    String status, {
    required bool Function(BuyRequirement) allowed,
  }) async {
    final i = _index(id);
    final old = _items[i];
    if (!allowed(old)) {
      throw Exception(
        'A request that is ${old.statusLabel.toLowerCase()} cannot do that.',
      );
    }
    final d = RequirementDraft.from(old);
    final updated = _build(
      id,
      d,
      status: status,
      createdAt: old.createdAt,
      quotes: old.quotesReceived,
    );
    _items[i] = updated;
    return updated;
  }

  @override
  Future<BuyRequirement> pause(String id) =>
      _setStatus(id, 'paused', allowed: (r) => r.isOpen);

  @override
  Future<BuyRequirement> resume(String id) =>
      _setStatus(id, 'open', allowed: (r) => r.isPaused);

  @override
  Future<BuyRequirement> cancel(String id) =>
      _setStatus(id, 'cancelled', allowed: (r) => r.isEditable);
}
