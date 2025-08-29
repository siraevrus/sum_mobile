import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sum_warehouse/features/products/domain/entities/product_template_entity.dart';
import 'package:sum_warehouse/features/products/domain/repositories/product_template_repository.dart';

part 'get_product_templates_usecase.g.dart';

/// Use case для получения списка шаблонов товаров
@riverpod
class GetProductTemplatesUseCase extends _$GetProductTemplatesUseCase {
  @override
  ProductTemplateRepository build() {
    // Здесь будет инъекция зависимости репозитория
    throw UnimplementedError('Repository injection not implemented yet');
  }

  /// Получить список шаблонов товаров с фильтрацией
  Future<List<ProductTemplateEntity>> call({
    String? search,
    bool? isActive,
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final repository = ref.read(productTemplateRepositoryProvider);
      
      return await repository.getProductTemplates(
        search: search,
        isActive: isActive,
        page: page,
        perPage: perPage,
      );
    } catch (e) {
      // Логирование ошибки
      print('Error in GetProductTemplatesUseCase: $e');
      rethrow;
    }
  }

  /// Получить активные шаблоны для выбора
  Future<List<ProductTemplateEntity>> getActiveTemplates() async {
    return call(isActive: true, perPage: 100);
  }

  /// Поиск шаблонов по названию
  Future<List<ProductTemplateEntity>> searchTemplates(String query) async {
    if (query.trim().isEmpty) {
      return call(isActive: true);
    }
    
    return call(
      search: query.trim(),
      isActive: true,
      perPage: 50,
    );
  }
}

/// Провайдер репозитория (заглушка - будет реализован позже)
@riverpod
ProductTemplateRepository productTemplateRepository(ProductTemplateRepositoryRef ref) {
  throw UnimplementedError('ProductTemplateRepository implementation not ready yet');
}
