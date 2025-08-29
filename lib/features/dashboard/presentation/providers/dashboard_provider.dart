import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sum_warehouse/features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'package:sum_warehouse/shared/models/dashboard_stats.dart' as models;

part 'dashboard_provider.g.dart';

/// Provider для загрузки статистики дашборда
@riverpod
class DashboardStats extends _$DashboardStats {
  @override
  FutureOr<models.DashboardStats> build() {
    return _loadDashboardStats();
  }
  
  /// Загрузить статистику
  Future<models.DashboardStats> _loadDashboardStats() async {
    final dataSource = ref.read(dashboardRemoteDataSourceProvider);
    return await dataSource.getDashboardStats();
  }
  
  /// Обновить статистику
  Future<void> refresh() async {
    print('🔄 DashboardStats: Принудительное обновление...');
    // Инвалидируем кэш
    ref.invalidateSelf();
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadDashboardStats());
  }
}

/// Провайдер для прямого получения статистики без кэширования (для отладки)
@riverpod
Future<models.DashboardStats> dashboardStatsNoCaching(DashboardStatsNoCachingRef ref) async {
  print('🚀 Прямой вызов API без кэширования...');
  final dataSource = ref.read(dashboardRemoteDataSourceProvider);
  final stats = await dataSource.getDashboardStats();
  print('✅ Получена статистика: Продажи=${stats.todaySales}, Компании=${stats.totalCompanies}, В пути=${stats.goodsInTransit}');
  return stats;
}

/// Provider для статистики складов
@riverpod
class WarehousesStats extends _$WarehousesStats {
  @override
  FutureOr<List<models.WarehouseStats>> build() {
    return _loadWarehousesStats();
  }
  
  Future<List<models.WarehouseStats>> _loadWarehousesStats() async {
    final dataSource = ref.read(dashboardRemoteDataSourceProvider);
    return await dataSource.getWarehousesStats();
  }
  
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadWarehousesStats());
  }
}

/// Provider для данных графика продаж
@riverpod
class SalesChart extends _$SalesChart {
  @override
  FutureOr<List<models.SalesChartData>> build({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final start = startDate ?? DateTime.now().subtract(const Duration(days: 7));
    final end = endDate ?? DateTime.now();
    return _loadSalesChartData(start, end);
  }
  
  Future<List<models.SalesChartData>> _loadSalesChartData(DateTime startDate, DateTime endDate) async {
    final dataSource = ref.read(dashboardRemoteDataSourceProvider);
    return await dataSource.getSalesChartData(startDate: startDate, endDate: endDate);
  }
  
  Future<void> refresh({DateTime? startDate, DateTime? endDate}) async {
    state = const AsyncValue.loading();
    final start = startDate ?? DateTime.now().subtract(const Duration(days: 7));
    final end = endDate ?? DateTime.now();
    state = await AsyncValue.guard(() => _loadSalesChartData(start, end));
  }
}

/// Provider для топ товаров
@riverpod
class TopProducts extends _$TopProducts {
  @override
  FutureOr<List<models.TopProduct>> build({int limit = 10}) {
    return _loadTopProducts(limit);
  }
  
  Future<List<models.TopProduct>> _loadTopProducts(int limit) async {
    final dataSource = ref.read(dashboardRemoteDataSourceProvider);
    return await dataSource.getTopProducts(limit: limit);
  }
  
  Future<void> refresh({int limit = 10}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadTopProducts(limit));
  }
}

/// Provider для недавних активностей
@riverpod
class RecentActivities extends _$RecentActivities {
  @override
  FutureOr<List<models.RecentActivity>> build({int limit = 20}) {
    return _loadRecentActivities(limit);
  }
  
  Future<List<models.RecentActivity>> _loadRecentActivities(int limit) async {
    final dataSource = ref.read(dashboardRemoteDataSourceProvider);
    return await dataSource.getRecentActivities(limit: limit);
  }
  
  Future<void> refresh({int limit = 20}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadRecentActivities(limit));
  }
}
