import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Revora's signature visual: dealers competing on price. Three offers slide in
/// one after another and the lowest is crowned. It is the product in one picture.
/// Purely illustrative (the figures are not real data).
class BidStack extends StatefulWidget {
  final double width;
  const BidStack({super.key, this.width = 280});

  @override
  State<BidStack> createState() => _BidStackState();
}

class _BidStackState extends State<BidStack> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const _bids = [
    ('A', 'Apex Motors', '₹7.45 L', false),
    ('C', 'City Wheels', '₹7.20 L', false),
    ('S', 'Sunrise Cars', '₹6.95 L', true),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) _controller.value = 1;

    return Semantics(
      label: 'Example: three dealers compete, the lowest offer is 6.95 lakh',
      child: ExcludeSemantics(
        child: SizedBox(
          width: widget.width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < _bids.length; i++) ...[
                _slide(i, _BidCard(
                  initial: _bids[i].$1,
                  dealer: _bids[i].$2,
                  price: _bids[i].$3,
                  best: _bids[i].$4,
                )),
                if (i < _bids.length - 1) const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _slide(int index, Widget child) {
    final start = index * 0.22;
    final animation = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, (start + 0.5).clamp(0, 1), curve: Curves.easeOutCubic),
    );
    // Cards alternate their indent so the stack feels alive, not like a table.
    final indent = index.isEven ? 0.0 : 18.0;
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) => Opacity(
        opacity: animation.value,
        child: Transform.translate(
          offset: Offset(indent + (1 - animation.value) * 36, 0),
          child: child,
        ),
      ),
    );
  }
}

class _BidCard extends StatelessWidget {
  final String initial;
  final String dealer;
  final String price;
  final bool best;

  const _BidCard({
    required this.initial,
    required this.dealer,
    required this.price,
    required this.best,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: best ? AppColors.success : Colors.transparent,
          width: 1.6,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 2, offset: const Offset(0, 1)),
          BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 18, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: best ? AppColors.success : AppColors.primary,
            child: Text(
              initial,
              style: AppTextStyles.labelMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(dealer, style: AppTextStyles.labelMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                if (best)
                  Text(
                    'Best price',
                    style: AppTextStyles.labelSmall.copyWith(color: AppColors.success, fontWeight: FontWeight.w700),
                  ),
              ],
            ),
          ),
          Text(
            price,
            style: AppTextStyles.titleLarge.copyWith(
              fontSize: 16,
              color: best ? AppColors.success : AppColors.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
