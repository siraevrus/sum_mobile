import 'package:sum_warehouse/features/producers/domain/entities/producer_entity.dart';

abstract class ProducersRepository {
  Future<List<ProducerEntity>> getProducers();
  Future<ProducerEntity> getProducer(int id);
  Future<ProducerEntity> createProducer(ProducerEntity producer);
  Future<ProducerEntity> updateProducer(int id, ProducerEntity producer);
  Future<void> deleteProducer(int id);
}
