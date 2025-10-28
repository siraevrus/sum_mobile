import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
            child: GestureDetector(
              onTap: () => context.go('/companies'),
              child: _StatsCard(
                title: 'Компании',
                value: _formatNumber(stats.companiesActive),
                subtitle: 'Активные',
                icon: Icons.business_outlined,
                iconColor: AppColors.primary,
                backgroundColor: const Color(0xFFF4ECFF),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: () => context.go('/employees'),
              child: _StatsCard(
                title: 'Сотрудники',
                value: _formatNumber(stats.employeesActive),
                subtitle: 'Активные',
                icon: Icons.people_outlined,
                iconColor: const Color(0xFF3498DB),
                backgroundColor: const Color(0xFFEBF3FD),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: () => context.go('/warehouses'),
              child: _StatsCard(
                title: 'Склады',
                value: _formatNumber(stats.warehousesActive),
                subtitle: 'Активные',
                icon: Icons.warehouse_outlined,
                iconColor: const Color(0xFF2ECC71),
                backgroundColor: const Color(0xFFE8F5E8),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: () => context.go('/products-inflow'),
              child: _StatsCard(
                title: 'Товары',
                value: _formatNumber(stats.productsTotal),
                subtitle: 'Всего товаров',
                icon: Icons.inventory_2_outlined,
                iconColor: const Color(0xFF8E44AD),
                backgroundColor: const Color(0xFFF4ECFF),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: () => context.go('/products-in-transit'),
              child: _StatsCard(
                title: 'Товары в пути',
                value: _formatNumber(stats.productsInTransit),
                subtitle: 'В доставке',
                icon: Icons.local_shipping_outlined,
                iconColor: const Color(0xFF16A085),
                backgroundColor: const Color(0xFFE8F6F3),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: () => context.go('/requests'),
              child: _StatsCard(
                title: 'Запросы',
                value: _formatNumber(stats.requestsPending),
                subtitle: 'Ожидают рассмотрения',
                icon: Icons.assignment_outlined,
                iconColor: const Color(0xFFF39C12),
                backgroundColor: const Color(0xFFFEF5E7),
              ),
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

class _StatsCard extends StatefulWidget {
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
  State<_StatsCard> createState() => _StatsCardState();
}

class _StatsCardState extends State<_StatsCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()..translate(0, _isHovered ? -4 : 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_isHovered ? 0.15 : 0.1),
              offset: Offset(0, _isHovered ? 8 : 2),
              blurRadius: _isHovered ? 16 : 8,
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(_isHovered ? 0.08 : 0.06),
              offset: const Offset(0, 1),
              blurRadius: 3,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.backgroundColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      widget.icon,
                      color: widget.iconColor,
                      size: 24,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6C757D),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF95A5A6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
