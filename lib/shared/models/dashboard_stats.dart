import 'package:freezed_annotation/freezed_annotation.dart';

part 'dashboard_stats.freezed.dart';
part 'dashboard_stats.g.dart';

/// Модель статистики для дашборда
@freezed
class DashboardStats with _$DashboardStats {
  const factory DashboardStats({
    /// Общее количество товаров
    @Default(0) int totalProducts,
    /// Товары с низким остатком
    @Default(0) int lowStockProducts,
    /// Общее количество компаний
    @Default(0) int totalCompanies,
    /// Активные компании
    @Default(0) int activeCompanies,
    /// Общее количество сотрудников
    @Default(0) int totalEmployees,
    /// Активные сотрудники
    @Default(0) int activeEmployees,
    /// Запросы за сегодня
    @Default(0) int todayRequests,
    /// Выполненные запросы за сегодня
    @Default(0) int completedTodayRequests,
    /// Продажи за сегодня (в рублях)
    @Default(0.0) double todaySales,
    /// Продажи за месяц (в рублях)
    @Default(0.0) double monthlySales,
    /// Товары в пути
    @Default(0) int goodsInTransit,
    /// Последнее обновление
    DateTime? lastUpdated,
  }) = _DashboardStats;

  factory DashboardStats.fromJson(Map<String, dynamic> json) => _$DashboardStatsFromJson(json);
}

/// Модель статистики по складам
@freezed
class WarehouseStats with _$WarehouseStats {
  const factory WarehouseStats({
    required int warehouseId,
    required String warehouseName,
    required String location,
    @Default(0) int totalProducts,
    @Default(0) int lowStockProducts,
    @Default(0) int todayRequests,
    @Default(0.0) double occupancyRate,
    @Default('Нормально') String status,
  }) = _WarehouseStats;

  factory WarehouseStats.fromJson(Map<String, dynamic> json) => _$WarehouseStatsFromJson(json);
}

/// Модель статистики продаж по периодам
@freezed 
class SalesChartData with _$SalesChartData {
  const factory SalesChartData({
    required String period, // дата или период
    required double amount, // сумма продаж
    required int quantity, // количество товаров
  }) = _SalesChartData;

  factory SalesChartData.fromJson(Map<String, dynamic> json) => _$SalesChartDataFromJson(json);
}

/// Модель топ товаров
@freezed
class TopProduct with _$TopProduct {
  const factory TopProduct({
    required int productId,
    required String name,
    required String category,
    @Default(0) int soldQuantity,
    @Default(0.0) double totalRevenue,
    @Default(0) int currentStock,
  }) = _TopProduct;

  factory TopProduct.fromJson(Map<String, dynamic> json) => _$TopProductFromJson(json);
}

/// Модель недавних активностей
@freezed
class RecentActivity with _$RecentActivity {
  const factory RecentActivity({
    required String id,
    required String type, // 'sale', 'request', 'inventory', 'user_action'
    required String description,
    required String userName,
    String? targetEntity, // товар, склад, пользователь и т.д.
    required DateTime timestamp,
    String? status, // 'success', 'pending', 'error'
  }) = _RecentActivity;

  factory RecentActivity.fromJson(Map<String, dynamic> json) => _$RecentActivityFromJson(json);
}
