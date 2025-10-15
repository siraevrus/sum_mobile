import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sum_warehouse/features/auth/presentation/providers/auth_provider.dart';
import 'package:sum_warehouse/features/dashboard/presentation/widgets/modern_app_bar.dart';
import 'package:sum_warehouse/features/dashboard/presentation/widgets/modern_sidebar.dart';
import 'package:sum_warehouse/features/dashboard/presentation/widgets/dashboard_stats_cards.dart';
import 'package:sum_warehouse/features/dashboard/presentation/widgets/recent_activities_card.dart';
import 'package:sum_warehouse/features/dashboard/presentation/widgets/quick_actions_card.dart';
import 'package:sum_warehouse/features/products/presentation/pages/products_list_page.dart';
import 'package:sum_warehouse/features/sales/presentation/pages/sales_list_page.dart';

/// Современный дашборд в стиле веб-интерфейса
class ModernDashboardPage extends ConsumerWidget {
  final String? selectedSection;
  
  const ModernDashboardPage({
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
      authenticated: (user, _) => _buildResponsiveDashboard(context, user),
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

  String _getSectionTitle(String section) {
    switch (section) {
      case 'dashboard':
        return 'Инфопанель';
      case 'products':
        return 'Поступление товаров';
      case 'warehouses':
        return 'Остатки на складе';
      case 'sales':
        return 'Продажи';
      case 'requests':
        return 'Запросы';
      case 'employees':
        return 'Пользователи';
      case 'companies':
        return 'Компании';
      case 'inventory':
        return 'Остатки';
      default:
        return 'Инфопанель';
    }
  }

  Widget _buildPageContent(String section) {
    switch (section) {
      case 'dashboard':
        return const DashboardContent();
      case 'products':
        return const ProductsListPage();
      case 'warehouses':
        return const Center(
          child: Text(
            'Модуль складов в разработке',
            style: TextStyle(fontSize: 18, color: Color(0xFF666666)),
          ),
        );
      case 'sales':
        return const SalesListPage();
      case 'requests':
        return const Center(
          child: Text(
            'Модуль запросов в разработке',
            style: TextStyle(fontSize: 18, color: Color(0xFF666666)),
          ),
        );
      case 'employees':
        return const Center(
          child: Text(
            'Модуль пользователей в разработке',
            style: TextStyle(fontSize: 18, color: Color(0xFF666666)),
          ),
        );
      case 'companies':
        return const Center(
          child: Text(
            'Модуль компаний в разработке',
            style: TextStyle(fontSize: 18, color: Color(0xFF666666)),
          ),
        );
      case 'inventory':
        return const Center(
          child: Text(
            'Модуль остатков в разработке',
            style: TextStyle(fontSize: 18, color: Color(0xFF666666)),
          ),
        );
      default:
        return const DashboardContent();
    }
  }
}

/// Содержимое дашборда
class DashboardContent extends StatelessWidget {
  const DashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Карточки со статистикой
          DashboardStatsCards(),
          SizedBox(height: 24),
          
          // Ряд с активностями и быстрыми действиями
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Недавние активности
              Expanded(
                flex: 2,
                child: RecentActivitiesCard(),
              ),
              SizedBox(width: 24),
              
              // Быстрые действия
              Expanded(
                flex: 1,
                child: QuickActionsCard(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
