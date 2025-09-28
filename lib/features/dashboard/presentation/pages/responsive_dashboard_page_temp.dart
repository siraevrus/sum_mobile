import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sum_warehouse/features/auth/presentation/providers/auth_provider.dart';
import 'package:sum_warehouse/features/dashboard/presentation/widgets/modern_app_bar.dart';
import 'package:sum_warehouse/features/dashboard/presentation/widgets/modern_sidebar.dart';
import 'package:sum_warehouse/features/dashboard/presentation/widgets/responsive_dashboard_content.dart';
import 'package:sum_warehouse/features/products/presentation/pages/products_list_page.dart';
import 'package:sum_warehouse/features/sales/presentation/pages/sales_list_page.dart';
import 'package:sum_warehouse/features/requests/presentation/pages/requests_list_page.dart';
import 'package:sum_warehouse/features/warehouses/presentation/pages/warehouses_list_page.dart';
import 'package:sum_warehouse/features/users/presentation/pages/employees_list_page.dart';
import 'package:sum_warehouse/features/inventory/presentation/pages/stocks_list_page.dart';
import 'package:sum_warehouse/features/auth/domain/entities/user_entity.dart';
import 'package:sum_warehouse/features/companies/presentation/pages/companies_list_page.dart';
import 'package:sum_warehouse/features/products_in_transit/presentation/pages/products_in_transit_list_page.dart';
import 'package:sum_warehouse/features/producers/presentation/pages/producers_list_page.dart';

/// Адаптивный дашборд для мобильных и десктопных устройств
class ResponsiveDashboardPage extends ConsumerWidget {
  final String? selectedSection;
  
