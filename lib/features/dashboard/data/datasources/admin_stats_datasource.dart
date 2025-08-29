import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sum_warehouse/core/network/dio_client.dart';
import 'package:sum_warehouse/shared/models/admin_stats_model.dart';

part 'admin_stats_datasource.g.dart';

/// Интерфейс для получения статистики администратора
abstract class AdminStatsDataSource {
  Future<ProductStatsResponse> getProductsStats();
  Future<SalesStatsResponse> getSalesStats();
  Future<UsersStatsResponse> getUsersStats();
  Future<WarehousesStatsResponse> getWarehousesStats();
}

/// Реализация удаленного источника данных для статистики админа
class AdminStatsRemoteDataSource implements AdminStatsDataSource {
  final Dio _dio;

  AdminStatsRemoteDataSource(this._dio);

  @override
  Future<ProductStatsResponse> getProductsStats() async {
    try {
      final response = await _dio.get('/products/stats');
      // API может возвращать данные в обертке {success: true, data: {...}}
      if (response.data is Map<String, dynamic> && response.data['success'] == true) {
        final productData = ProductStatsModel.fromJson(response.data['data']);
        return ProductStatsResponse(success: true, data: productData);
      } else {
        // Или напрямую данные
        final productData = ProductStatsModel.fromJson(response.data);
        return ProductStatsResponse(success: true, data: productData);
      }
    } on DioException catch (e) {
      print('⚠️ API /products/stats не работает: ${e.response?.statusCode} - ${e.message}.');
      throw Exception('Нет данных о товарах');
    }
  }

  @override
  Future<SalesStatsResponse> getSalesStats() async {
    try {
      final response = await _dio.get('/sales/stats');
      print('🟢 SalesStats API response: ${response.data}');
      
      // Попробуем разные варианты структуры ответа
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        
        // Если есть обертка success/data
        if (data.containsKey('success') && data.containsKey('data')) {
          return SalesStatsResponse.fromJson(data);
        } else {
          // Если данные напрямую
          return SalesStatsResponse(
            success: true,
            data: SalesStatsModel.fromJson(data),
          );
        }
      }
      
      return SalesStatsResponse(success: true, data: SalesStatsModel.fromJson(response.data));
    } on DioException catch (e) {
      print('⚠️ API /sales/stats не работает: ${e.response?.statusCode} - ${e.message}.');
      throw Exception('Нет данных о продажах');
    } catch (e) {
      print('⚠️ Ошибка парсинга /sales/stats: $e.');
      throw Exception('Нет данных о продажах');
    }
  }

  @override
  Future<UsersStatsResponse> getUsersStats() async {
    try {
      // API не предоставляет эндпоинт /users/stats, используем /users для получения базовой статистики
      final response = await _dio.get('/users');
      print('🟢 Users API response for stats: ${response.data}');
      
      final usersData = response.data is Map<String, dynamic> && response.data['data'] != null
          ? response.data['data'] as List<dynamic>
          : response.data as List<dynamic>;
      
      // Подсчитываем статистику на основе списка пользователей
      int total = usersData.length;
      int active = 0;
      int blocked = 0;
      Map<String, int> byRole = {};
      
      for (final user in usersData) {
        final userMap = user as Map<String, dynamic>;
        
        // Подсчет активных/заблокированных (предполагаем что есть поле is_active)
        if (userMap['is_active'] == true) {
          active++;
        } else {
          blocked++;
        }
        
        // Подсчет по ролям
        final role = userMap['role']?.toString() ?? 'unknown';
        byRole[role] = (byRole[role] ?? 0) + 1;
      }
      
      return UsersStatsResponse(
        success: true,
        data: UsersStatsModel(
          total: total,
          active: active,
          blocked: blocked,
          byRole: byRole,
        ),
      );
    } on DioException catch (e) {
      print('⚠️ API /users не работает: ${e.response?.statusCode} - ${e.message}.');
      throw Exception('Нет данных о пользователях');
    } catch (e) {
      print('⚠️ Ошибка обработки пользователей: $e.');
      throw Exception('Нет данных о пользователях');
    }
  }

  @override
  Future<WarehousesStatsResponse> getWarehousesStats() async {
    try {
      // API не предоставляет эндпоинт /warehouses/stats, используем /warehouses для получения базовой статистики
      final response = await _dio.get('/warehouses');
      print('🟢 Warehouses API response for stats: ${response.data}');
      
      final warehousesData = response.data is Map<String, dynamic> && response.data['data'] != null
          ? response.data['data'] as List<dynamic>
          : response.data as List<dynamic>;
      
      // Подсчитываем статистику на основе списка складов
      int total = warehousesData.length;
      int active = 0;
      int inactive = 0;
      
      for (final warehouse in warehousesData) {
        final warehouseMap = warehouse as Map<String, dynamic>;
        
        // Подсчет активных/неактивных
        if (warehouseMap['is_active'] == true) {
          active++;
        } else {
          inactive++;
        }
      }
      
      return WarehousesStatsResponse(
        success: true,
        data: WarehousesStatsModel(
          total: total,
          active: active,
          inactive: inactive,
        ),
      );
    } on DioException catch (e) {
      print('⚠️ API /warehouses не работает: ${e.response?.statusCode} - ${e.message}.');
      throw Exception('Нет данных о складах');
    } catch (e) {
      print('⚠️ Ошибка обработки складов: $e.');
      throw Exception('Нет данных о складах');
    }
  }
}

/// Провайдер для AdminStatsDataSource
@riverpod
AdminStatsDataSource adminStatsDataSource(AdminStatsDataSourceRef ref) {
  final dio = ref.watch(dioClientProvider);
  return AdminStatsRemoteDataSource(dio);
}
