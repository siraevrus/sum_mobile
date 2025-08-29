import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sum_warehouse/features/products/domain/entities/product_template_entity.dart';

part 'product_template_model.freezed.dart';
part 'product_template_model.g.dart';

/// Модель шаблона товара для работы с API
@freezed
class ProductTemplateModel with _$ProductTemplateModel {
  const factory ProductTemplateModel({
    required int id,
    required String name,
    required String unit,
    String? description,
    String? formula,
    @Default([]) List<TemplateAttributeModel> attributes,
    @Default(true) @JsonKey(name: 'is_active') bool isActive,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _ProductTemplateModel;

  const ProductTemplateModel._();

  /// Создание из JSON
  factory ProductTemplateModel.fromJson(Map<String, dynamic> json) =>
      _$ProductTemplateModelFromJson(json);

  /// Конвертация в Entity
  ProductTemplateEntity toEntity() {
    return ProductTemplateEntity(
      id: id,
      name: name,
      unit: unit,
      description: description,
      formula: formula,
      attributes: attributes.map((attr) => attr.toEntity()).toList(),
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Создание из Entity
  factory ProductTemplateModel.fromEntity(ProductTemplateEntity entity) {
    return ProductTemplateModel(
      id: entity.id,
      name: entity.name,
      unit: entity.unit,
      description: entity.description,
      formula: entity.formula,
      attributes: entity.attributes.map((attr) => TemplateAttributeModel.fromEntity(attr)).toList(),
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}

/// Модель атрибута шаблона
@freezed
class TemplateAttributeModel with _$TemplateAttributeModel {
  const factory TemplateAttributeModel({
    required int id,
    @JsonKey(name: 'product_template_id') required int productTemplateId,
    required String name,
    required String variable,
    required String type, // Сериализуем как строку
    @JsonKey(name: 'default_value') String? defaultValue,
    dynamic value, // Поле value из API может содержать опции для select
    dynamic options, // Поле options из API для select-атрибутов (может быть String или List)
    String? unit,
    @Default(false) @JsonKey(name: 'is_required') bool isRequired,
    @Default(false) @JsonKey(name: 'is_in_formula') bool isInFormula,
    @Default(0) @JsonKey(name: 'sort_order') int sortOrder,
    @JsonKey(name: 'select_options') List<String>? selectOptions,
    @JsonKey(name: 'min_value') double? minValue,
    @JsonKey(name: 'max_value') double? maxValue,
    @JsonKey(name: 'validation_pattern') String? validationPattern,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _TemplateAttributeModel;

  const TemplateAttributeModel._();

  /// Создание из JSON
  factory TemplateAttributeModel.fromJson(Map<String, dynamic> json) =>
      _$TemplateAttributeModelFromJson(json);

  /// Получить тип как enum
  AttributeType get attributeType => AttributeTypeExtension.fromCode(type);

  /// Конвертация в Entity
  TemplateAttributeEntity toEntity() {
    // Для select атрибутов ищем опции в разных полях
    List<String>? parsedOptions = selectOptions;
    
    if (parsedOptions == null && type == 'select') {
      // Сначала проверяем поле options
      if (options != null) {
        parsedOptions = _parseSelectOptions(options);
      }
      // Если options пустое, проверяем поле value
      else if (value != null) {
        parsedOptions = _parseSelectOptions(value);
      }
    }
    
    return TemplateAttributeEntity(
      id: id,
      productTemplateId: productTemplateId,
      name: name,
      variable: variable,
      type: attributeType,
      defaultValue: defaultValue,
      unit: unit,
      isRequired: isRequired,
      isInFormula: isInFormula,
      sortOrder: sortOrder,
      selectOptions: parsedOptions,
      minValue: minValue,
      maxValue: maxValue,
      validationPattern: validationPattern,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Создание из Entity
  factory TemplateAttributeModel.fromEntity(TemplateAttributeEntity entity) {
    return TemplateAttributeModel(
      id: entity.id,
      productTemplateId: entity.productTemplateId,
      name: entity.name,
      variable: entity.variable,
      type: entity.type.code,
      defaultValue: entity.defaultValue,
      unit: entity.unit,
      isRequired: entity.isRequired,
      isInFormula: entity.isInFormula,
      sortOrder: entity.sortOrder,
      selectOptions: entity.selectOptions,
      minValue: entity.minValue,
      maxValue: entity.maxValue,
      validationPattern: entity.validationPattern,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}

/// Модель для создания/обновления шаблона
@freezed
class CreateProductTemplateModel with _$CreateProductTemplateModel {
  const factory CreateProductTemplateModel({
    required String name,
    required String unit,
    String? description,
    String? formula,
    @Default([]) List<CreateTemplateAttributeModel> attributes,
    @Default(true) @JsonKey(name: 'is_active') bool isActive,
  }) = _CreateProductTemplateModel;

  /// Создание из JSON
  factory CreateProductTemplateModel.fromJson(Map<String, dynamic> json) =>
      _$CreateProductTemplateModelFromJson(json);
}

/// Модель для создания/обновления атрибута шаблона
@freezed
class CreateTemplateAttributeModel with _$CreateTemplateAttributeModel {
  const factory CreateTemplateAttributeModel({
    required String name,
    required String variable,
    required String type,
    @JsonKey(name: 'default_value') String? defaultValue,
    String? unit,
    @Default(false) @JsonKey(name: 'is_required') bool isRequired,
    @Default(false) @JsonKey(name: 'is_in_formula') bool isInFormula,
    @Default(0) @JsonKey(name: 'sort_order') int sortOrder,
    @JsonKey(name: 'select_options') List<String>? selectOptions,
    @JsonKey(name: 'min_value') double? minValue,
    @JsonKey(name: 'max_value') double? maxValue,
    @JsonKey(name: 'validation_pattern') String? validationPattern,
  }) = _CreateTemplateAttributeModel;

  /// Создание из JSON
  factory CreateTemplateAttributeModel.fromJson(Map<String, dynamic> json) =>
      _$CreateTemplateAttributeModelFromJson(json);
}

/// Парсинг опций для select атрибутов
List<String>? _parseSelectOptions(dynamic value) {
  if (value == null) return null;
  
  // Если это уже список строк
  if (value is List<String>) return value;
  
  // Если это список с любыми типами, конвертируем в строки
  if (value is List) {
    return value.map((e) => e.toString()).toList();
  }
  
  // Если это строка с разделителями (например, "брус, доску, брусок, вагонку, блок-хаус, обапол,горбыль.")
  if (value is String && value.isNotEmpty) {
    // Убираем точку в конце если есть, разбиваем по запятой
    String cleanValue = value.trim();
    if (cleanValue.endsWith('.')) {
      cleanValue = cleanValue.substring(0, cleanValue.length - 1);
    }
    
    return cleanValue
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }
  
  return null;
}
