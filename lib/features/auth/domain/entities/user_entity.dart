import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_entity.freezed.dart';

/// Domain entity для пользователя (чистая модель без зависимостей от внешних библиотек)
@freezed
class UserEntity with _$UserEntity {
  const factory UserEntity({
    required int id,
    required String name,
    required String email,
    required UserRole role,
    String? username,
    String? phone,
    int? companyId,
    int? warehouseId,
    required bool isBlocked,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? firstName,
    String? lastName,
    String? middleName,
  }) = _UserEntity;
}

/// Роли пользователей согласно ТЗ
enum UserRole {
  /// Администратор - полный доступ
  admin,
  /// Оператор ПК - товары/остатки/товар в пути  
  operator,
  /// Работник склада - запросы/остатки/товар в пути/реализация/приемка
  @JsonValue('warehouse_worker')
  warehouseWorker,
  /// Менеджер - запросы/остатки/товар в пути
  manager,
  /// Менеджер по продажам - продажи/клиенты
  @JsonValue('sales_manager')
  salesManager,
}

/// Состояние аутентификации
@freezed
class AuthState with _$AuthState {
  const factory AuthState.initial() = _Initial;
  const factory AuthState.loading() = _Loading;
  const factory AuthState.authenticated({
    required UserEntity user,
    required String token,
  }) = _Authenticated;
  const factory AuthState.unauthenticated() = _Unauthenticated;
  const factory AuthState.error(String message) = _Error;
}
