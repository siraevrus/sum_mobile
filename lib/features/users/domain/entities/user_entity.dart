import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sum_warehouse/features/auth/domain/entities/user_entity.dart' show UserRole;

part 'user_entity.freezed.dart';

/// Сущность пользователя в домене
@freezed
class UserEntity with _$UserEntity {
  const factory UserEntity({
    required int id,
    required String name,
    required String email,
    @Default(UserRole.operator) UserRole role,
    String? username,
    String? phone,
    int? companyId,
    int? warehouseId,
    @Default(false) bool isBlocked,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? firstName,
    String? lastName,
    String? middleName,
  }) = _UserEntity;
}