  const ResponsiveDashboardPage({
    super.key,
    this.selectedSection,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    
    return authState.when(
      initial: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      authenticated: (user, token) => _buildDashboard(context, user),
      unauthenticated: () => const Scaffold(
        body: Center(child: Text('Не авторизован')),
      ),
      error: (message) => Scaffold(
        body: Center(child: Text('Ошибка: $message')),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, UserEntity user) {
    final currentSection = selectedSection ?? 'dashboard';
    
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 1200) {
            return _buildDesktopLayout(context, user, currentSection);
          } else {
            return _buildMobileLayout(context, user, currentSection);
          }
        },
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, UserEntity user, String section) {
    return Row(
      children: [
        // Боковое меню
        Container(
          width: 280,
          decoration: const BoxDecoration(
            color: Color(0xFF2C3E50),
            border: Border(right: BorderSide(color: Color(0xFFE9ECEF))),
          ),
          child: Column(
            children: [
              // Заголовок
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFF34495E))),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3498DB),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.warehouse,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'SUM Warehouse',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Меню
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      children: [
                        // Дашборд - доступен всем
                        _buildDrawerMenuItem(
                          context,
                          icon: Icons.dashboard,
                          title: 'Инфопанель',
                          section: 'dashboard',
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Управление - только админ
                        if (_hasAccess(user, ['admin'])) ...[
                          _buildSectionHeader('Управление'),
                          _buildDrawerMenuItem(
                            context,
                            icon: Icons.business,
                            title: 'Компании',
                            section: 'companies',
                          ),
                          _buildDrawerMenuItem(
                            context,
                            icon: Icons.people,
                            title: 'Сотрудники',
                            section: 'employees',
                          ),
                          _buildDrawerMenuItem(
                            context,
                            icon: Icons.warehouse,
                            title: 'Склады',
                            section: 'warehouses',
                          ),
                          _buildDrawerMenuItem(
                            context,
                            icon: Icons.business_center,
                            title: 'Производители',
                            section: 'producers',
                          ),
                          const SizedBox(height: 16),
                        ],
                        
                        // Операции
                        _buildSectionHeader('Операции'),
                        
                        // Остатки - админ, оператор, работник склада, менеджер по продажам
                        if (_hasAccess(user, ['admin', 'operator', 'warehouse_worker', 'sales_manager']))
                          _buildDrawerMenuItem(
                            context,
                            icon: Icons.storage,
                            title: 'Остатки на складе',
                            section: 'inventory',
                          ),
                        // Поступление товаров - админ и оператор (скрываем для роли sales)
                        if (_hasAccess(user, ['admin', 'operator']))
                          _buildDrawerMenuItem(
                            context,
                            icon: Icons.inventory,
                            title: 'Поступление товаров',
                            section: 'products',
                          ),
                        // Товары в пути - админ, оператор, работник склада, менеджер по продажам
                        if (_hasAccess(user, ['admin', 'operator', 'warehouse_worker', 'sales_manager']))
                          _buildDrawerMenuItem(
                            context,
                            icon: Icons.local_shipping,
                            title: 'Товары В Пути',
                            section: 'products-in-transit',
                          ),
                        // Запросы - админ, работник склада, менеджер по продажам (БЕЗ оператора)
                        if (_hasAccess(user, ['admin', 'warehouse_worker', 'sales_manager']))
                          _buildDrawerMenuItem(
                            context,
                            icon: Icons.assignment,
                            title: 'Запросы',
                            section: 'requests',
                          ),
                        // Реализация - админ, работник склада
                        if (_hasAccess(user, ['admin', 'warehouse_worker']))
                          _buildDrawerMenuItem(
                            context,
                            icon: Icons.point_of_sale,
                            title: 'Реализация',
                            section: 'sales',
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Профиль пользователя
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFF34495E))),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFF3498DB),
                      child: Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            _getRoleDisplayName(user.role),
                            style: const TextStyle(
                              color: Color(0xFFBDC3C7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton(
                      icon: const Icon(Icons.more_vert, color: Color(0xFFBDC3C7)),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'logout',
                          child: Row(
                            children: [
                              Icon(Icons.logout, size: 20),
                              SizedBox(width: 8),
                              Text('Выйти'),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'logout') {
                          ref.read(authProvider.notifier).logout();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Основной контент
        Expanded(
          child: Column(
            children: [
              // Верхняя панель
              Container(
                height: 80,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Color(0xFFE9ECEF))),
                ),
                child: Row(
                  children: [
                    Text(
                      _getSectionTitle(section),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const Spacer(),
                    // Дополнительные элементы управления могут быть здесь
                  ],
                ),
              ),
              
              // Контент страницы
              Expanded(
                child: _buildPageContent(context, section),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context, UserEntity user, String section) {
    return Scaffold(
      appBar: ModernAppBar(
        title: _getSectionTitle(section),
        user: user,
      ),
      drawer: ModernSidebar(
        user: user,
        selectedSection: section,
      ),
      body: _buildPageContent(context, section),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF7F8C8D),
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildDrawerMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String section,
  }) {
    final isSelected = (selectedSection ?? 'dashboard') == section;
    
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
        onTap: () {
          Navigator.of(context).pop(); // Закрываем drawer
          context.go('/$section');
        },
      ),
    );
  }

  String _getSectionTitle(String section) {
    switch (section) {
      case 'dashboard':
        return 'Инфопанель';
      case 'products':
        return 'Поступление товаров';
      case 'warehouses':
        return 'Склад';
      case 'sales':
        return 'Реализация';
      case 'requests':
        return 'Запросы';
      case 'employees':
        return 'Сотрудники';
      case 'producers':
        return 'Производители';
      case 'companies':
        return 'Компании';
      case 'inventory':
        return 'Остатки на складе';
      case 'products-in-transit':
        return 'Товары в пути';
      default:
        return 'Инфопанель';
    }
  }

  Widget _buildPageContent(BuildContext context, String section) {
    switch (section) {
      case 'dashboard':
        return ResponsiveDashboardContent(
          onShowAllProductsPressed: () => context.go('/products'),
        );
      case 'products':
        return const ProductsListPage();
      case 'warehouses':
        return const WarehousesListPage();
      case 'sales':
        return const SalesListPage();
      case 'requests':
        return const RequestsListPage();
      case 'employees':
        return const EmployeesListPage();
      case 'producers':
        return const ProducersListPage();
      case 'companies':
        return const CompaniesListPage();
      case 'inventory':
        return const StocksListPage();
      case 'products-in-transit':
        return const ProductsInTransitListPage();
      default:
        return ResponsiveDashboardContent(
          onShowAllProductsPressed: () => context.go('/products'),
        );
    }
  }

  bool _hasAccess(UserEntity user, List<String> allowedRoles) {
    final userRole = _getRoleCode(user.role);
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

  String _defaultSectionForRole(UserEntity user) {
    switch (user.role) {
      case UserRole.admin:
        return 'dashboard';
      case UserRole.salesManager:
        return 'inventory';
      case UserRole.operator:
        return 'inventory';
      case UserRole.warehouseWorker:
        return 'inventory';
      case UserRole.manager:
        return 'inventory';
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
