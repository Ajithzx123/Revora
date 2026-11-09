import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/buy_requirement.dart';
import '../../domain/entities/requirement_draft.dart';
import '../../domain/repositories/requirement_repository.dart';

/// The signed-in buyer's requests. Each action stores the server's answer and
/// rethrows failures so the screen can show them.
class RequirementsNotifier extends AsyncNotifier<List<BuyRequirement>> {
  RequirementRepository get _repo => ref.read(requirementRepositoryProvider);

  @override
  Future<List<BuyRequirement>> build() => _repo.list();

  Future<void> refresh() async {
    state = await AsyncValue.guard(_repo.list);
  }

  List<BuyRequirement> get _current => state.valueOrNull ?? const [];

  Future<BuyRequirement> create(RequirementDraft draft) async {
    final created = await _repo.create(draft);
    state = AsyncData([created, ..._current]);
    return created;
  }

  Future<BuyRequirement> _replace(
    Future<BuyRequirement> Function() action,
  ) async {
    final updated = await action();
    state = AsyncData([
      for (final r in _current) r.id == updated.id ? updated : r,
    ]);
    return updated;
  }

  Future<BuyRequirement> edit(String id, RequirementDraft draft) =>
      _replace(() => _repo.update(id, draft));
  Future<BuyRequirement> pause(String id) => _replace(() => _repo.pause(id));
  Future<BuyRequirement> resume(String id) => _replace(() => _repo.resume(id));
  Future<BuyRequirement> cancel(String id) => _replace(() => _repo.cancel(id));
}

final requirementsProvider =
    AsyncNotifierProvider<RequirementsNotifier, List<BuyRequirement>>(
      RequirementsNotifier.new,
    );
