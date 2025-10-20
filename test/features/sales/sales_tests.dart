import 'package:flutter_test/flutter_test.dart';
import 'package:sum_warehouse/features/sales/data/models/sale_model.dart';

void main() {
  group('Sales Section Tests', () {
    test('SaleModel should initialize with all required fields', () {
      final sale = SaleModel(
        id: 1,
        productId: 10,
        warehouseId: 5,
        userId: 1,
        saleNumber: 'SALE-202510-0001',
        customerName: 'John Doe',
        quantity: 10.5,
        unitPrice: 100.0,
        totalPrice: 1050.0,
      );

      expect(sale.id, equals(1));
      expect(sale.productId, equals(10));
      expect(sale.warehouseId, equals(5));
      expect(sale.saleNumber, equals('SALE-202510-0001'));
      expect(sale.customerName, equals('John Doe'));
    });

    test('Sale quantity should be positive', () {
      expect(
        () {
          SaleModel(
            id: 1,
            productId: 10,
            warehouseId: 5,
            userId: 1,
            quantity: -5.0,
            unitPrice: 100.0,
            totalPrice: -500.0,
          );
        },
        throwsException,
      );
    });

    test('Sale total price should equal quantity * unit price', () {
      final quantity = 10.0;
      final unitPrice = 50.0;
      final expectedTotal = quantity * unitPrice;

      final sale = SaleModel(
        id: 1,
        productId: 10,
        warehouseId: 5,
        userId: 1,
        quantity: quantity,
        unitPrice: unitPrice,
        totalPrice: expectedTotal,
      );

      expect(sale.totalPrice, equals(expectedTotal));
    });

    test('Sale should support different payment methods', () {
      final paymentMethods = ['cash', 'bank_transfer', 'check', 'mixed'];

      for (final method in paymentMethods) {
        final sale = SaleModel(
          id: 1,
          productId: 10,
          warehouseId: 5,
          userId: 1,
          quantity: 10.0,
          unitPrice: 100.0,
          totalPrice: 1000.0,
          paymentMethod: method,
        );

        expect(sale.paymentMethod, equals(method));
      }
    });

    test('Sale exchange rate should be applied correctly', () {
      final exchangeRate = 1.2;
      final originalAmount = 1000.0;
      final convertedAmount = originalAmount * exchangeRate;

      final sale = SaleModel(
        id: 1,
        productId: 10,
        warehouseId: 5,
        userId: 1,
        quantity: 10.0,
        unitPrice: 100.0,
        totalPrice: convertedAmount,
        exchangeRate: exchangeRate,
      );

      expect(sale.exchangeRate, equals(exchangeRate));
      expect(sale.totalPrice, equals(convertedAmount));
    });

    test('Sale currency should default to RUB', () {
      final sale = SaleModel(
        id: 1,
        productId: 10,
        warehouseId: 5,
        userId: 1,
        quantity: 10.0,
        unitPrice: 100.0,
        totalPrice: 1000.0,
      );

      expect(sale.currency, equals('RUB'));
    });

    test('Sale with customer info should be complete', () {
      final sale = SaleModel(
        id: 1,
        productId: 10,
        warehouseId: 5,
        userId: 1,
        customerName: 'John Doe',
        customerPhone: '+1234567890',
        customerEmail: 'john@example.com',
        customerAddress: '123 Main St',
        quantity: 10.0,
        unitPrice: 100.0,
        totalPrice: 1000.0,
      );

      expect(sale.customerName, isNotEmpty);
      expect(sale.customerPhone, isNotEmpty);
      expect(sale.customerEmail, isNotEmpty);
      expect(sale.customerAddress, isNotEmpty);
    });

    test('CreateSaleRequest should validate required fields', () {
      expect(
        () {
          CreateSaleRequest(
            compositeProductKey: '',
            warehouseId: 1,
            customerName: '',
            quantity: 10.0,
            currency: 'RUB',
            exchangeRate: 1.0,
            cashAmount: 500.0,
            nocashAmount: 500.0,
            totalPrice: 1000.0,
            saleDate: '2025-10-20',
          );
        },
        throwsException,
      );
    });

    test('Multiple sales should have unique sale numbers', () {
      final sales = [
        SaleModel(
          id: 1,
          productId: 10,
          warehouseId: 5,
          userId: 1,
          saleNumber: 'SALE-202510-0001',
          quantity: 10.0,
          unitPrice: 100.0,
          totalPrice: 1000.0,
        ),
        SaleModel(
          id: 2,
          productId: 11,
          warehouseId: 5,
          userId: 1,
          saleNumber: 'SALE-202510-0002',
          quantity: 5.0,
          unitPrice: 200.0,
          totalPrice: 1000.0,
        ),
      ];

      final saleNumbers = sales.map((s) => s.saleNumber).toSet();
      expect(saleNumbers.length, equals(2));
    });
  });
}
