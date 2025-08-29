import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sum_warehouse/features/dashboard/data/repositories/admin_stats_repository.dart';
import 'package:sum_warehouse/shared/models/admin_stats_model.dart';

part 'admin_stats_provider.g.dart';

/// Провайдер для общей статистики дашборда администратора
@riverpod
Future<AdminDashboardStats> adminDashboardStats(AdminDashboardStatsRef ref) async {
  final repository = ref.watch(adminStatsRepositoryProvider);
  return await repository.getDashboardStats();
}

/// Провайдер для статистики товаров
@riverpod
Future<ProductStatsModel> adminProductsStats(AdminProductsStatsRef ref) async {
  final repository = ref.watch(adminStatsRepositoryProvider);
  return await repository.getProductsStats();
}

/// Провайдер для статистики продаж
@riverpod
Future<SalesStatsModel> adminSalesStats(AdminSalesStatsRef ref) async {
  final repository = ref.watch(adminStatsRepositoryProvider);
  return await repository.getSalesStats();
}

/// Провайдер для статистики пользователей
@riverpod
Future<UsersStatsModel> adminUsersStats(AdminUsersStatsRef ref) async {
  final repository = ref.watch(adminStatsRepositoryProvider);
  return await repository.getUsersStats();
}

/// Провайдер для статистики складов
@riverpod
Future<WarehousesStatsModel> adminWarehousesStats(AdminWarehousesStatsRef ref) async {
  final repository = ref.watch(adminStatsRepositoryProvider);
  return await repository.getWarehousesStats();
}


