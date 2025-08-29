import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sum_warehouse/core/theme/app_colors.dart';
import 'package:sum_warehouse/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:sum_warehouse/shared/widgets/loading_widget.dart';
import 'package:sum_warehouse/shared/widgets/metric_card.dart';
import 'package:sum_warehouse/shared/widgets/quick_action_card.dart';
import 'package:sum_warehouse/shared/widgets/charts/activity_chart.dart';
import 'package:sum_warehouse/features/products/presentation/pages/product_templates_list_page.dart';

/// Инфопанель администратора со статистикой
class AdminDashboardPage extends ConsumerStatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  ConsumerState<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends ConsumerState<AdminDashboardPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Инфопанель администратора'),
        backgroundColor: const Color(0xFF9B59B6),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Быстрые действия
              _buildQuickActions(),
              
              const SizedBox(height: 24),
              
              // Основные метрики
              _buildMainMetrics(),
              
              const SizedBox(height: 24),
              
              // Графики продаж и активности
              _buildChartsSection(),
              
              const SizedBox(height: 24),
              
              // Статистика складов
              _buildWarehousesSection(),
              
              const SizedBox(height: 24),
              
              // Топ товары и активности
              _buildBottomSection(),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Быстрые действия
  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Быстрые действия',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        QuickActionsGrid(
          actions: [
            QuickActionData(
              title: 'Новый запрос',
              description: 'Создать запрос',
              icon: Icons.add_box,
              iconColor: AppColors.primary,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const RequestFormPage(),
                  ),
                ).then((_) => ref.invalidate(requestsListProvider));
              },
            ),
            QuickActionData(
              title: 'Шаблоны товаров',
              description: 'Управление шаблонами',
              icon: Icons.inventory_2,
              iconColor: AppColors.success,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ProductTemplatesListPage(),
                  ),
                ).then((_) => ref.invalidate(productTemplatesProvider));
              },
            ),
            QuickActionData(
              title: 'Отчеты',
              description: 'Создать отчет',
              icon: Icons.analytics,
              iconColor: AppColors.info,
              onTap: () {
                // TODO: Навигация к отчетам
              },
            ),
            QuickActionData(
              title: 'Пользователи',
              description: 'Управление',
              icon: Icons.people,
              iconColor: AppColors.warning,
              badge: '3',
              badgeColor: AppColors.error,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const EmployeesListPage(),
                  ),
                );
              },
            ),
          ],
          crossAxisCount: 2,
          childAspectRatio: 1.1,
        ),
      ],
    );
  }

  /// Основные метрики
  Widget _buildMainMetrics() {
    // Используем провайдер без кэширования для отладки
    final dashboardStats = ref.watch(dashboardStatsNoCachingProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Общая статистика',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        dashboardStats.when(
          loading: () => const LoadingWidget(message: 'Загружаем статистику...'),
          error: (error, stack) => AppErrorWidget(
            message: 'Не удалось загрузить статистику',
            onRetry: () => ref.invalidate(dashboardStatsProvider),
          ),
          data: (stats) => GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              MetricCard(
                title: 'Товары',
                value: _formatNumber(stats.totalProducts),
                subtitle: stats.lowStockProducts > 0 
                    ? '${stats.lowStockProducts} мало остатков'
                    : 'Все в наличии',
                icon: Icons.inventory,
                iconColor: stats.lowStockProducts > 0 ? AppColors.warning : AppColors.success,
              ),
              MetricCard(
                title: 'Склады',
                value: '5', // Статичное значение как на фронте
                subtitle: '5 активных',
                icon: Icons.warehouse,
                iconColor: AppColors.warning,
              ),
              MetricCard(
                title: 'Продажи',
                value: '${stats.todaySales.round()} ₽',
                subtitle: 'Общая выручка',
                icon: Icons.trending_up,
                iconColor: AppColors.success,
              ),
              MetricCard(
                title: 'Сотрудники',
                value: _formatNumber(stats.totalEmployees),
                subtitle: '${stats.activeEmployees} заблокированы',
                icon: Icons.people,
                iconColor: AppColors.info,
              ),
              MetricCard(
                title: 'Компании',
                value: _formatNumber(stats.totalCompanies),
                subtitle: 'Активные компании',
                icon: Icons.business,
                iconColor: AppColors.primary,
              ),
              MetricCard(
                title: 'Запросы',
                value: _formatNumber(stats.todayRequests),
                subtitle: 'Ожидают рассмотрения',
                icon: Icons.assignment,
                iconColor: AppColors.warning,
              ),
              MetricCard(
                title: 'В пути',
                value: _formatNumber(stats.goodsInTransit),
                subtitle: 'Товары в доставке',
                icon: Icons.local_shipping,
                iconColor: AppColors.info,
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  /// Секция с графиками (упрощенная версия)
  Widget _buildChartsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Аналитика',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ActivityChart(
          data: _getMockActivityData(),
          title: 'Активность за неделю',
        ),
      ],
    );
  }

  /// Секция складов
  Widget _buildWarehousesSection() {
    final warehousesStats = ref.watch(warehousesStatsProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Склады',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        warehousesStats.when(
          loading: () => const LoadingWidget(message: 'Загружаем склады...'),
          error: (error, stack) => AppErrorWidget(
            message: 'Ошибка загрузки складов',
            onRetry: () => ref.invalidate(warehousesStatsProvider),
          ),
          data: (warehouses) => Column(
            children: warehouses.map((warehouse) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DetailedMetricCard(
                title: warehouse.warehouseName,
                primaryValue: '${warehouse.totalProducts}',
                secondaryValue: '${warehouse.occupancyRate.toStringAsFixed(1)}%',
                description: warehouse.location,
                icon: Icons.warehouse,
                iconColor: _getWarehouseStatusColor(warehouse.status),
                additionalMetrics: [
                  MetricItem(
                    label: 'Статус',
                    value: warehouse.status,
                    color: _getWarehouseStatusColor(warehouse.status),
                  ),
                  MetricItem(
                    label: 'Запросы сегодня',
                    value: '${warehouse.todayRequests}',
                  ),
                  MetricItem(
                    label: 'Мало остатков',
                    value: '${warehouse.lowStockProducts}',
                    color: warehouse.lowStockProducts > 0 ? AppColors.warning : null,
                  ),
                ],
                onTap: () {
                  // TODO: Переход к детальной информации о складе
                },
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }

  /// Нижняя секция с топ товарами и активностями
  Widget _buildBottomSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 800) {
          // Десктоп - два блока рядом
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildTopProducts()),
              const SizedBox(width: 16),
              Expanded(child: _buildRecentActivities()),
            ],
          );
        } else {
          // Мобильный - блоки друг под другом
          return Column(
            children: [
              _buildTopProducts(),
              const SizedBox(height: 16),
              _buildRecentActivities(),
            ],
          );
        }
      },
    );
  }

  /// Основная статистика (старый метод - удалить позже)
  Widget _buildMainStats() {
    final dashboardStats = ref.watch(dashboardStatsProvider);
    
    return dashboardStats.when(
      loading: () => const LoadingWidget(message: 'Загружаем статистику...'),
      error: (error, stack) => AppErrorWidget(
        message: 'Не удалось загрузить статистику',
        onRetry: () => ref.invalidate(dashboardStatsProvider),
      ),
      data: (stats) => GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          MetricCard(
            title: 'Товары',
            value: _formatNumber(stats.totalProducts),
            subtitle: stats.lowStockProducts > 0 
                ? '${stats.lowStockProducts} мало остатков'
                : 'Все в наличии',
            icon: Icons.inventory,
            iconColor: stats.lowStockProducts > 0 ? AppColors.warning : AppColors.success,
          ),
          MetricCard(
            title: 'Компании',
            value: _formatNumber(stats.totalCompanies),
            subtitle: '${stats.activeCompanies} активных',
            icon: Icons.business,
            iconColor: AppColors.primary,
          ),
          MetricCard(
            title: 'Сотрудники',
            value: _formatNumber(stats.totalEmployees),
            subtitle: '${stats.activeEmployees} активных',
            icon: Icons.people,
            iconColor: AppColors.info,
          ),
          MetricCard(
            title: 'Продажи сегодня',
            value: _formatMoney(stats.todaySales),
            subtitle: 'За месяц: ${_formatMoney(stats.monthlySales)}',
            icon: Icons.attach_money,
            iconColor: AppColors.success,
          ),
          MetricCard(
            title: 'Запросы сегодня',
            value: '${stats.completedTodayRequests}/${stats.todayRequests}',
            subtitle: 'Выполнено/всего',
            icon: Icons.assignment,
            iconColor: stats.todayRequests > 0 
                ? (stats.completedTodayRequests / stats.todayRequests > 0.8 
                    ? AppColors.success : AppColors.warning)
                : AppColors.info,
          ),
          MetricCard(
            title: 'Товар в пути',
            value: _formatNumber(stats.goodsInTransit),
            subtitle: 'Поставки',
            icon: Icons.local_shipping,
            iconColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
  
  /// Статистика складов
  Widget _buildWarehousesStats() {
    final warehousesStats = ref.watch(warehousesStatsProvider);
    
    return warehousesStats.when(
      loading: () => const LoadingWidget(message: 'Загружаем данные складов...'),
      error: (error, stack) => AppErrorWidget(
        message: 'Не удалось загрузить данные складов',
        onRetry: () => ref.invalidate(warehousesStatsProvider),
      ),
      data: (warehouses) => ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: warehouses.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final warehouse = warehouses[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: DetailedMetricCard(
              title: warehouse.warehouseName,
              primaryValue: '${warehouse.totalProducts}',
              secondaryValue: '${warehouse.occupancyRate.toStringAsFixed(1)}%',
              description: warehouse.location,
              icon: Icons.warehouse,
              iconColor: _getWarehouseStatusColor(warehouse.status),
              additionalMetrics: [
                MetricItem(
                  label: 'Статус',
                  value: warehouse.status,
                  color: _getWarehouseStatusColor(warehouse.status),
                ),
                MetricItem(
                  label: 'Запросы сегодня',
                  value: '${warehouse.todayRequests}',
                ),
                MetricItem(
                  label: 'Мало остатков',
                  value: '${warehouse.lowStockProducts}',
                  color: warehouse.lowStockProducts > 0 ? AppColors.warning : null,
                ),
              ],
              onTap: () {
                // TODO: Переход к детальной странице склада
              },
            ),
          );
        },
      ),
    );
  }
  
  /// Топ товары
  Widget _buildTopProducts() {
    final topProducts = ref.watch(topProductsProvider());
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Топ товары',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            topProducts.when(
              loading: () => const LoadingWidget(size: 20),
              error: (error, stack) => const Text('Ошибка загрузки'),
              data: (products) => ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: products.take(5).length,
                separatorBuilder: (context, index) => const Divider(height: 16),
                itemBuilder: (context, index) {
                  final product = products[index];
                  return Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: AppColors.primary,
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
                              product.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Продано: ${product.soldQuantity} шт.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      Text(
                        _formatMoney(product.totalRevenue),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Недавние активности
  Widget _buildRecentActivities() {
    final activities = ref.watch(recentActivitiesProvider());
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Недавние действия',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            activities.when(
              loading: () => const LoadingWidget(size: 20),
              error: (error, stack) => const Text('Ошибка загрузки'),
              data: (activityList) => ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activityList.take(5).length,
                separatorBuilder: (context, index) => const Divider(height: 16),
                itemBuilder: (context, index) {
                  final activity = activityList[index];
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        _getActivityIcon(activity.type),
                        size: 16,
                        color: _getActivityColor(activity.type),
                      ),
                      const SizedBox(width: 8),
                      
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activity.description,
                              style: const TextStyle(fontSize: 13),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${activity.userName} • ${_formatTime(activity.timestamp)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Обновить все данные
  Future<void> _refreshData() async {
    print('🔄 Обновление данных дашборда...');
    await Future.wait([
      ref.refresh(dashboardStatsNoCachingProvider.future), // Используем новый провайдер
      ref.refresh(dashboardStatsProvider.future),
      ref.refresh(warehousesStatsProvider.future),
      ref.refresh(topProductsProvider().future),
      ref.refresh(recentActivitiesProvider().future),
    ]);
    print('✅ Данные дашборда обновлены');
  }
  
  /// Форматирование числа
  String _formatNumber(int number) {
    if (number < 1000) return number.toString();
    if (number < 1000000) return '${(number / 1000).toStringAsFixed(1)}К';
    return '${(number / 1000000).toStringAsFixed(1)}М';
  }
  
  /// Форматирование денег
  String _formatMoney(double amount) {
    if (amount < 1000) return '${amount.toStringAsFixed(0)} ₽';
    if (amount < 1000000) return '${(amount / 1000).toStringAsFixed(1)}К ₽';
    return '${(amount / 1000000).toStringAsFixed(1)}М ₽';
  }
  
  /// Форматирование времени
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) return 'сейчас';
    if (difference.inMinutes < 60) return '${difference.inMinutes} мин назад';
    if (difference.inHours < 24) return '${difference.inHours} ч назад';
    return '${difference.inDays} дн назад';
  }
  
  /// Иконка для типа активности
  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'sale':
        return Icons.point_of_sale;
      case 'request':
        return Icons.assignment;
      case 'inventory':
        return Icons.inventory;
      case 'user_action':
        return Icons.person;
      default:
        return Icons.circle;
    }
  }
  
  /// Цвет для типа активности
  Color _getActivityColor(String type) {
    switch (type) {
      case 'sale':
        return AppColors.success;
      case 'request':
        return AppColors.primary;
      case 'inventory':
        return AppColors.warning;
      case 'user_action':
        return AppColors.info;
      default:
        return Colors.grey;
    }
  }

  /// Цвет статуса склада
  Color _getWarehouseStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'нормально':
        return AppColors.success;
      case 'переполнен':
        return AppColors.error;
      case 'низкие остатки':
        return AppColors.warning;
      default:
        return AppColors.info;
    }
  }

  /// Мок-данные для графика активности
  List<ActivityData> _getMockActivityData() {
    return const [
      ActivityData(period: 'Пн', completed: 12, pending: 3),
      ActivityData(period: 'Вт', completed: 15, pending: 5),
      ActivityData(period: 'Ср', completed: 8, pending: 2),
      ActivityData(period: 'Чт', completed: 18, pending: 4),
      ActivityData(period: 'Пт', completed: 22, pending: 6),
      ActivityData(period: 'Сб', completed: 10, pending: 1),
      ActivityData(period: 'Вс', completed: 5, pending: 0),
    ];
  }
}
