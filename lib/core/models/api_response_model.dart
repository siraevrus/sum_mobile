import 'package:freezed_annotation/freezed_annotation.dart';

part 'api_response_model.freezed.dart';
part 'api_response_model.g.dart';

/// Базовая модель ответа API с обертками success/data
@Freezed(genericArgumentFactories: true)
class ApiResponse<T> with _$ApiResponse<T> {
  const factory ApiResponse({
    required bool success,
    T? data,
    String? message,
    @JsonKey(name: 'errors') Map<String, List<String>>? errors,
  }) = _ApiResponse<T>;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) =>
      _$ApiResponseFromJson(json, fromJsonT);
}

/// Модель ответа с пагинацией
@Freezed(genericArgumentFactories: true)
class PaginatedResponse<T> with _$PaginatedResponse<T> {
  const factory PaginatedResponse({
    required bool success,
    required List<T> data,
    required PaginationModel pagination,
    String? message,
  }) = _PaginatedResponse<T>;

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) =>
      _$PaginatedResponseFromJson(json, fromJsonT);
}

/// Модель пагинации
@freezed
class PaginationModel with _$PaginationModel {
  const factory PaginationModel({
    @JsonKey(name: 'current_page') required int currentPage,
    @JsonKey(name: 'last_page') required int lastPage,
    @JsonKey(name: 'per_page') required int perPage,
    required int total,
    @JsonKey(name: 'has_more_pages') @Default(false) bool hasMorePages,
  }) = _PaginationModel;

  factory PaginationModel.fromJson(Map<String, dynamic> json) =>
      _$PaginationModelFromJson(json);
}

/// Модель для Laravel пагинации с links и meta
@Freezed(genericArgumentFactories: true)
class LaravelPaginatedResponse<T> with _$LaravelPaginatedResponse<T> {
  const factory LaravelPaginatedResponse({
    required List<T> data,
    required LinksModel links,
    required MetaModel meta,
  }) = _LaravelPaginatedResponse<T>;

  factory LaravelPaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) =>
      _$LaravelPaginatedResponseFromJson(json, fromJsonT);
}

/// Модель ссылок пагинации Laravel
@freezed
class LinksModel with _$LinksModel {
  const factory LinksModel({
    String? first,
    String? last,
    String? prev,
    String? next,
  }) = _LinksModel;

  factory LinksModel.fromJson(Map<String, dynamic> json) =>
      _$LinksModelFromJson(json);
}

/// Модель мета информации пагинации Laravel
@freezed
class MetaModel with _$MetaModel {
  const factory MetaModel({
    @JsonKey(name: 'current_page') required int currentPage,
    @JsonKey(name: 'last_page') required int lastPage,
    @JsonKey(name: 'per_page') required int perPage,
    required int total,
  }) = _MetaModel;

  factory MetaModel.fromJson(Map<String, dynamic> json) =>
      _$MetaModelFromJson(json);
}
