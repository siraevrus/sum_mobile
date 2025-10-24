import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sum_warehouse/features/auth/presentation/providers/auth_provider.dart';
import 'package:sum_warehouse/features/dashboard/presentation/widgets/modern_app_bar.dart';
import 'package:sum_warehouse/features/dashboard/presentation/widgets/modern_sidebar.dart';
import 'package:sum_warehouse/features/dashboard/presentation/widgets/responsive_dashboard_content.dart';
import 'package:sum_warehouse/features/sales/presentation/pages/sales_list_page.dart';
import 'package:sum_warehouse/features/requests/presentation/pages/requests_list_page.dart';
import 'package:sum_warehouse/features/warehouses/presentation/pages/warehouses_list_page.dart';
import 'package:sum_warehouse/features/users/presentation/pages/employees_list_page.dart';
import 'package:sum_warehouse/features/inventory/presentation/pages/inventory_tabs_page.dart';
import 'package:sum_warehouse/features/auth/domain/entities/user_entity.dart';
import 'package:sum_warehouse/features/companies/presentation/pages/companies_list_page.dart';
import 'package:sum_warehouse/features/producers/presentation/pages/producers_list_page.dart';
import 'package:sum_warehouse/features/products_inflow/presentation/pages/products_inflow_list_page.dart';
import 'package:sum_warehouse/features/products_in_transit/presentation/pages/products_in_transit_list_page.dart';
import 'package:sum_warehouse/features/acceptance/presentation/pages/acceptance_list_page.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      unauthenticated: () {
        // Если пользователь не авторизован, перенаправляем на логин
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.go('/login');
        });
        return const SizedBox.shrink();
      },
      authenticated: (user, _) => _buildResponsiveDashboard(context, user, ref),
      error: (error) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Ошибка: $error',
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(authProvider.notifier).checkAuthStatus();
                },
                child: const Text('Попробовать снова'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Создает адаптивный дашборд в зависимости от размера экрана
  Widget _buildResponsiveDashboard(BuildContext context, UserEntity user, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1024;
        
        if (isDesktop) {
          // Большие экраны - используем текущий дизайн с боковым меню
          return _buildDesktopLayout(context, user, ref);
        } else {
          // Мобильные и планшеты - используем Drawer
          return _buildMobileLayout(context, user, ref);
        }
      },
    );
  }

  /// Десктопная версия с постоянным боковым меню
  Widget _buildDesktopLayout(BuildContext context, UserEntity user, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Row(
          children: [
            // Боковое меню
            ModernSidebar(
              currentUser: user,
              selectedSection: selectedSection ?? _defaultSectionForRole(user),
              onSectionSelected: (section) {
                context.go('/$section');
              },
              onLogout: () {
                ref.read(authProvider.notifier).logout();
              },
            ),
            
            // Основной контент
            Expanded(
              child: Column(
                children: [
                  // Верхняя панель без меню кнопки
                  MobileAppBar(
                    currentUser: user,
                    title: _getSectionTitle(selectedSection ?? 'dashboard'),
                    showMenuButton: false,
                  ),
                  
                  // Контент страницы
                  Expanded(
                    child: _buildPageContent(context, selectedSection ?? 'dashboard'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Мобильная версия с выдвижным меню
  Widget _buildMobileLayout(BuildContext context, UserEntity user, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: SafeArea(
          child: MobileAppBar(
            currentUser: user,
            title: _getSectionTitle(selectedSection ?? 'dashboard'),
            showMenuButton: true,
          ),
        ),
      ),
      drawer: _buildMobileDrawer(user, context, ref),
      body: SafeArea(
        child: _buildPageContent(context, selectedSection ?? 'dashboard'),
      ),
    );
  }

  /// Выдвижное меню для мобильных устройств
  Widget _buildMobileDrawer(UserEntity user, BuildContext context, WidgetRef ref) {
    return _MobileDrawerMenu(
      user: user,
      selectedSection: selectedSection ?? 'dashboard',
      onLogout: () {
        Navigator.of(context).pop(); // Закрываем drawer
        ref.read(authProvider.notifier).logout();
      },
    );
  }
}

/// Stateful виджет для мобильного меню с поддержкой expandable разделов
class _MobileDrawerMenu extends StatefulWidget {
  final UserEntity user;
  final String selectedSection;
  final VoidCallback onLogout;

  const _MobileDrawerMenu({
    required this.user,
    required this.selectedSection,
    required this.onLogout,
  });

  @override
  State<_MobileDrawerMenu> createState() => _MobileDrawerMenuState();
}

class _MobileDrawerMenuState extends State<_MobileDrawerMenu> {
  bool _infoExpanded = false;

  @override
  void initState() {
    super.initState();
    // Если текущий раздел - один из подразделов Инфо, раскрываем меню
    _infoExpanded = ['companies', 'warehouses', 'employees'].contains(widget.selectedSection);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF256437),
      child: SafeArea(
        child: Column(
          children: [
            // Заголовок приложения
            Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  SvgPicture.asset(
                    'assets/logos/logo-expertwood.svg',
                    width: 32,
                    height: 32,
                    colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Wood Warehouse',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const Divider(
              color: Color(0xFF2D7A45),
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
                      widget.user.name.isNotEmpty
                          ? widget.user.name[0].toUpperCase()
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
                          widget.user.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const Divider(
              color: Color(0xFF2D7A45),
              thickness: 1,
              height: 1,
            ),
            
            // Навигационное меню
            Expanded(
              child: Column(
                children: [
                  // Основное меню
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: [
                        // Инфопанель: показываем только админу
                        if (_hasAccess(widget.user, ['admin']))
                          _buildDrawerMenuItem(
                            context,
                            icon: Icons.dashboard,
                            title: 'Инфопанель',
                            section: 'dashboard',
                          ),
                        
                        // Остатки - админ, оператор, работник склада, менеджер по продажам
                        if (_hasAccess(widget.user, ['admin', 'operator', 'warehouse_worker', 'sales_manager']))
                          _buildDrawerMenuItem(
                            context,
                            icon: Icons.storage,
                            title: 'Остатки на складе',
                            section: 'inventory',
                          ),
                        // Поступление товаров - админ и оператор
                        if (_hasAccess(widget.user, ['admin', 'operator']))
                          _buildDrawerMenuItem(
                            context,
                            icon: Icons.input,
                            title: 'Поступление товаров',
                            section: 'products-inflow',
                          ),
                        // Товары в пути - админ, оператор, работник склада, менеджер по продажам
                        if (_hasAccess(widget.user, ['admin', 'operator', 'warehouse_worker', 'sales_manager']))
                          _buildDrawerMenuItem(
                            context,
                            icon: Icons.local_shipping,
                            title: 'Товары в пути',
                            section: 'products-in-transit',
                          ),
                        // Приемка - только админ
                        if (_hasAccess(widget.user, ['admin']))
                          _buildDrawerMenuItem(
                            context,
                            icon: Icons.inventory_2,
                            title: 'Приемка',
                            section: 'acceptance',
                          ),
                        // Запросы - админ, работник склада, менеджер по продажам (БЕЗ оператора)
                        if (_hasAccess(widget.user, ['admin', 'warehouse_worker', 'sales_manager']))
                          _buildDrawerMenuItem(
                            context,
                            icon: Icons.assignment,
                            title: 'Запросы',
                            section: 'requests',
                          ),
                        // Реализация - админ, работник склада
                        if (_hasAccess(widget.user, ['admin', 'warehouse_worker']))
                          _buildDrawerMenuItem(
                            context,
                            icon: Icons.point_of_sale,
                            title: 'Реализация',
                            section: 'sales',
                          ),
                      ],
                    ),
                  ),
                  
                  // Раздел "Инфо" в нижней части - только админ
                  if (_hasAccess(widget.user, ['admin']))
                    Column(
                      children: [
                        const Divider(
                          color: Color(0xFF2D7A45),
                          thickness: 1,
                          height: 1,
                        ),
                        _buildExpandableDrawerMenuItem(
                          context,
                          icon: Icons.info_outline,
                          title: 'Инфо',
                          isExpanded: _infoExpanded,
                          onTap: () {
                            setState(() {
                              _infoExpanded = !_infoExpanded;
                            });
                          },
                          children: [
                            _buildSubDrawerMenuItem(
                              context,
                              icon: Icons.business,
                              title: 'Компании',
                              section: 'companies',
                            ),
                            _buildSubDrawerMenuItem(
                              context,
                              icon: Icons.warehouse,
                              title: 'Склад',
                              section: 'warehouses',
                            ),
                            _buildSubDrawerMenuItem(
                              context,
                              icon: Icons.people,
                              title: 'Сотрудники',
                              section: 'employees',
                            ),
                          ],
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
      ),
    );
  }

  Widget _buildExpandableDrawerMenuItem(
    BuildContext context, {
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
            color: isExpanded ? const Color(0xFF0C3B1B) : Colors.transparent,
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
                    color: Color(0xFF0C3B1B),
                  ),
                  child: Column(children: children),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildSubDrawerMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String section,
  }) {
    final isSelected = widget.selectedSection == section;
    
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
        selectedTileColor: const Color(0xFF0C3B1B),
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

  Widget _buildDrawerMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String section,
  }) {
    final isSelected = widget.selectedSection == section;
    
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
        selectedTileColor: const Color(0xFF0C3B1B),
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
      case UserRole.salesManager:
        return 'sales_manager';
    }
  }
}

// Теперь методы родительского класса ResponsiveDashboardPage

extension on ResponsiveDashboardPage {
  String _getSectionTitle(String section) {
    switch (section) {
      case 'dashboard':
        return 'Инфопанель';
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
      case 'products-inflow':
        return 'Поступление товаров';
      case 'products-in-transit':
        return 'Товары в пути';
      case 'acceptance':
        return 'Приемка';
      default:
        return 'Инфопанель';
    }
  }

  Widget _buildPageContent(BuildContext context, String section) {
    switch (section) {
      case 'dashboard':
        return ResponsiveDashboardContent(
          onShowAllProductsPressed: () => context.go('/inventory'),
        );
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
        return const InventoryTabsPage();
      case 'products-inflow':
        return const ProductsInflowListPage();
      case 'products-in-transit':
        return const ProductsInTransitListPage();
      case 'acceptance':
        return const AcceptanceListPage();
      default:
        return ResponsiveDashboardContent(
          onShowAllProductsPressed: () => context.go('/inventory'),
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
      case UserRole.salesManager:
        return 'sales_manager';
    }
  }

  String _defaultSectionForRole(UserEntity user) {
    final role = _getRoleCode(user.role);
    // Админ видит инфопанель по умолчанию, остальные — первый доступный раздел
    if (role == 'admin') return 'dashboard';
    // Для sales менеджера открываем 'inventory' если доступен
    if (role == 'sales_manager') {
      if (_hasAccess(user, ['admin', 'operator', 'warehouse_worker', 'sales_manager'])) return 'inventory';
      return 'requests';
    }

    // По умолчанию открываем 'inventory' если есть доступ, иначе первый доступный
    if (_hasAccess(user, ['admin', 'operator', 'warehouse_worker', 'sales_manager'])) return 'inventory';
    if (_hasAccess(user, ['admin', 'warehouse_worker', 'sales_manager'])) return 'requests';
    return 'dashboard';
  }


}

/// Адаптированная версия AppBar для мобильных устройств
class MobileAppBar extends StatelessWidget {
  final UserEntity currentUser;
  final String title;
  final bool showMenuButton;

  const MobileAppBar({
    super.key,
    required this.currentUser,
    required this.title,
    this.showMenuButton = true,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Кнопка меню для мобильных
          if (showMenuButton)
            IconButton(
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
              icon: const Icon(
                Icons.menu,
                color: Color(0xFF2C3E50),
              ),
            ),
          
          // Заголовок страницы
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
            ),
          ),
          
          // Пустое место вместо профиля
          const SizedBox.shrink(),
        ],
      ),
    );
  }


}
