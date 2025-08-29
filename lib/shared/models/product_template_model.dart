import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_template_model.freezed.dart';
part 'product_template_model.g.dart';

/// Основная модель шаблона товара по API
@freezed
class ProductTemplateModel with _$ProductTemplateModel {
  const factory ProductTemplateModel({
    required int id,
    required String name,
    required String unit,
    String? description,
    String? formula,
    @JsonKey(name: 'is_active') required bool isActive,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    
    // Связанные объекты
    @Default([]) List<ProductTemplateAttribute> attributes,
  }) = _ProductTemplateModel;

  factory ProductTemplateModel.fromJson(Map<String, dynamic> json) => 
      _$ProductTemplateModelFromJson(json);
}

/// Модель атрибута шаблона товара
@freezed
class ProductTemplateAttribute with _$ProductTemplateAttribute {
  const factory ProductTemplateAttribute({
    required int id,
    @JsonKey(name: 'product_template_id') required int productTemplateId,
    required String name,
    required String variable,
    required String type, // 'number', 'text', 'select'
    dynamic value,
    String? unit,
    @JsonKey(name: 'is_required') @Default(false) bool isRequired,
    @JsonKey(name: 'is_in_formula') @Default(false) bool isInFormula,
    @JsonKey(name: 'sort_order') @Default(0) int sortOrder,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _ProductTemplateAttribute;

  factory ProductTemplateAttribute.fromJson(Map<String, dynamic> json) => 
      _$ProductTemplateAttributeFromJson(json);
}

/// Модель создания шаблона товара
@freezed
class CreateProductTemplateRequest with _$CreateProductTemplateRequest {
  const factory CreateProductTemplateRequest({
    required String name,
    required String unit,
    String? description,
    String? formula,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
  }) = _CreateProductTemplateRequest;

  factory CreateProductTemplateRequest.fromJson(Map<String, dynamic> json) => 
      _$CreateProductTemplateRequestFromJson(json);
}

/// Модель обновления шаблона товара
@freezed
class UpdateProductTemplateRequest with _$UpdateProductTemplateRequest {
  const factory UpdateProductTemplateRequest({
    String? name,
    String? unit,
    String? description,
    String? formula,
    @JsonKey(name: 'is_active') bool? isActive,
  }) = _UpdateProductTemplateRequest;

  factory UpdateProductTemplateRequest.fromJson(Map<String, dynamic> json) => 
      _$UpdateProductTemplateRequestFromJson(json);
}

/// Модель создания атрибута шаблона
@freezed
class CreateTemplateAttributeRequest with _$CreateTemplateAttributeRequest {
  const factory CreateTemplateAttributeRequest({
    required String name,
    required String variable,
    required String type, // 'number', 'text', 'select'
    dynamic value,
    String? unit,
    @JsonKey(name: 'is_required') @Default(false) bool isRequired,
    @JsonKey(name: 'is_in_formula') @Default(false) bool isInFormula,
    @JsonKey(name: 'sort_order') @Default(0) int sortOrder,
  }) = _CreateTemplateAttributeRequest;

  factory CreateTemplateAttributeRequest.fromJson(Map<String, dynamic> json) => 
      _$CreateTemplateAttributeRequestFromJson(json);
}

/// Модель обновления атрибута шаблона
@freezed
class UpdateTemplateAttributeRequest with _$UpdateTemplateAttributeRequest {
  const factory UpdateTemplateAttributeRequest({
    String? name,
    String? variable,
    String? type,
    dynamic value,
    String? unit,
    @JsonKey(name: 'is_required') bool? isRequired,
    @JsonKey(name: 'is_in_formula') bool? isInFormula,
    @JsonKey(name: 'sort_order') int? sortOrder,
  }) = _UpdateTemplateAttributeRequest;

  factory UpdateTemplateAttributeRequest.fromJson(Map<String, dynamic> json) => 
      _$UpdateTemplateAttributeRequestFromJson(json);
}

/// Модель тестирования формулы
@freezed
class TestFormulaRequest with _$TestFormulaRequest {
  const factory TestFormulaRequest({
    required Map<String, double> values,
  }) = _TestFormulaRequest;

  factory TestFormulaRequest.fromJson(Map<String, dynamic> json) => 
      _$TestFormulaRequestFromJson(json);
}

/// Модель фильтров шаблонов товаров
@freezed
class ProductTemplateFilters with _$ProductTemplateFilters {
  const factory ProductTemplateFilters({
    @JsonKey(name: 'is_active') bool? isActive,
    String? search,
    String? sort,
    String? order,
    @JsonKey(name: 'per_page') @Default(15) int perPage,
    @Default(1) int page,
  }) = _ProductTemplateFilters;

  factory ProductTemplateFilters.fromJson(Map<String, dynamic> json) => 
      _$ProductTemplateFiltersFromJson(json);
}

/// Extension для ProductTemplateFilters
extension ProductTemplateFiltersExtension on ProductTemplateFilters {
  /// Конвертация в query параметры
  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};
    
    if (isActive != null) params['is_active'] = isActive! ? 1 : 0;
    if (search != null && search!.isNotEmpty) params['search'] = search;
    if (sort != null) params['sort'] = sort;
    if (order != null) params['order'] = order;
    params['per_page'] = perPage;
    params['page'] = page;
    
    return params;
  }
}


