import 'package:sum_warehouse/shared/models/company_model.dart';
import 'package:sum_warehouse/shared/models/warehouse_model.dart';

/// Абстрактный репозиторий для работы с компаниями
abstract class CompaniesRepository {
  /// Получить список компаний
  Future<List<CompanyModel>> getCompanies({
    String? search,
    bool? isActive,
    bool showArchived = false,
    int page = 1,
    int perPage = 15,
  });
  
  /// Получить компанию по ID
  Future<CompanyModel> getCompanyById(int id);
  
  /// Создать компанию
  Future<CompanyModel> createCompany(CompanyFormModel company);
  
  /// Обновить компанию
  Future<CompanyModel> updateCompany(int id, CompanyFormModel company);
  
  /// Удалить компанию
  Future<void> deleteCompany(int id);
  
  /// Архивировать компанию
  Future<void> archiveCompany(int id);
  
  /// Восстановить компанию
  Future<void> restoreCompany(int id);
  
  /// Получить статистику компаний
  Future<List<CompanyStatsModel>> getCompaniesStats();
  
  /// Получить склады компании
  Future<List<WarehouseModel>> getCompanyWarehouses(int companyId);
}
