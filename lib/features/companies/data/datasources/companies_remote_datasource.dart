import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sum_warehouse/core/network/dio_client.dart';
import 'package:sum_warehouse/core/error/error_handler.dart';
import 'package:sum_warehouse/shared/models/company_model.dart';
import 'package:sum_warehouse/shared/models/warehouse_model.dart';

part 'companies_remote_datasource.g.dart';

/// Remote data source для компаний
abstract class CompaniesRemoteDataSource {
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
  
  /// Архивировать компанию
  Future<void> archiveCompany(int id);
  
  /// Восстановить компанию из архива
  Future<void> restoreCompany(int id);
  
  /// Получить статистику компаний
  Future<List<CompanyStatsModel>> getCompaniesStats();
  
  /// Получить склады компании
  Future<List<WarehouseModel>> getCompanyWarehouses(int companyId);
}

/// Реализация remote data source для компаний
class CompaniesRemoteDataSourceImpl implements CompaniesRemoteDataSource {
  final Dio _dio;
  
  CompaniesRemoteDataSourceImpl(this._dio);
  
  @override
  Future<List<CompanyModel>> getCompanies({
    String? search,
    bool? isActive,
    bool showArchived = false,
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };
      
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (isActive != null) queryParams['is_active'] = isActive;
      
      final response = await _dio.get('/companies', queryParameters: queryParams);
      final List<dynamic> data = response.data['data'] as List<dynamic>;
      
      final companies = data.map((json) => CompanyModel.fromJson(json as Map<String, dynamic>)).toList();
      
      // Фильтруем архивированные компании в зависимости от настройки
      if (!showArchived) {
        return companies.where((company) => !company.isArchived).toList();
      }
      
      return companies;
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }
  
  @override
  Future<CompanyModel> getCompanyById(int id) async {
    try {
      final response = await _dio.get('/companies/$id');
      final raw = response.data;
      // API часто возвращает { success: true, data: { ...company } }
      final Map<String, dynamic> json =
          raw is Map<String, dynamic>
              ? (raw['data'] is Map<String, dynamic> ? raw['data'] as Map<String, dynamic> : raw)
              : <String, dynamic>{};
      final company = CompanyModel.fromJson(json);
      
      // Проверяем, что компания не архивирована
      if (company.isArchived) {
        throw Exception('Компания архивирована');
      }
      
      return company;
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }
  
  @override
  Future<CompanyModel> createCompany(CompanyFormModel company) async {
    try {
      // Отправляем поля согласно спецификации (postal_address, phone_fax, general_director, ...)
      final payload = company.toCreateRequest().toJson();
      final response = await _dio.post('/companies', data: payload);
      final raw = response.data;
      final Map<String, dynamic> json =
          raw is Map<String, dynamic>
              ? (raw['data'] is Map<String, dynamic> ? raw['data'] as Map<String, dynamic> : raw)
              : <String, dynamic>{};
      return CompanyModel.fromJson(json);
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }
  
  @override
  Future<CompanyModel> updateCompany(int id, CompanyFormModel company) async {
    try {
      // Отправляем поля согласно спецификации (postal_address, phone_fax, general_director, ...)
      final payload = company.toUpdateRequest().toJson();
      final response = await _dio.put('/companies/$id', data: payload);
      // Defensive parsing: sometimes API may return partial/empty body.
      final data = response.data;
      // Log response for debugging
      try {
        print('🔵 companies.updateCompany response.data: $data');
      } catch (_) {}
      if (data is Map<String, dynamic>) {
        if (data['data'] is Map<String, dynamic>) {
          return CompanyModel.fromJson(data['data'] as Map<String, dynamic>);
        }
        if (data['id'] != null) {
          return CompanyModel.fromJson(data);
        }
      }

      // Fallback: fetch full company from server
      try {
        final fresh = await getCompanyById(id);
        return fresh;
      } catch (e) {
        // Log the error and rethrow
        print('🔴 Failed to GET company after update fallback: $e');
        throw ErrorHandler.handleError(e);
      }
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }
  
  @override
  Future<void> archiveCompany(int id) async {
    try {
      await _dio.post('/companies/$id/archive');
    } catch (e) {
      print('⚠️ API /companies/$id/archive не работает');
      throw ErrorHandler.handleError(e);
    }
  }

  @override
  Future<void> restoreCompany(int id) async {
    try {
      await _dio.post('/companies/$id/restore');
    } catch (e) {
      print('⚠️ API /companies/$id/restore не работает');
      throw ErrorHandler.handleError(e);
    }
  }
  
  @override
  Future<List<CompanyStatsModel>> getCompaniesStats() async {
    try {
      final response = await _dio.get('/companies/stats');
      final List<dynamic> data = response.data as List<dynamic>;
      
      return data.map((json) => CompanyStatsModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }
  
  @override
  Future<List<WarehouseModel>> getCompanyWarehouses(int companyId) async {
    try {
      final response = await _dio.get('/companies/$companyId/warehouses');
      final List<dynamic> data = response.data as List<dynamic>;
      
      return data.map((json) => WarehouseModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }
}

/// Provider для remote data source компаний
@riverpod
CompaniesRemoteDataSource companiesRemoteDataSource(CompaniesRemoteDataSourceRef ref) {
  final dio = ref.watch(dioClientProvider);
  return CompaniesRemoteDataSourceImpl(dio);
}

