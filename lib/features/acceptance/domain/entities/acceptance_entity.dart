import 'package:freezed_annotation/freezed_annotation.dart';

part 'acceptance_entity.freezed.dart';

/// Сущность товара для раздела приемки
@freezed
class AcceptanceEntity with _$AcceptanceEntity {
  const factory AcceptanceEntity({
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
  }) = _AcceptanceEntity;
}
