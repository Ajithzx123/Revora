import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/dealer_match_card.dart';
import '../providers/customer_providers.dart';
import '../widgets/requirement_summary_card.dart';
import '../widgets/customer_quote_card.dart';
import '../widgets/customer_sell_car_card.dart';

class CustomerHomeScreen extends ConsumerWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sellPosts = ref.watch(customerSellPostsProvider);
    final requirements = ref.watch(customerRequirementsProvider);
    final allQuotes = ref.watch(allCustomerQuotesProvider);
    final topDealers = ref.watch(topDealersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Top Section: Clean title & compact Buy/Sell action cards
                _buildTopSection(context),
                const SizedBox(height: AppSpacing.xl),

                // 2. Cars for Sale
                SectionHeader(
                  title: 'For Sale',
                  actionLabel: 'View All',
                  onActionTap: () {
                    ref.read(customerActiveTabProvider.notifier).state = 2;
                  },
                ),
                if (sellPosts.isEmpty)
                  _buildEmptyCard('No cars listed for sale yet')
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final double itemWidth = constraints.maxWidth > 900
                          ? (constraints.maxWidth - (2 * AppSpacing.md)) / 3
                          : constraints.maxWidth > 600
                              ? (constraints.maxWidth - AppSpacing.md) / 2
                              : constraints.maxWidth * 0.82;

                      return SizedBox(
                        height: 345,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: sellPosts.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(width: AppSpacing.md),
                          itemBuilder: (context, index) {
                            final post = sellPosts[index];
                            return SizedBox(
                              width: itemWidth,
                              child: CustomerSellCarCard(
                                post: post,
                                imageHeight: 105,
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                const SizedBox(height: AppSpacing.xl),

                // 3. Looking to Buy (Requirements)
                SectionHeader(
                  title: 'Looking to Buy',
                  actionLabel: 'View All',
                  onActionTap: () {
                    ref.read(customerActiveTabProvider.notifier).state = 1;
                  },
                ),
                if (requirements.isEmpty)
                  _buildEmptyCard('No active requirements yet')
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final double itemWidth = constraints.maxWidth > 900
                          ? (constraints.maxWidth - (2 * AppSpacing.md)) / 3
                          : constraints.maxWidth > 600
                              ? (constraints.maxWidth - AppSpacing.md) / 2
                              : constraints.maxWidth * 0.82;

                      return SizedBox(
                        height: 226,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: requirements.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(width: AppSpacing.md),
                          itemBuilder: (context, index) {
                            final req = requirements[index];
                            return SizedBox(
                              width: itemWidth,
                              child: RequirementSummaryCard(
                                requirement: req,
                                imageHeight: 44,
                                onViewQuotes: () {
                                  ref.read(customerActiveTabProvider.notifier).state =
                                      1;
                                },
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                const SizedBox(height: AppSpacing.xl),

                // 4. Recent Quotes Received
                SectionHeader(
                  title: 'Recent Quotes',
                  actionLabel: 'Compare All',
                  onActionTap: () {
                    ref.read(customerActiveTabProvider.notifier).state = 1;
                  },
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final double itemWidth = constraints.maxWidth > 900
                        ? (constraints.maxWidth - (2 * AppSpacing.md)) / 3
                        : constraints.maxWidth > 600
                            ? (constraints.maxWidth - AppSpacing.md) / 2
                            : constraints.maxWidth * 0.82;

                    return SizedBox(
                      height: 345,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: allQuotes.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(width: AppSpacing.md),
                        itemBuilder: (context, index) {
                          return SizedBox(
                            width: itemWidth,
                            child: CustomerQuoteCard(
                              quote: allQuotes[index],
                              isHomeScreen: true,
                              imageHeight: 110,
                              onContact: () => context.push('/chat'),
                              onAccept: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Quote accepted! Dealer notified.',
                                    ),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.xxl),

                // 5. Verified Network Dealers
                const SectionHeader(
                  title: 'Top Verified Dealers',
                ),
                SizedBox(
                  height: 180,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: topDealers.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: AppSpacing.md),
                    itemBuilder: (context, index) {
                      final dealer = topDealers[index];
                      return DealerMatchCard(
                        dealer: dealer,
                        onConnect: () => context.push('/chat'),
                        onViewProfile: () {},
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What can we help you with today?',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 600;

            final buyCard = _CompactActionCard(
              emoji: '🚗',
              title: 'Buy a Car',
              subtitle: "Tell us what you're looking for",
              accentColor: const Color(0xFF2563EB),
              onTap: () => context.push('/post-requirement'),
            );

            final sellCard = _CompactActionCard(
              emoji: '💰',
              title: 'Sell My Car',
              subtitle: 'Get offers from verified dealers',
              accentColor: AppColors.accent,
              onTap: () => context.push('/sell-car'),
            );

            if (isWide) {
              return Row(
                children: [
                  Expanded(child: buyCard),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: sellCard),
                ],
              );
            }

            return Column(
              children: [
                buyCard,
                const SizedBox(height: AppSpacing.sm),
                sellCard,
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyCard(String message) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

class _CompactActionCard extends StatefulWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;

  const _CompactActionCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_CompactActionCard> createState() => _CompactActionCardState();
}

class _CompactActionCardState extends State<_CompactActionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: _isHovered
                  ? widget.accentColor
                  : AppColors.border,
              width: _isHovered ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? widget.accentColor.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.03),
                blurRadius: _isHovered ? 10 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: widget.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Center(
                  child: Text(
                    widget.emoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _isHovered
                      ? widget.accentColor
                      : widget.accentColor.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: _isHovered ? Colors.white : widget.accentColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

