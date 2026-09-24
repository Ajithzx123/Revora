import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme_provider.dart';

class ThemeToggleButton extends ConsumerWidget {
  final bool showLabel;
  final EdgeInsetsGeometry? padding;

  const ThemeToggleButton({
    super.key,
    this.showLabel = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    final tooltip = isDark ? 'Switch to light mode' : 'Switch to dark mode';

    if (!showLabel) {
      return Tooltip(
        message: tooltip,
        child: IconButton(
          padding: padding ?? const EdgeInsets.all(8),
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, anim) =>
                RotationTransition(turns: anim, child: child),
            child: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              key: ValueKey<bool>(isDark),
              size: 20,
              color: isDark ? const Color(0xFFFBBF24) : const Color(0xFF64748B),
            ),
          ),
          onPressed: () => ref.read(themeModeProvider.notifier).toggleTheme(),
        ),
      );
    }

    return InkWell(
      onTap: () => ref.read(themeModeProvider.notifier).toggleTheme(),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              size: 18,
              color: isDark ? const Color(0xFFFBBF24) : Colors.white70,
            ),
            const SizedBox(width: 8),
            Text(
              isDark ? 'Light Mode' : 'Dark Mode',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFFF1F5F9) : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SidebarThemeToggle extends ConsumerWidget {
  const SidebarThemeToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                size: 16,
                color: isDark ? const Color(0xFFFBBF24) : const Color(0xFF94A3B8),
              ),
              const SizedBox(width: 8),
              Text(
                isDark ? 'Dark Mode' : 'Light Mode',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Switch.adaptive(
            value: isDark,
            activeThumbColor: const Color(0xFFFF6B00),
            activeTrackColor: const Color(0xFF334155),
            inactiveThumbColor: const Color(0xFF94A3B8),
            inactiveTrackColor: const Color(0xFF1E293B),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onChanged: (_) =>
                ref.read(themeModeProvider.notifier).toggleTheme(),
          ),
        ],
      ),
    );
  }
}
