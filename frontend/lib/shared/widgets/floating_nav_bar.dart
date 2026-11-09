import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import 'app_sidebar.dart';

/// Phone navigation: a floating ink pill. The selected destination expands to
/// show its label on an orange chip, the others stay as quiet icons, so the bar
/// stays readable with 4-5 destinations without cramming text under every icon.
class FloatingNavBar extends StatelessWidget {
  final List<AppSidebarItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const FloatingNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Container(
          height: 68,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(26),
            // Layered shadow: tight contact + soft ambient.
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.18),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.16),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  flex: i == selectedIndex ? 3 : 2,
                  child: _NavItem(
                    item: items[i],
                    selected: i == selectedIndex,
                    onTap: () {
                      if (i != selectedIndex) HapticFeedback.selectionClick();
                      onSelected(i);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final AppSidebarItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final count = item.badgeCount ?? 0;
    final icon = Icon(
      selected ? (item.selectedIcon ?? item.icon) : item.icon,
      size: 22,
      color: selected
          ? AppColors.onAccent
          : Colors.white.withValues(alpha: 0.72),
    );

    return Semantics(
      button: true,
      selected: selected,
      label: count > 0 ? '${item.label}, $count new' : item.label,
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: selected ? AppColors.accent : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (count > 0 && !selected)
                  Badge(
                    label: Text('$count'),
                    backgroundColor: AppColors.accent,
                    textColor: AppColors.onAccent,
                    child: icon,
                  )
                else
                  icon,
                if (selected) ...[
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.onAccent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
