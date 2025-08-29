import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sum_warehouse/features/reception/domain/entities/receipt_entity.dart';

part 'product_in_transit_model.freezed.dart';
part 'product_in_transit_model.g.dart';

/// Конвертер для quantity
double _quantityFromJson(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

@freezed
class ProductInTransitModel with _$ProductInTransitModel {
  const factory ProductInTransitModel({
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
    WarehouseInTransitModel? warehouse,
    TemplateInTransitModel? template,
    CreatorInTransitModel? creator,
  }) = _ProductInTransitModel;

  factory ProductInTransitModel.fromJson(Map<String, dynamic> json) =>
      _$ProductInTransitModelFromJson(json);

  const ProductInTransitModel._();

  /// Конвертация в ReceiptEntity для совместимости
  ReceiptEntity toReceiptEntity() => ReceiptEntity(
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
class WarehouseInTransitModel with _$WarehouseInTransitModel {
  const factory WarehouseInTransitModel({
    required int id,
    required String name,
    required String address,
    @JsonKey(name: 'company_id') required int companyId,
    @JsonKey(name: 'is_active') required bool isActive,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _WarehouseInTransitModel;

  factory WarehouseInTransitModel.fromJson(Map<String, dynamic> json) =>
      _$WarehouseInTransitModelFromJson(json);

  const WarehouseInTransitModel._();

  WarehouseEntity toWarehouseEntity() => WarehouseEntity(
        id: id,
        name: name,
        address: address,
        companyId: companyId,
      );
}

@freezed
class TemplateInTransitModel with _$TemplateInTransitModel {
  const factory TemplateInTransitModel({
    required int id,
    required String name,
    String? description,
    String? formula,
    required String unit,
    @JsonKey(name: 'is_active') required bool isActive,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _TemplateInTransitModel;

  factory TemplateInTransitModel.fromJson(Map<String, dynamic> json) =>
      _$TemplateInTransitModelFromJson(json);
}

@freezed
class CreatorInTransitModel with _$CreatorInTransitModel {
  const factory CreatorInTransitModel({
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
  }) = _CreatorInTransitModel;

  factory CreatorInTransitModel.fromJson(Map<String, dynamic> json) =>
      _$CreatorInTransitModelFromJson(json);

  const CreatorInTransitModel._();

  UserEntity toUserEntity() => UserEntity(
        id: id,
        name: name,
        email: email,
      );
}

/// Модель пагинации
@freezed
class PaginationModel with _$PaginationModel {
  const factory PaginationModel({
    @JsonKey(name: 'current_page') required int currentPage,
    @JsonKey(name: 'last_page') required int lastPage,
    @JsonKey(name: 'per_page') required int perPage,
    required int total,
  }) = _PaginationModel;

  factory PaginationModel.fromJson(Map<String, dynamic> json) =>
      _$PaginationModelFromJson(json);
}

/// Ответ API для списка товаров в пути
@freezed
class ProductsInTransitResponse with _$ProductsInTransitResponse {
  const factory ProductsInTransitResponse({
    required bool success,
    required List<ProductInTransitModel> data,
    PaginationModel? pagination,
  }) = _ProductsInTransitResponse;

  factory ProductsInTransitResponse.fromJson(Map<String, dynamic> json) =>
      _$ProductsInTransitResponseFromJson(json);
}

