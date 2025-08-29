import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sum_warehouse/features/reception/data/repositories/receipts_repository_impl.dart';
import 'package:sum_warehouse/features/reception/domain/entities/receipt_entity.dart';

part 'receipts_provider.g.dart';

@riverpod
class Receipts extends _$Receipts {
  @override
  Future<List<ReceiptEntity>> build() async {
    return await _loadReceipts();
  }

  Future<List<ReceiptEntity>> _loadReceipts() async {
    try {
      final repository = ref.read(receiptsRepositoryProvider);
      return await repository.getReceipts();
    } catch (e) {
      throw Exception('Ошибка загрузки приемок: $e');
    }
  }

  /// Обновить список приемок
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadReceipts());
  }

  /// Поиск приемок
  Future<void> searchReceipts(String query) async {
    if (query.isEmpty) {
      await refresh();
      return;
    }

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(receiptsRepositoryProvider);
      return await repository.getReceipts(search: query);
    });
  }

  /// Фильтр по статусу
  Future<void> filterByStatus(String? status) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(receiptsRepositoryProvider);
      return await repository.getReceipts(status: status);
    });
  }

  /// Принять товар
  Future<void> receiveGoods(int receiptId) async {
    try {
      final repository = ref.read(receiptsRepositoryProvider);
      await repository.receiveGoods(receiptId);
      // Обновляем список после принятия
      await refresh();
    } catch (e) {
      throw Exception('Ошибка принятия товара: $e');
    }
  }
}

@riverpod
Future<ReceiptEntity> receiptById(ReceiptByIdRef ref, int id) async {
  final repository = ref.read(receiptsRepositoryProvider);
  return await repository.getReceiptById(id);
}

@riverpod
Future<Map<String, dynamic>> receiptsStats(ReceiptsStatsRef ref) async {
  final repository = ref.read(receiptsRepositoryProvider);
  return await repository.getReceiptsStats();
}

