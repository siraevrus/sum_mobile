import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sum_warehouse/features/reception/data/datasources/receipts_remote_datasource.dart';
import 'package:sum_warehouse/features/reception/domain/entities/receipt_entity.dart';
import 'package:sum_warehouse/features/reception/domain/repositories/receipts_repository.dart';

part 'receipts_repository_impl.g.dart';

@riverpod
ReceiptsRepository receiptsRepository(ReceiptsRepositoryRef ref) {
  final dataSource = ref.watch(receiptsRemoteDataSourceProvider);
  return ReceiptsRepositoryImpl(dataSource);
}

class ReceiptsRepositoryImpl implements ReceiptsRepository {
  final ReceiptsRemoteDataSource _dataSource;

  ReceiptsRepositoryImpl(this._dataSource);

  @override
  Future<List<ReceiptEntity>> getReceipts({
    int? page,
    int? perPage,
    String? status,
    String? search,
  }) async {
    final models = await _dataSource.getReceipts(
      page: page,
      perPage: perPage,
      status: status,
      search: search,
    );
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<ReceiptEntity> getReceiptById(int id) async {
    final model = await _dataSource.getReceiptById(id);
    return model.toEntity();
  }

  @override
  Future<void> receiveGoods(int receiptId) async {
    return await _dataSource.receiveGoods(receiptId);
  }

  @override
  Future<Map<String, dynamic>> getReceiptsStats() async {
    return await _dataSource.getReceiptsStats();
  }
}
