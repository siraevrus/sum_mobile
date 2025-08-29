import 'package:freezed_annotation/freezed_annotation.dart';

part 'admin_stats_model.freezed.dart';
part 'admin_stats_model.g.dart';

/// Общая статистика для дашборда администратора
@freezed
class AdminDashboardStats with _$AdminDashboardStats {
  const factory AdminDashboardStats({
    required ProductStatsModel products,
    required SalesStatsModel sales,
    required UsersStatsModel users,
    required WarehousesStatsModel warehouses,
  }) = _AdminDashboardStats;

  factory AdminDashboardStats.fromJson(Map<String, dynamic> json) =>
      _$AdminDashboardStatsFromJson(json);
}

/// Статистика товаров
@freezed
class ProductStatsModel with _$ProductStatsModel {
  const factory ProductStatsModel({
    @JsonKey(name: 'total_products') @Default(0) int totalProducts,
    @JsonKey(name: 'active_products') @Default(0) int activeProducts,
    @JsonKey(name: 'in_stock') @Default(0) int inStock,
    @JsonKey(name: 'low_stock') @Default(0) int lowStock,
    @JsonKey(name: 'out_of_stock') @Default(0) int outOfStock,
    @JsonKey(name: 'total_quantity', fromJson: _parseStringToDouble) @Default(0.0) double totalQuantity,
    @JsonKey(name: 'total_volume', fromJson: _parseStringToDouble) @Default(0.0) double totalVolume,
  }) = _ProductStatsModel;

  factory ProductStatsModel.fromJson(Map<String, dynamic> json) =>
      _$ProductStatsModelFromJson(json);
}

/// Парсер строки в double для API полей
double _parseStringToDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

/// Статистика продаж согласно OpenAPI спецификации
@freezed
class SalesStatsModel with _$SalesStatsModel {
  const factory SalesStatsModel({
    @JsonKey(name: 'total_sales') @Default(0) int totalSales,
    @JsonKey(name: 'paid_sales') @Default(0) int paidSales,
    @JsonKey(name: 'pending_payments') @Default(0) int pendingPayments,
    @JsonKey(name: 'today_sales') @Default(0) int todaySales,
    @JsonKey(name: 'month_revenue') @Default(0.0) double monthRevenue,
    @JsonKey(name: 'total_revenue') @Default(0.0) double totalRevenue,
    @JsonKey(name: 'total_quantity') @Default(0.0) double totalQuantity,
    @JsonKey(name: 'average_sale', fromJson: _parseStringToDouble) @Default(0.0) double averageSale,
    @JsonKey(name: 'in_delivery') @Default(0) int inDelivery,
  }) = _SalesStatsModel;

  factory SalesStatsModel.fromJson(Map<String, dynamic> json) =>
      _$SalesStatsModelFromJson(json);
}

/// Статистика пользователей
@freezed
class UsersStatsModel with _$UsersStatsModel {
  const factory UsersStatsModel({
    @Default(0) int total,
    @Default(0) int active,
    @Default(0) int blocked,
    @Default({}) Map<String, int> byRole,
  }) = _UsersStatsModel;

  factory UsersStatsModel.fromJson(Map<String, dynamic> json) =>
      _$UsersStatsModelFromJson(json);
}

/// Статистика складов
@freezed
class WarehousesStatsModel with _$WarehousesStatsModel {
  const factory WarehousesStatsModel({
    @Default(0) int total,
    @Default(0) int active,
    @Default(0) int inactive,
  }) = _WarehousesStatsModel;

  factory WarehousesStatsModel.fromJson(Map<String, dynamic> json) =>
      _$WarehousesStatsModelFromJson(json);
}

/// Ответ API для статистики товаров
@freezed
class ProductStatsResponse with _$ProductStatsResponse {
  const factory ProductStatsResponse({
    required bool success,
    required ProductStatsModel data,
  }) = _ProductStatsResponse;

  factory ProductStatsResponse.fromJson(Map<String, dynamic> json) =>
      _$ProductStatsResponseFromJson(json);
}

/// Ответ API для статистики продаж
@freezed
class SalesStatsResponse with _$SalesStatsResponse {
  const factory SalesStatsResponse({
    required bool success,
    required SalesStatsModel data,
  }) = _SalesStatsResponse;

  factory SalesStatsResponse.fromJson(Map<String, dynamic> json) =>
      _$SalesStatsResponseFromJson(json);
}

/// Ответ API для статистики пользователей
@freezed
class UsersStatsResponse with _$UsersStatsResponse {
  const factory UsersStatsResponse({
    required bool success,
    required UsersStatsModel data,
  }) = _UsersStatsResponse;

  factory UsersStatsResponse.fromJson(Map<String, dynamic> json) =>
      _$UsersStatsResponseFromJson(json);
}

/// Ответ API для статистики складов
@freezed
class WarehousesStatsResponse with _$WarehousesStatsResponse {
  const factory WarehousesStatsResponse({
    required bool success,
    required WarehousesStatsModel data,
  }) = _WarehousesStatsResponse;

  factory WarehousesStatsResponse.fromJson(Map<String, dynamic> json) =>
      _$WarehousesStatsResponseFromJson(json);
}


