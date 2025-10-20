import 'package:flutter_test/flutter_test.dart';
import 'package:sum_warehouse/core/models/api_response_model.dart';

void main() {
  group('API Response Model Tests', () {
    test('ApiResponse should handle success case', () {
      final response = ApiResponse<String>(
        success: true,
        data: 'Test data',
        message: 'Success',
      );

      expect(response.success, isTrue);
      expect(response.data, equals('Test data'));
      expect(response.message, equals('Success'));
    });

    test('ApiResponse should handle error case', () {
      final errors = {
        'email': ['Email is required'],
        'password': ['Password must be at least 8 characters'],
      };

      final response = ApiResponse<String>(
        success: false,
        data: null,
        message: 'Validation failed',
        errors: errors,
      );

      expect(response.success, isFalse);
      expect(response.data, isNull);
      expect(response.errors, isNotNull);
      expect(response.errors?['email'], isNotEmpty);
    });

    test('PaginatedResponse should contain pagination info', () {
      final pagination = PaginationModel(
        currentPage: 1,
        lastPage: 10,
        perPage: 15,
        total: 150,
        hasMorePages: true,
      );

      final response = PaginatedResponse<String>(
        success: true,
        data: ['Item 1', 'Item 2', 'Item 3'],
        pagination: pagination,
      );

      expect(response.pagination, isNotNull);
      expect(response.pagination?.currentPage, equals(1));
      expect(response.pagination?.total, equals(150));
      expect(response.pagination?.hasMorePages, isTrue);
    });

    test('PaginationModel should calculate if more pages exist', () {
      final pagination = PaginationModel(
        currentPage: 1,
        lastPage: 10,
        perPage: 15,
        total: 150,
        hasMorePages: true,
      );

      expect(pagination.currentPage < pagination.lastPage, isTrue);
    });

    test('PaginatedResponse data should be a list', () {
      final response = PaginatedResponse<Map<String, dynamic>>(
        success: true,
        data: [
          {'id': 1, 'name': 'Item 1'},
          {'id': 2, 'name': 'Item 2'},
        ],
      );

      expect(response.data, isA<List>());
      expect(response.data.length, equals(2));
    });

    test('ApiResponse should support generic types', () {
      final mapData = {
        'id': 1,
        'name': 'Test',
        'active': true,
      };

      final response = ApiResponse<Map<String, dynamic>>(
        success: true,
        data: mapData,
      );

      expect(response.data, isA<Map>());
      expect(response.data?['id'], equals(1));
    });

    test('PaginatedResponse should handle empty data', () {
      final response = PaginatedResponse<String>(
        success: true,
        data: [],
      );

      expect(response.data, isEmpty);
      expect(response.data.length, equals(0));
    });

    test('ApiResponse errors should map multiple error types', () {
      final errors = {
        'field1': ['Error 1', 'Error 2'],
        'field2': ['Error 3'],
        'field3': ['Error 4', 'Error 5', 'Error 6'],
      };

      final response = ApiResponse<String>(
        success: false,
        errors: errors,
      );

      expect(response.errors?.keys.length, equals(3));
      expect(response.errors?['field1']?.length, equals(2));
      expect(response.errors?['field3']?.length, equals(3));
    });
  });
}
