import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sum_warehouse/core/network/dio_client.dart';
import 'package:sum_warehouse/features/products_inflow/data/models/product_template_model.dart';

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
      
      final response = await _dio.get('/product-templates');
      
      
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        
        if (data['success'] == true && data['data'] != null) {
          final templatesList = data['data'] as List<dynamic>;
          final templates = templatesList.map((json) => ProductTemplateModel.fromJson(json as Map<String, dynamic>)).toList();
          return templates;
        } else {
          throw Exception('Некорректный формат ответа API');
        }
      } else {
        throw Exception('Ожидался объект, получен ${response.data.runtimeType}');
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<ProductTemplateModel> getProductTemplate(int id) async {
    try {
      
      final response = await _dio.get('/product-templates/$id');
      
      
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        
        if (data['success'] == true && data['data'] != null) {
          final templateData = data['data'] as Map<String, dynamic>;
          final template = ProductTemplateModel.fromJson(templateData);
          return template;
        } else {
          throw Exception('Некорректный формат ответа API');
        }
      } else {
        throw Exception('Ожидался объект, получен ${response.data.runtimeType}');
      }
    } catch (e) {
      rethrow;
    }
  }
}

final productTemplateRemoteDataSourceProvider = Provider<ProductTemplateRemoteDataSource>((ref) {
  final dio = ref.watch(dioClientProvider);
  return ProductTemplateRemoteDataSourceImpl(dio);
});
