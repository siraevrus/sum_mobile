import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sum_warehouse/features/users/domain/entities/user_entity.dart';
import 'package:sum_warehouse/features/warehouses/domain/entities/warehouse_entity.dart';
import 'package:sum_warehouse/features/products/domain/entities/product_entity.dart';

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
    // Связанные объекты
    ProductEntity? productTemplate,
    WarehouseEntity? warehouse,
    UserEntity? creator,
  }) = _ProductInTransitEntity;
}

@freezed
class ProductEntity with _$ProductEntity {
  const factory ProductEntity({
    required int id,
    required String name,
    required int productTemplateId,
    String? unit,
    String? producer,
    String? description,
  }) = _ProductEntity;
}

@freezed
class WarehouseEntity with _$WarehouseEntity {
  const factory WarehouseEntity({
    required int id,
    required String name,
    required String address,
    required int companyId,
  }) = _WarehouseEntity;
}

@freezed
class UserEntity with _$UserEntity {
  const factory UserEntity({
    required int id,
    required String name,
    String? email,
    @Default(UserRole.operator) UserRole role,
  }) = _UserEntity;
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
