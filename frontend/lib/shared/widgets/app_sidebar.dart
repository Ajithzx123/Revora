import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/revora_theme_colors.dart';
import 'theme_toggle_button.dart';

class AppSidebarItem {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;
  final int? badgeCount;

  const AppSidebarItem({
    required this.icon,
    this.selectedIcon,
    required this.label,
    this.badgeCount,
  });
}

class AppSidebar extends StatelessWidget {
  final String title;
  final String roleBadge;
  final List<AppSidebarItem> items;
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final Widget? footer;

  const AppSidebar({
    super.key,
    required this.title,
    required this.roleBadge,
    required this.items,
    required this.selectedIndex,
    required this.onItemSelected,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final colors = context.revoraColors;

    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: colors.sidebarBg,
        border: Border(
          right: BorderSide(color: colors.sidebarBorder, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header / Brand
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.xxl,
              AppSpacing.xl,
              AppSpacing.lg,
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: cs.secondary,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: const Center(
                    child: Text(
                      'R',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: colors.sidebarText,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs + 2,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: cs.secondary.withValues(alpha: 0.2),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusPill),
                      ),
                      child: Text(
                        roleBadge.toUpperCase(),
                        style: TextStyle(
                          color: cs.secondary,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(color: colors.sidebarBorder, height: 1),
          const SizedBox(height: AppSpacing.md),

          // Nav Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = index == selectedIndex;

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xxs + 1),
                  child: InkWell(
                    onTap: () => onItemSelected(index),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm + 2,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colors.sidebarSelectedBg
                            : Colors.transparent,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                        border: isSelected
                            ? Border(
                                left: BorderSide(
                                  color: cs.secondary,
                                  width: 3,
                                ),
                              )
                            : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? (item.selectedIcon ?? item.icon)
                                : item.icon,
                            color: isSelected
                                ? cs.secondary
                                : colors.sidebarTextMuted,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              item.label,
                              style: TextStyle(
                                color: isSelected
                                    ? colors.sidebarText
                                    : colors.sidebarTextMuted,
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                          if (item.badgeCount != null && item.badgeCount! > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xs + 2,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? cs.secondary
                                    : colors.sidebarBorder,
                                borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusPill),
                              ),
                              child: Text(
                                '${item.badgeCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Footer
          Divider(color: colors.sidebarBorder, height: 1),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: footer ?? const SidebarThemeToggle(),
          ),
        ],
      ),
    );
  }
}
