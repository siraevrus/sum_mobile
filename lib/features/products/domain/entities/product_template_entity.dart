import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_template_entity.freezed.dart';

/// Сущность шаблона товара с динамическими характеристиками
@freezed
class ProductTemplateEntity with _$ProductTemplateEntity {
  const factory ProductTemplateEntity({
    required int id,
    required String name,
    required String unit, // Единица измерения (м3, шт, кг и т.д.)
    String? description,
    String? formula, // Формула для расчета (например, "length * width * height")
    @Default([]) List<TemplateAttributeEntity> attributes,
    @Default(true) bool isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _ProductTemplateEntity;
}

/// Сущность атрибута шаблона (характеристика товара)
@freezed
class TemplateAttributeEntity with _$TemplateAttributeEntity {
  const factory TemplateAttributeEntity({
    required int id,
    required int productTemplateId,
    required String name, // Отображаемое название (например, "Длина")
    required String variable, // Переменная для формул (например, "length")
    required AttributeType type,
    String? defaultValue,
    String? unit, // Единица измерения атрибута (см, мм, и т.д.)
    @Default(false) bool isRequired,
    @Default(false) bool isInFormula, // Используется ли в формулах расчета
    @Default(0) int sortOrder,
    List<String>? selectOptions, // Опции для select типа
    double? minValue, // Минимальное значение для number
    double? maxValue, // Максимальное значение для number
    String? validationPattern, // Regex для валидации text
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _TemplateAttributeEntity;
}

/// Типы атрибутов
enum AttributeType {
  /// Числовое значение
  number,
  /// Текстовое значение
  text,
  /// Выбор из списка
  select,
  /// Булево значение (да/нет)
  boolean,
  /// Дата
  date,
  /// Файл/изображение
  file,
}

/// Расширение для получения отображаемого названия типа
extension AttributeTypeExtension on AttributeType {
  String get displayName {
    switch (this) {
      case AttributeType.number:
        return 'Число';
      case AttributeType.text:
        return 'Текст';
      case AttributeType.select:
        return 'Выбор';
      case AttributeType.boolean:
        return 'Да/Нет';
      case AttributeType.date:
        return 'Дата';
      case AttributeType.file:
        return 'Файл';
    }
  }

  String get code {
    switch (this) {
      case AttributeType.number:
        return 'number';
      case AttributeType.text:
        return 'text';
      case AttributeType.select:
        return 'select';
      case AttributeType.boolean:
        return 'boolean';
      case AttributeType.date:
        return 'date';
      case AttributeType.file:
        return 'file';
    }
  }

  static AttributeType fromCode(String code) {
    switch (code) {
      case 'number':
        return AttributeType.number;
      case 'text':
        return AttributeType.text;
      case 'select':
        return AttributeType.select;
      case 'boolean':
        return AttributeType.boolean;
      case 'date':
        return AttributeType.date;
      case 'file':
        return AttributeType.file;
      default:
        throw ArgumentError('Unknown AttributeType code: $code');
    }
  }
}
