import 'package:flutter/material.dart';
import 'package:sum_warehouse/core/theme/app_colors.dart';

/// Карточка с быстрыми действиями
class QuickActionsCard extends StatelessWidget {
  const QuickActionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            offset: const Offset(0, 1),
            blurRadius: 3,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Быстрые действия',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 20),
          
          // Кнопки быстрых действий
          _QuickActionButton(
            icon: Icons.add_box_outlined,
            title: 'Добавить товар',
            subtitle: 'Создать новую позицию',
            color: const Color(0xFF3498DB),
            onTap: () {
              // TODO: Переход к добавлению товара
            },
          ),
          const SizedBox(height: 12),
          
          _QuickActionButton(
            icon: Icons.shopping_cart_outlined,
            title: 'Новая продажа',
            subtitle: 'Оформить продажу товара',
            color: const Color(0xFF2ECC71),
            onTap: () {
              // TODO: Переход к созданию продажи
            },
          ),
          const SizedBox(height: 12),
          
          _QuickActionButton(
            icon: Icons.assignment_outlined,
            title: 'Создать запрос',
            subtitle: 'Запрос на товар',
            color: const Color(0xFFF39C12),
            onTap: () {
              // TODO: Переход к созданию запроса
            },
          ),
          const SizedBox(height: 12),
          
          _QuickActionButton(
            icon: Icons.inventory_outlined,
            title: 'Остатки',
            subtitle: 'Проверить остатки',
            color: AppColors.primary,
            onTap: () {
              // TODO: Переход к остаткам
            },
          ),
          const SizedBox(height: 20),
          
          // Дополнительные ссылки
          const Divider(color: Color(0xFFE9ECEF)),
          const SizedBox(height: 16),
          
          _QuickLink(
            icon: Icons.file_download_outlined,
            title: 'Экспорт данных',
            onTap: () {
              // TODO: Экспорт
            },
          ),
          const SizedBox(height: 8),
          
          _QuickLink(
            icon: Icons.analytics_outlined,
            title: 'Отчеты',
            onTap: () {
              // TODO: Отчеты
            },
          ),
          const SizedBox(height: 8),
          
          _QuickLink(
            icon: Icons.settings_outlined,
            title: 'Настройки',
            onTap: () {
              // TODO: Настройки
            },
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color(0xFFE9ECEF),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6C757D),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF95A5A6),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickLink extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _QuickLink({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Icon(
              icon,
              color: const Color(0xFF6C757D),
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF495057),
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF95A5A6),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}


