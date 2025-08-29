import 'package:freezed_annotation/freezed_annotation.dart';

part 'receipt_entity.freezed.dart';

@freezed
class ReceiptEntity with _$ReceiptEntity {
  const factory ReceiptEntity({
    required int id,
    required int productId,
    required int warehouseId,
    required int userId,
    required double quantity,
    required String status,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? documentNumber,
    String? description,
    String? transportInfo,
    String? driverInfo,
    DateTime? dispatchDate,
    DateTime? expectedArrivalDate,
    DateTime? actualArrivalDate,
    String? notes,
    // Связанные объекты
    ProductEntity? product,
    WarehouseEntity? warehouse,
    UserEntity? user,
  }) = _ReceiptEntity;
}

// Модели для связанных объектов (упрощенные)
@freezed
class ProductEntity with _$ProductEntity {
  const factory ProductEntity({
    required int id,
    required String name,
    required int productTemplateId,
    String? unit,
    String? producer,
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
  }) = _UserEntity;
}

// Enum для статусов приемки
enum ReceiptStatus {
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
      case ReceiptStatus.inTransit:
        return 'В пути';
      case ReceiptStatus.arrived:
        return 'Прибыл';
      case ReceiptStatus.received:
        return 'Принят';
      case ReceiptStatus.cancelled:
        return 'Отменен';
    }
  }
}
