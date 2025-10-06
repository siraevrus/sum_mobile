import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sum_warehouse/core/network/dio_client.dart';
import 'package:sum_warehouse/features/products_in_transit/data/models/product_template_model.dart';

abstract class ProductTemplateRemoteDataSource {
  Future<List<ProductTemplateModel>> getProductTemplates();
  Future<ProductTemplateModel> getProductTemplate(int id);
}

class ProductTemplateRemoteDataSourceImpl implements ProductTemplateRemoteDataSource {
  final Dio _dio;

  ProductTemplateRemoteDataSourceImpl(this._dio);

  @override
  Future<List<ProductTemplateModel>> getProductTemplates() async {
    try {
      print('🔵 ProductTemplateRemoteDataSource: Запрос GET /product-templates');
      
      final response = await _dio.get('/product-templates');
      
      print('🔵 ProductTemplateRemoteDataSource: Ответ API /product-templates: ${response.data}');
      
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        
        if (data['success'] == true && data['data'] != null) {
          final templatesList = data['data'] as List<dynamic>;
          final templates = templatesList.map((json) => ProductTemplateModel.fromJson(json as Map<String, dynamic>)).toList();
          print('🔵 ProductTemplateRemoteDataSource: Загружено шаблонов: ${templates.length}');
          return templates;
        } else {
          throw Exception('Некорректный формат ответа API');
        }
      } else {
        throw Exception('Ожидался объект, получен ${response.data.runtimeType}');
      }
    } catch (e) {
      print('🔴 ProductTemplateRemoteDataSource: Ошибка загрузки шаблонов товаров: $e');
      rethrow;
    }
  }

  @override
  Future<ProductTemplateModel> getProductTemplate(int id) async {
    try {
      print('🔵 ProductTemplateRemoteDataSource: Запрос GET /product-templates/$id');
      
      final response = await _dio.get('/product-templates/$id');
      
      print('🔵 ProductTemplateRemoteDataSource: Ответ API /product-templates/$id: ${response.data}');
      
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        
        if (data['success'] == true && data['data'] != null) {
          final templateData = data['data'] as Map<String, dynamic>;
          final template = ProductTemplateModel.fromJson(templateData);
          print('🔵 ProductTemplateRemoteDataSource: Загружен шаблон: ${template.name}');
          return template;
        } else {
          throw Exception('Некорректный формат ответа API');
        }
      } else {
        throw Exception('Ожидался объект, получен ${response.data.runtimeType}');
      }
    } catch (e) {
      print('🔴 ProductTemplateRemoteDataSource: Ошибка загрузки шаблона товара ID $id: $e');
      rethrow;
    }
  }
}

final productTemplateRemoteDataSourceProvider = Provider<ProductTemplateRemoteDataSource>((ref) {
  final dio = ref.watch(dioClientProvider);
  return ProductTemplateRemoteDataSourceImpl(dio);
});
