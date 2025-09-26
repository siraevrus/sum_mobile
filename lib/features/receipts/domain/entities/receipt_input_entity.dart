import 'package:freezed_annotation/freezed_annotation.dart';

part 'receipt_input_entity.freezed.dart';

@freezed
class ReceiptInputEntity with _$ReceiptInputEntity {
  const factory ReceiptInputEntity({
    required int productTemplateId,
    required int warehouseId,
    int? producerId,
    required Map<String, dynamic> attributes,
    required int quantity,
    String? shippingLocation,
    DateTime? shippingDate,
    DateTime? expectedArrivalDate,
    String? transportNumber,
    String? notes,
  }) = _ReceiptInputEntity;
}