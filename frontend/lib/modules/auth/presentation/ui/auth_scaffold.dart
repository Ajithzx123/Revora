import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/bid_stack.dart';

/// Shared layout for sign-in and sign-up.
/// Phone: a brand header with the form sheet rising over it.
/// Wide: brand panel on the left, form centred on the right.
class AuthScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 900) return _wide(context);
          return _compact(context);
        },
      ),
    );
  }

  Widget _formHeader(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: t.headlineMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(subtitle, style: t.bodyMedium?.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }

  Widget _compact(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: MediaQuery.sizeOf(context).height),
        child: Column(
          children: [
            // Brand header
            Container(
              width: double.infinity,
              color: AppColors.primary,
              child: Stack(
                children: [
                  const Positioned(right: -70, top: -70, child: _Glow(size: 260)),
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 64),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _Logo(),
                          const SizedBox(height: 28),
                          Text(
                            'Post once.\nDealers compete.',
                            style: t.displaySmall?.copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Verified dealers send you their best price. You pick the winner.',
                            style: t.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.78)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Form sheet rising over the header
            Transform.translate(
              offset: const Offset(0, -32),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [_formHeader(context), child],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _wide(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Container(
            color: AppColors.primary,
            child: Stack(
              children: [
                const Positioned(right: -120, top: -120, child: _Glow(size: 460)),
                const Positioned(left: -140, bottom: -160, child: _Glow(size: 380, opacity: 0.18)),
                Padding(
                  padding: const EdgeInsets.all(56),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _Logo(),
                      const Spacer(),
                      Text('Post once.\nDealers compete.',
                          style: t.displayMedium?.copyWith(color: Colors.white, fontSize: 44)),
                      const SizedBox(height: 14),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Text(
                          'Tell us the car you want, or the car you are selling. '
                          'Verified dealers send itemised offers and you choose the best one.',
                          style: t.bodyLarge?.copyWith(color: Colors.white.withValues(alpha: 0.78)),
                        ),
                      ),
                      const SizedBox(height: 40),
                      const BidStack(width: 320),
                      const Spacer(),
                      Text(
                        'Verified dealers  ·  Itemised prices  ·  Price lock after you accept',
                        style: t.labelMedium?.copyWith(color: Colors.white.withValues(alpha: 0.6)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [_formHeader(context), child],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(13),
          ),
          alignment: Alignment.center,
          child: Text(
            'R',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.onAccent,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Revora',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 22,
              ),
        ),
      ],
    );
  }
}

/// Soft orange light behind the brand content.
class _Glow extends StatelessWidget {
  final double size;
  final double opacity;
  const _Glow({required this.size, this.opacity = 0.32});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [AppColors.accent.withValues(alpha: opacity), AppColors.accent.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}
