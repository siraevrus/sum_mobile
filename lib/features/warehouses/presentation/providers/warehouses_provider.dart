import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sum_warehouse/features/warehouses/data/datasources/warehouses_remote_datasource.dart';
import 'package:sum_warehouse/shared/models/warehouse_model.dart';

part 'warehouses_provider.g.dart';

@riverpod
class Warehouses extends _$Warehouses {
  @override
  Future<List<WarehouseModel>> build() async {
    final dataSource = ref.read(warehousesRemoteDataSourceProvider);
    final response = await dataSource.getWarehouses();
    return response.data;
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final dataSource = ref.read(warehousesRemoteDataSourceProvider);
      final response = await dataSource.getWarehouses();
      return response.data;
    });
  }
}
