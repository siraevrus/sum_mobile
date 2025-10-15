import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sum_warehouse/shared/models/common_references.dart';

part 'product_in_transit_model.freezed.dart';
part 'product_in_transit_model.g.dart';

/// Преобразование quantity из int или String в String
String _quantityFromJson(dynamic value) {
  if (value is int) {
    return value.toString();
  } else if (value is double) {
    return value.toString();
  } else if (value is String) {
    return value;
  }
  return '0';
}

/// Модель товара для раздела "Товары в пути"
@freezed
class ProductInTransitModel with _$ProductInTransitModel {
  const factory ProductInTransitModel({
    required int id,
    @JsonKey(name: 'product_template_id') required int productTemplateId,
    @JsonKey(name: 'warehouse_id') required int warehouseId,
    @JsonKey(name: 'created_by') required int createdBy,
    String? name,
    String? description,
    dynamic attributes,
    @JsonKey(name: 'calculated_volume') String? calculatedVolume,
    @JsonKey(fromJson: _quantityFromJson) required String quantity,
    @JsonKey(name: 'sold_quantity') @Default(0) int soldQuantity,
    @JsonKey(name: 'transport_number') String? transportNumber,
    @JsonKey(name: 'producer_id') int? producerId,
    @JsonKey(name: 'arrival_date') String? arrivalDate,
    required String status,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    @JsonKey(name: 'shipping_location') String? shippingLocation,
    @JsonKey(name: 'shipping_date') String? shippingDate,
    @JsonKey(name: 'expected_arrival_date') String? expectedArrivalDate,
    @JsonKey(name: 'actual_arrival_date') String? actualArrivalDate,
    @JsonKey(name: 'document_path') @Default([]) List<String> documentPath,
    String? notes,
    String? correction,
    @JsonKey(name: 'correction_status') String? correctionStatus,
    @JsonKey(name: 'revised_at') String? revisedAt,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'updated_at') required String updatedAt,
    
    // Связанные объекты
    ProductTemplateReference? template,
    WarehouseReference? warehouse,
    UserReference? creator,
    ProducerReference? producer,
  }) = _ProductInTransitModel;

  factory ProductInTransitModel.fromJson(Map<String, dynamic> json) => _$ProductInTransitModelFromJson(json);
}

/// Фильтры для товаров в пути
@freezed
class ProductInTransitFilters with _$ProductInTransitFilters {
  const factory ProductInTransitFilters({
    String? search,
    @JsonKey(name: 'warehouse_id') int? warehouseId,
    @JsonKey(name: 'template_id') int? templateId,
    @JsonKey(name: 'producer_id') int? producerId,
    @JsonKey(name: 'in_stock') bool? inStock,
    String? status,
    @JsonKey(name: 'correction_status') String? correctionStatus,
    @JsonKey(name: 'company_id') int? companyId,
    @JsonKey(name: 'employee_id') int? employeeId,
    // Поля фильтра по ожидаемой дате прибытия (от/до). На API должны уйти как date_from/date_to
    String? arrivalDateFrom,
    String? arrivalDateTo,
    @JsonKey(name: 'created_by') int? createdBy,
    @JsonKey(name: 'per_page') @Default(15) int perPage,
    @Default(1) int page,
  }) = _ProductInTransitFilters;

  factory ProductInTransitFilters.fromJson(Map<String, dynamic> json) => _$ProductInTransitFiltersFromJson(json);
}

/// Extension для ProductInTransitFilters
extension ProductInTransitFiltersExtension on ProductInTransitFilters {
  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};
    
    if (search != null) params['search'] = search;
    if (warehouseId != null) params['warehouse_id'] = warehouseId;
    if (templateId != null) params['template_id'] = templateId;
    if (producerId != null) params['producer_id'] = producerId;
    if (inStock != null) params['in_stock'] = inStock;
    if (status != null) params['status'] = status;
    if (correctionStatus != null) params['correction_status'] = correctionStatus;
    if (companyId != null) params['company_id'] = companyId;
    if (employeeId != null) params['employee_id'] = employeeId;
    // Отправляем в API как date_from/date_to для ожидаемой даты прибытия (YYYY-MM-DD)
    if (arrivalDateFrom != null) params['date_from'] = arrivalDateFrom;
    if (arrivalDateTo != null) params['date_to'] = arrivalDateTo;
    if (createdBy != null) params['created_by'] = createdBy;
    params['per_page'] = perPage;
    params['page'] = page;
    
    return params;
  }
}

