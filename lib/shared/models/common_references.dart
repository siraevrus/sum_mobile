import 'package:freezed_annotation/freezed_annotation.dart';

part 'common_references.freezed.dart';
part 'common_references.g.dart';

/// Ссылка на товар
@freezed
class ProductReference with _$ProductReference {
  const factory ProductReference({
    required int id,
    String? name,
  }) = _ProductReference;

  factory ProductReference.fromJson(Map<String, dynamic> json) =>
      _$ProductReferenceFromJson(json);
}

/// Ссылка на склад
@freezed
class WarehouseReference with _$WarehouseReference {
  const factory WarehouseReference({
    required int id,
    String? name,
  }) = _WarehouseReference;

  factory WarehouseReference.fromJson(Map<String, dynamic> json) =>
      _$WarehouseReferenceFromJson(json);
}

/// Ссылка на пользователя
@freezed
class UserReference with _$UserReference {
  const factory UserReference({
    required int id,
    String? name,
  }) = _UserReference;

  factory UserReference.fromJson(Map<String, dynamic> json) =>
      _$UserReferenceFromJson(json);
}

/// Ссылка на компанию
@freezed
class CompanyReference with _$CompanyReference {
  const factory CompanyReference({
    required int id,
    String? name,
  }) = _CompanyReference;

  factory CompanyReference.fromJson(Map<String, dynamic> json) =>
      _$CompanyReferenceFromJson(json);
}

/// Ссылка на шаблон товара
@freezed
class ProductTemplateReference with _$ProductTemplateReference {
  const factory ProductTemplateReference({
    required int id,
    String? name,
    String? unit,
  }) = _ProductTemplateReference;

  factory ProductTemplateReference.fromJson(Map<String, dynamic> json) =>
      _$ProductTemplateReferenceFromJson(json);
}

/// Ссылка на производителя
@freezed
class ProducerReference with _$ProducerReference {
  const factory ProducerReference({
    required int id,
    String? name,
  }) = _ProducerReference;

  factory ProducerReference.fromJson(Map<String, dynamic> json) =>
      _$ProducerReferenceFromJson(json);
}


