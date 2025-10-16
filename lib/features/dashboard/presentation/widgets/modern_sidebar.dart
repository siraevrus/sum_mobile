import 'package:flutter/material.dart';
import 'package:sum_warehouse/features/auth/domain/entities/user_entity.dart';

/// Современное боковое меню в стиле веб-интерфейса
class ModernSidebar extends StatefulWidget {
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
  State<ModernSidebar> createState() => _ModernSidebarState();
}

class _ModernSidebarState extends State<ModernSidebar> {
  bool _infoExpanded = false;

  @override
  void initState() {
    super.initState();
    // Если текущий раздел - один из подразделов Инфо, раскрываем меню
    _infoExpanded = ['companies', 'warehouses', 'employees'].contains(widget.selectedSection);
  }

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
          // Информация о роли пользователя
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF3498DB),
                  child: Text(
                    widget.currentUser.name.isNotEmpty
                        ? widget.currentUser.name[0].toUpperCase()
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
                        widget.currentUser.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _getRoleDisplayName(widget.currentUser.role),
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
                    isSelected: widget.selectedSection == 'dashboard',
                  ),
                
                // Производители - только админ
                if (_hasAccess(['admin']))
                  _buildMenuItem(
                    icon: Icons.factory,
                    title: 'Производители',
                    section: 'producers',
                    isSelected: widget.selectedSection == 'producers',
                  ),
                // Поступление товаров - админ и оператор
                if (_hasAccess(['admin', 'operator']))
                  _buildMenuItem(
                    icon: Icons.input,
                    title: 'Поступление товаров',
                    section: 'products-inflow',
                    isSelected: widget.selectedSection == 'products-inflow',
                  ),
                // Товары в пути - админ и оператор
                if (_hasAccess(['admin', 'operator']))
                  _buildMenuItem(
                    icon: Icons.local_shipping,
                    title: 'Товары в пути',
                    section: 'products-in-transit',
                    isSelected: widget.selectedSection == 'products-in-transit',
                  ),
                // Приемка - только админ
                if (_hasAccess(['admin']))
                  _buildMenuItem(
                    icon: Icons.inventory_2,
                    title: 'Приемка',
                    section: 'acceptance',
                    isSelected: widget.selectedSection == 'acceptance',
                  ),
                // Запросы - админ, работник склада, менеджер по продажам (БЕЗ оператора)
                if (_hasAccess(['admin', 'warehouse_worker', 'sales_manager']))
                  _buildMenuItem(
                    icon: Icons.assignment,
                    title: 'Запросы',
                    section: 'requests',
                    isSelected: widget.selectedSection == 'requests',
                  ),
                // Остатки на складе - админ, оператор, работник склада, менеджер по продажам
                if (_hasAccess(['admin', 'operator', 'warehouse_worker', 'sales_manager']))
                  _buildMenuItem(
                    icon: Icons.storage,
                    title: 'Остатки на складе',
                    section: 'inventory',
                    isSelected: widget.selectedSection == 'inventory',
                  ),

                // Реализация - админ, работник склада
                if (_hasAccess(['admin', 'warehouse_worker']))
                  _buildMenuItem(
                    icon: Icons.point_of_sale,
                    title: 'Реализация',
                    section: 'sales',
                    isSelected: widget.selectedSection == 'sales',
                  ),
                
                // Раздел "Инфо" с подменю в конце списка - только админ
                if (_hasAccess(['admin']))
                  _buildExpandableMenuItem(
                    icon: Icons.info_outline,
                    title: 'Инфо',
                    isExpanded: _infoExpanded,
                    onTap: () {
                      setState(() {
                        _infoExpanded = !_infoExpanded;
                      });
                    },
                    children: [
                      _buildSubMenuItem(
                        icon: Icons.business,
                        title: 'Компании',
                        section: 'companies',
                        isSelected: widget.selectedSection == 'companies',
                      ),
                      _buildSubMenuItem(
                        icon: Icons.warehouse,
                        title: 'Склад',
                        section: 'warehouses',
                        isSelected: widget.selectedSection == 'warehouses',
                      ),
                      _buildSubMenuItem(
                        icon: Icons.people,
                        title: 'Сотрудники',
                        section: 'employees',
                        isSelected: widget.selectedSection == 'employees',
                      ),
                    ],
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
                onPressed: widget.onLogout,
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
        onTap: () => widget.onSectionSelected(section),
      ),
    );
  }

  Widget _buildExpandableMenuItem({
    required IconData icon,
    required String title,
    required bool isExpanded,
    required VoidCallback onTap,
    required List<Widget> children,
  }) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: isExpanded ? const Color(0xFF23384D) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListTile(
            leading: Icon(
              icon,
              color: const Color(0xFFBDC3C7),
              size: 20,
            ),
            title: Text(
              title,
              style: const TextStyle(
                color: Color(0xFFBDC3C7),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
            trailing: AnimatedRotation(
              turns: isExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 300),
              child: const Icon(
                Icons.expand_more,
                color: Color(0xFFBDC3C7),
                size: 20,
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            onTap: onTap,
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: isExpanded
              ? Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF23384D),
                  ),
                  child: Column(children: children),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildSubMenuItem({
    required IconData icon,
    required String title,
    required String section,
    required bool isSelected,
  }) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 8, top: 2, bottom: 2),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? Colors.white : const Color(0xFFBDC3C7),
          size: 18,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFFBDC3C7),
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        selected: isSelected,
        selectedTileColor: const Color(0xFF34495E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        onTap: () => widget.onSectionSelected(section),
      ),
    );
  }

  bool _hasAccess(List<String> allowedRoles) {
    final userRole = _getRoleCode(widget.currentUser.role);
    final hasAccess = allowedRoles.contains(userRole);
    return hasAccess;
  }

  String _getRoleCode(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'admin';
      case UserRole.operator:
        return 'operator';
      case UserRole.warehouseWorker:
        return 'warehouse_worker';
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
      case UserRole.salesManager:
        return 'Менеджер по продажам';
    }
  }
}
