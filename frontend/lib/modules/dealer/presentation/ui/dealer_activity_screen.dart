import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/activity_tile.dart';
import '../providers/dealer_providers.dart';

class DealerActivityScreen extends ConsumerWidget {
  const DealerActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activities = ref.watch(dealerActivitiesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: 'Dealership Activity & Alerts',
                  subtitle: 'Real-time broadcasted leads, accepted quotes, and system logs',
                ),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: AppColors.border, width: 0.8),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: activities.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, color: AppColors.borderLight),
                    itemBuilder: (context, index) {
                      final act = activities[index];
                      IconData icon;
                      Color iconColor;
                      Color iconBg;

                      switch (act.type) {
                        case 'quote_accepted':
                          icon = Icons.check_circle_outline;
                          iconColor = AppColors.success;
                          iconBg = AppColors.successBg;
                          break;
                        case 'lead':
                          icon = Icons.bolt;
                          iconColor = AppColors.accent;
                          iconBg = AppColors.accentLight;
                          break;
                        case 'offer':
                          icon = Icons.local_offer_outlined;
                          iconColor = AppColors.info;
                          iconBg = AppColors.infoBg;
                          break;
                        default:
                          icon = Icons.directions_car_outlined;
                          iconColor = AppColors.primary;
                          iconBg = AppColors.primarySubtle;
                      }

                      return ActivityTile(
                        title: act.title,
                        subtitle: act.subtitle,
                        time: act.time,
                        icon: icon,
                        iconColor: iconColor,
                        iconBgColor: iconBg,
                        onTap: () {},
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
