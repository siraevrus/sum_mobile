import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/receipt_model.dart';
import '../models/receipt_input_model.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/error/app_exceptions.dart';
import '../../../../core/error/error_handler.dart';

part 'receipts_remote_datasource.g.dart';

/// Abstract interface for receipts remote data source
abstract class ReceiptsRemoteDataSource {
  Future<Map<String, dynamic>> getReceipts({
    int page = 1,
    int perPage = 15,
    String? status,
    int? warehouseId,
  });

  Future<ReceiptModel> getReceiptById(int id);

  Future<ReceiptModel> createReceipt(ReceiptInputModel receiptInput);

  Future<void> receiveProducts(
    int receiptId, {
    Map<String, dynamic>? data,
  });

  Future<Map<String, dynamic>> getProductsInTransit({
    int page = 1,
    int perPage = 15,
  });

  /// Принять товар (переводит в статус in_stock)
  Future<Map<String, dynamic>> receiveProduct(int receiptId);

  /// Добавить уточнение к товару (автоматически принимает товар)
  Future<Map<String, dynamic>> addCorrection(int receiptId, String correction);
}

/// Implementation of receipts remote data source
class ReceiptsRemoteDataSourceImpl implements ReceiptsRemoteDataSource {
  final Dio _dio;
  
  ReceiptsRemoteDataSourceImpl(this._dio);

  @override
  Future<Map<String, dynamic>> getReceipts({
    int page = 1,
    int perPage = 15,
    String? status,
    int? warehouseId,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'per_page': perPage,
    };
    
    if (status != null) queryParams['status'] = status;
    if (warehouseId != null) queryParams['warehouse_id'] = warehouseId;

    print('🔵 ReceiptsDataSource: ========== API REQUEST DEBUG ==========');
    print('🔵 ReceiptsDataSource: Making request to ${_dio.options.baseUrl}');
    print('🔵 ReceiptsDataSource: Raw params passed to method: page=$page, perPage=$perPage, status=$status, warehouseId=$warehouseId');
    print('🔵 ReceiptsDataSource: Final queryParams object: $queryParams');
    print('🔵 ReceiptsDataSource: QueryParams type: ${queryParams.runtimeType}');
    print('🔵 ReceiptsDataSource: QueryParams keys: ${queryParams.keys.toList()}');
    print('🔵 ReceiptsDataSource: QueryParams values: ${queryParams.values.toList()}');
    print('🔵 ReceiptsDataSource: Dio base URL: ${_dio.options.baseUrl}');
    print('🔵 ReceiptsDataSource: Dio headers: ${_dio.options.headers}');
    print('🔵 ReceiptsDataSource: =======================================');
    
    // Try multiple endpoints in order of preference
    final endpoints = ['/receipts', '/products-in-transit', '/products'];
    
    for (int i = 0; i < endpoints.length; i++) {
      final endpoint = endpoints[i];
      try {
        print('🔵 ReceiptsDataSource: Trying endpoint: $endpoint');
        
        // For products endpoint, add additional filters to get only products in transit
        final actualQueryParams = Map<String, dynamic>.from(queryParams);
        print('🔵 ReceiptsDataSource: ActualQueryParams will be: $actualQueryParams');
        print('🔵 ReceiptsDataSource: About to make GET request to: ${_dio.options.baseUrl}$endpoint with params: $actualQueryParams');
        
        if (endpoint == '/products') {
          actualQueryParams['include'] = 'template,warehouse,creator,producer';
          if (status != null) {
            // Map receipt status to product status or filter
            // Since this is fallback, we'll try to get all products
          }
        }
        
        final response = await _dio.get(endpoint, queryParameters: actualQueryParams);
        
        print('🔵 ReceiptsDataSource: ✅ Success with endpoint: $endpoint');
        print('🔵 ReceiptsDataSource: Response status code: ${response.statusCode}');
        print('🔵 ReceiptsDataSource: Response data type: ${response.data.runtimeType}');
        
        if (response.data is Map<String, dynamic>) {
          final responseMap = response.data as Map<String, dynamic>;
          print('🔵 ReceiptsDataSource: Response keys: ${responseMap.keys.toList()}');
          
          // Transform products data to receipts format if needed
          if (endpoint == '/products' && responseMap.containsKey('data')) {
            final products = responseMap['data'] as List<dynamic>;
            print('🔵 ReceiptsDataSource: Transforming ${products.length} products to receipts format');
            
            // Transform products to receipt-like structure
            final transformedData = products.map((product) {
              final productMap = product as Map<String, dynamic>;
              return {
                'id': productMap['id'],
                'name': productMap['name'] ?? 'Неизвестный товар',
                'product_template_id': productMap['product_template_id'] ?? productMap['template']?['id'] ?? 0,
                'warehouse_id': productMap['warehouse_id'] ?? productMap['warehouse']?['id'] ?? 0,
                'producer_id': productMap['producer_id'] ?? productMap['producer']?['id'],
                'attributes': productMap['attributes'] ?? {},
                'calculated_volume': productMap['calculated_volume'],
                'quantity': productMap['quantity'] ?? 0,
                'status': 'in_transit', // Default status for products
                'shipping_location': null,
                'shipping_date': null,
                'expected_arrival_date': null,
                'transport_number': null,
                'document_path': null,
                'notes': productMap['notes'],
                'created_by': productMap['created_by'] ?? productMap['creator']?['id'],
                'created_at': productMap['created_at'],
                'updated_at': productMap['updated_at'],
              };
            }).toList();
            
            return {
              'data': transformedData,
              'links': responseMap['links'],
              'meta': responseMap['meta'],
            };
          }
          
          return responseMap;
        } else {
          print('🔴 ReceiptsDataSource: Response is not a Map, wrapping in data structure');
          return {'data': response.data is List ? response.data : []};
        }
      } catch (e) {
        print('🔴 ReceiptsDataSource: Failed with endpoint $endpoint: $e');
        
        if (e is DioException) {
          print('🔴 ReceiptsDataSource: DioException details:');
          print('  - Type: ${e.type}');
          print('  - Message: ${e.message}');
          print('  - Response status: ${e.response?.statusCode}');
          print('  - Response data: ${e.response?.data}');
        }
        
        // If this is the last endpoint, throw the error
        if (i == endpoints.length - 1) {
          throw _handleError(e);
        }
        
        // Otherwise, continue to next endpoint
        continue;
      }
    }
    
    // This should never be reached, but just in case
    throw Exception('Не удалось получить данные о приемках с любого эндпоинта');
  }

