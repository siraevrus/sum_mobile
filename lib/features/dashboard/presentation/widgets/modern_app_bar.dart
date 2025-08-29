import 'package:flutter/material.dart';
import 'package:sum_warehouse/features/auth/domain/entities/user_entity.dart';

/// Современная верхняя панель в стиле веб-интерфейса
class ModernAppBar extends StatelessWidget {
  final UserEntity currentUser;
  final String title;

  const ModernAppBar({
    super.key,
    required this.currentUser,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          // Заголовок страницы
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C3E50),
            ),
          ),
          
          const Spacer(),
          
          // Поиск (пока заглушка)
          Container(
            width: 300,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFE9ECEF),
                width: 1,
              ),
            ),
            child: const TextField(
              decoration: InputDecoration(
                hintText: 'Поиск...',
                hintStyle: TextStyle(
                  color: Color(0xFF6C757D),
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Color(0xFF6C757D),
                  size: 20,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 24),
          
          // Уведомления
          IconButton(
            onPressed: () {
              // TODO: Показать уведомления
            },
            icon: const Icon(
              Icons.notifications_outlined,
              color: Color(0xFF6C757D),
            ),
            tooltip: 'Уведомления',
          ),
          
          const SizedBox(width: 16),
          
          // Профиль пользователя
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF3498DB),
                child: Text(
                  currentUser.name.isNotEmpty
                      ? currentUser.name[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                child: Row(
                  children: [
                    Text(
                      currentUser.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF495057),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      size: 16,
                      color: Color(0xFF6C757D),
                    ),
                  ],
                ),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 16,
                          color: Color(0xFF495057),
                        ),
                        SizedBox(width: 8),
                        Text('Профиль'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'settings',
                    child: Row(
                      children: [
                        Icon(
                          Icons.settings_outlined,
                          size: 16,
                          color: Color(0xFF495057),
                        ),
                        SizedBox(width: 8),
                        Text('Настройки'),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  switch (value) {
                    case 'profile':
                      // TODO: Открыть профиль
                      break;
                    case 'settings':
                      // TODO: Открыть настройки
                      break;
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
