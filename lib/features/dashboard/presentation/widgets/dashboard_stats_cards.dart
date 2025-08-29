import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sum_warehouse/features/dashboard/presentation/providers/admin_stats_provider.dart';
import 'package:sum_warehouse/core/theme/app_colors.dart';
import 'package:sum_warehouse/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:sum_warehouse/shared/widgets/loading_widget.dart';

/// Карточки со статистикой для дашборда
class DashboardStatsCards extends ConsumerWidget {
  const DashboardStatsCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Используем новый провайдер без кэширования для получения актуальных данных
    final dashboardStats = ref.watch(dashboardStatsNoCachingProvider);
    
    return dashboardStats.when(
      loading: () => const SizedBox(
        height: 120,
        child: Center(
          child: LoadingWidget(message: 'Загружаем статистику...'),
        ),
      ),
      error: (error, stackTrace) => SizedBox(
        height: 120,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                'Ошибка загрузки статистики',
                style: TextStyle(color: Colors.red, fontSize: 14),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => ref.invalidate(dashboardStatsNoCachingProvider),
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      ),
      data: (stats) => Row(
        children: [
          Expanded(
            child: _StatsCard(
              title: 'Товары',
              value: _formatNumber(stats.totalProducts),
              subtitle: stats.lowStockProducts > 0 
                  ? '${stats.lowStockProducts} мало остатков'
                  : 'Все в наличии',
              icon: Icons.inventory_2_outlined,
              iconColor: stats.lowStockProducts > 0 
                  ? const Color(0xFFE74C3C)
                  : const Color(0xFF3498DB),
              backgroundColor: stats.lowStockProducts > 0
                  ? const Color(0xFFFDEBEB)
                  : const Color(0xFFEBF3FD),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _StatsCard(
              title: 'Склады',
              value: '5', // Статичное значение как в логах
              subtitle: '5 активных',
              icon: Icons.warehouse_outlined,
              iconColor: const Color(0xFF2ECC71),
              backgroundColor: const Color(0xFFE8F5E8),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _StatsCard(
              title: 'Продажи',
              value: '₽${stats.todaySales.round()}', // Используем average_sale как целое число
              subtitle: 'За этот месяц',
              icon: Icons.trending_up_outlined,
              iconColor: const Color(0xFF2ECC71),
              backgroundColor: const Color(0xFFE8F5E8),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _StatsCard(
              title: 'Сотрудники',
              value: _formatNumber(stats.totalEmployees),
              subtitle: stats.activeEmployees > 0
                  ? '${stats.totalEmployees - stats.activeEmployees} заблокированы'
                  : 'Все активны',
              icon: Icons.people_outlined,
              iconColor: (stats.totalEmployees - stats.activeEmployees) > 0
                  ? const Color(0xFFF39C12)
                  : const Color(0xFF3498DB),
              backgroundColor: (stats.totalEmployees - stats.activeEmployees) > 0
                  ? const Color(0xFFFEF5E7)
                  : const Color(0xFFEBF3FD),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _StatsCard(
              title: 'Компании',
              value: _formatNumber(stats.totalCompanies), // Используем реальные данные
              subtitle: 'Активные компании',
              icon: Icons.business_outlined,
              iconColor: AppColors.primary,
              backgroundColor: const Color(0xFFF4ECFF),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _StatsCard(
              title: 'Запросы',
              value: _formatNumber(stats.todayRequests), // Используем реальные данные
              subtitle: 'Ожидают рассмотрения',
              icon: Icons.assignment_outlined,
              iconColor: AppColors.primary,
              backgroundColor: const Color(0xFFFDF2E9),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _StatsCard(
              title: 'В пути',
              value: _formatNumber(stats.goodsInTransit), // Используем реальные данные
              subtitle: 'Товары в доставке',
              icon: Icons.local_shipping_outlined,
              iconColor: const Color(0xFF16A085),
              backgroundColor: const Color(0xFFE8F6F3),
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  String _formatMoney(double amount) {
    if (amount >= 1000000) {
      return '₽${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '₽${(amount / 1000).toStringAsFixed(0)}K';
    }
    return '₽${amount.toStringAsFixed(0)}';
  }
}

class _StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;

  const _StatsCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
  });

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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 24,
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6C757D),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF95A5A6),
            ),
          ),
        ],
      ),
    );
  }
}
