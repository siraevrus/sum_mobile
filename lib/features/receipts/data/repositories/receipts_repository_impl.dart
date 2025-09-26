import '../../domain/entities/receipt_entity.dart';
import '../../domain/entities/receipt_input_entity.dart';
import '../../domain/repositories/receipts_repository.dart';
import '../datasources/receipts_remote_datasource.dart';
import '../models/receipt_input_model.dart';
import '../models/receipt_model.dart';

class ReceiptsRepositoryImpl implements ReceiptsRepository {
  final ReceiptsRemoteDataSource _remoteDataSource;

  ReceiptsRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<ReceiptEntity>> getReceipts({
    int page = 1,
    int perPage = 15,
    String? status,
    int? warehouseId,
  }) async {
    try {
      print('🔵 ReceiptsRepository: Making request with params - page: $page, perPage: $perPage, status: $status, warehouseId: $warehouseId');
      
      final response = await _remoteDataSource.getReceipts(
        page: page,
        perPage: perPage,
        status: status,
        warehouseId: warehouseId,
      );

      print('🔵 ReceiptsRepository: Raw response received: $response');
      print('🔵 ReceiptsRepository: Response type: ${response.runtimeType}');
      print('🔵 ReceiptsRepository: Response keys: ${response.keys.toList()}');

      // Handle different response formats
      List<dynamic> dataList;
      if (response['data'] != null) {
        print('🔵 ReceiptsRepository: Found data key, type: ${response['data'].runtimeType}');
        if (response['data'] is List) {
          dataList = response['data'] as List<dynamic>;
        } else {
          print('🔴 ReceiptsRepository: data key is not a List, it is: ${response['data'].runtimeType}');
          dataList = [];
        }
      } else if (response['success'] == true && response['data'] != null) {
        print('🔵 ReceiptsRepository: Found success=true with data');
        dataList = response['data'] as List<dynamic>;
      } else {
        print('🔴 ReceiptsRepository: No valid data structure found in response');
        dataList = [];
      }

      print('🔵 ReceiptsRepository: DataList length: ${dataList.length}');
      if (dataList.isNotEmpty) {
        print('🔵 ReceiptsRepository: First item: ${dataList.first}');
      }

      final receipts = dataList
          .map((json) {
            try {
              print('🔵 ReceiptsRepository: Parsing item: $json');
              return ReceiptModel.fromJson(json as Map<String, dynamic>);
            } catch (e) {
              print('🔴 ReceiptsRepository: Error parsing item: $e');
              print('🔴 ReceiptsRepository: Problematic json: $json');
              rethrow;
            }
          })
          .map((model) => model.toEntity())
          .toList();
          
      print('🔵 ReceiptsRepository: Successfully parsed ${receipts.length} receipts');
      return receipts;
    } catch (e) {
      print('🔴 ReceiptsRepository: Exception caught: $e');
      throw Exception('Failed to fetch receipts: $e');
    }
  }

  @override
  Future<ReceiptEntity> getReceiptById(int id) async {
    try {
      final receiptModel = await _remoteDataSource.getReceiptById(id);
      return receiptModel.toEntity();
    } catch (e) {
      throw Exception('Failed to fetch receipt: $e');
    }
  }

  @override
  Future<ReceiptEntity> createReceipt(ReceiptInputEntity receiptInput) async {
    try {
      final inputModel = ReceiptInputModel.fromEntity(receiptInput);
      final receiptModel = await _remoteDataSource.createReceipt(inputModel);
      return receiptModel.toEntity();
    } catch (e) {
      throw Exception('Failed to create receipt: $e');
    }
  }

  @override
  Future<void> receiveProducts({
    required int receiptId,
    int? actualQuantity,
    String? notes,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (actualQuantity != null) {
        data['actual_quantity'] = actualQuantity;
      }
      if (notes != null) {
        data['notes'] = notes;
      }

      await _remoteDataSource.receiveProducts(
        receiptId,
        data: data.isNotEmpty ? data : null,
      );
    } catch (e) {
      throw Exception('Failed to receive products: $e');
    }
  }
}