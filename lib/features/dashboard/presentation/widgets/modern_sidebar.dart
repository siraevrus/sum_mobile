import 'package:flutter/material.dart';
import 'package:sum_warehouse/features/auth/domain/entities/user_entity.dart';

/// Современное боковое меню в стиле веб-интерфейса
class ModernSidebar extends StatelessWidget {
  final UserEntity currentUser;
  final String selectedSection;
  final Function(String) onSectionSelected;
  final VoidCallback onLogout;

  const ModernSidebar({
    super.key,
    required this.currentUser,
    required this.selectedSection,
    required this.onSectionSelected,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: const BoxDecoration(
        color: Color(0xFF2C3E50),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Заголовок приложения
          Container(
            padding: const EdgeInsets.all(24),
            child: const Row(
              children: [
                Icon(
                  Icons.warehouse,
                  color: Colors.white,
                  size: 32,
                ),
                SizedBox(width: 12),
                Text(
                  'Складской учет',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(
            color: Color(0xFF34495E),
            thickness: 1,
            height: 1,
          ),
          
          // Информация о пользователе
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF3498DB),
                  child: Text(
                    currentUser.name.isNotEmpty
                        ? currentUser.name[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentUser.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _getRoleDisplayName(currentUser.role),
                        style: const TextStyle(
                          color: Color(0xFFBDC3C7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(
            color: Color(0xFF34495E),
            thickness: 1,
            height: 1,
          ),
          
          // Навигационное меню
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // Инфопанель: показываем только админу
                if (_hasAccess(['admin']))
                  _buildMenuItem(
                    icon: Icons.dashboard,
                    title: 'Инфопанель',
                    section: 'dashboard',
                    isSelected: selectedSection == 'dashboard',
                  ),
                // Компании - только админ
                if (_hasAccess(['admin']))
                  _buildMenuItem(
                    icon: Icons.business,
                    title: 'Компании',
                    section: 'companies',
                    isSelected: selectedSection == 'companies',
                  ),
                // Склады - только админ
                if (_hasAccess(['admin']))
                  _buildMenuItem(
                    icon: Icons.warehouse,
                    title: 'Склады',
                    section: 'warehouses',
                    isSelected: selectedSection == 'warehouses',
                  ),
                // Сотрудники - только админ
                if (_hasAccess(['admin']))
                  _buildMenuItem(
                    icon: Icons.people,
                    title: 'Сотрудники',
                    section: 'employees',
                    isSelected: selectedSection == 'employees',
                  ),
                // Товары - админ и оператор (скрываем для роли sales)
                if (_hasAccess(['admin', 'operator']))
                  _buildMenuItem(
                    icon: Icons.inventory,
                    title: 'Товары',
                    section: 'products',
                    isSelected: selectedSection == 'products',
                  ),
                // Товары в пути - админ, оператор, работник склада, менеджер по продажам
                if (_hasAccess(['admin', 'operator', 'warehouse_worker', 'sales_manager']))
                  _buildMenuItem(
                    icon: Icons.local_shipping,
                    title: 'Товары В Пути',
                    section: 'goods_in_transit',
                    isSelected: selectedSection == 'goods_in_transit',
                  ),
                // Запросы - админ, работник склада, менеджер по продажам (БЕЗ оператора)
                if (_hasAccess(['admin', 'warehouse_worker', 'sales_manager']))
                  _buildMenuItem(
                    icon: Icons.assignment,
                    title: 'Запросы',
                    section: 'requests',
                    isSelected: selectedSection == 'requests',
                  ),
                // Остатки - админ, оператор, работник склада, менеджер по продажам
                if (_hasAccess(['admin', 'operator', 'warehouse_worker', 'sales_manager']))
                  _buildMenuItem(
                    icon: Icons.storage,
                    title: 'Остатки',
                    section: 'inventory',
                    isSelected: selectedSection == 'inventory',
                  ),
                // Реализация - админ, работник склада
                if (_hasAccess(['admin', 'warehouse_worker']))
                  _buildMenuItem(
                    icon: Icons.point_of_sale,
                    title: 'Реализация',
                    section: 'sales',
                    isSelected: selectedSection == 'sales',
                  ),
                // Приемка - админ, работник склада
                if (_hasAccess(['admin', 'warehouse_worker']))
                  _buildMenuItem(
                    icon: Icons.inbox,
                    title: 'Приемка',
                    section: 'reception',
                    isSelected: selectedSection == 'reception',
                  ),
              ],
            ),
          ),
          
          // Кнопка выхода
          Container(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onLogout,
                icon: const Icon(
                  Icons.logout,
                  size: 18,
                  color: Color(0xFFE74C3C),
                ),
                label: const Text(
                  'Выйти',
                  style: TextStyle(
                    color: Color(0xFFE74C3C),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                    color: Color(0xFFE74C3C),
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String section,
    required bool isSelected,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? Colors.white : const Color(0xFFBDC3C7),
          size: 20,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFFBDC3C7),
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        selected: isSelected,
        selectedTileColor: const Color(0xFF34495E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        onTap: () => onSectionSelected(section),
      ),
    );
  }

  bool _hasAccess(List<String> allowedRoles) {
    final userRole = _getRoleCode(currentUser.role);
    return allowedRoles.contains(userRole);
  }

  String _getRoleCode(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'admin';
      case UserRole.operator:
        return 'operator';
      case UserRole.warehouseWorker:
        return 'warehouse_worker';
      case UserRole.manager:
        return 'manager';
      case UserRole.salesManager:
        return 'sales_manager';
    }
  }

  String _getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Администратор';
      case UserRole.operator:
        return 'Оператор';
      case UserRole.warehouseWorker:
        return 'Работник склада';
      case UserRole.manager:
        return 'Менеджер';
      case UserRole.salesManager:
        return 'Менеджер по продажам';
    }
  }
}
