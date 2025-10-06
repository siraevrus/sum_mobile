import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_in_transit_entity.freezed.dart';

/// Сущность товара для товаров в пути
@freezed
class ProductInTransitEntity with _$ProductInTransitEntity {
  const factory ProductInTransitEntity({
    required int id,
    required int productTemplateId,
    required int warehouseId,
    required int createdBy,
    required String name,
    String? description,
    @Default({}) Map<String, dynamic> attributes,
    String? calculatedVolume,
    required String quantity,
    @Default(0) int soldQuantity,
    String? transportNumber,
    int? producerId,
    String? arrivalDate,
    required String status,
    @Default(true) bool isActive,
    String? shippingLocation,
    String? shippingDate,
    String? expectedArrivalDate,
    String? actualArrivalDate,
    @Default([]) List<String> documentPath,
    String? notes,
    String? correction,
    String? correctionStatus,
    String? revisedAt,
    required String createdAt,
    required String updatedAt,
    
    // Связанные объекты
    String? templateName,
    String? warehouseName,
    String? creatorName,
    String? producerName,
  }) = _ProductInTransitEntity;
}
