import 'package:flutter/material.dart';
import '../../core/theme/revora_theme_colors.dart';

enum ButtonVariant { primary, secondary, outline, text }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final bool isLoading;
  final double? width;
  final double height;
  final Widget? icon;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = ButtonVariant.primary,
    this.isLoading = false,
    this.width,
    this.height = 48,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final revoraColors = context.revoraColors;

    Color getBackgroundColor() {
      if (onPressed == null) return revoraColors.disabledBg;
      switch (variant) {
        case ButtonVariant.primary:
          return cs.primary;
        case ButtonVariant.secondary:
          return cs.secondary;
        case ButtonVariant.outline:
        case ButtonVariant.text:
          return Colors.transparent;
      }
    }

    Color getTextColor() {
      if (onPressed == null) return revoraColors.disabledFg;
      switch (variant) {
        case ButtonVariant.primary:
          return cs.onPrimary;
        case ButtonVariant.secondary:
          return cs.onSecondary;
        case ButtonVariant.outline:
          return cs.onSurface;
        case ButtonVariant.text:
          return cs.primary;
      }
    }

    Border? getBorder() {
      if (variant == ButtonVariant.outline) {
        final color = onPressed == null
            ? revoraColors.disabledBg
            : cs.outline;
        return Border.all(color: color, width: 1.5);
      }
      return null;
    }

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: Material(
        color: getBackgroundColor(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: (isLoading || onPressed == null) ? null : onPressed,
          child: Container(
            decoration: BoxDecoration(
              border: getBorder(),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        variant == ButtonVariant.outline || variant == ButtonVariant.text
                            ? cs.primary
                            : cs.onPrimary,
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        icon!,
                        const SizedBox(width: 8),
                      ],
                      Text(
                        text,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: getTextColor(),
                          fontWeight: FontWeight.bold,
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
