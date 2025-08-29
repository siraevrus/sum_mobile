import 'package:flutter/material.dart';

/// Карточка с недавними активностями
class RecentActivitiesCard extends StatelessWidget {
  const RecentActivitiesCard({super.key});

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
          Row(
            children: [
              const Text(
                'Недавние активности',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  // TODO: Показать все активности
                },
                child: const Text(
                  'Показать все',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF3498DB),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Список активностей
          ...List.generate(5, (index) => _ActivityItem(
            icon: _getActivityIcon(index),
            iconColor: _getActivityColor(index),
            title: _getActivityTitle(index),
            subtitle: _getActivitySubtitle(index),
            time: _getActivityTime(index),
          )),
        ],
      ),
    );
  }

  IconData _getActivityIcon(int index) {
    switch (index % 4) {
      case 0:
        return Icons.add_shopping_cart_outlined;
      case 1:
        return Icons.inventory_2_outlined;
      case 2:
        return Icons.person_add_outlined;
      case 3:
        return Icons.assignment_turned_in_outlined;
      default:
        return Icons.info_outlined;
    }
  }

  Color _getActivityColor(int index) {
    switch (index % 4) {
      case 0:
        return const Color(0xFF2ECC71);
      case 1:
        return const Color(0xFF3498DB);
      case 2:
        return const Color(0xFFF39C12);
      case 3:
        return const Color(0xFFE74C3C);
      default:
        return const Color(0xFF95A5A6);
    }
  }

  String _getActivityTitle(int index) {
    switch (index % 4) {
      case 0:
        return 'Новая продажа';
      case 1:
        return 'Добавлен товар';
      case 2:
        return 'Новый пользователь';
      case 3:
        return 'Запрос обработан';
      default:
        return 'Активность';
    }
  }

  String _getActivitySubtitle(int index) {
    switch (index % 4) {
      case 0:
        return 'Продажа на сумму ₽12,500';
      case 1:
        return 'Кирпич керамический (500 шт.)';
      case 2:
        return 'Иван Петров (Оператор)';
      case 3:
        return 'Запрос #${1234 + index} завершен';
      default:
        return 'Описание активности';
    }
  }

  String _getActivityTime(int index) {
    switch (index) {
      case 0:
        return '2 мин назад';
      case 1:
        return '15 мин назад';
      case 2:
        return '1 час назад';
      case 3:
        return '2 часа назад';
      case 4:
        return 'Вчера';
      default:
        return 'Недавно';
    }
  }
}

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String time;

  const _ActivityItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor,
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
          Text(
            time,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF95A5A6),
            ),
          ),
        ],
      ),
    );
  }
}


