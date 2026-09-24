import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/constants.dart';
import '../utils/storage_helper.dart';
import 'app_accent_colors.dart';

final accentProvider =
    StateNotifierProvider<AccentNotifier, AppAccentColor>((ref) {
  return AccentNotifier();
});

class AccentNotifier extends StateNotifier<AppAccentColor> {
  AccentNotifier() : super(_getInitialAccent());

  static AppAccentColor _getInitialAccent() {
    try {
      final savedId = StorageHelper.getString(AppConstants.prefAccentColor);
      if (savedId != null && savedId.isNotEmpty) {
        final match = kAccentPresets.cast<AppAccentColor?>().firstWhere(
              (p) => p?.id == savedId,
              orElse: () => null,
            );
        if (match != null) return match;
      }
    } catch (_) {
      // Fallback gracefully in testing/uninitialized environments
    }
    return kDefaultAccent;
  }

  void setAccent(AppAccentColor accent) {
    state = accent;
    try {
      StorageHelper.setString(AppConstants.prefAccentColor, accent.id)
          .catchError((_) => false);
    } catch (_) {
      // Fallback gracefully in testing environments
    }
  }
}