  @override
  Future<ReceiptModel> getReceiptById(int id) async {
    try {
      final response = await _dio.get('/receipts/$id');
      return ReceiptModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<ReceiptModel> createReceipt(ReceiptInputModel receiptInput) async {
    try {
      final response = await _dio.post('/receipts', data: receiptInput.toJson());
      
      // Handle different response formats
      final responseData = response.data as Map<String, dynamic>;
      if (responseData.containsKey('receipt')) {
        return ReceiptModel.fromJson(responseData['receipt']);
      } else if (responseData.containsKey('data')) {
        return ReceiptModel.fromJson(responseData['data']);
      } else {
        return ReceiptModel.fromJson(responseData);
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<void> receiveProducts(
    int receiptId, {
    Map<String, dynamic>? data,
  }) async {
    try {
      await _dio.post('/receipts/$receiptId/receive', data: data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> getProductsInTransit({
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };

      print('🔵 Запрос к /products-in-transit с параметрами: $queryParams');
      final response = await _dio.get('/products-in-transit', queryParameters: queryParams);
      
      print('📥 Products in Transit API response: ${response.data}');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> receiveProduct(int receiptId) async {
    try {
      print('🔵 Принимаем товар с ID: $receiptId');
      final response = await _dio.post('/receipts/$receiptId/receive');
      print('📥 Receive Product API response: ${response.data}');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> addCorrection(int receiptId, String correction) async {
    try {
      print('🔵 Добавляем уточнение к товару с ID: $receiptId');
      final response = await _dio.post(
        '/receipts/$receiptId/correction',
        data: {
          'correction': correction,
        },
      );
      print('📥 Add Correction API response: ${response.data}');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  AppException _handleError(dynamic error) {
    return ErrorHandler.handleError(error);
  }
}

@riverpod
ReceiptsRemoteDataSource receiptsRemoteDataSource(ReceiptsRemoteDataSourceRef ref) {
  final dio = ref.watch(dioClientProvider);
  return ReceiptsRemoteDataSourceImpl(dio);
}