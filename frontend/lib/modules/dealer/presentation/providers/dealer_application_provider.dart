import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/dealer_application.dart';
import '../../domain/repositories/dealer_onboarding_repository.dart';

/// The signed-in dealer's application. Actions update the state with the server's
/// answer and rethrow failures so the screen can show them.
class DealerApplicationNotifier extends AsyncNotifier<DealerApplication> {
  DealerOnboardingRepository get _repo =>
      ref.read(dealerOnboardingRepositoryProvider);

  @override
  Future<DealerApplication> build() => _repo.fetch();

  Future<void> refresh() async {
    state = await AsyncValue.guard(_repo.fetch);
  }

  Future<void> _apply(Future<DealerApplication> Function() action) async {
    final updated = await action();
    state = AsyncData(updated);
  }

  Future<void> saveDetails({
    required String businessName,
    required String gstin,
    required String address,
    required String city,
  }) => _apply(
    () => _repo.updateDetails(
      businessName: businessName,
      gstin: gstin,
      address: address,
      city: city,
    ),
  );

  Future<void> upload(DocumentType type, String fileName, Uint8List bytes) =>
      _apply(
        () => _repo.uploadDocument(type, fileName: fileName, bytes: bytes),
      );

  Future<void> remove(String documentId) =>
      _apply(() => _repo.deleteDocument(documentId));

  Future<void> submit() => _apply(_repo.submit);

  Future<void> setSourcingMakes(List<String> makes) =>
      _apply(() => _repo.setSourcingMakes(makes));
}

final dealerApplicationProvider =
    AsyncNotifierProvider<DealerApplicationNotifier, DealerApplication>(
      DealerApplicationNotifier.new,
    );
