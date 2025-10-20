import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:sum_warehouse/core/network/dio_client.dart';
import 'package:dio/dio.dart';

/// Setup для интеграционных тестов
class TestSetup {
  static ProviderContainer createTestContainer() {
    return ProviderContainer();
  }

  static void setupMocks() {
    // Здесь можно добавить мок-ы для Dio и других сервисов
  }
}

/// Вспомогательные функции для тестов
class TestHelpers {
  /// Получить контролер текстового поля
  static String extractValueFromTextField(String text) {
    return text;
  }

  /// Проверить, содержит ли текст ожидаемое значение
  static bool containsText(String haystack, String needle) {
    return haystack.contains(needle);
  }
}
