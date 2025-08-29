import 'package:freezed_annotation/freezed_annotation.dart';

part 'api_response_model.freezed.dart';
part 'api_response_model.g.dart';

/// Общая модель ответа API для пагинированных данных (реальная структура API)
@Freezed(genericArgumentFactories: true)
class PaginatedResponse<T> with _$PaginatedResponse<T> {
  const factory PaginatedResponse({
    required List<T> data,
    PaginationLinks? links,
    PaginationMeta? meta,
    Pagination? pagination, // Для реального API
    bool? success, // Для реального API
  }) = _PaginatedResponse<T>;

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) {
    // Парсим реальную структуру API {success: true, data: [...], pagination: {...}}
    if (json.containsKey('success') && json.containsKey('data')) {
      final dataList = json['data'] as List<dynamic>;
      final parsedData = dataList.map((item) => fromJsonT(item)).toList();
      
      final paginationData = json['pagination'] as Map<String, dynamic>?;
      final pagination = paginationData != null ? Pagination.fromJson(paginationData) : null;
      
      return PaginatedResponse<T>(
        data: parsedData,
        success: json['success'] as bool?,
        pagination: pagination,
      );
    } else {
      // Парсим старую структуру для совместимости
      final dataList = json['data'] as List<dynamic>;
      final parsedData = dataList.map((item) => fromJsonT(item)).toList();
      
      return PaginatedResponse<T>(
        data: parsedData,
        links: json.containsKey('links') ? PaginationLinks.fromJson(json['links']) : null,
        meta: json.containsKey('meta') ? PaginationMeta.fromJson(json['meta']) : null,
      );
    }
  }
}

/// Модель ссылок пагинации
@freezed
class PaginationLinks with _$PaginationLinks {
  const factory PaginationLinks({
    String? first,
    String? last,
    String? prev,
    String? next,
  }) = _PaginationLinks;

  factory PaginationLinks.fromJson(Map<String, dynamic> json) => 
      _$PaginationLinksFromJson(json);
}

/// Модель метаданных пагинации
@freezed
class PaginationMeta with _$PaginationMeta {
  const factory PaginationMeta({
    @JsonKey(name: 'current_page') required int currentPage,
    @JsonKey(name: 'last_page') required int lastPage,
    @JsonKey(name: 'per_page') required int perPage,
    required int total,
  }) = _PaginationMeta;

  factory PaginationMeta.fromJson(Map<String, dynamic> json) => 
      _$PaginationMetaFromJson(json);
}

/// Общая модель ответа API с флагом успеха (альтернативный стиль)
@Freezed(genericArgumentFactories: true)
class SuccessResponse<T> with _$SuccessResponse<T> {
  const factory SuccessResponse({
    required bool success,
    String? message,
    T? data,
    Pagination? pagination,
  }) = _SuccessResponse<T>;

  factory SuccessResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) => 
      _$SuccessResponseFromJson(json, fromJsonT);
}

/// Альтернативная модель пагинации
@freezed
class Pagination with _$Pagination {
  const factory Pagination({
    @JsonKey(name: 'current_page') required int currentPage,
    @JsonKey(name: 'last_page') required int lastPage,
    @JsonKey(name: 'per_page') required int perPage,
    required int total,
    @JsonKey(name: 'has_more_pages') bool? hasMorePages,
  }) = _Pagination;

  factory Pagination.fromJson(Map<String, dynamic> json) => 
      _$PaginationFromJson(json);
}

/// Модель ошибки API
@freezed
class ApiErrorModel with _$ApiErrorModel {
  const factory ApiErrorModel({
    required String message,
    Map<String, List<String>>? errors, // Для валидационных ошибок
  }) = _ApiErrorModel;

  factory ApiErrorModel.fromJson(Map<String, dynamic> json) => 
      _$ApiErrorModelFromJson(json);
}

/// Модель простого ответа с сообщением
@freezed
class MessageResponse with _$MessageResponse {
  const factory MessageResponse({
    required String message,
  }) = _MessageResponse;

  factory MessageResponse.fromJson(Map<String, dynamic> json) => 
      _$MessageResponseFromJson(json);
}
