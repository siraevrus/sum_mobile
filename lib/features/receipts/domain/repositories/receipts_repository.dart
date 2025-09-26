import '../entities/receipt_entity.dart';
import '../entities/receipt_input_entity.dart';

abstract class ReceiptsRepository {
  /// Get list of receipts with pagination
  Future<List<ReceiptEntity>> getReceipts({
    int page = 1,
    int perPage = 15,
    String? status,
    int? warehouseId,
  });

  /// Get receipt by ID
  Future<ReceiptEntity> getReceiptById(int id);

  /// Create new receipt
  Future<ReceiptEntity> createReceipt(ReceiptInputEntity receiptInput);

  /// Receive products (mark as received)
  Future<void> receiveProducts({
    required int receiptId,
    int? actualQuantity,
    String? notes,
  });
}