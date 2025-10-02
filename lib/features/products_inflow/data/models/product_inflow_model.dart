import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sum_warehouse/shared/models/common_references.dart';

part 'product_inflow_model.freezed.dart';
part 'product_inflow_model.g.dart';

/// Модель товара для раздела "Поступление товаров"
@freezed
class ProductInflowModel with _$ProductInflowModel {
  const factory ProductInflowModel({
    required int id,
    @JsonKey(name: 'product_template_id') required int productTemplateId,
    @JsonKey(name: 'warehouse_id') required int warehouseId,
    @JsonKey(name: 'created_by') required int createdBy,
    String? name,
    String? description,
    @Default({}) Map<String, dynamic> attributes,
    @JsonKey(name: 'calculated_volume') String? calculatedVolume,
    required String quantity,
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
  }) = _ProductInflowModel;

  factory ProductInflowModel.fromJson(Map<String, dynamic> json) => _productInflowModelFromJsonSafe(json);
}

ProductInflowModel _productInflowModelFromJsonSafe(Map<String, dynamic> json) {
  return ProductInflowModel(
    id: json['id'] as int,
    productTemplateId: json['product_template_id'] as int,
    warehouseId: json['warehouse_id'] as int,
    createdBy: json['created_by'] as int,
    name: json['name'] as String?,
    description: json['description'] as String?,
    attributes: json['attributes'] as Map<String, dynamic>? ?? {},
    calculatedVolume: json['calculated_volume'] as String?,
    quantity: json['quantity'] as String,
    soldQuantity: json['sold_quantity'] as int? ?? 0,
    transportNumber: json['transport_number'] as String?,
    producerId: json['producer_id'] as int?,
    arrivalDate: json['arrival_date'] as String?,
    status: json['status'] as String,
    isActive: (json['is_active'] as bool?) ?? true,
    shippingLocation: json['shipping_location'] as String?,
    shippingDate: json['shipping_date'] as String?,
    expectedArrivalDate: json['expected_arrival_date'] as String?,
    actualArrivalDate: json['actual_arrival_date'] as String?,
    documentPath: (json['document_path'] as List<dynamic>?)?.cast<String>() ?? [],
    notes: json['notes'] as String?,
    correction: json['correction'] as String?,
    correctionStatus: json['correction_status'] as String?,
    revisedAt: json['revised_at'] as String?,
    createdAt: json['created_at'] as String,
    updatedAt: json['updated_at'] as String,
    
    // Связанные объекты
    template: json['template'] != null 
        ? ProductTemplateReference.fromJson(json['template'] as Map<String, dynamic>)
        : null,
    warehouse: json['warehouse'] != null 
        ? WarehouseReference.fromJson(json['warehouse'] as Map<String, dynamic>)
        : null,
    creator: json['creator'] != null 
        ? UserReference.fromJson(json['creator'] as Map<String, dynamic>)
        : null,
    producer: json['producer'] != null 
        ? ProducerReference.fromJson(json['producer'] as Map<String, dynamic>)
        : null,
  );
}

/// Фильтры для товаров
@freezed
class ProductInflowFilters with _$ProductInflowFilters {
  const factory ProductInflowFilters({
    String? search,
    @JsonKey(name: 'warehouse_id') int? warehouseId,
    @JsonKey(name: 'template_id') int? templateId,
    @JsonKey(name: 'producer_id') int? producerId,
    @JsonKey(name: 'in_stock') bool? inStock,
    String? status,
    @JsonKey(name: 'arrival_date_from') String? arrivalDateFrom,
    @JsonKey(name: 'arrival_date_to') String? arrivalDateTo,
    @JsonKey(name: 'created_by') int? createdBy,
    @JsonKey(name: 'per_page') @Default(15) int perPage,
    @Default(1) int page,
  }) = _ProductInflowFilters;

  factory ProductInflowFilters.fromJson(Map<String, dynamic> json) => _$ProductInflowFiltersFromJson(json);
}

/// Extension для ProductInflowFilters
extension ProductInflowFiltersExtension on ProductInflowFilters {
  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};
    
    if (search != null) params['search'] = search;
    if (warehouseId != null) params['warehouse_id'] = warehouseId;
    if (templateId != null) params['template_id'] = templateId;
    if (producerId != null) params['producer_id'] = producerId;
    if (inStock != null) params['in_stock'] = inStock;
    if (status != null) params['status'] = status;
    if (arrivalDateFrom != null) params['arrival_date_from'] = arrivalDateFrom;
    if (arrivalDateTo != null) params['arrival_date_to'] = arrivalDateTo;
    if (createdBy != null) params['created_by'] = createdBy;
    params['per_page'] = perPage;
    params['page'] = page;
    
    return params;
  }
}

/// Запрос создания товара
@freezed
class CreateProductInflowRequest with _$CreateProductInflowRequest {
  const factory CreateProductInflowRequest({
    @JsonKey(name: 'product_template_id') required int productTemplateId,
    @JsonKey(name: 'warehouse_id') required int warehouseId,
    String? name,
    String? description,
    @Default({}) Map<String, dynamic> attributes,
    @JsonKey(name: 'calculated_volume') String? calculatedVolume,
    required String quantity,
    @JsonKey(name: 'transport_number') String? transportNumber,
    @JsonKey(name: 'producer_id') int? producerId,
    @JsonKey(name: 'arrival_date') String? arrivalDate,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    @Default('in_stock') String status,
    @JsonKey(name: 'shipping_location') String? shippingLocation,
    @JsonKey(name: 'shipping_date') String? shippingDate,
    @JsonKey(name: 'expected_arrival_date') String? expectedArrivalDate,
    String? notes,
    @JsonKey(name: 'document_path') @Default([]) List<String> documentPath,
  }) = _CreateProductInflowRequest;

  factory CreateProductInflowRequest.fromJson(Map<String, dynamic> json) => _$CreateProductInflowRequestFromJson(json);
}

/// Запрос обновления товара
@freezed
class UpdateProductInflowRequest with _$UpdateProductInflowRequest {
  const factory UpdateProductInflowRequest({
    String? name,
    String? description,
    Map<String, dynamic>? attributes,
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
  }) = _UpdateProductInflowRequest;

  factory UpdateProductInflowRequest.fromJson(Map<String, dynamic> json) => _$UpdateProductInflowRequestFromJson(json);
}
