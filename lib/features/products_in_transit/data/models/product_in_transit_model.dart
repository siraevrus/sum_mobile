import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sum_warehouse/features/products_in_transit/domain/entities/product_in_transit_entity.dart';
import 'package:sum_warehouse/shared/models/paginated_response.dart';

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
    @JsonKey(name: 'warehouse_id') required int warehouseId,
    required String name,
    required String status,
    @JsonKey(fromJson: _quantityFromJson) required double quantity,
    @JsonKey(name: 'actual_quantity') @Default(0.0) @JsonKey(fromJson: _quantityFromJson) double actualQuantity,
    String? producer,
    @JsonKey(name: 'shipping_location') String? shippingLocation,
    @JsonKey(name: 'shipping_date') DateTime? shippingDate,
    @JsonKey(name: 'expected_arrival_date') DateTime? expectedArrivalDate,
    String? notes,
    required bool isActive,
    @JsonKey(name: 'created_by') required int createdBy,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
    // Связанные объекты
    WarehouseProductInTransitModel? warehouse,
    ProductTemplateInTransitModel? template,
    CreatorProductInTransitModel? creator,
  }) = _ProductInTransitModel;

  factory ProductInTransitModel.fromJson(Map<String, dynamic> json) =>
      _$ProductInTransitModelFromJson(json);

  const ProductInTransitModel._();

  /// Конвертация в entity
  ProductInTransitEntity toEntity() => ProductInTransitEntity(
        id: id,
        warehouseId: warehouseId,
        name: name,
        status: status,
        quantity: quantity,
        actualQuantity: actualQuantity,
        producer: producer,
        shippingLocation: shippingLocation,
        shippingDate: shippingDate,
        expectedArrivalDate: expectedArrivalDate,
        notes: notes,
        isActive: isActive,
        createdBy: createdBy,
        createdAt: createdAt,
        updatedAt: updatedAt,
        warehouse: warehouse?.toWarehouseInfo(),
        productTemplate: template?.toProductTemplateInfo(),
        creator: creator?.toCreatorInfo(),
      );
}

@freezed
class WarehouseProductInTransitModel with _$WarehouseProductInTransitModel {
  const factory WarehouseProductInTransitModel({
    required int id,
    required String name,
    required String address,
    @JsonKey(name: 'company_id') required int companyId,
    @JsonKey(name: 'is_active') required bool isActive,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _WarehouseProductInTransitModel;

  factory WarehouseProductInTransitModel.fromJson(Map<String, dynamic> json) =>
      _$WarehouseProductInTransitModelFromJson(json);

  const WarehouseProductInTransitModel._();

  // Добавим метод toWarehouseInfo
  WarehouseInfo toWarehouseInfo() => WarehouseInfo(
        id: id,
        name: name,
        address: address,
        companyId: companyId,
      );
}

@freezed
class ProductTemplateInTransitModel with _$ProductTemplateInTransitModel {
  const factory ProductTemplateInTransitModel({
    required int id,
    required String name,
    String? description,
    String? formula,
    required String unit,
    @JsonKey(name: 'is_active') required bool isActive,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _ProductTemplateInTransitModel;

  factory ProductTemplateInTransitModel.fromJson(Map<String, dynamic> json) =>
      _$ProductTemplateInTransitModelFromJson(json);

  const ProductTemplateInTransitModel._();

  // Добавим метод toProductTemplateInfo
  ProductTemplateInfo toProductTemplateInfo() => ProductTemplateInfo(
        id: id,
        name: name,
        description: description,
        unit: unit,
      );
}

@freezed
class CreatorProductInTransitModel with _$CreatorProductInTransitModel {
  const factory CreatorProductInTransitModel({
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
  }) = _CreatorProductInTransitModel;

  factory CreatorProductInTransitModel.fromJson(Map<String, dynamic> json) =>
      _$CreatorProductInTransitModelFromJson(json);

  const CreatorProductInTransitModel._();

  CreatorInfo toCreatorInfo() => CreatorInfo(
        id: id,
        name: name,
        email: email,
        role: role,
      );
}

/// Модель для элемента продукта в запросе создания
@freezed
class ProductInTransitItemModel with _$ProductInTransitItemModel {
  const factory ProductInTransitItemModel({
    @JsonKey(name: 'product_template_id') required int productTemplateId,
    @JsonKey(fromJson: _quantityFromJson) required double quantity,
    String? producer,
    required String name,
  }) = _ProductInTransitItemModel;

  factory ProductInTransitItemModel.fromJson(Map<String, dynamic> json) =>
      _$ProductInTransitItemModelFromJson(json);
}

/// Модель запроса для создания товара в пути
@freezed
class CreateProductInTransitRequest with _$CreateProductInTransitRequest {
  const factory CreateProductInTransitRequest({
    @JsonKey(name: 'warehouse_id') required int warehouseId,
    required List<ProductInTransitItemModel> products,
    @JsonKey(name: 'shipping_location') String? shippingLocation,
    @JsonKey(name: 'shipping_date') String? shippingDate, // Assuming ISO 8601 string
  }) = _CreateProductInTransitRequest;

  factory CreateProductInTransitRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateProductInTransitRequestFromJson(json);
}

/// Модель запроса для приемки товара в пути
@freezed
class ReceiveProductInTransitRequest with _$ReceiveProductInTransitRequest {
  const factory ReceiveProductInTransitRequest({
    @JsonKey(name: 'actual_quantity') @JsonKey(fromJson: _quantityFromJson) required double actualQuantity,
    String? notes,
  }) = _ReceiveProductInTransitRequest;

  factory ReceiveProductInTransitRequest.fromJson(Map<String, dynamic> json) =>
      _$ReceiveProductInTransitRequestFromJson(json);
}

/// Ответ API для списка товаров в пути
@freezed
class ProductInTransitResponse with _$ProductInTransitResponse {
  const factory ProductInTransitResponse({
    required bool success,
    required List<ProductInTransitModel> data,
    @JsonKey(name: 'pagination') Map<String, dynamic>? pagination,
  }) = _ProductInTransitResponse;

  factory ProductInTransitResponse.fromJson(Map<String, dynamic> json) =>
      _$ProductInTransitResponseFromJson(json);
}
