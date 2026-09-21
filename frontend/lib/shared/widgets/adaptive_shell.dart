import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import 'app_sidebar.dart';
import 'responsive_layout.dart';

class AdaptiveShell extends StatelessWidget {
  final String title;
  final String roleBadge;
  final List<AppSidebarItem> items;
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? desktopHeaderTrailing;

  const AdaptiveShell({
    super.key,
    required this.title,
    required this.roleBadge,
    required this.items,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.body,
    this.floatingActionButton,
    this.desktopHeaderTrailing,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      // 1. Mobile (<600px): BottomNavigationBar
      mobile: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          scrolledUnderElevation: 1,
          title: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                ),
                child: const Center(
                  child: Text(
                    'R',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          actions: desktopHeaderTrailing != null
              ? [desktopHeaderTrailing!]
              : null,
        ),
        body: body,
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onItemSelected,
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.accent.withValues(alpha: 0.15),
          destinations: items.map((item) {
            return NavigationDestination(
              icon: item.badgeCount != null && item.badgeCount! > 0
                  ? Badge(
                      label: Text('${item.badgeCount}'),
                      child: Icon(item.icon),
                    )
                  : Icon(item.icon),
              selectedIcon: Icon(
                item.selectedIcon ?? item.icon,
                color: AppColors.accent,
              ),
              label: item.label,
            );
          }).toList(),
        ),
      ),

      // 2. Tablet (600-1199px): NavigationRail
      tablet: Scaffold(
        backgroundColor: AppColors.background,
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: onItemSelected,
              backgroundColor: AppColors.primary,
              selectedIconTheme: const IconThemeData(color: AppColors.accent),
              unselectedIconTheme: const IconThemeData(
                color: Color(0xFF94A3B8),
              ),
              selectedLabelTextStyle: const TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              unselectedLabelTextStyle: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 12,
              ),
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
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
              ),
              destinations: items.map((item) {
                return NavigationRailDestination(
                  icon: item.badgeCount != null && item.badgeCount! > 0
                      ? Badge(
                          label: Text('${item.badgeCount}'),
                          child: Icon(item.icon),
                        )
                      : Icon(item.icon),
                  selectedIcon: Icon(item.selectedIcon ?? item.icon),
                  label: Text(item.label),
                );
              }).toList(),
            ),
            const VerticalDivider(
              thickness: 1,
              width: 1,
              color: Color(0xFF1E293B),
            ),
            Expanded(
              child: Column(
                children: [
                  if (desktopHeaderTrailing != null)
                    Container(
                      height: 56,
                      color: AppColors.surface,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [desktopHeaderTrailing!],
                      ),
                    ),
                  Expanded(child: body),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: floatingActionButton,
      ),

      // 3. Desktop (>=1200px): Full AppSidebar
      desktop: Scaffold(
        backgroundColor: AppColors.background,
        body: Row(
          children: [
            AppSidebar(
              title: title,
              roleBadge: roleBadge,
              items: items,
              selectedIndex: selectedIndex,
              onItemSelected: onItemSelected,
            ),
            Expanded(
              child: Column(
                children: [
                  Container(
                    height: 64,
                    color: AppColors.surface,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xxl,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          items[selectedIndex].label,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        if (desktopHeaderTrailing != null)
                          desktopHeaderTrailing!,
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.border),
                  Expanded(child: body),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: floatingActionButton,
      ),
    );
  }
}
