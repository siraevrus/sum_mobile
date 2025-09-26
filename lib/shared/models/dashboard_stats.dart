import 'package:freezed_annotation/freezed_annotation.dart';

part 'dashboard_stats.freezed.dart';
// part 'dashboard_stats.g.dart'; // Temporarily disable json_serializable

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

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    final latestSalesList = (json['latest_sales'] as List<dynamic>? ?? [])
        .map((item) => LatestSale.fromJson(item as Map<String, dynamic>))
        .toList();
    
    return DashboardStats(
      companiesActive: json['companies_active'] as int? ?? 0,
      employeesActive: json['employees_active'] as int? ?? 0,
      warehousesActive: json['warehouses_active'] as int? ?? 0,
      productsTotal: json['products_total'] as int? ?? 0,
      productsInTransit: json['products_in_transit'] as int? ?? 0,
      requestsPending: json['requests_pending'] as int? ?? 0,
      latestSales: latestSalesList,
      lastUpdated: json['last_updated'] != null ? DateTime.tryParse(json['last_updated']) : null,
    );
  }
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

  factory WarehouseStats.fromJson(Map<String, dynamic> json) {
    return WarehouseStats(
      warehouseId: json['warehouse_id'] as int,
      warehouseName: json['warehouse_name'] as String,
      location: json['location'] as String,
      totalProducts: json['total_products'] as int? ?? 0,
      lowStockProducts: json['low_stock_products'] as int? ?? 0,
      todayRequests: json['today_requests'] as int? ?? 0,
      occupancyRate: (json['occupancy_rate'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'Нормально',
    );
  }
}

/// Модель статистики продаж по периодам
@freezed 
class SalesChartData with _$SalesChartData {
  const factory SalesChartData({
    required String period, // дата или период
    required double amount, // сумма продаж
    required int quantity, // количество товаров
  }) = _SalesChartData;

  factory SalesChartData.fromJson(Map<String, dynamic> json) {
    return SalesChartData(
      period: json['period'] as String,
      amount: (json['amount'] as num).toDouble(),
      quantity: json['quantity'] as int,
    );
  }
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

  factory TopProduct.fromJson(Map<String, dynamic> json) {
    return TopProduct(
      productId: json['product_id'] as int,
      name: json['name'] as String,
      category: json['category'] as String,
      soldQuantity: json['sold_quantity'] as int? ?? 0,
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0.0,
      currentStock: json['current_stock'] as int? ?? 0,
    );
  }
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

  factory RecentActivity.fromJson(Map<String, dynamic> json) {
    return RecentActivity(
      id: json['id'] as String,
      type: json['type'] as String,
      description: json['description'] as String,
      userName: json['user_name'] as String,
      targetEntity: json['target_entity'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      status: json['status'] as String?,
    );
  }
}

/// Модель последних продаж
@freezed
class LatestSale with _$LatestSale {
  const factory LatestSale({
    required int id,
    @JsonKey(name: 'product_name') required String productName,
    @JsonKey(name: 'client_name') String? clientName,
    required double quantity,
    @JsonKey(name: 'total_amount') required double totalAmount,
    @JsonKey(name: 'sale_date') required DateTime saleDate,
  }) = _LatestSale;

  factory LatestSale.fromJson(Map<String, dynamic> json) {
    return LatestSale(
      id: json['id'] as int,
      productName: json['product_name'] as String,
      clientName: json['client_name'] as String?,
      quantity: _parseDouble(json['quantity']),
      totalAmount: _parseDouble(json['total_amount']),
      saleDate: DateTime.parse(json['sale_date'] as String),
    );
  }
}

/// Модель суммы в валюте
@freezed
class CurrencyAmount with _$CurrencyAmount {
  const factory CurrencyAmount({
    required double amount,
    required String formatted,
  }) = _CurrencyAmount;

  factory CurrencyAmount.fromJson(Map<String, dynamic> json) {
    return CurrencyAmount(
      amount: _parseDouble(json['amount']),
      formatted: json['formatted']?.toString() ?? '',
    );
  }
}

/// Помощник для парсинга double значений
double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
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
