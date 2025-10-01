import 'package:sum_warehouse/features/sales/data/models/sale_model.dart';
import 'package:sum_warehouse/shared/models/api_response_model.dart';

/// Абстрактный репозиторий для работы с продажами
abstract class SalesRepository {
  /// Получить список продаж с фильтрацией
  Future<PaginatedResponse<SaleModel>> getSales({
    int page = 1,
    int perPage = 15,
    SaleFilters? filters,
  });

  /// Получить продажу по ID
  Future<SaleModel> getSale(int id);

  /// Создать новую продажу
  Future<SaleModel> createSale(CreateSaleRequest request);

  /// Обновить продажу
  Future<SaleModel> updateSale(int id, UpdateSaleRequest request);

  /// Удалить продажу
  Future<void> deleteSale(int id);

  /// Обработать продажу (списание товара)
  Future<void> processSale(int id);

  /// Отменить продажу
  Future<void> cancelSale(int id);
}
