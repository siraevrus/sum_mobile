import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sum_warehouse/features/reception/domain/entities/receipt_entity.dart';

part 'receipt_model.freezed.dart';
part 'receipt_model.g.dart';

/// Конвертер для quantity
double _quantityFromJson(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

@freezed
class ReceiptModel with _$ReceiptModel {
  const factory ReceiptModel({
    required int id,
    @JsonKey(name: 'product_template_id') required int productTemplateId,
    @JsonKey(name: 'warehouse_id') required int warehouseId,
    @JsonKey(name: 'created_by') required int createdBy,
    required String name,
    String? description,
    Map<String, dynamic>? attributes,
    @JsonKey(name: 'calculated_volume') String? calculatedVolume,
    @JsonKey(fromJson: _quantityFromJson) required double quantity,
    @JsonKey(name: 'transport_number') String? transportNumber,
    @JsonKey(name: 'tracking_number') String? trackingNumber,
    String? producer,
    @JsonKey(name: 'shipping_location') String? shippingLocation,
    @JsonKey(name: 'shipping_date') DateTime? shippingDate,
    @JsonKey(name: 'expected_arrival_date') DateTime? expectedArrivalDate,
    @JsonKey(name: 'actual_arrival_date') DateTime? actualArrivalDate,
    @JsonKey(name: 'arrival_date') DateTime? arrivalDate,
    required String status,
    String? notes,
    @JsonKey(name: 'document_path') List<String>? documentPath,
    @JsonKey(name: 'is_active') required bool isActive,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
    // Связанные объекты
    WarehouseReceiptModel? warehouse,
    TemplateReceiptModel? template,
    CreatorReceiptModel? creator,
  }) = _ReceiptModel;

  factory ReceiptModel.fromJson(Map<String, dynamic> json) =>
      _$ReceiptModelFromJson(json);

  const ReceiptModel._();

  /// Конвертация в entity
  ReceiptEntity toEntity() => ReceiptEntity(
        id: id,
        productId: productTemplateId, // Используем template_id как product_id
        warehouseId: warehouseId,
        userId: createdBy,
        quantity: quantity,
        status: status,
        createdAt: createdAt,
        updatedAt: updatedAt,
        documentNumber: transportNumber, // Номер транспорта как номер документа
        description: description,
        transportInfo: transportNumber != null ? 'Транспорт: $transportNumber' : null,
        driverInfo: null, // Не предоставлено в API
        dispatchDate: shippingDate,
        expectedArrivalDate: expectedArrivalDate,
        actualArrivalDate: actualArrivalDate,
        notes: notes,
        // Связанные объекты
        product: template != null 
          ? ProductEntity(
              id: template!.id,
              name: template!.name,
              productTemplateId: template!.id,
              unit: template!.unit,
              producer: producer,
            )
          : ProductEntity(
              id: productTemplateId,
              name: name,
              productTemplateId: productTemplateId,
              unit: 'шт',
              producer: producer,
            ),
        warehouse: warehouse?.toWarehouseEntity(),
        user: creator?.toUserEntity(),
      );
}

@freezed
class WarehouseReceiptModel with _$WarehouseReceiptModel {
  const factory WarehouseReceiptModel({
    required int id,
    required String name,
    required String address,
    @JsonKey(name: 'company_id') required int companyId,
    @JsonKey(name: 'is_active') required bool isActive,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _WarehouseReceiptModel;

  factory WarehouseReceiptModel.fromJson(Map<String, dynamic> json) =>
      _$WarehouseReceiptModelFromJson(json);

  const WarehouseReceiptModel._();

  WarehouseEntity toWarehouseEntity() => WarehouseEntity(
        id: id,
        name: name,
        address: address,
        companyId: companyId,
      );
}

@freezed
class TemplateReceiptModel with _$TemplateReceiptModel {
  const factory TemplateReceiptModel({
    required int id,
    required String name,
    String? description,
    String? formula,
    required String unit,
    @JsonKey(name: 'is_active') required bool isActive,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _TemplateReceiptModel;

  factory TemplateReceiptModel.fromJson(Map<String, dynamic> json) =>
      _$TemplateReceiptModelFromJson(json);
}

@freezed
class CreatorReceiptModel with _$CreatorReceiptModel {
  const factory CreatorReceiptModel({
    required int id,
    required String name,
    required String username,
    required String email,
    @JsonKey(name: 'email_verified_at') DateTime? emailVerifiedAt,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
    required String role,
    @JsonKey(name: 'first_name') String? firstName,
    @JsonKey(name: 'last_name') String? lastName,
    @JsonKey(name: 'middle_name') String? middleName,
    String? phone,
    @JsonKey(name: 'company_id') int? companyId,
    @JsonKey(name: 'warehouse_id') int? warehouseId,
    @JsonKey(name: 'is_blocked') required bool isBlocked,
    @JsonKey(name: 'blocked_at') DateTime? blockedAt,
  }) = _CreatorReceiptModel;

  factory CreatorReceiptModel.fromJson(Map<String, dynamic> json) =>
      _$CreatorReceiptModelFromJson(json);

  const CreatorReceiptModel._();

  UserEntity toUserEntity() => UserEntity(
        id: id,
        name: name,
        email: email,
      );
}

/// Ответ API для списка приемок
@freezed
class ReceiptsResponse with _$ReceiptsResponse {
  const factory ReceiptsResponse({
    required bool success,
    required List<ReceiptModel> data,
    @JsonKey(name: 'pagination') Map<String, dynamic>? pagination,
  }) = _ReceiptsResponse;

  factory ReceiptsResponse.fromJson(Map<String, dynamic> json) =>
      _$ReceiptsResponseFromJson(json);
}
