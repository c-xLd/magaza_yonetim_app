import 'package:flutter/material.dart';

/// Modern ve tekrar kullanılabilir kart widget'ı
class CustomListCard extends StatelessWidget {
  final IconData? icon;
  final Color? iconBgColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? cardColor;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;

  const CustomListCard({
    super.key,
    this.icon,
    this.iconBgColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.cardColor,
    this.padding,
    this.borderRadius = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      color: cardColor ?? colorScheme.surfaceContainerHigh,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: onTap,
        child: Padding(
          padding: padding ?? const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (icon != null)
                Container(
                  decoration: BoxDecoration(
                    color: iconBgColor ?? colorScheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Icon(icon, color: colorScheme.primary, size: 28),
                ),
              if (icon != null) const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ]
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 10),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
