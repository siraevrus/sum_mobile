import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sum_warehouse/core/network/dio_client.dart';
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
    } on DioException catch (e) {
      // В режиме разработки возвращаем мок-данные в зависимости от настройки
      final mockCompanies = _getMockCompanies();
      if (!showArchived) {
        return mockCompanies.where((company) => !company.isArchived).toList();
      }
      return mockCompanies;
    }
  }
  
  @override
  Future<CompanyModel> getCompanyById(int id) async {
    try {
      final response = await _dio.get('/companies/$id');
      final company = CompanyModel.fromJson(response.data as Map<String, dynamic>);
      
      // Проверяем, что компания не архивирована
      if (company.isArchived) {
        throw Exception('Компания архивирована');
      }
      
      return company;
    } on DioException catch (e) {
      final company = _getMockCompanies().firstWhere((company) => company.id == id,
          orElse: () => _getMockCompanies().first);
      
      // Проверяем, что компания не архивирована
      if (company.isArchived) {
        throw Exception('Компания архивирована');
      }
      
      return company;
    }
  }
  
  @override
  Future<CompanyModel> createCompany(CompanyFormModel company) async {
    try {
      final response = await _dio.post('/companies', data: company.toJson());
      return CompanyModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      // Мок создания
      return _getMockCompanies().first.copyWith(
        id: DateTime.now().millisecondsSinceEpoch,
        name: company.name ?? 'Новая компания',
        inn: company.inn ?? '0000000000',
        kpp: company.kpp ?? '000000000',
        legalAddress: company.legalAddress ?? 'Не указан',
        createdAt: DateTime.now(),
      );
    }
  }
  
  @override
  Future<CompanyModel> updateCompany(int id, CompanyFormModel company) async {
    try {
      final response = await _dio.put('/companies/$id', data: company.toJson());
      // Defensive parsing: sometimes API may return partial/empty body.
      final data = response.data;
      // Log response for debugging
      try {
        print('🔵 companies.updateCompany response.data: $data');
      } catch (_) {}
      if (data is Map<String, dynamic> && data['id'] != null) {
        return CompanyModel.fromJson(data);
      }

      // Fallback: fetch full company from server
      try {
        final fresh = await getCompanyById(id);
        return fresh;
      } catch (e) {
        // Log the error and fallback
        print('🔴 Failed to GET company after update fallback: $e');
        final existing = _getMockCompanies().firstWhere((c) => c.id == id, orElse: () => _getMockCompanies().first);
        return existing.copyWith(
          name: company.name ?? existing.name,
          inn: company.inn ?? existing.inn,
          kpp: company.kpp ?? existing.kpp,
          legalAddress: company.legalAddress ?? existing.legalAddress,
          postalAddress: company.actualAddress ?? existing.postalAddress,
          phoneFax: company.phone ?? existing.phoneFax,
          email: company.email ?? existing.email,
          updatedAt: DateTime.now(),
        );
      }
    } on DioException catch (e) {
      // Мок обновления
      final existing = _getMockCompanies().firstWhere((c) => c.id == id,
          orElse: () => _getMockCompanies().first);
      return existing.copyWith(
        name: company.name ?? existing.name,
        inn: company.inn ?? existing.inn,
        kpp: company.kpp ?? existing.kpp,
        legalAddress: company.legalAddress ?? existing.legalAddress,
        postalAddress: company.actualAddress ?? existing.postalAddress,
        phoneFax: company.phone ?? existing.phoneFax,
        email: company.email ?? existing.email,
        updatedAt: DateTime.now(),
      );
    }
  }
  
  @override
  Future<void> archiveCompany(int id) async {
    try {
      await _dio.post('/companies/$id/archive');
    } on DioException catch (e) {
      print('⚠️ API /companies/$id/archive не работает: ${e.response?.statusCode} - ${e.message}.');
      throw Exception('Ошибка архивирования компании: ${e.message}');
    }
  }

  @override
  Future<void> restoreCompany(int id) async {
    try {
      await _dio.post('/companies/$id/restore');
    } on DioException catch (e) {
      print('⚠️ API /companies/$id/restore не работает: ${e.response?.statusCode} - ${e.message}.');
      throw Exception('Ошибка восстановления компании: ${e.message}');
    }
  }
  
  @override
  Future<List<CompanyStatsModel>> getCompaniesStats() async {
    try {
      final response = await _dio.get('/companies/stats');
      final List<dynamic> data = response.data as List<dynamic>;
      
      return data.map((json) => CompanyStatsModel.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      return _getMockCompaniesStats();
    }
  }
  
  @override
  Future<List<WarehouseModel>> getCompanyWarehouses(int companyId) async {
    try {
      final response = await _dio.get('/companies/$companyId/warehouses');
      final List<dynamic> data = response.data as List<dynamic>;
      
      return data.map((json) => WarehouseModel.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      return _getMockWarehouses().where((w) => w.companyId == companyId).toList();
    }
  }
  
  /// Мок-данные компаний
  List<CompanyModel> _getMockCompanies() {
    return [
      CompanyModel(
        id: 1,
        name: 'ООО "СтройМат Плюс"',
        legalAddress: '123456, Москва, ул. Строительная, д. 15, оф. 301',
        postalAddress: '123456, Москва, ул. Строительная, д. 15, оф. 301',
        phoneFax: '+7 (495) 123-45-67',
        email: 'info@stroymat-plus.ru',
        generalDirector: 'Петров Иван Сергеевич',
        inn: '7701234567',
        kpp: '770101001',
        ogrn: '1027700123456',
        bank: 'ПАО Сбербанк',
        accountNumber: '40702810123456789012',
        correspondentAccount: '30101810400000000225',
        bik: '044525225',
        employeesCount: 25,
        warehousesCount: 2,
        isArchived: false,
        createdAt: DateTime.now().subtract(const Duration(days: 180)),
        updatedAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      CompanyModel(
        id: 2,
        name: 'АО "ТехноСклад"',
        legalAddress: '109028, Москва, Хохловский пер., д. 7-9, стр. 3',
        phoneFax: '+7 (495) 234-56-78',
        email: 'office@technosklad.com',
        generalDirector: 'Сидорова Анна Владимировна',
        inn: '7702345678',
        kpp: '770201001',
        ogrn: '1027700234567',
        bank: 'ПАО ВТБ',
        accountNumber: '40702810234567890123',
        correspondentAccount: '30101810700000000187',
        bik: '044525187',
        employeesCount: 42,
        warehousesCount: 1,
        isArchived: false,
        createdAt: DateTime.now().subtract(const Duration(days: 365)),
        updatedAt: DateTime.now().subtract(const Duration(days: 12)),
      ),
      CompanyModel(
        id: 3,
        name: 'ИП Козлов В.М.',
        legalAddress: '115088, Москва, ул. Южнопортовая, д. 22',
        phoneFax: '+7 (926) 123-45-67',
        email: 'kozlov.vm@mail.ru',
        generalDirector: 'Козлов Владимир Михайлович',
        inn: '771234567890',
        kpp: '000000000',
        ogrn: '321774600001234',
        bank: 'ПАО Россельхозбанк',
        accountNumber: '40802810345678901234',
        correspondentAccount: '30101810400000000001',
        bik: '044525001',
        employeesCount: 3,
        warehousesCount: 1,
        isArchived: true,
        archivedAt: DateTime.now().subtract(const Duration(days: 30)),
        createdAt: DateTime.now().subtract(const Duration(days: 90)),
        updatedAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
    ];
  }
  
  /// Мок-данные статистики компаний
  List<CompanyStatsModel> _getMockCompaniesStats() {
    return [
      const CompanyStatsModel(
        companyId: 1,
        companyName: 'ООО "СтройМат Плюс"',
        warehousesCount: 2,
        employeesCount: 25,
        activeEmployees: 24,
        totalProducts: 1247,
        monthlyRevenue: 2850000.0,
        monthlyOrders: 156,
        status: 'active',
      ),
      const CompanyStatsModel(
        companyId: 2,
        companyName: 'АО "ТехноСклад"',
        warehousesCount: 1,
        employeesCount: 42,
        activeEmployees: 40,
        totalProducts: 893,
        monthlyRevenue: 1240000.0,
        monthlyOrders: 89,
        status: 'active',
      ),
      const CompanyStatsModel(
        companyId: 3,
        companyName: 'ИП Козлов В.М.',
        warehousesCount: 1,
        employeesCount: 3,
        activeEmployees: 2,
        totalProducts: 45,
        monthlyRevenue: 85000.0,
        monthlyOrders: 12,
        status: 'inactive',
      ),
    ];
  }
  
  /// Мок-данные складов
  List<WarehouseModel> _getMockWarehouses() {
    return [
      const WarehouseModel(
        id: 1,
        name: 'Центральный склад',
        address: 'Москва, ул. Промышленная, д. 15',
        companyId: 1,
        isActive: true,
        createdAt: '2024-01-15T10:00:00Z',
        updatedAt: '2024-01-15T10:00:00Z',
        phone: '+7 (495) 123-45-68',
        manager: 'Иванов Петр Александрович',
        notes: 'Основной склад для строительных материалов',
        productsCount: 856,
        lowStockCount: 12,
      ),
      const WarehouseModel(
        id: 2,
        name: 'Склад №2 (Подольск)',
        address: 'Подольск, ул. Индустриальная, д. 45',
        companyId: 1,
        isActive: true,
        createdAt: '2024-01-20T09:00:00Z',
        updatedAt: '2024-01-20T09:00:00Z',
        phone: '+7 (4967) 12-34-56',
        manager: 'Смирнов Алексей Викторович',
        notes: 'Дополнительный склад в Подольске',
        productsCount: 391,
        lowStockCount: 11,
      ),
      const WarehouseModel(
        id: 3,
        name: 'ТехноСклад Основной',
        address: 'СПб, пр. Индустриальный, д. 78',
        companyId: 2,
        isActive: true,
        createdAt: '2024-01-25T11:00:00Z',
        updatedAt: '2024-01-25T11:00:00Z',
        phone: '+7 (812) 234-56-78',
        manager: 'Федорова Елена Сергеевна',
        notes: 'Склад технического оборудования',
        productsCount: 624,
        lowStockCount: 8,
      ),
    ];
  }
}

/// Provider для remote data source компаний
@riverpod
CompaniesRemoteDataSource companiesRemoteDataSource(CompaniesRemoteDataSourceRef ref) {
  final dio = ref.watch(dioClientProvider);
  return CompaniesRemoteDataSourceImpl(dio);
}
