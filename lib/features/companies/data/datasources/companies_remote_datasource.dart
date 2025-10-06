import 'package:dio/dio.dart';
import 'package:sum_warehouse/core/error/error_handler.dart';
import 'package:sum_warehouse/core/models/api_response_model.dart';
import 'package:sum_warehouse/shared/models/company_model.dart';

abstract class CompaniesRemoteDataSource {
  Future<PaginatedResponse<CompanyModel>> getCompanies({
    Map<String, dynamic>? queryParams,
  });
  Future<CompanyModel> getCompany(int id);
  Future<CompanyModel> createCompany(CreateCompanyRequest request);
  Future<CompanyModel> updateCompany(int id, UpdateCompanyRequest request);
  Future<void> deleteCompany(int id);
  Future<CompanyStats> getCompaniesStats();
  Future<SingleCompanyStats> getCompanyStats(int id);
  Future<void> archiveCompany(int id);
  Future<void> restoreCompany(int id);
}

class CompaniesRemoteDataSourceImpl implements CompaniesRemoteDataSource {
  final Dio _dio;

  CompaniesRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  @override
  Future<PaginatedResponse<CompanyModel>> getCompanies({
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      final response = await _dio.get(
        '/companies',
        queryParameters: queryParams,
      );
      
      if (response.statusCode == 200) {
        return PaginatedResponse<CompanyModel>.fromJson(
          response.data,
          (json) => CompanyModel.fromJson(json as Map<String, dynamic>),
        );
      } else {
        throw Exception('Failed to load companies: ${response.statusCode}');
      }
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }

  @override
  Future<CompanyModel> getCompany(int id) async {
    try {
      final response = await _dio.get('/companies/$id');
      
      if (response.statusCode == 200) {
        return CompanyModel.fromJson(response.data);
      } else if (response.statusCode == 404) {
        throw Exception('Company not found');
      } else {
        throw Exception('Failed to load company: ${response.statusCode}');
      }
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }

  @override
  Future<CompanyModel> createCompany(CreateCompanyRequest request) async {
    try {
      final response = await _dio.post(
        '/companies',
        data: request.toJson(),
      );
      
      if (response.statusCode == 201) {
        return CompanyModel.fromJson(response.data);
      } else if (response.statusCode == 422) {
        final Map<String, dynamic> errorJson = response.data;
        throw Exception('Validation error: ${errorJson['errors']}');
      } else {
        throw Exception('Failed to create company: ${response.statusCode}');
      }
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }

  @override
  Future<CompanyModel> updateCompany(int id, UpdateCompanyRequest request) async {
    try {
      final response = await _dio.put(
        '/companies/$id',
        data: request.toJson(),
      );
      
      if (response.statusCode == 200) {
        return CompanyModel.fromJson(response.data);
      } else if (response.statusCode == 404) {
        throw Exception('Company not found');
      } else if (response.statusCode == 422) {
        final Map<String, dynamic> errorJson = response.data;
        throw Exception('Validation error: ${errorJson['errors']}');
      } else {
        throw Exception('Failed to update company: ${response.statusCode}');
      }
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }

  @override
  Future<void> deleteCompany(int id) async {
    try {
      final response = await _dio.delete('/companies/$id');
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        return;
      } else if (response.statusCode == 404) {
        throw Exception('Company not found');
      } else {
        throw Exception('Failed to delete company: ${response.statusCode}');
      }
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }

  Future<void> archiveCompany(int id) async {
    try {
      final response = await _dio.put('/companies/$id/archive');
      
      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 404) {
        throw Exception('Company not found');
      } else {
        throw Exception('Failed to archive company: ${response.statusCode}');
      }
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }

  Future<void> restoreCompany(int id) async {
    try {
      final response = await _dio.put('/companies/$id/restore');
      
      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 404) {
        throw Exception('Company not found');
      } else {
        throw Exception('Failed to restore company: ${response.statusCode}');
      }
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }

  @override
  Future<CompanyStats> getCompaniesStats() async {
    try {
      final response = await _dio.get('/companies/stats');
      
      if (response.statusCode == 200) {
        return CompanyStats.fromJson(response.data);
      } else {
        throw Exception('Failed to load companies stats: ${response.statusCode}');
      }
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }

  @override
  Future<SingleCompanyStats> getCompanyStats(int id) async {
    try {
      final response = await _dio.get('/companies/$id/stats');
      
      if (response.statusCode == 200) {
        return SingleCompanyStats.fromJson(response.data);
      } else if (response.statusCode == 404) {
        throw Exception('Company not found');
      } else {
        throw Exception('Failed to load company stats: ${response.statusCode}');
      }
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }
}
