import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sum_warehouse/core/network/dio_client.dart';
import 'package:sum_warehouse/core/error/error_handler.dart';

part 'app_counters_remote_datasource.g.dart';

/// Интерфейс для работы с API счетчиков новых записей
abstract class AppCountersRemoteDataSource {
  /// Отметить открытие приложения
  Future<void> markAppOpened();

  /// Получить время последнего открытия приложения
  Future<Map<String, dynamic>> getLastOpened();

  /// Отметить просмотр раздела
  Future<Map<String, dynamic>> markSectionViewed(String section);

  /// Получить счетчик новых поступлений
  Future<Map<String, dynamic>> getReceiptsNewCount();

  /// Получить счетчик новых товаров в пути
  Future<Map<String, dynamic>> getProductsInTransitNewCount();

  /// Получить счетчик новых продаж
  Future<Map<String, dynamic>> getSalesNewCount();
}

/// Реализация API источника данных для счетчиков
class AppCountersRemoteDataSourceImpl implements AppCountersRemoteDataSource {
  final Dio _dio;

  AppCountersRemoteDataSourceImpl(this._dio);

  @override
  Future<void> markAppOpened() async {
    try {
      await _dio.post('/app/opened');
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> getLastOpened() async {
    try {
      final response = await _dio.get('/app/last-opened');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> markSectionViewed(String section) async {
    try {
      final response = await _dio.post(
        '/app/sections/viewed',
        data: {'section': section},
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> getReceiptsNewCount() async {
    try {
      final response = await _dio.get('/receipts/new-count');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> getProductsInTransitNewCount() async {
    try {
      final response = await _dio.get('/products-in-transit/new-count');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> getSalesNewCount() async {
    try {
      final response = await _dio.get('/sales/new-count');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Обработка ошибок API
  Exception _handleError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return Exception('Ошибка соединения с сервером');
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          final message = error.response?.data?['message'] ?? 'Неизвестная ошибка сервера';
          return Exception('Ошибка сервера ($statusCode): $message');
        case DioExceptionType.cancel:
          return Exception('Запрос отменен');
        case DioExceptionType.unknown:
          return Exception('Ошибка сети: ${error.message}');
        default:
          return Exception('Неизвестная ошибка: ${error.message}');
      }
    }
    return Exception('Неожиданная ошибка: $error');
  }
}

/// Provider для API источника данных счетчиков
@riverpod
AppCountersRemoteDataSource appCountersRemoteDataSource(AppCountersRemoteDataSourceRef ref) {
  final dio = ref.watch(dioClientProvider);
  return AppCountersRemoteDataSourceImpl(dio);
}


