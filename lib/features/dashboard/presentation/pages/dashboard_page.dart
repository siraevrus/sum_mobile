import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sum_warehouse/core/theme/app_colors.dart';
import 'package:sum_warehouse/features/auth/domain/entities/user_entity.dart';
import 'package:sum_warehouse/features/auth/presentation/providers/auth_provider.dart';
import 'package:sum_warehouse/features/dashboard/presentation/pages/admin_dashboard_page.dart';
import 'package:sum_warehouse/features/companies/presentation/pages/companies_list_page.dart';
import 'package:sum_warehouse/features/products/presentation/pages/product_templates_list_page.dart';
import 'package:sum_warehouse/features/products/presentation/pages/products_list_page.dart';
import 'package:sum_warehouse/features/requests/presentation/pages/requests_list_page.dart';
import 'package:sum_warehouse/features/inventory/presentation/pages/stocks_list_page.dart';
import 'package:sum_warehouse/features/reception/presentation/pages/reception_list_page.dart';

/// Главный экран дашборда
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final currentRole = ref.watch(currentUserRoleProvider);
    
    // Слушаем изменения состояния авторизации для logout
    ref.listen<AuthState>(authProvider, (previous, next) {
      print('🟡 Dashboard: Состояние изменилось: ${previous?.runtimeType} → ${next.runtimeType}');
      
      next.maybeWhen(
        unauthenticated: () {
          print('🔴 Dashboard: Пользователь вышел, переходим на логин');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              print('🚀 Dashboard: Выполняем go на /login');
              context.go('/login');
            }
          });
        },
        error: (message) {
          print('🔴 Dashboard: Ошибка авторизации: $message');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              print('🚀 Dashboard: Ошибка, переходим на логин');
              context.go('/login');
            }
          });
        },
        orElse: () {},
      );
    });
    
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sum Warehouse'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                ref.read(authProvider.notifier).logout();
              } else if (value == 'profile') {
                // TODO: Открыть профиль пользователя
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'profile',
                child: Row(
                  children: [
                    const Icon(Icons.person),
                    const SizedBox(width: 8),
                    Text(currentUser.name),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Выйти'),
                  ],
                ),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.2),
                    child: Text(
                      currentUser.name.characters.first.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_drop_down, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
      
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Приветствие
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Добро пожаловать, ${currentUser.name}!',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Роль: ${_getRoleDisplayName(currentRole)}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (currentUser.companyId != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Компания ID: ${currentUser.companyId}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                      if (currentUser.warehouseId != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Склад ID: ${currentUser.warehouseId}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Быстрые действия согласно роли
              Text(
                'Доступные функции',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              _buildRoleBasedActions(context, ref, currentRole),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleBasedActions(BuildContext context, WidgetRef ref, UserRole? role) {
    final List<_ActionTile> actions = [];
    
    switch (role) {
      case UserRole.admin:
        actions.addAll([
          _ActionTile(
            icon: Icons.dashboard,
            title: 'Дашборд администратора',
            subtitle: 'Общая статистика и метрики',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AdminDashboardPage(),
                ),
              );
            },
          ),
          _ActionTile(
            icon: Icons.business,
            title: 'Управление компаниями',
            subtitle: 'Создание и редактирование компаний',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CompaniesListPage(),
                ),
              );
            },
          ),
          _ActionTile(
            icon: Icons.people,
            title: 'Управление сотрудниками',
            subtitle: 'Добавление и блокировка пользователей',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const EmployeesListPage(),
                ),
              );
            },
          ),
        ]);
        break;
      
      case UserRole.operator:
        actions.addAll([
          _ActionTile(
            icon: Icons.inventory,
            title: 'Поступление товаров',
            subtitle: 'Просмотр и управление товарами',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ProductsListPage(),
                ),
              );
            },
          ),
          _ActionTile(
            icon: Icons.storage,
            title: 'Остатки',
            subtitle: 'Контроль остатков на складах',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const StocksListPage(),
                ),
              );
            },
          ),
        ]);
        break;
        
      case UserRole.warehouseWorker:
        actions.addAll([
          _ActionTile(
            icon: Icons.assignment,
            title: 'Запросы',
            subtitle: 'Обработка складских запросов',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const RequestsListPage(),
                ),
              );
            },
          ),
          _ActionTile(
            icon: Icons.local_shipping,
            title: 'Товар в пути',
            subtitle: 'Отслеживание поставок',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ReceptionListPage(),
                ),
              );
            },
          ),
          _ActionTile(
            icon: Icons.point_of_sale,
            title: 'Реализация',
            subtitle: 'Продажи и оформление',
            onTap: () {
              // TODO: Navigate to sales
            },
          ),
        ]);
        break;
        
      case UserRole.manager:
        actions.addAll([
          _ActionTile(
            icon: Icons.assignment,
            title: 'Запросы',
            subtitle: 'Создание и просмотр запросов',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const RequestsListPage(),
                ),
              );
            },
          ),
          _ActionTile(
            icon: Icons.storage,
            title: 'Остатки',
            subtitle: 'Контроль остатков',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const StocksListPage(),
                ),
              );
            },
          ),
        ]);
        break;
        
      default:
        break;
    }
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.3, // Увеличиваем высоту карточек
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return Card(
          elevation: 2,
          child: InkWell(
            onTap: action.onTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(12.0), // Уменьшаем padding
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    action.icon,
                    size: 28, // Уменьшаем размер иконки
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 6), // Уменьшаем отступ
                  Flexible( // Делаем текст гибким
                    child: Text(
                      action.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13, // Уменьшаем размер шрифта
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2, // Максимум 2 строки
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Flexible( // Делаем subtitle гибким
                    child: Text(
                      action.subtitle,
                      style: TextStyle(
                        fontSize: 11, // Уменьшаем размер шрифта
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2, // Максимум 2 строки
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _getRoleDisplayName(UserRole? role) {
    switch (role) {
      case UserRole.admin:
        return 'Администратор';
      case UserRole.operator:
        return 'Оператор ПК';
      case UserRole.warehouseWorker:
        return 'Работник склада';
      case UserRole.manager:
        return 'Менеджер';
      default:
        return 'Неизвестная роль';
    }
  }
}

class _ActionTile {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}
