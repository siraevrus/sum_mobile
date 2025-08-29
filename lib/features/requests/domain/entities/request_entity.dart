import 'package:freezed_annotation/freezed_annotation.dart';

part 'request_entity.freezed.dart';

/// Сущность запроса складского работника
@freezed
class RequestEntity with _$RequestEntity {
  const factory RequestEntity({
    required int id,
    required int userId,
    required int warehouseId,
    required int productTemplateId,
    required String title,
    required String description,
    required double quantity,
    required RequestPriority priority,
    required RequestStatus status,
    String? adminNotes,
    DateTime? processedAt,
    int? processedByUserId,
    DateTime? createdAt,
    DateTime? updatedAt,
    
    // Связанные объекты
    UserEntity? user,
    WarehouseEntity? warehouse,
    ProductTemplateEntity? productTemplate,
    UserEntity? processedBy,
  }) = _RequestEntity;
  
  const RequestEntity._();
  
  /// Получить цвет статуса
  String get statusColor {
    switch (status) {
      case RequestStatus.pending:
        return '#E53E3E'; // Красный
      case RequestStatus.processing:
        return '#D69E2E'; // Желтый
      case RequestStatus.completed:
        return '#38A169'; // Зеленый
      case RequestStatus.rejected:
        return '#718096'; // Серый
    }
  }
  
  /// Получить цвет приоритета
  String get priorityColor {
    switch (priority) {
      case RequestPriority.low:
        return '#3182CE'; // Синий
      case RequestPriority.normal:
        return '#38A169'; // Зеленый
      case RequestPriority.high:
        return '#D69E2E'; // Желтый
      case RequestPriority.urgent:
        return '#E53E3E'; // Красный
    }
  }
  
  /// Проверить, может ли пользователь редактировать запрос
  bool canEdit(int currentUserId, String currentUserRole) {
    // Только создатель может редактировать pending запросы
    if (status == RequestStatus.pending && userId == currentUserId) {
      return true;
    }
    // Админы могут редактировать любые запросы
    if (currentUserRole == 'admin') {
      return true;
    }
    return false;
  }
  
  /// Проверить, может ли пользователь обрабатывать запрос
  bool canProcess(String currentUserRole) {
    return (currentUserRole == 'admin' || currentUserRole == 'warehouse_worker') &&
           status == RequestStatus.pending;
  }
}

/// Приоритет запроса
enum RequestPriority {
  low,
  normal,
  high,
  urgent,
}

/// Статус запроса
enum RequestStatus {
  pending,
  processing,
  completed,
  rejected,
}

/// Расширения для приоритета
extension RequestPriorityExtension on RequestPriority {
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
  
  String get code {
    switch (this) {
      case RequestPriority.low:
        return 'low';
      case RequestPriority.normal:
        return 'normal';
      case RequestPriority.high:
        return 'high';
      case RequestPriority.urgent:
        return 'urgent';
    }
  }
  
  static RequestPriority fromCode(String code) {
    switch (code) {
      case 'low':
        return RequestPriority.low;
      case 'normal':
        return RequestPriority.normal;
      case 'high':
        return RequestPriority.high;
      case 'urgent':
        return RequestPriority.urgent;
      default:
        throw ArgumentError('Unknown RequestPriority code: $code');
    }
  }
}

/// Расширения для статуса
extension RequestStatusExtension on RequestStatus {
  String get displayName {
    switch (this) {
      case RequestStatus.pending:
        return 'Ожидает';
      case RequestStatus.processing:
        return 'В обработке';
      case RequestStatus.completed:
        return 'Выполнен';
      case RequestStatus.rejected:
        return 'Отклонен';
    }
  }
  
  String get code {
    switch (this) {
      case RequestStatus.pending:
        return 'pending';
      case RequestStatus.processing:
        return 'processing';
      case RequestStatus.completed:
        return 'completed';
      case RequestStatus.rejected:
        return 'rejected';
    }
  }
  
  static RequestStatus fromCode(String code) {
    switch (code) {
      case 'pending':
        return RequestStatus.pending;
      case 'processing':
        return RequestStatus.processing;
      case 'completed':
        return RequestStatus.completed;
      case 'rejected':
        return RequestStatus.rejected;
      default:
        throw ArgumentError('Unknown RequestStatus code: $code');
    }
  }
}

/// Временные сущности (заглушки)
@freezed
class UserEntity with _$UserEntity {
  const factory UserEntity({
    required int id,
    required String name,
    required String email,
    String? role,
  }) = _UserEntity;
}

@freezed
class WarehouseEntity with _$WarehouseEntity {
  const factory WarehouseEntity({
    required int id,
    required String name,
    required String address,
    required int companyId,
    @Default(true) bool isActive,
  }) = _WarehouseEntity;
}

@freezed
class ProductTemplateEntity with _$ProductTemplateEntity {
  const factory ProductTemplateEntity({
    required int id,
    required String name,
    required String unit,
    String? description,
  }) = _ProductTemplateEntity;
}
