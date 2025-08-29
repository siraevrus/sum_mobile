import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sum_warehouse/core/network/dio_client.dart';
import 'package:sum_warehouse/features/reception/data/models/receipt_model.dart';

part 'receipts_remote_datasource.g.dart';

@riverpod
ReceiptsRemoteDataSource receiptsRemoteDataSource(ReceiptsRemoteDataSourceRef ref) {
  final dio = ref.watch(dioClientProvider);
  return ReceiptsRemoteDataSource(dio);
}

class ReceiptsRemoteDataSource {
  final Dio _dio;

  ReceiptsRemoteDataSource(this._dio);

  /// Получить список приемок (товары в пути)
  Future<List<ReceiptModel>> getReceipts({
    int? page,
    int? perPage,
    String? status,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (page != null) queryParams['page'] = page;
      if (perPage != null) queryParams['per_page'] = perPage;
      if (status != null) queryParams['status'] = status;
      if (search != null) queryParams['search'] = search;

      final response = await _dio.get(
        '/receipts',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.data is Map<String, dynamic>) {
        final responseModel = ReceiptsResponse.fromJson(response.data as Map<String, dynamic>);
        return responseModel.data;
      }

      throw Exception('Неожиданный формат ответа API');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (e.response?.statusCode == 403) {
        throw Exception('Нет доступа к приемкам');
      } else if (e.response?.statusCode == 404) {
        throw Exception('Приемки не найдены');
      } else {
        throw Exception('Ошибка загрузки приемок: ${e.message}');
      }
    } catch (e) {
      throw Exception('Неожиданная ошибка: $e');
    }
  }

  /// Получить приемку по ID
  Future<ReceiptModel> getReceiptById(int id) async {
    try {
      final response = await _dio.get('/receipts/$id');
      
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data.containsKey('data')) {
          return ReceiptModel.fromJson(data['data'] as Map<String, dynamic>);
        }
        return ReceiptModel.fromJson(data);
      }

      throw Exception('Неожиданный формат ответа API');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (e.response?.statusCode == 403) {
        throw Exception('Нет доступа к приемке');
      } else if (e.response?.statusCode == 404) {
        throw Exception('Приемка не найдена');
      } else {
        throw Exception('Ошибка загрузки приемки: ${e.message}');
      }
    } catch (e) {
      throw Exception('Неожиданная ошибка: $e');
    }
  }

  /// Принять товар (изменить статус на received)
  Future<void> receiveGoods(int receiptId) async {
    try {
      await _dio.post('/receipts/$receiptId/receive');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (e.response?.statusCode == 403) {
        throw Exception('Нет прав на принятие товара');
      } else if (e.response?.statusCode == 404) {
        throw Exception('Приемка не найдена');
      } else if (e.response?.statusCode == 422) {
        throw Exception('Нельзя принять товар в текущем статусе');
      } else {
        throw Exception('Ошибка принятия товара: ${e.message}');
      }
    } catch (e) {
      throw Exception('Неожиданная ошибка: $e');
    }
  }

  /// Получить статистику приемок
  Future<Map<String, dynamic>> getReceiptsStats() async {
    try {
      final response = await _dio.get('/receipts/stats');
      
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data.containsKey('data')) {
          return data['data'] as Map<String, dynamic>;
        }
        return data;
      }

      throw Exception('Неожиданный формат ответа API');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (e.response?.statusCode == 403) {
        throw Exception('Нет доступа к статистике');
      } else {
        throw Exception('Ошибка загрузки статистики: ${e.message}');
      }
    } catch (e) {
      throw Exception('Неожиданная ошибка: $e');
    }
  }


}
