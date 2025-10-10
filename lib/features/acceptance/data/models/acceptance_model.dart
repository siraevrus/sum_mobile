import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sum_warehouse/shared/models/common_references.dart';

part 'acceptance_model.freezed.dart';
part 'acceptance_model.g.dart';

/// Модель товара для раздела "Приемка"
@freezed
class AcceptanceModel with _$AcceptanceModel {
  const factory AcceptanceModel({
    required int id,
    @JsonKey(name: 'product_template_id') required int productTemplateId,
    @JsonKey(name: 'warehouse_id') required int warehouseId,
    @JsonKey(name: 'created_by') required int createdBy,
    String? name,
    String? description,
    dynamic attributes,
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
  }) = _AcceptanceModel;

  factory AcceptanceModel.fromJson(Map<String, dynamic> json) => _$AcceptanceModelFromJson(json);
}

/// Фильтры для товаров приемки
@freezed
class AcceptanceFilters with _$AcceptanceFilters {
  const factory AcceptanceFilters({
    String? search,
    @JsonKey(name: 'warehouse_id') int? warehouseId,
    @JsonKey(name: 'template_id') int? templateId,
    @JsonKey(name: 'producer_id') int? producerId,
    @JsonKey(name: 'in_stock') bool? inStock,
    String? status,
    @JsonKey(name: 'correction_status') String? correctionStatus,
    @JsonKey(name: 'company_id') int? companyId,
    @JsonKey(name: 'employee_id') int? employeeId,
    // Поля фильтра по дате прихода (от/до). На API должны уйти как date_from/date_to
    String? arrivalDateFrom,
    String? arrivalDateTo,
    @JsonKey(name: 'created_by') int? createdBy,
    @JsonKey(name: 'per_page') @Default(15) int perPage,
    @Default(1) int page,
  }) = _AcceptanceFilters;

  factory AcceptanceFilters.fromJson(Map<String, dynamic> json) => _$AcceptanceFiltersFromJson(json);
}

/// Extension для AcceptanceFilters
extension AcceptanceFiltersExtension on AcceptanceFilters {
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
    // Отправляем в API как date_from/date_to (YYYY-MM-DD)
    if (arrivalDateFrom != null) params['date_from'] = arrivalDateFrom;
    if (arrivalDateTo != null) params['date_to'] = arrivalDateTo;
    if (createdBy != null) params['created_by'] = createdBy;
    params['per_page'] = perPage;
    params['page'] = page;
    
    return params;
  }
}

/// Запрос создания товара в приемке
@freezed
class CreateAcceptanceRequest with _$CreateAcceptanceRequest {
  const factory CreateAcceptanceRequest({
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
    @Default('accepted') String status, // Основное отличие - статус accepted для приемки
    @JsonKey(name: 'shipping_location') String? shippingLocation,
    @JsonKey(name: 'shipping_date') String? shippingDate,
    @JsonKey(name: 'expected_arrival_date') String? expectedArrivalDate,
    String? notes,
    @JsonKey(name: 'document_path') @Default([]) List<String> documentPath,
  }) = _CreateAcceptanceRequest;

  factory CreateAcceptanceRequest.fromJson(Map<String, dynamic> json) => _$CreateAcceptanceRequestFromJson(json);
}

/// Запрос обновления товара в приемке
@freezed
class UpdateAcceptanceRequest with _$UpdateAcceptanceRequest {
  const factory UpdateAcceptanceRequest({
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
  }) = _UpdateAcceptanceRequest;

  factory UpdateAcceptanceRequest.fromJson(Map<String, dynamic> json) => _$UpdateAcceptanceRequestFromJson(json);
}
