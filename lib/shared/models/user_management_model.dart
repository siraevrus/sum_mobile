import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sum_warehouse/features/auth/domain/entities/user_entity.dart';
import 'package:sum_warehouse/shared/models/common_references.dart';

part 'user_management_model.freezed.dart';
part 'user_management_model.g.dart';

/// Расширенная модель пользователя для управления
@freezed
class UserManagementModel with _$UserManagementModel {
  const factory UserManagementModel({
    required int id,
    required String name,
    String? firstName,
    String? lastName,
    String? middleName,
    String? username,
    required String email,
    String? phone,
    required UserRole role,
    @JsonKey(name: 'company_id') int? companyId,
    @JsonKey(name: 'warehouse_id') int? warehouseId,
    @JsonKey(name: 'is_blocked') required bool isBlocked,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'updated_at') required String updatedAt,
    // Дополнительные поля
    CompanyReference? company,
    WarehouseReference? warehouse,
    @JsonKey(name: 'last_login') String? lastLogin,
  }) = _UserManagementModel;

  factory UserManagementModel.fromJson(Map<String, dynamic> json) =>
      _$UserManagementModelFromJson(json);
}

/// Запрос создания пользователя
@freezed
class CreateUserRequest with _$CreateUserRequest {
  const factory CreateUserRequest({
    required String firstName,
    required String lastName,
    String? middleName,
    String? username,
    required String email,
    required String password,
    required UserRole role,
    @JsonKey(name: 'company_id') int? companyId,
    @JsonKey(name: 'warehouse_id') int? warehouseId,
    String? phone,
    @JsonKey(name: 'is_blocked') bool? isBlocked,
  }) = _CreateUserRequest;

  factory CreateUserRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateUserRequestFromJson(json);
}

/// Запрос обновления пользователя
@freezed
class UpdateUserRequest with _$UpdateUserRequest {
  const factory UpdateUserRequest({
    String? firstName,
    String? lastName,
    String? middleName,
    String? username,
    String? email,
    String? password,
    UserRole? role,
    @JsonKey(name: 'company_id') int? companyId,
    @JsonKey(name: 'warehouse_id') int? warehouseId,
    String? phone,
    @JsonKey(name: 'is_blocked') bool? isBlocked,
  }) = _UpdateUserRequest;

  factory UpdateUserRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateUserRequestFromJson(json);
}

/// Статистика пользователей
@freezed
class UsersStatsModel with _$UsersStatsModel {
  const factory UsersStatsModel({
    @JsonKey(name: 'total_users') required int totalUsers,
    @JsonKey(name: 'active_users') required int activeUsers,
    @JsonKey(name: 'blocked_users') required int blockedUsers,
    @JsonKey(name: 'admins_count') required int adminsCount,
    @JsonKey(name: 'operators_count') required int operatorsCount,
    @JsonKey(name: 'warehouse_workers_count') required int warehouseWorkersCount,
    @JsonKey(name: 'managers_count') required int managersCount,
    @JsonKey(name: 'online_users') required int onlineUsers,
  }) = _UsersStatsModel;

  factory UsersStatsModel.fromJson(Map<String, dynamic> json) =>
      _$UsersStatsModelFromJson(json);
}

/// Ответ API для статистики пользователей
@freezed
class UsersStatsResponse with _$UsersStatsResponse {
  const factory UsersStatsResponse({
    required bool success,
    required UsersStatsModel data,
  }) = _UsersStatsResponse;

  factory UsersStatsResponse.fromJson(Map<String, dynamic> json) =>
      _$UsersStatsResponseFromJson(json);
}
