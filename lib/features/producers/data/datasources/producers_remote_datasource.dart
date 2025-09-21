import 'package:dio/dio.dart';
import 'package:sum_warehouse/shared/models/producer_model.dart';

abstract class ProducersRemoteDataSource {
  Future<List<ProducerModel>> getProducers();
  Future<ProducerModel> getProducer(int id);
  Future<ProducerModel> createProducer(ProducerModel producer);
  Future<ProducerModel> updateProducer(int id, ProducerModel producer);
  Future<void> deleteProducer(int id);
}

class ProducersRemoteDataSourceImpl implements ProducersRemoteDataSource {
  final Dio _dio;

  ProducersRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  @override
  Future<List<ProducerModel>> getProducers() async {
    try {
      final response = await _dio.get('/producers');
      
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = response.data;
        return jsonList
            .map((json) => ProducerModel.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to load producers: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading producers: $e');
    }
  }

  @override
  Future<ProducerModel> getProducer(int id) async {
    try {
      final response = await _dio.get('/producers/$id');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> json = response.data;
        return ProducerModel.fromJson(json);
      } else if (response.statusCode == 404) {
        throw Exception('Producer not found');
      } else {
        throw Exception('Failed to load producer: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading producer: $e');
    }
  }

  @override
  Future<ProducerModel> createProducer(ProducerModel producer) async {
    try {
      final response = await _dio.post(
        '/producers',
        data: producer.toCreateJson(),
      );
      
      if (response.statusCode == 201) {
        final Map<String, dynamic> json = response.data;
        return ProducerModel.fromJson(json);
      } else if (response.statusCode == 422) {
        final Map<String, dynamic> errorJson = response.data;
        throw Exception('Validation error: ${errorJson['errors']}');
      } else {
        throw Exception('Failed to create producer: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating producer: $e');
    }
  }

  @override
  Future<ProducerModel> updateProducer(int id, ProducerModel producer) async {
    try {
      final response = await _dio.put(
        '/producers/$id',
        data: producer.toUpdateJson(),
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> json = response.data;
        return ProducerModel.fromJson(json);
      } else if (response.statusCode == 404) {
        throw Exception('Producer not found');
      } else if (response.statusCode == 422) {
        final Map<String, dynamic> errorJson = response.data;
        throw Exception('Validation error: ${errorJson['errors']}');
      } else {
        throw Exception('Failed to update producer: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating producer: $e');
    }
  }

  @override
  Future<void> deleteProducer(int id) async {
    try {
      final response = await _dio.delete('/producers/$id');
      
      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 404) {
        throw Exception('Producer not found');
      } else {
        throw Exception('Failed to delete producer: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting producer: $e');
    }
  }
}