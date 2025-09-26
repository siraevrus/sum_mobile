import 'package:freezed_annotation/freezed_annotation.dart';

part 'warehouse_entity.freezed.dart';

/// Сущность склада в домене
@freezed
class WarehouseEntity with _$WarehouseEntity {
  const factory WarehouseEntity({
    required int id,
    required String name,
    required String address,
    required int companyId,
    @Default(true) bool isActive,
    String? phone,
    String? manager,
    String? notes,
    @Default(0) int productsCount,
    @Default(0) int employeesCount,
    @Default(0) int lowStockCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _WarehouseEntity;
}
