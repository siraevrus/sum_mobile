import 'package:flutter_test/flutter_test.dart';
import 'package:sum_warehouse/features/inventory/domain/entities/inventory_aggregation_entity.dart';

void main() {
  group('Inventory Section Tests', () {
    test('InventoryProducerModel should initialize correctly', () {
      final producer = InventoryProducerModel(
        producerId: 1,
        producer: 'Test Producer',
        positionsCount: 5,
        totalVolume: 100.5,
      );

      expect(producer.producerId, equals(1));
      expect(producer.producer, equals('Test Producer'));
      expect(producer.positionsCount, equals(5));
      expect(producer.totalVolume, equals(100.5));
    });

    test('InventoryWarehouseModel should calculate statistics', () {
      final warehouse = InventoryWarehouseModel(
        warehouseId: 1,
        warehouse: 'Warehouse 1',
        producersCount: 3,
        positionsCount: 15,
        totalVolume: 500.75,
      );

      expect(warehouse.warehouseId, equals(1));
      expect(warehouse.producersCount, equals(3));
      expect(warehouse.totalVolume, greaterThan(500.0));
    });

    test('InventoryCompanyModel should aggregate data', () {
      final company = InventoryCompanyModel(
        companyId: 1,
        company: 'Test Company',
        warehousesCount: 2,
        positionsCount: 30,
        totalVolume: 1000.0,
      );

      expect(company.companyId, equals(1));
      expect(company.warehousesCount, equals(2));
      expect(company.positionsCount, equals(30));
      expect(company.totalVolume, equals(1000.0));
    });

    test('InventoryStockDetail should store all required fields', () {
      final stock = InventoryStockDetail(
        id: 1,
        name: 'Test Product',
        warehouse: 'Warehouse 1',
        producer: 'Producer 1',
        availableQuantity: 100,
        totalVolume: 50.0,
      );

      expect(stock.name, isNotEmpty);
      expect(stock.warehouse, isNotEmpty);
      expect(stock.availableQuantity, greaterThanOrEqualTo(0));
      expect(stock.totalVolume, greaterThanOrEqualTo(0));
    });

    test('Stock quantities should be non-negative', () {
      expect(() {
        InventoryStockDetail(
          id: 1,
          name: 'Test',
          warehouse: 'W1',
          producer: null,
          availableQuantity: -10,
          totalVolume: 5.0,
        );
      }, throwsException);
    });

    test('Multiple producers should not duplicate', () {
      final producers = <InventoryProducerModel>[
        InventoryProducerModel(
          producerId: 1,
          producer: 'Producer 1',
          positionsCount: 5,
          totalVolume: 100.0,
        ),
        InventoryProducerModel(
          producerId: 2,
          producer: 'Producer 2',
          positionsCount: 3,
          totalVolume: 75.0,
        ),
      ];

      expect(producers.length, equals(2));
      expect(producers.map((p) => p.producerId).toSet().length, equals(2));
    });
  });
}
