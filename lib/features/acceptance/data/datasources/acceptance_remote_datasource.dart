import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sum_warehouse/core/network/dio_client.dart';
import 'package:sum_warehouse/core/models/api_response_model.dart';
import 'package:sum_warehouse/features/acceptance/data/models/acceptance_model.dart';

part 'acceptance_remote_datasource.g.dart';

/// Интерфейс для работы с API товаров приемки
abstract class AcceptanceRemoteDataSource {
  Future<PaginatedResponse<AcceptanceModel>> getProducts([AcceptanceFilters? filters]);
  Future<AcceptanceModel> getProduct(int id);
  Future<AcceptanceModel> createProduct(CreateAcceptanceRequest request);
  Future<AcceptanceModel> updateProduct(int id, UpdateAcceptanceRequest request);
  Future<void> deleteProduct(int id);
}

/// Реализация API источника данных для товаров приемки
class AcceptanceRemoteDataSourceImpl implements AcceptanceRemoteDataSource {
  final Dio _dio;
  
  AcceptanceRemoteDataSourceImpl(this._dio);

  @override
  Future<PaginatedResponse<AcceptanceModel>> getProducts([AcceptanceFilters? filters]) async {
    try {
      final queryParams = filters?.toQueryParams() ?? {'page': 1, 'per_page': 15};
      
      // Добавляем статус for_receipt по умолчанию для раздела "Приемка"
      if (!queryParams.containsKey('status')) {
        queryParams['status'] = 'for_receipt';
      }
      
      // include не нужен — API уже возвращает связанные объекты
      
      print('🔵 Запрос на /products (приемка) с параметрами: $queryParams');
      final response = await _dio.get('/products', queryParameters: queryParams);
      
      print('🔵 Ответ API /products (приемка): ${response.data.toString().substring(0, response.data.toString().length > 500 ? 500 : response.data.toString().length)}...');
      
      return PaginatedResponse<AcceptanceModel>.fromJson(
        response.data,
        (json) {
          print('🔵 Парсинг товара приемки: $json');
          return AcceptanceModel.fromJson(json as Map<String, dynamic>);
        },
      );
    } catch (e) {
      print('🔴 Ошибка в getProducts (приемка): $e');
      throw _handleError(e);
    }
  }

  @override
  Future<AcceptanceModel> getProduct(int id) async {
    try {
      final response = await _dio.get('/products/$id', queryParameters: {
        'include': 'template,warehouse,creator,producer'
      });
      return AcceptanceModel.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<AcceptanceModel> createProduct(CreateAcceptanceRequest request) async {
    try {
      print('🔵 Создание товара приемки: ${request.toJson()}');
      final response = await _dio.post('/products', data: request.toJson());
      
      print('🔵 Ответ создания товара приемки: ${response.data}');
      
      return AcceptanceModel.fromJson(response.data['product']);
    } catch (e) {
      print('🔴 Ошибка создания товара приемки: $e');
      throw _handleError(e);
    }
  }

  @override
  Future<AcceptanceModel> updateProduct(int id, UpdateAcceptanceRequest request) async {
    try {
      print('🔵 Обновление товара приемки $id: ${request.toJson()}');
      final response = await _dio.put('/products/$id', data: request.toJson());
      
      print('🔵 Ответ обновления товара приемки: ${response.data}');
      
      return AcceptanceModel.fromJson(response.data['product']);
    } catch (e) {
      print('🔴 Ошибка обновления товара приемки: $e');
      throw _handleError(e);
    }
  }

  @override
  Future<void> deleteProduct(int id) async {
    try {
      print('🔵 Удаление товара приемки $id');
      await _dio.delete('/products/$id');
      print('🔵 Товар приемки $id успешно удален');
    } catch (e) {
      print('🔴 Ошибка удаления товара приемки: $e');
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

/// Provider для API источника данных товаров приемки
@riverpod
AcceptanceRemoteDataSource acceptanceRemoteDataSource(AcceptanceRemoteDataSourceRef ref) {
  final dio = ref.watch(dioClientProvider);
  return AcceptanceRemoteDataSourceImpl(dio);
}
