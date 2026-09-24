import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/revora_theme_colors.dart';
import 'app_sidebar.dart';
import 'responsive_layout.dart';
import 'theme_toggle_button.dart';

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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final colors = context.revoraColors;

    return ResponsiveLayout(
      // 1. Mobile (<600px): BottomNavigationBar
      mobile: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: cs.surface,
          elevation: 0,
          scrolledUnderElevation: 1,
          title: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: cs.secondary,
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
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          actions: [
            const ThemeToggleButton(),
            ?desktopHeaderTrailing,
          ],
        ),
        body: body,
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onItemSelected,
          backgroundColor: cs.surface,
          indicatorColor: cs.secondary.withValues(alpha: 0.15),
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
                color: cs.secondary,
              ),
              label: item.label,
            );
          }).toList(),
        ),
      ),

      // 2. Tablet (600-1199px): NavigationRail
      tablet: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: onItemSelected,
              backgroundColor: colors.sidebarBg,
              selectedIconTheme: IconThemeData(color: cs.secondary),
              unselectedIconTheme: IconThemeData(
                color: colors.sidebarTextMuted,
              ),
              selectedLabelTextStyle: TextStyle(
                color: cs.secondary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              unselectedLabelTextStyle: TextStyle(
                color: colors.sidebarTextMuted,
                fontSize: 12,
              ),
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Container(
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
            VerticalDivider(
              thickness: 1,
              width: 1,
              color: colors.sidebarBorder,
            ),
            Expanded(
              child: Column(
                children: [
                  Container(
                    height: 56,
                    color: cs.surface,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const ThemeToggleButton(),
                        if (desktopHeaderTrailing != null) ...[
                          const SizedBox(width: AppSpacing.sm),
                          desktopHeaderTrailing!,
                        ],
                      ],
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
        backgroundColor: theme.scaffoldBackgroundColor,
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
                    color: cs.surface,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xxl,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          items[selectedIndex].label,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const ThemeToggleButton(),
                            if (desktopHeaderTrailing != null) ...[
                              const SizedBox(width: AppSpacing.md),
                              desktopHeaderTrailing!,
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: cs.outline),
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
