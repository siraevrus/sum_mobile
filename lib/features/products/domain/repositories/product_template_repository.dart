import 'package:sum_warehouse/features/products/domain/entities/product_template_entity.dart';
import 'package:sum_warehouse/features/products/domain/entities/product_entity.dart';
import 'package:sum_warehouse/features/products/data/models/product_template_model.dart';

/// Репозиторий для работы с шаблонами товаров
abstract class ProductTemplateRepository {
  /// Получить список шаблонов товаров
  Future<List<ProductTemplateEntity>> getProductTemplates({
    String? search,
    bool? isActive,
    int page = 1,
    int perPage = 15,
  });

  /// Получить шаблон товара по ID
  Future<ProductTemplateEntity> getProductTemplate(int id);

  /// Создать новый шаблон товара
  Future<ProductTemplateEntity> createProductTemplate(CreateProductTemplateModel template);

  /// Обновить шаблон товара
  Future<ProductTemplateEntity> updateProductTemplate(int id, CreateProductTemplateModel template);

  /// Удалить шаблон товара
  Future<void> deleteProductTemplate(int id);

  /// Активировать/деактивировать шаблон товара
  Future<ProductTemplateEntity> toggleProductTemplateStatus(int id, bool isActive);

  /// Тестировать формулу шаблона
  Future<Map<String, dynamic>> testFormula(int id, Map<String, dynamic> values);

  /// Получить характеристики шаблона
  Future<List<TemplateAttributeEntity>> getTemplateAttributes(int templateId);

  /// Создать характеристику для шаблона
  Future<TemplateAttributeEntity> createTemplateAttribute(
    int templateId, 
    CreateTemplateAttributeModel attribute
  );

  /// Обновить характеристику шаблона
  Future<TemplateAttributeEntity> updateTemplateAttribute(
    int templateId, 
    int attributeId, 
    CreateTemplateAttributeModel attribute
  );

  /// Удалить характеристику шаблона
  Future<void> deleteTemplateAttribute(int templateId, int attributeId);

  /// Получить товары по шаблону
  Future<List<ProductEntity>> getProductsByTemplate(
    int templateId, {
    bool? isActive,
    int? warehouseId,
    String? search,
    int page = 1,
    int perPage = 15,
  });

  /// Получить доступные единицы измерения
  Future<List<String>> getAvailableUnits();
}
