import 'package:freezed_annotation/freezed_annotation.dart';

part 'goods_in_transit_entity.freezed.dart';

/// Сущность товара в пути
@freezed
class GoodsInTransitEntity with _$GoodsInTransitEntity {
  const factory GoodsInTransitEntity({
    required int id,
    required int productId,
    required int fromWarehouseId,
    required int toWarehouseId,
    required int userId,
    required double quantity,
    required TransitStatus status,
    required TransitType type,
    String? documentNumber,
    String? description,
    String? transportInfo,
    String? driverInfo,
    DateTime? dispatchDate,
    DateTime? expectedArrivalDate,
    DateTime? actualArrivalDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    
    // Связанные объекты
    ProductEntity? product,
    WarehouseEntity? fromWarehouse,
    WarehouseEntity? toWarehouse,
    UserEntity? user,
    List<TransitTrackingEntity>? trackingEvents,
  }) = _GoodsInTransitEntity;
  
  const GoodsInTransitEntity._();
  
  /// Получить цвет статуса
  String get statusColor {
    switch (status) {
      case TransitStatus.planned:
        return '#718096'; // Серый
      case TransitStatus.dispatched:
        return '#3182CE'; // Синий
      case TransitStatus.inTransit:
        return '#D69E2E'; // Желтый
      case TransitStatus.arrived:
        return '#38A169'; // Зеленый
      case TransitStatus.delivered:
        return '#38A169'; // Зеленый
      case TransitStatus.cancelled:
        return '#E53E3E'; // Красный
      case TransitStatus.delayed:
        return '#E53E3E'; // Красный
    }
  }
  
  /// Получить иконку статуса
  String get statusIcon {
    switch (status) {
      case TransitStatus.planned:
        return 'schedule';
      case TransitStatus.dispatched:
        return 'local_shipping';
      case TransitStatus.inTransit:
        return 'directions_car';
      case TransitStatus.arrived:
        return 'place';
      case TransitStatus.delivered:
        return 'check_circle';
      case TransitStatus.cancelled:
        return 'cancel';
      case TransitStatus.delayed:
        return 'warning';
    }
  }
  
  /// Проверить просрочена ли поставка
  bool get isOverdue {
    if (expectedArrivalDate == null) return false;
    if (status == TransitStatus.delivered || status == TransitStatus.cancelled) {
      return false;
    }
    return DateTime.now().isAfter(expectedArrivalDate!);
  }
  
  /// Количество дней в пути
  int? get daysInTransit {
    if (dispatchDate == null) return null;
    final endDate = actualArrivalDate ?? DateTime.now();
    return endDate.difference(dispatchDate!).inDays;
  }
  
  /// Процент выполнения поставки
  double get progressPercentage {
    switch (status) {
      case TransitStatus.planned:
        return 0.0;
      case TransitStatus.dispatched:
        return 25.0;
      case TransitStatus.inTransit:
        return 50.0;
      case TransitStatus.arrived:
        return 75.0;
      case TransitStatus.delivered:
        return 100.0;
      case TransitStatus.cancelled:
        return 0.0;
      case TransitStatus.delayed:
        return 40.0;
    }
  }
  
  /// Можно ли обновить статус
  bool canUpdateStatus(String userRole) {
    if (userRole == 'admin') return true;
    if (userRole == 'warehouse_worker') {
      return status != TransitStatus.delivered && status != TransitStatus.cancelled;
    }
    return false;
  }
}

/// Сущность события отслеживания
@freezed
class TransitTrackingEntity with _$TransitTrackingEntity {
  const factory TransitTrackingEntity({
    required int id,
    required int goodsInTransitId,
    required int userId,
    required String event,
    required String description,
    String? location,
    String? notes,
    DateTime? createdAt,
    
    // Связанные объекты
    UserEntity? user,
  }) = _TransitTrackingEntity;
  
  const TransitTrackingEntity._();
  
