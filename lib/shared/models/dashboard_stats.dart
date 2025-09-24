import 'package:freezed_annotation/freezed_annotation.dart';

part 'dashboard_stats.freezed.dart';
part 'dashboard_stats.g.dart';

/// Модель статистики для дашборда
@freezed
class DashboardStats with _$DashboardStats {
  const factory DashboardStats({
    /// Активные компании
    @JsonKey(name: 'companies_active') @Default(0) int companiesActive,
    /// Активные сотрудники
    @JsonKey(name: 'employees_active') @Default(0) int employeesActive,
    /// Активные склады
    @JsonKey(name: 'warehouses_active') @Default(0) int warehousesActive,
    /// Общее количество товаров
    @JsonKey(name: 'products_total') @Default(0) int productsTotal,
    /// Товары в пути
    @JsonKey(name: 'products_in_transit') @Default(0) int productsInTransit,
    /// Ожидающие запросы
    @JsonKey(name: 'requests_pending') @Default(0) int requestsPending,
    /// Последние продажи
    @JsonKey(name: 'latest_sales') @Default([]) List<LatestSale> latestSales,
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

/// Модель последних продаж
@freezed
class LatestSale with _$LatestSale {
  const factory LatestSale({
    required int id,
    @JsonKey(name: 'product_name') required String productName,
    @JsonKey(name: 'client_name') String? clientName,
    required int quantity,
    @JsonKey(name: 'total_amount') required String totalAmount,
    @JsonKey(name: 'sale_date') required DateTime saleDate,
  }) = _LatestSale;

  factory LatestSale.fromJson(Map<String, dynamic> json) => _$LatestSaleFromJson(json);
}

/// Модель суммы в валюте
@freezed
class CurrencyAmount with _$CurrencyAmount {
  const factory CurrencyAmount({
    required double amount,
    required String formatted,
  }) = _CurrencyAmount;

  factory CurrencyAmount.fromJson(Map<String, dynamic> json) => _$CurrencyAmountFromJson(json);
}

/// Модель выручки по валютам
@freezed
class RevenueData with _$RevenueData {
  const factory RevenueData({
    required String period,
    @JsonKey(name: 'date_from') required String dateFrom,
    @JsonKey(name: 'date_to') required String dateTo,
    required Map<String, CurrencyAmount> revenue,
  }) = _RevenueData;

  factory RevenueData.fromJson(Map<String, dynamic> json) {
    final revenueMap = <String, CurrencyAmount>{};
    final revenueJson = json['revenue'] as Map<String, dynamic>;
    
    for (final entry in revenueJson.entries) {
      revenueMap[entry.key] = CurrencyAmount.fromJson(entry.value as Map<String, dynamic>);
    }
    
    return RevenueData(
      period: json['period'] as String,
      dateFrom: json['date_from'] as String,
      dateTo: json['date_to'] as String,
      revenue: revenueMap,
    );
  }
}
