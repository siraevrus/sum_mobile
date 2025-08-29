import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sum_warehouse/features/dashboard/data/datasources/admin_stats_datasource.dart';
import 'package:sum_warehouse/shared/models/admin_stats_model.dart';

part 'admin_stats_repository.g.dart';

/// Интерфейс репозитория статистики администратора
abstract class AdminStatsRepository {
  Future<AdminDashboardStats> getDashboardStats();
  Future<ProductStatsModel> getProductsStats();
  Future<SalesStatsModel> getSalesStats();
  Future<UsersStatsModel> getUsersStats();
  Future<WarehousesStatsModel> getWarehousesStats();
}

/// Реализация репозитория статистики администратора
class AdminStatsRepositoryImpl implements AdminStatsRepository {
  final AdminStatsDataSource _dataSource;

  AdminStatsRepositoryImpl(this._dataSource);

  @override
  Future<AdminDashboardStats> getDashboardStats() async {
    try {
      print('🔵 AdminStatsRepository: Начинаем загрузку статистики...');
      
      // Последовательно получаем все статистики для лучшей диагностики
      print('🔵 Загружаем статистику товаров...');
      final productsResponse = await _dataSource.getProductsStats();
      print('✅ Статистика товаров загружена');
      
      print('🔵 Загружаем статистику продаж...');
      final salesResponse = await _dataSource.getSalesStats();
      print('✅ Статистика продаж загружена');
      
      print('🔵 Загружаем статистику пользователей...');
      final usersResponse = await _dataSource.getUsersStats();
      print('✅ Статистика пользователей загружена');
      
      print('🔵 Загружаем статистику складов...');
      final warehousesResponse = await _dataSource.getWarehousesStats();
      print('✅ Статистика складов загружена');

      final result = AdminDashboardStats(
        products: productsResponse.data,
        sales: salesResponse.data,
        users: usersResponse.data,
        warehouses: warehousesResponse.data,
      );
      
      print('✅ AdminStatsRepository: Вся статистика успешно загружена');
      return result;
    } catch (e, stackTrace) {
      print('🔴 AdminStatsRepository: Ошибка загрузки статистики: $e');
      print('🔴 StackTrace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<ProductStatsModel> getProductsStats() async {
    final response = await _dataSource.getProductsStats();
    return response.data;
  }

  @override
  Future<SalesStatsModel> getSalesStats() async {
    final response = await _dataSource.getSalesStats();
    return response.data;
  }

  @override
  Future<UsersStatsModel> getUsersStats() async {
    final response = await _dataSource.getUsersStats();
    return response.data;
  }

  @override
  Future<WarehousesStatsModel> getWarehousesStats() async {
    final response = await _dataSource.getWarehousesStats();
    return response.data;
  }
}

/// Провайдер репозитория статистики администратора
@riverpod
AdminStatsRepository adminStatsRepository(AdminStatsRepositoryRef ref) {
  final dataSource = ref.watch(adminStatsDataSourceProvider);
  return AdminStatsRepositoryImpl(dataSource);
}
