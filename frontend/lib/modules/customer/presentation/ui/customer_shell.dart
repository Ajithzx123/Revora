import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../shared/widgets/adaptive_shell.dart';
import '../../../../shared/widgets/app_sidebar.dart';
import '../providers/customer_providers.dart';
import 'customer_home_screen.dart';
import 'customer_buy_screen.dart';
import 'customer_sell_screen.dart';
import 'customer_activity_screen.dart';
import 'customer_profile_screen.dart';

class CustomerShell extends ConsumerWidget {
  const CustomerShell({super.key});

  static const List<AppSidebarItem> _navItems = [
    AppSidebarItem(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      label: 'Home',
    ),
    AppSidebarItem(
      icon: Icons.directions_car_outlined,
      selectedIcon: Icons.directions_car,
      label: 'Buy Cars',
      badgeCount: 3,
    ),
    AppSidebarItem(
      icon: Icons.sell_outlined,
      selectedIcon: Icons.sell,
      label: 'Sell Car',
    ),
    AppSidebarItem(
      icon: Icons.notifications_none_outlined,
      selectedIcon: Icons.notifications,
      label: 'Activity',
      badgeCount: 2,
    ),
    AppSidebarItem(
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeIndex = ref.watch(customerActiveTabProvider);

    final screens = const [
      CustomerHomeScreen(),
      CustomerBuyScreen(),
      CustomerSellScreen(),
      CustomerActivityScreen(),
      CustomerProfileScreen(),
    ];

    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    return AdaptiveShell(
      title: 'Revora',
      roleBadge: 'Customer',
      items: _navItems,
      selectedIndex: activeIndex,
      onItemSelected: (index) {
        ref.read(customerActiveTabProvider.notifier).state = index;
      },
      desktopHeaderTrailing: IconButton(
        tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
        icon: Icon(
          isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          color: isDark ? Colors.amber : AppColors.textSecondary,
          size: 20,
        ),
        onPressed: () {
          ref.read(themeModeProvider.notifier).toggleTheme();
        },
      ),
      body: IndexedStack(index: activeIndex, children: screens),
    );
  }
}
