import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/receipt_entity.dart';
import '../../domain/repositories/receipts_repository.dart';
import '../../data/datasources/receipts_remote_datasource.dart';
import '../../data/repositories/receipts_repository_impl.dart';

part 'receipts_provider.g.dart';

@riverpod
ReceiptsRepository receiptsRepository(ReceiptsRepositoryRef ref) {
  final remoteDataSource = ref.watch(receiptsRemoteDataSourceProvider);
  return ReceiptsRepositoryImpl(remoteDataSource);
}

@riverpod
class ReceiptsNotifier extends _$ReceiptsNotifier {
  @override
  Future<List<ReceiptEntity>> build({
    int page = 1,
    int perPage = 15,
    String? status,
    int? warehouseId,
  }) async {
    final repository = ref.watch(receiptsRepositoryProvider);
    return repository.getReceipts(
      page: page,
      perPage: perPage,
      status: status,
      warehouseId: warehouseId,
    );
  }

  Future<void> refresh() async {
    // Invalidate and rebuild the provider
    ref.invalidateSelf();
  }

  Future<void> loadMore() async {
    // Implementation for pagination
    // This would be enhanced to handle cumulative loading
    final currentState = await future;
    if (currentState.length >= 15) {
      // Load next page
      final repository = ref.watch(receiptsRepositoryProvider);
      final nextPage = (currentState.length ~/ 15) + 1;
      final newReceipts = await repository.getReceipts(
        page: nextPage,
        perPage: 15,
        status: null,
        warehouseId: null,
      );
      
      state = AsyncValue.data([...currentState, ...newReceipts]);
    }
  }

  Future<void> receiveProducts({
    required int receiptId,
    int? actualQuantity,
    String? notes,
  }) async {
    try {
      final repository = ref.watch(receiptsRepositoryProvider);
      await repository.receiveProducts(
        receiptId: receiptId,
        actualQuantity: actualQuantity,
        notes: notes,
      );
      
      // Refresh the list after receiving
      await refresh();
    } catch (e) {
      rethrow;
    }
  }
}

@riverpod
Future<ReceiptEntity> receiptDetail(ReceiptDetailRef ref, int receiptId) async {
  final repository = ref.watch(receiptsRepositoryProvider);
  return repository.getReceiptById(receiptId);
}