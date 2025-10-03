import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_template_model.freezed.dart';
part 'product_template_model.g.dart';

@freezed
class ProductTemplateModel with _$ProductTemplateModel {
  const factory ProductTemplateModel({
    required int id,
    required String name,
    String? description,
    String? formula,
    String? unit,
    @Default(true) bool isActive,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default([]) List<ProductAttributeModel> attributes,
  }) = _ProductTemplateModel;

  factory ProductTemplateModel.fromJson(Map<String, dynamic> json) => _$ProductTemplateModelFromJson(json);
}

@freezed
class ProductAttributeModel with _$ProductAttributeModel {
  const factory ProductAttributeModel({
    required int id,
    required int productTemplateId,
    required String name,
    required String variable,
    required String type, // 'number', 'select', 'text'
    String? options, // JSON строка для select типа
    String? unit,
    @Default(false) bool isRequired,
    @Default(false) bool isInFormula,
    @Default(0) int sortOrder,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ProductAttributeModel;

  factory ProductAttributeModel.fromJson(Map<String, dynamic> json) => _$ProductAttributeModelFromJson(json);
}

@freezed
class ProductTemplateResponse with _$ProductTemplateResponse {
  const factory ProductTemplateResponse({
    required bool success,
    required ProductTemplateModel data,
  }) = _ProductTemplateResponse;

  factory ProductTemplateResponse.fromJson(Map<String, dynamic> json) => _$ProductTemplateResponseFromJson(json);
}

@freezed
class ProductTemplatesListResponse with _$ProductTemplatesListResponse {
  const factory ProductTemplatesListResponse({
    required bool success,
    required List<ProductTemplateModel> data,
  }) = _ProductTemplatesListResponse;

  factory ProductTemplatesListResponse.fromJson(Map<String, dynamic> json) => _$ProductTemplatesListResponseFromJson(json);
}
