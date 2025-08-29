import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sum_warehouse/shared/models/common_references.dart';

part 'warehouse_model.freezed.dart';
part 'warehouse_model.g.dart';

/// Модель склада
@freezed
class WarehouseModel with _$WarehouseModel {
  const factory WarehouseModel({
    required int id,
    required String name,
    required String address,
    @JsonKey(name: 'company_id') required int companyId,
    @JsonKey(name: 'is_active') required bool isActive,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'updated_at') required String updatedAt,
    // Дополнительные поля
    String? phone,
    String? manager,
    String? notes,
    // Связанные объекты
    CompanyReference? company,
    @JsonKey(name: 'products_count') int? productsCount,
    @JsonKey(name: 'employees_count') int? employeesCount,
    @JsonKey(name: 'low_stock_count') @Default(0) int lowStockCount,
    // Массив сотрудников
    List<EmployeeReference>? employees,
  }) = _WarehouseModel;

  const WarehouseModel._();

  factory WarehouseModel.fromJson(Map<String, dynamic> json) =>
      _$WarehouseModelFromJson(json);
  
  /// Получить актуальное количество сотрудников
  int get actualEmployeesCount => employees?.length ?? employeesCount ?? 0;
}

// CompanyReference moved to common_references.dart

/// Ссылка на сотрудника
@freezed
class EmployeeReference with _$EmployeeReference {
  const factory EmployeeReference({
    required int id,
    required String name,
    String? role,
  }) = _EmployeeReference;

  factory EmployeeReference.fromJson(Map<String, dynamic> json) =>
      _$EmployeeReferenceFromJson(json);
}

/// Запрос создания склада
@freezed
class CreateWarehouseRequest with _$CreateWarehouseRequest {
  const factory CreateWarehouseRequest({
    required String name,
    required String address,
    @JsonKey(name: 'company_id') required int companyId,
  }) = _CreateWarehouseRequest;

  factory CreateWarehouseRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateWarehouseRequestFromJson(json);
}

/// Запрос обновления склада
@freezed
class UpdateWarehouseRequest with _$UpdateWarehouseRequest {
  const factory UpdateWarehouseRequest({
    String? name,
    String? address,
    @JsonKey(name: 'company_id') int? companyId,
  }) = _UpdateWarehouseRequest;

  factory UpdateWarehouseRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateWarehouseRequestFromJson(json);
}

/// Статистика склада
@freezed
class WarehouseStats with _$WarehouseStats {
  const factory WarehouseStats({
    @JsonKey(name: 'products_count') required int productsCount,
    @JsonKey(name: 'employees_count') required int employeesCount,
    @JsonKey(name: 'total_quantity') required double totalQuantity,
    @JsonKey(name: 'total_value') required double totalValue,
    @JsonKey(name: 'low_stock_items') required int lowStockItems,
    @JsonKey(name: 'out_of_stock_items') required int outOfStockItems,
  }) = _WarehouseStats;

  factory WarehouseStats.fromJson(Map<String, dynamic> json) =>
      _$WarehouseStatsFromJson(json);
}

/// Статистика всех складов
@freezed
class WarehousesStatsModel with _$WarehousesStatsModel {
  const factory WarehousesStatsModel({
    @JsonKey(name: 'total_warehouses') required int totalWarehouses,
    @JsonKey(name: 'active_warehouses') required int activeWarehouses,
    @JsonKey(name: 'total_products') required int totalProducts,
    @JsonKey(name: 'total_value') required double totalValue,
    @JsonKey(name: 'total_employees') required int totalEmployees,
    @JsonKey(name: 'capacity_utilization') required double capacityUtilization,
  }) = _WarehousesStatsModel;

  factory WarehousesStatsModel.fromJson(Map<String, dynamic> json) =>
      _$WarehousesStatsModelFromJson(json);
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