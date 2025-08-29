import 'package:flutter/material.dart';
import 'package:sum_warehouse/core/theme/app_colors.dart';

/// Карточка быстрого действия
class QuickActionCard extends StatelessWidget {
  final String title;
  final String? description;
  final IconData icon;
  final Color? iconColor;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final String? badge;
  final Color? badgeColor;
  final bool isEnabled;

  const QuickActionCard({
    super.key,
    required this.title,
    this.description,
    required this.icon,
    this.iconColor,
    this.backgroundColor,
    this.onTap,
    this.badge,
    this.badgeColor,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = backgroundColor ?? theme.cardColor;
    final primaryIconColor = iconColor ?? AppColors.primary;

    return Card(
      elevation: isEnabled ? 2 : 1,
      color: cardColor,
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Иконка с бейджем
              Stack(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: primaryIconColor.withOpacity(isEnabled ? 0.1 : 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: primaryIconColor.withOpacity(isEnabled ? 1.0 : 0.5),
                      size: 24,
                    ),
                  ),
                  
                  // Бейдж
                  if (badge != null)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: badgeColor ?? AppColors.error,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Text(
                          badge!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Заголовок
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isEnabled 
                    ? theme.colorScheme.onSurface 
                    : theme.colorScheme.onSurface.withOpacity(0.5),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              // Описание
              if (description != null) ...[
                const SizedBox(height: 4),
                Text(
                  description!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isEnabled 
                      ? Colors.grey[600] 
                      : Colors.grey[400],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Горизонтальная карточка быстрого действия
class HorizontalQuickActionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color? iconColor;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool isEnabled;

  const HorizontalQuickActionCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    this.iconColor,
    this.onTap,
    this.trailing,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryIconColor = iconColor ?? AppColors.primary;

    return Card(
      elevation: isEnabled ? 2 : 1,
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Иконка
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: primaryIconColor.withOpacity(isEnabled ? 0.1 : 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: primaryIconColor.withOpacity(isEnabled ? 1.0 : 0.5),
                  size: 20,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Заголовок и подзаголовок
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isEnabled 
                          ? theme.colorScheme.onSurface 
                          : theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isEnabled 
                            ? Colors.grey[600] 
                            : Colors.grey[400],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Trailing элемент
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ] else if (isEnabled) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Сетка быстрых действий
class QuickActionsGrid extends StatelessWidget {
  final List<QuickActionData> actions;
  final int crossAxisCount;
  final double childAspectRatio;
  final double crossAxisSpacing;
  final double mainAxisSpacing;

  const QuickActionsGrid({
    super.key,
    required this.actions,
    this.crossAxisCount = 2,
    this.childAspectRatio = 1.0,
    this.crossAxisSpacing = 16,
    this.mainAxisSpacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return QuickActionCard(
          title: action.title,
          description: action.description,
          icon: action.icon,
          iconColor: action.iconColor,
          backgroundColor: action.backgroundColor,
          onTap: action.onTap,
          badge: action.badge,
          badgeColor: action.badgeColor,
          isEnabled: action.isEnabled,
        );
      },
    );
  }
}

/// Данные для быстрого действия
class QuickActionData {
  final String title;
  final String? description;
  final IconData icon;
  final Color? iconColor;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final String? badge;
  final Color? badgeColor;
  final bool isEnabled;

  const QuickActionData({
    required this.title,
    this.description,
    required this.icon,
    this.iconColor,
    this.backgroundColor,
    this.onTap,
    this.badge,
    this.badgeColor,
    this.isEnabled = true,
  });
}
