import 'package:freezed_annotation/freezed_annotation.dart';

part 'inventory_aggregation_entity.freezed.dart';
part 'inventory_aggregation_entity.g.dart';

/// Карточка производителя с агрегацией
@freezed
class InventoryProducerModel with _$InventoryProducerModel {
  const factory InventoryProducerModel({
    @JsonKey(name: 'producer_id') required int producerId,
    required String producer,
    @JsonKey(name: 'positions_count') required int positionsCount,
    @JsonKey(name: 'total_volume') required double totalVolume,
  }) = _InventoryProducerModel;

  factory InventoryProducerModel.fromJson(Map<String, dynamic> json) =>
      _$InventoryProducerModelFromJson(json);
}

/// Карточка склада с агрегацией
@freezed
class InventoryWarehouseModel with _$InventoryWarehouseModel {
  const factory InventoryWarehouseModel({
    @JsonKey(name: 'warehouse_id') required int warehouseId,
    required String warehouse,
    required String company,
    required String address,
    @JsonKey(name: 'positions_count') required int positionsCount,
    @JsonKey(name: 'total_volume') required double totalVolume,
  }) = _InventoryWarehouseModel;

  factory InventoryWarehouseModel.fromJson(Map<String, dynamic> json) =>
      _$InventoryWarehouseModelFromJson(json);
}

/// Карточка компании с агрегацией
@freezed
class InventoryCompanyModel with _$InventoryCompanyModel {
  const factory InventoryCompanyModel({
    @JsonKey(name: 'company_id') required int companyId,
    required String company,
    @JsonKey(name: 'warehouses_count') required int warehousesCount,
    @JsonKey(name: 'positions_count') required int positionsCount,
    @JsonKey(name: 'total_volume') required double totalVolume,
  }) = _InventoryCompanyModel;

  factory InventoryCompanyModel.fromJson(Map<String, dynamic> json) =>
      _$InventoryCompanyModelFromJson(json);
}

/// Детальная информация по товарам (для всех типов агрегации)
@freezed
class InventoryStockDetail with _$InventoryStockDetail {
  const factory InventoryStockDetail({
    required String name,
    required String warehouse,
    String? producer, // Может быть null
    required double quantity,
    @JsonKey(name: 'available_quantity') required double availableQuantity,
    @JsonKey(name: 'sold_quantity') required double soldQuantity,
    @JsonKey(name: 'total_volume') required double totalVolume,
  }) = _InventoryStockDetail;

  factory InventoryStockDetail.fromJson(Map<String, dynamic> json) =>
      _$InventoryStockDetailFromJson(json);
}

/// Пагинация для детальных данных
@freezed
class PaginatedStockDetails with _$PaginatedStockDetails {
  const factory PaginatedStockDetails({
    required List<InventoryStockDetail> data,
    required PaginationMeta meta,
  }) = _PaginatedStockDetails;

  factory PaginatedStockDetails.fromJson(Map<String, dynamic> json) =>
      _$PaginatedStockDetailsFromJson(json);
}

/// Метаданные пагинации
@freezed
class PaginationMeta with _$PaginationMeta {
  const factory PaginationMeta({
    @JsonKey(name: 'current_page') required int currentPage,
    @JsonKey(name: 'last_page') required int lastPage,
    @JsonKey(name: 'per_page') required int perPage,
    required int total,
  }) = _PaginationMeta;

  factory PaginationMeta.fromJson(Map<String, dynamic> json) =>
      _$PaginationMetaFromJson(json);
}

