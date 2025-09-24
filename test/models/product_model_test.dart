import 'package:flutter_test/flutter_test.dart';
import 'package:sum_warehouse/shared/models/product_model.dart';

void main() {
  group('ProductModel Parsing Tests', () {
    test('should parse product with string ID', () {
      final jsonData = {
        'id': '123', // String ID
        'name': 'Test Product',
        'quantity': 15.5,
        'is_active': true,
      };

      final product = ProductModel.fromJson(jsonData);

      expect(product.id, 123);
      expect(product.name, 'Test Product');
      expect(product.quantity, 15.5);
      expect(product.isActive, true);
    });

    test('should parse product with string quantity', () {
      final jsonData = {
        'id': 1,
        'name': 'Test Product',
        'quantity': '15.5', // String quantity
        'is_active': true,
        'product_template_id': '2', // String ID
        'warehouse_id': '3', // String ID
        'producer_id': '4', // String ID
        'created_by': '5', // String ID
      };

      final product = ProductModel.fromJson(jsonData);

      expect(product.id, 1);
      expect(product.name, 'Test Product');
      expect(product.quantity, 15.5);
      expect(product.isActive, true);
      expect(product.productTemplateId, 2);
      expect(product.warehouseId, 3);
      expect(product.producerId, 4);
      expect(product.createdBy, 5);
    });

    test('should parse product with numeric quantity', () {
      final jsonData = {
        'id': 1,
        'name': 'Test Product',
        'quantity': 25.0, // Numeric quantity
        'is_active': true,
        'product_template_id': 2, // Numeric ID
        'warehouse_id': 3, // Numeric ID
      };

      final product = ProductModel.fromJson(jsonData);

      expect(product.id, 1);
      expect(product.name, 'Test Product');
      expect(product.quantity, 25.0);
      expect(product.isActive, true);
      expect(product.productTemplateId, 2);
      expect(product.warehouseId, 3);
    });

    test('should handle null and invalid values gracefully', () {
      final jsonData = {
        'id': 1,
        'name': 'Test Product',
        'quantity': null, // null quantity should default to 0
        'is_active': true,
        'product_template_id': 'invalid', // Invalid ID should become null
        'warehouse_id': '', // Empty string ID should become null
      };

      final product = ProductModel.fromJson(jsonData);

      expect(product.id, 1);
      expect(product.name, 'Test Product');
      expect(product.quantity, 0.0); // Should default to 0
      expect(product.isActive, true);
      expect(product.productTemplateId, null); // Invalid string should be null
      expect(product.warehouseId, null); // Empty string should be null
    });

    test('should parse calculated_volume from string', () {
      final jsonData = {
        'id': 1,
        'name': 'Test Product',
        'quantity': 10.0,
        'is_active': true,
        'calculated_volume': '15.75', // String volume
      };

      final product = ProductModel.fromJson(jsonData);

      expect(product.calculatedVolume, 15.75);
    });

    test('should parse attributes from JSON string', () {
      final jsonData = {
        'id': 1,
        'name': 'Test Product',
        'quantity': 10.0,
        'is_active': true,
        'attributes': '{length: 100, width: 50, height: 25}', // JSON string
      };

      final product = ProductModel.fromJson(jsonData);

      expect(product.attributes, isNotNull);
      expect(product.attributes!['length'], 100);
      expect(product.attributes!['width'], 50);
      expect(product.attributes!['height'], 25);
    });
  });
}