  /// Получить цвет события
  String get eventColor {
    if (event.contains('dispatch') || event.contains('отправлен')) {
      return '#3182CE'; // Синий
    } else if (event.contains('arrive') || event.contains('прибыл')) {
      return '#38A169'; // Зеленый
    } else if (event.contains('delay') || event.contains('задержка')) {
      return '#E53E3E'; // Красный
    } else if (event.contains('update') || event.contains('обновление')) {
      return '#D69E2E'; // Желтый
    } else {
      return '#718096'; // Серый
    }
  }
}

/// Статус товара в пути
enum TransitStatus {
  planned,    // Запланировано
  dispatched, // Отправлено
  inTransit,  // В пути
  arrived,    // Прибыло
  delivered,  // Доставлено
  cancelled,  // Отменено
  delayed,    // Задержано
}

/// Тип перемещения
enum TransitType {
  transfer,   // Перемещение между складами
  delivery,   // Доставка клиенту
  return_,    // Возврат
  incoming,   // Входящая поставка
}

/// Расширения для статуса
extension TransitStatusExtension on TransitStatus {
  String get displayName {
    switch (this) {
      case TransitStatus.planned:
        return 'Запланировано';
      case TransitStatus.dispatched:
        return 'Отправлено';
      case TransitStatus.inTransit:
        return 'В пути';
      case TransitStatus.arrived:
        return 'Прибыло';
      case TransitStatus.delivered:
        return 'Доставлено';
      case TransitStatus.cancelled:
        return 'Отменено';
      case TransitStatus.delayed:
        return 'Задержано';
    }
  }
  
  String get code {
    switch (this) {
      case TransitStatus.planned:
        return 'planned';
      case TransitStatus.dispatched:
        return 'dispatched';
      case TransitStatus.inTransit:
        return 'in_transit';
      case TransitStatus.arrived:
        return 'arrived';
      case TransitStatus.delivered:
        return 'delivered';
      case TransitStatus.cancelled:
        return 'cancelled';
      case TransitStatus.delayed:
        return 'delayed';
    }
  }
  
  static TransitStatus fromCode(String code) {
    switch (code) {
      case 'planned':
        return TransitStatus.planned;
      case 'dispatched':
        return TransitStatus.dispatched;
      case 'in_transit':
        return TransitStatus.inTransit;
      case 'arrived':
        return TransitStatus.arrived;
      case 'delivered':
        return TransitStatus.delivered;
      case 'cancelled':
        return TransitStatus.cancelled;
      case 'delayed':
        return TransitStatus.delayed;
      default:
        throw ArgumentError('Unknown TransitStatus code: $code');
    }
  }
}

/// Расширения для типа перемещения
extension TransitTypeExtension on TransitType {
  String get displayName {
    switch (this) {
      case TransitType.transfer:
        return 'Перемещение';
      case TransitType.delivery:
        return 'Доставка';
      case TransitType.return_:
        return 'Возврат';
      case TransitType.incoming:
        return 'Поставка';
    }
  }
  
  String get code {
    switch (this) {
      case TransitType.transfer:
        return 'transfer';
      case TransitType.delivery:
        return 'delivery';
      case TransitType.return_:
        return 'return';
      case TransitType.incoming:
        return 'incoming';
    }
  }
  
  static TransitType fromCode(String code) {
    switch (code) {
      case 'transfer':
        return TransitType.transfer;
      case 'delivery':
        return TransitType.delivery;
      case 'return':
        return TransitType.return_;
      case 'incoming':
        return TransitType.incoming;
      default:
        throw ArgumentError('Unknown TransitType code: $code');
    }
  }
}

/// Временные сущности (заглушки)
@freezed
class ProductEntity with _$ProductEntity {
  const factory ProductEntity({
    required int id,
    required String name,
    required int productTemplateId,
    required String unit,
    String? description,
    String? producer,
    String? qrCode,
    @Default(true) bool isActive,
  }) = _ProductEntity;
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
class UserEntity with _$UserEntity {
  const factory UserEntity({
    required int id,
    required String name,
    required String email,
    String? role,
  }) = _UserEntity;
}
