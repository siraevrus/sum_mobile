import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sum_warehouse/features/producers/domain/entities/producer_entity.dart';
import 'package:sum_warehouse/features/producers/domain/repositories/producers_repository.dart';
import 'package:sum_warehouse/core/network/dio_client.dart';
import 'package:sum_warehouse/features/producers/data/datasources/producers_remote_datasource.dart';
import 'package:sum_warehouse/features/producers/data/repositories/producers_repository_impl.dart';

// Provider для remote datasource
final producersRemoteDataSourceProvider = Provider<ProducersRemoteDataSource>((ref) {
  final dio = ref.watch(dioClientProvider);
  return ProducersRemoteDataSourceImpl(dio: dio);
});

// Provider для repository
final producersRepositoryProvider = Provider<ProducersRepository>((ref) {
  final remoteDataSource = ref.watch(producersRemoteDataSourceProvider);
  return ProducersRepositoryImpl(remoteDataSource: remoteDataSource);
});

// Provider для состояния списка производителей
final producersProvider = StateNotifierProvider<ProducersNotifier, AsyncValue<List<ProducerEntity>>>((ref) {
  final repository = ref.watch(producersRepositoryProvider);
  return ProducersNotifier(repository);
});

class ProducersNotifier extends StateNotifier<AsyncValue<List<ProducerEntity>>> {
  final ProducersRepository _repository;

  ProducersNotifier(this._repository) : super(const AsyncValue.loading());

  Future<void> loadProducers() async {
    print('🔵 ProducersNotifier: loadProducers вызван');
    state = const AsyncValue.loading();
    try {
      print('🔵 ProducersNotifier: Загружаем производителей из repository...');
      final producers = await _repository.getProducers();
      print('🔵 ProducersNotifier: Производители загружены: ${producers.length} шт');
      state = AsyncValue.data(producers);
    } catch (error, stackTrace) {
      print('🔴 ProducersNotifier: Ошибка загрузки производителей: $error');
      print('🔴 ProducersNotifier: Stack trace: $stackTrace');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> createProducer(ProducerEntity producer) async {
    try {
      await _repository.createProducer(producer);
      // Перезагружаем список после создания
      await loadProducers();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateProducer(int id, ProducerEntity producer) async {
    try {
      await _repository.updateProducer(id, producer);
      // Перезагружаем список после обновления
      await loadProducers();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteProducer(int id) async {
    try {
      await _repository.deleteProducer(id);
      // Перезагружаем список после удаления
      await loadProducers();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}