import 'package:flutter/material.dart';

class CustomLoader extends StatelessWidget {
  final bool isFullScreen;

  const CustomLoader({
    super.key,
    this.isFullScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final spinner = CircularProgressIndicator(
      valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
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
