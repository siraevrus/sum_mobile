import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sum_warehouse/shared/models/common_references.dart';

part 'request_model.freezed.dart';
part 'request_model.g.dart';

/// Модель запроса
@freezed
class RequestModel with _$RequestModel {
  const factory RequestModel({
    required int id,
    required String title,
    String? description,
    required double quantity,
    @JsonKey(name: 'priority') required RequestPriority priority,
    required String status,
    WarehouseReference? warehouse,
    UserReference? user,
    @JsonKey(name: 'product_template') ProductTemplateReference? productTemplate,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'updated_at') required String updatedAt,
  }) = _RequestModel;

  factory RequestModel.fromJson(Map<String, dynamic> json) => _requestModelFromJsonSafe(json);
}

RequestModel _requestModelFromJsonSafe(Map<String, dynamic> json) {
  return RequestModel(
    id: json['id'] as int,
    title: json['title'] as String,
    description: json['description'] as String?,
    quantity: _parseDouble(json['quantity']),
    priority: RequestPriority.values.firstWhere(
      (e) => e.name == (json['priority'] as String?),
      orElse: () => RequestPriority.normal,
    ),
    status: json['status'] as String,
    warehouse: json['warehouse'] != null ? WarehouseReference.fromJson(json['warehouse'] as Map<String, dynamic>) : null,
    user: json['user'] != null ? UserReference.fromJson(json['user'] as Map<String, dynamic>) : null,
    productTemplate: json['product_template'] != null ? ProductTemplateReference.fromJson(json['product_template'] as Map<String, dynamic>) : null,
    createdAt: json['created_at'] as String,
    updatedAt: json['updated_at'] as String,
  );
}

/// Безопасный парсер double из dynamic (может быть String или num)
double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

// ProductTemplateReference moved to common_references.dart

/// Приоритет запроса
@JsonEnum(fieldRename: FieldRename.snake)
enum RequestPriority {
  @JsonValue('low')
  low,
  @JsonValue('normal')
  normal,
  @JsonValue('high')
  high,
  @JsonValue('urgent')
  urgent;

  String get displayName {
    switch (this) {
      case RequestPriority.low:
        return 'Низкий';
      case RequestPriority.normal:
        return 'Обычный';
      case RequestPriority.high:
        return 'Высокий';
      case RequestPriority.urgent:
        return 'Срочный';
    }
  }

  String get colorCode {
    switch (this) {
      case RequestPriority.low:
        return '#6C757D';
      case RequestPriority.normal:
        return '#007BFF';
      case RequestPriority.high:
        return '#FFC107';
      case RequestPriority.urgent:
        return '#DC3545';
    }
  }
}

/// Запрос создания запроса
@freezed
class CreateRequestRequest with _$CreateRequestRequest {
  const factory CreateRequestRequest({
    @JsonKey(name: 'warehouse_id') required int warehouseId,
    @JsonKey(name: 'product_template_id') required int productTemplateId,
    required String title,
    required int quantity, // Изменено с double на int для отправки без .0
    required RequestPriority priority,
    String? description,
    String? status,
    @Default({}) Map<String, dynamic> attributes,
  }) = _CreateRequestRequest;

  factory CreateRequestRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateRequestRequestFromJson(json);
}

/// Запрос обновления запроса
@freezed
class UpdateRequestRequest with _$UpdateRequestRequest {
  const factory UpdateRequestRequest({
    @JsonKey(name: 'warehouse_id') int? warehouseId,
    @JsonKey(name: 'product_template_id') int? productTemplateId,
    String? title,
    int? quantity, // Изменено с double на int для отправки без .0
    RequestPriority? priority,
    String? description,
    String? status,
    Map<String, dynamic>? attributes,
  }) = _UpdateRequestRequest;

  factory UpdateRequestRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateRequestRequestFromJson(json);
}

/// Запрос одобрения запроса
@freezed
class ApproveRequestRequest with _$ApproveRequestRequest {
  const factory ApproveRequestRequest({
    String? notes,
  }) = _ApproveRequestRequest;

  factory ApproveRequestRequest.fromJson(Map<String, dynamic> json) =>
      _$ApproveRequestRequestFromJson(json);
}