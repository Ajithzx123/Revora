import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class CustomLoader extends StatelessWidget {
  final bool isFullScreen;

  const CustomLoader({
    super.key,
    this.isFullScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    final spinner = const CircularProgressIndicator(
      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
    );

    if (isFullScreen) {
      return Container(
        color: Colors.black.withValues(alpha: 0.3),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: spinner,
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: spinner,
      ),
    );
  }
}
