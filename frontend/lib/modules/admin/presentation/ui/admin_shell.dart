import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_sidebar.dart';
import '../../../../shared/widgets/responsive_layout.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../providers/admin_providers.dart';
import 'admin_dashboard_screen.dart';
import 'admin_dealer_verification_screen.dart';
import 'admin_requirements_screen.dart';
import 'admin_vehicles_screen.dart';

class AdminShell extends ConsumerWidget {
  const AdminShell({super.key});

  static const List<AppSidebarItem> _navItems = [
    AppSidebarItem(
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      label: 'Overview',
    ),
    AppSidebarItem(
      icon: Icons.verified_user_outlined,
      selectedIcon: Icons.verified_user,
      label: 'Dealer Verification',
      badgeCount: 3,
    ),
    AppSidebarItem(
      icon: Icons.assignment_outlined,
      selectedIcon: Icons.assignment,
      label: 'Buy Requirements',
    ),
    AppSidebarItem(
      icon: Icons.directions_car_outlined,
      selectedIcon: Icons.directions_car,
      label: 'Vehicle Inventory',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeIndex = ref.watch(adminActiveNavIndexProvider);

    final screens = const [
      AdminDashboardScreen(),
      AdminDealerVerificationScreen(),
      AdminRequirementsScreen(),
      AdminVehiclesScreen(),
    ];

    return ResponsiveLayout(
      // Mobile: Uses drawer instead of bottom navigation
      mobile: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            _navItems[activeIndex].label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, size: 20, color: Colors.white),
              tooltip: 'Log Out',
              onPressed: () async {
                await ref.read(authControllerProvider.notifier).signOut();
                if (context.mounted) {
                  context.go('/login');
                }
              },
            ),
          ],
        ),
        drawer: Drawer(
          child: AppSidebar(
            title: 'Revora Admin',
            roleBadge: 'Superadmin',
            items: _navItems,
            selectedIndex: activeIndex,
            onItemSelected: (index) {
              ref.read(adminActiveNavIndexProvider.notifier).state = index;
              Navigator.of(context).pop();
            },
          ),
        ),
        body: IndexedStack(index: activeIndex, children: screens),
      ),

      // Tablet: Navigation rail
      tablet: Scaffold(
        backgroundColor: AppColors.background,
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: activeIndex,
              onDestinationSelected: (index) {
                ref.read(adminActiveNavIndexProvider.notifier).state = index;
              },
              backgroundColor: AppColors.primary,
              selectedIconTheme: const IconThemeData(color: AppColors.accent),
              unselectedIconTheme: const IconThemeData(
                color: Color(0xFF94A3B8),
              ),
              destinations: _navItems.map((item) {
                return NavigationRailDestination(
                  icon: item.badgeCount != null && item.badgeCount! > 0
                      ? Badge(
                          label: Text('${item.badgeCount}'),
                          child: Icon(item.icon),
                        )
                      : Icon(item.icon),
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
              child: IndexedStack(index: activeIndex, children: screens),
            ),
          ],
        ),
      ),

      // Desktop: Full AppSidebar with dark automotive SaaS header
      desktop: Scaffold(
        backgroundColor: AppColors.background,
        body: Row(
          children: [
            AppSidebar(
              title: 'Revora Admin',
              roleBadge: 'Superadmin',
              items: _navItems,
              selectedIndex: activeIndex,
              onItemSelected: (index) {
                ref.read(adminActiveNavIndexProvider.notifier).state = index;
              },
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
                          _navItems[activeIndex].label,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primarySubtle,
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusPill,
                                ),
                              ),
                              child: const Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: AppColors.primary,
                                    child: Text(
                                      'A',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: AppSpacing.xs),
                                  Text(
                                    'Admin Console',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            IconButton(
                              icon: const Icon(Icons.logout,
                                  size: 18, color: AppColors.error),
                              tooltip: 'Log Out',
                              onPressed: () async {
                                await ref
                                    .read(authControllerProvider.notifier)
                                    .signOut();
                                if (context.mounted) {
                                  context.go('/login');
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.border),
                  Expanded(
                    child: IndexedStack(index: activeIndex, children: screens),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
