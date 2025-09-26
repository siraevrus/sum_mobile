import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_in_transit_entity.freezed.dart';

@freezed
class ProductInTransitEntity with _$ProductInTransitEntity {
  const factory ProductInTransitEntity({
    required int id,
    required int warehouseId,
    required String name,
    required String status,
    required double quantity,
    required double actualQuantity,
    String? producer,
    String? shippingLocation,
    DateTime? shippingDate,
    DateTime? expectedArrivalDate,
    String? notes,
    required bool isActive,
    required int createdBy,
    required DateTime createdAt,
    required DateTime updatedAt,
    // Связанные объекты как простые объекты
    ProductTemplateInfo? productTemplate,
    WarehouseInfo? warehouse,
    CreatorInfo? creator,
  }) = _ProductInTransitEntity;
}

/// Информация о шаблоне товара
@freezed
class ProductTemplateInfo with _$ProductTemplateInfo {
  const factory ProductTemplateInfo({
    required int id,
    required String name,
    String? description,
    String? unit,
  }) = _ProductTemplateInfo;
}

/// Информация о складе
@freezed
class WarehouseInfo with _$WarehouseInfo {
  const factory WarehouseInfo({
    required int id,
    required String name,
    required String address,
    required int companyId,
  }) = _WarehouseInfo;
}

/// Информация о создателе
@freezed
class CreatorInfo with _$CreatorInfo {
  const factory CreatorInfo({
    required int id,
    required String name,
    required String email,
    String? role,
  }) = _CreatorInfo;
}


// Enum для статусов товаров в пути
enum ProductInTransitStatus {
  @JsonValue('in_transit')
  inTransit,
  @JsonValue('arrived')
  arrived,
  @JsonValue('received')
  received,
  @JsonValue('cancelled')
  cancelled;

  String get displayName {
    switch (this) {
      case ProductInTransitStatus.inTransit:
        return 'В пути';
      case ProductInTransitStatus.arrived:
        return 'Прибыл';
      case ProductInTransitStatus.received:
        return 'Принят';
      case ProductInTransitStatus.cancelled:
        return 'Отменен';
    }
  }
}
