import 'package:freezed_annotation/freezed_annotation.dart';

part 'company_entity.freezed.dart';

@freezed
class CompanyEntity with _$CompanyEntity {
  const factory CompanyEntity({
    required int id,
    required String name,
    String? legalAddress,
    String? postalAddress,
    String? phoneFax,
    String? generalDirector,
    String? email,
    String? inn,
    String? kpp,
    String? ogrn,
    String? bank,
    String? accountNumber,
    String? correspondentAccount,
    String? bik,
    int? employeesCount,
    int? warehousesCount,
    @Default(false) bool isArchived,
    DateTime? archivedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _CompanyEntity;
}
