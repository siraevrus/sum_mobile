import 'package:sum_warehouse/features/reception/domain/entities/receipt_entity.dart';

abstract class ReceiptsRepository {
  Future<List<ReceiptEntity>> getReceipts({
    int? page,
    int? perPage,
    String? status,
    String? search,
  });

  Future<ReceiptEntity> getReceiptById(int id);

  Future<void> receiveGoods(int receiptId);

  Future<Map<String, dynamic>> getReceiptsStats();
}