/// Запрос создания товара в пути
@freezed
class CreateProductInTransitRequest with _$CreateProductInTransitRequest {
  const factory CreateProductInTransitRequest({
    @JsonKey(name: 'product_template_id') required int productTemplateId,
    @JsonKey(name: 'warehouse_id') required int warehouseId,
    String? name,
    String? description,
    dynamic attributes,
    @JsonKey(name: 'calculated_volume') String? calculatedVolume,
    required String quantity,
    @JsonKey(name: 'transport_number') String? transportNumber,
    @JsonKey(name: 'producer_id') int? producerId,
    @JsonKey(name: 'arrival_date') String? arrivalDate,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    @Default('for_receipt') String status, // Основное отличие - статус for_receipt
    @JsonKey(name: 'shipping_location') String? shippingLocation,
    @JsonKey(name: 'shipping_date') String? shippingDate,
    @JsonKey(name: 'expected_arrival_date') String? expectedArrivalDate,
    String? notes,
    @JsonKey(name: 'document_path') @Default([]) List<String> documentPath,
  }) = _CreateProductInTransitRequest;

  factory CreateProductInTransitRequest.fromJson(Map<String, dynamic> json) => _$CreateProductInTransitRequestFromJson(json);
}

  @freezed
  class CreateMultipleProductsInTransitRequest with _$CreateMultipleProductsInTransitRequest {
    const factory CreateMultipleProductsInTransitRequest({
      @JsonKey(name: 'warehouse_id') required int warehouseId,
      @JsonKey(name: 'shipping_location') String? shippingLocation,
      @JsonKey(name: 'shipping_date') String? shippingDate,
      @JsonKey(name: 'transport_number') String? transportNumber,
      @JsonKey(name: 'arrival_date') String? arrivalDate,
      @JsonKey(name: 'expected_arrival_date') String? expectedArrivalDate,
      String? notes,
      @JsonKey(name: 'document_path') @Default([]) List<String> documentPath,
      required List<ProductInTransitItem> products,
    }) = _CreateMultipleProductsInTransitRequest;

  factory CreateMultipleProductsInTransitRequest.fromJson(Map<String, dynamic> json) => _$CreateMultipleProductsInTransitRequestFromJson(json);
}

@freezed
class ProductInTransitItem with _$ProductInTransitItem {
  const factory ProductInTransitItem({
    @JsonKey(name: 'product_template_id') required int productTemplateId,
    required String quantity,
    @JsonKey(name: 'producer_id') int? producerId,
    String? description,
    String? name,
    dynamic attributes,
  }) = _ProductInTransitItem;

  factory ProductInTransitItem.fromJson(Map<String, dynamic> json) => _$ProductInTransitItemFromJson(json);
}

/// Запрос обновления товара в пути
@freezed
class UpdateProductInTransitRequest with _$UpdateProductInTransitRequest {
  const factory UpdateProductInTransitRequest({
    String? name,
    String? description,
    dynamic attributes,
    @JsonKey(name: 'calculated_volume') String? calculatedVolume,
    String? quantity,
    @JsonKey(name: 'transport_number') String? transportNumber,
    @JsonKey(name: 'producer_id') int? producerId,
    @JsonKey(name: 'arrival_date') String? arrivalDate,
    @JsonKey(name: 'is_active') bool? isActive,
    String? status,
    @JsonKey(name: 'shipping_location') String? shippingLocation,
    @JsonKey(name: 'shipping_date') String? shippingDate,
    @JsonKey(name: 'expected_arrival_date') String? expectedArrivalDate,
    String? notes,
    @JsonKey(name: 'document_path') List<String>? documentPath,
  }) = _UpdateProductInTransitRequest;

  factory UpdateProductInTransitRequest.fromJson(Map<String, dynamic> json) => _$UpdateProductInTransitRequestFromJson(json);
}
