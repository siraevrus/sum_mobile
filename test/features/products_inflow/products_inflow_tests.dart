import 'package:flutter_test/flutter_test.dart';
import 'package:sum_warehouse/features/products_inflow/data/models/product_inflow_model.dart';

void main() {
  group('Products Inflow Section Tests', () {
    test('ProductInflowModel should initialize correctly', () {
      final product = ProductInflowModel(
        id: 1,
        productTemplateId: 10,
        warehouseId: 5,
        createdBy: 1,
        name: 'Test Product',
        quantity: '100',
      );

      expect(product.id, equals(1));
      expect(product.productTemplateId, equals(10));
      expect(product.warehouseId, equals(5));
      expect(product.name, equals('Test Product'));
    });

    test('ProductInflowModel quantity should be stored as string', () {
      final product = ProductInflowModel(
        id: 1,
        productTemplateId: 10,
        warehouseId: 5,
        createdBy: 1,
        quantity: '150.5',
      );

      expect(product.quantity, isA<String>());
      expect(product.quantity, equals('150.5'));
    });

    test('ProductInflowModel should support attributes', () {
      final attributes = {'size': '100x100x6000', 'grade': 'A', 'species': 'pine'};
      
      final product = ProductInflowModel(
        id: 1,
        productTemplateId: 10,
        warehouseId: 5,
        createdBy: 1,
        quantity: '100',
        attributes: attributes,
      );

      expect(product.attributes, isNotNull);
    });

    test('ProductInflowModel should track volume calculation', () {
      final product = ProductInflowModel(
        id: 1,
        productTemplateId: 10,
        warehouseId: 5,
        createdBy: 1,
        quantity: '100',
        calculatedVolume: '600.0',
      );

      expect(product.calculatedVolume, equals('600.0'));
    });

    test('ProductInflowModel should support optional descriptions', () {
      final product = ProductInflowModel(
        id: 1,
        productTemplateId: 10,
        warehouseId: 5,
        createdBy: 1,
        quantity: '100',
        description: 'High quality pine lumber',
      );

      expect(product.description, equals('High quality pine lumber'));
    });

    test('CreateProductInflowRequest should validate product template', () {
      expect(
        () {
          CreateProductInflowRequest(
            productTemplateId: 0,
            warehouseId: 1,
            quantity: '100',
            name: 'Test',
          );
        },
        throwsException,
      );
    });

    test('UpdateProductInflowRequest should preserve warehouse on edit', () {
      final updateRequest = UpdateProductInflowRequest(
        quantity: '150',
        name: 'Updated Product',
        warehouseId: 5,
        producerId: 1,
      );

      expect(updateRequest.warehouseId, equals(5));
      expect(updateRequest.quantity, equals('150'));
    });

    test('ProductInflowModel arrival date should be parseable', () {
      final product = ProductInflowModel(
        id: 1,
        productTemplateId: 10,
        warehouseId: 5,
        createdBy: 1,
        quantity: '100',
        arrivalDate: '2025-10-20',
      );

      expect(product.arrivalDate, isNotNull);
      expect(product.arrivalDate, equals('2025-10-20'));
    });

    test('Multiple products should have unique IDs', () {
      final products = [
        ProductInflowModel(
          id: 1,
          productTemplateId: 10,
          warehouseId: 5,
          createdBy: 1,
          quantity: '100',
        ),
        ProductInflowModel(
          id: 2,
          productTemplateId: 11,
          warehouseId: 5,
          createdBy: 1,
          quantity: '150',
        ),
      ];

      final ids = products.map((p) => p.id).toSet();
      expect(ids.length, equals(2));
    });

    test('ProductInflowModel should support transport number', () {
      final product = ProductInflowModel(
        id: 1,
        productTemplateId: 10,
        warehouseId: 5,
        createdBy: 1,
        quantity: '100',
        transportNumber: 'TRUCK-001',
      );

      expect(product.transportNumber, equals('TRUCK-001'));
    });

    test('ProductInflowModel quantity should be convertible to double', () {
      final product = ProductInflowModel(
        id: 1,
        productTemplateId: 10,
        warehouseId: 5,
        createdBy: 1,
        quantity: '123.45',
      );

      final quantityDouble = double.tryParse(product.quantity);
      expect(quantityDouble, equals(123.45));
    });
  });
}
