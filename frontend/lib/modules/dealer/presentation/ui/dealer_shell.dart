import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/adaptive_shell.dart';
import '../../../../shared/widgets/app_sidebar.dart';
import '../providers/dealer_providers.dart';
import 'dealer_home_screen.dart';
import 'dealer_leads_screen.dart';
import 'dealer_inventory_screen.dart';
import 'dealer_activity_screen.dart';
import 'dealer_profile_screen.dart';

class DealerShell extends ConsumerWidget {
  const DealerShell({super.key});

  static const List<AppSidebarItem> _navItems = [
    AppSidebarItem(
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      label: 'Home',
    ),
    AppSidebarItem(
      icon: Icons.tune_outlined,
      selectedIcon: Icons.tune,
      label: 'Leads',
      badgeCount: 6,
    ),
    AppSidebarItem(
      icon: Icons.directions_car_outlined,
      selectedIcon: Icons.directions_car,
      label: 'Inventory',
    ),
    AppSidebarItem(
      icon: Icons.notifications_none_outlined,
      selectedIcon: Icons.notifications,
      label: 'Activity',
      badgeCount: 1,
    ),
    AppSidebarItem(
      icon: Icons.business_outlined,
      selectedIcon: Icons.business,
      label: 'Dealership',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeIndex = ref.watch(dealerActiveTabProvider);

    final screens = const [
      DealerHomeScreen(),
      DealerLeadsScreen(),
      DealerInventoryScreen(),
      DealerActivityScreen(),
      DealerProfileScreen(),
    ];

    return AdaptiveShell(
      title: 'Revora Pro',
      roleBadge: 'Dealer Portal',
      items: _navItems,
      selectedIndex: activeIndex,
      onItemSelected: (index) {
        ref.read(dealerActiveTabProvider.notifier).state = index;
      },
      body: IndexedStack(index: activeIndex, children: screens),
    );
  }
}
