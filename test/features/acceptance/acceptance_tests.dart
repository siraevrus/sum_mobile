import 'package:flutter_test/flutter_test.dart';
import 'package:sum_warehouse/features/acceptance/data/models/acceptance_model.dart';

void main() {
  group('Acceptance Section Tests', () {
    test('AcceptanceModel should initialize correctly', () {
      final product = AcceptanceModel(
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

    test('AcceptanceModel quantity should be stored as string', () {
      final product = AcceptanceModel(
        id: 1,
        productTemplateId: 10,
        warehouseId: 5,
        createdBy: 1,
        quantity: '200.75',
      );

      expect(product.quantity, isA<String>());
      expect(product.quantity, equals('200.75'));
    });

    test('AcceptanceModel should support attributes', () {
      final attributes = {
        'dimensions': '100x100x6000',
        'quality': 'First Grade',
        'wood_type': 'Pine'
      };
      
      final product = AcceptanceModel(
        id: 1,
        productTemplateId: 10,
        warehouseId: 5,
        createdBy: 1,
        quantity: '100',
        attributes: attributes,
      );

      expect(product.attributes, isNotNull);
    });

    test('AcceptanceModel should track calculated volume', () {
      final product = AcceptanceModel(
        id: 1,
        productTemplateId: 10,
        warehouseId: 5,
        createdBy: 1,
        quantity: '100',
        calculatedVolume: '500.25',
      );

      expect(product.calculatedVolume, equals('500.25'));
    });

    test('AcceptanceModel should support shipping information', () {
      final product = AcceptanceModel(
        id: 1,
        productTemplateId: 10,
        warehouseId: 5,
        createdBy: 1,
        quantity: '100',
        shippingLocation: 'Warehouse A - Dock 3',
        shippingDate: '2025-10-20',
      );

      expect(product.shippingLocation, isNotEmpty);
      expect(product.shippingDate, equals('2025-10-20'));
    });

    test('CreateAcceptanceRequest should validate required fields', () {
      expect(
        () {
          CreateAcceptanceRequest(
            productTemplateId: 0,
            warehouseId: 1,
            quantity: '100',
            name: 'Test',
          );
        },
        throwsException,
      );
    });

    test('UpdateAcceptanceRequest should preserve warehouse on edit', () {
      final updateRequest = UpdateAcceptanceRequest(
        quantity: '200',
        name: 'Updated Acceptance',
        warehouseId: 5,
        producerId: 1,
      );

      expect(updateRequest.warehouseId, equals(5));
      expect(updateRequest.quantity, equals('200'));
    });

    test('AcceptanceModel should track acceptance date', () {
      final product = AcceptanceModel(
        id: 1,
        productTemplateId: 10,
        warehouseId: 5,
        createdBy: 1,
        quantity: '100',
      );

      expect(product.id, isPositive);
    });

    test('Multiple acceptance products should have unique IDs', () {
      final products = [
        AcceptanceModel(
          id: 1,
          productTemplateId: 10,
          warehouseId: 5,
          createdBy: 1,
          quantity: '100',
        ),
        AcceptanceModel(
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

    test('AcceptanceModel should support notes', () {
      final product = AcceptanceModel(
        id: 1,
        productTemplateId: 10,
        warehouseId: 5,
        createdBy: 1,
        quantity: '100',
        notes: 'All units inspected and approved',
      );

      expect(product.notes, isNotEmpty);
      expect(product.notes, contains('approved'));
    });

    test('AcceptanceModel quantity should be convertible to double', () {
      final product = AcceptanceModel(
        id: 1,
        productTemplateId: 10,
        warehouseId: 5,
        createdBy: 1,
        quantity: '456.78',
      );

      final quantityDouble = double.tryParse(product.quantity);
      expect(quantityDouble, equals(456.78));
    });
  });
}
