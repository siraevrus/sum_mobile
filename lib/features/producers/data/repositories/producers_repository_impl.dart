import 'package:sum_warehouse/features/producers/data/datasources/producers_remote_datasource.dart';
import 'package:sum_warehouse/features/producers/domain/entities/producer_entity.dart';
import 'package:sum_warehouse/features/producers/domain/repositories/producers_repository.dart';
import 'package:sum_warehouse/shared/models/producer_model.dart';

class ProducersRepositoryImpl implements ProducersRepository {
  final ProducersRemoteDataSource _remoteDataSource;

  ProducersRepositoryImpl({
    required ProducersRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  @override
  Future<List<ProducerEntity>> getProducers() async {
    try {
      final producers = await _remoteDataSource.getProducers();
      return producers.map((model) => _mapModelToEntity(model)).toList();
    } catch (e) {
      throw Exception('Failed to get producers: $e');
    }
  }

  @override
  Future<ProducerEntity> getProducer(int id) async {
    try {
      final producer = await _remoteDataSource.getProducer(id);
      return _mapModelToEntity(producer);
    } catch (e) {
      throw Exception('Failed to get producer: $e');
    }
  }

  @override
  Future<ProducerEntity> createProducer(ProducerEntity producer) async {
    try {
      final model = _mapEntityToModel(producer);
      final createdProducer = await _remoteDataSource.createProducer(model);
      return _mapModelToEntity(createdProducer);
    } catch (e) {
      throw Exception('Failed to create producer: $e');
    }
  }

  @override
  Future<ProducerEntity> updateProducer(int id, ProducerEntity producer) async {
    try {
      final model = _mapEntityToModel(producer);
      final updatedProducer = await _remoteDataSource.updateProducer(id, model);
      return _mapModelToEntity(updatedProducer);
    } catch (e) {
      throw Exception('Failed to update producer: $e');
    }
  }

  @override
  Future<void> deleteProducer(int id) async {
    try {
      await _remoteDataSource.deleteProducer(id);
    } catch (e) {
      throw Exception('Failed to delete producer: $e');
    }
  }

  ProducerEntity _mapModelToEntity(ProducerModel model) {
    return ProducerEntity(
      id: model.id,
      name: model.name,
      region: model.region,
      productsCount: model.productsCount,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }

  ProducerModel _mapEntityToModel(ProducerEntity entity) {
    return ProducerModel(
      id: entity.id,
      name: entity.name,
      region: entity.region,
      productsCount: entity.productsCount,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
