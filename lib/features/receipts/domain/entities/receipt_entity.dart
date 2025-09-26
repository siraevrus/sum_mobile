import 'package:freezed_annotation/freezed_annotation.dart';

part 'receipt_entity.freezed.dart';

enum ReceiptStatus {
  @JsonValue('in_transit')
  inTransit,
  @JsonValue('for_receipt') 
  forReceipt,
  @JsonValue('in_stock')
  inStock,
}

@freezed
class ReceiptEntity with _$ReceiptEntity {
  const factory ReceiptEntity({
    required int id,
    required String name,
    required int productTemplateId,
    required int warehouseId,
    int? producerId,
    required Map<String, dynamic> attributes,
    double? calculatedVolume,
    required int quantity,
    required ReceiptStatus status,
    String? shippingLocation,
    DateTime? shippingDate,
    DateTime? expectedArrivalDate,
    String? transportNumber,
    String? documentPath,
    String? notes,
    int? createdBy,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ReceiptEntity;
}