import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/receipt_input_entity.dart';

part 'receipt_input_model.freezed.dart';
part 'receipt_input_model.g.dart';

@freezed
class ReceiptInputModel with _$ReceiptInputModel {
  const factory ReceiptInputModel({
    @JsonKey(name: 'product_template_id') required int productTemplateId,
    @JsonKey(name: 'warehouse_id') required int warehouseId,
    @JsonKey(name: 'producer_id') int? producerId,
    required Map<String, dynamic> attributes,
    required int quantity,
    @JsonKey(name: 'shipping_location') String? shippingLocation,
    @JsonKey(name: 'shipping_date') DateTime? shippingDate,
    @JsonKey(name: 'expected_arrival_date') DateTime? expectedArrivalDate,
    @JsonKey(name: 'transport_number') String? transportNumber,
    String? notes,
  }) = _ReceiptInputModel;

  factory ReceiptInputModel.fromJson(Map<String, dynamic> json) =>
      _$ReceiptInputModelFromJson(json);

  const ReceiptInputModel._();

  /// Convert from domain entity
  factory ReceiptInputModel.fromEntity(ReceiptInputEntity entity) {
    return ReceiptInputModel(
      productTemplateId: entity.productTemplateId,
      warehouseId: entity.warehouseId,
      producerId: entity.producerId,
      attributes: entity.attributes,
      quantity: entity.quantity,
      shippingLocation: entity.shippingLocation,
      shippingDate: entity.shippingDate,
      expectedArrivalDate: entity.expectedArrivalDate,
      transportNumber: entity.transportNumber,
      notes: entity.notes,
    );
  }

  /// Convert to domain entity
  ReceiptInputEntity toEntity() {
    return ReceiptInputEntity(
      productTemplateId: productTemplateId,
      warehouseId: warehouseId,
      producerId: producerId,
      attributes: attributes,
      quantity: quantity,
      shippingLocation: shippingLocation,
      shippingDate: shippingDate,
      expectedArrivalDate: expectedArrivalDate,
      transportNumber: transportNumber,
      notes: notes,
    );
  }
}