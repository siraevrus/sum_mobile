# Sum Warehouse - Автотесты

## Быстрый старт

### Запуск всех тестов
```bash
cd /Users/ruslansiraev/sum_mobile
flutter test
```

### Запуск определенного набора тестов

**Inventory (Остатки на складе):**
```bash
flutter test test/features/inventory/inventory_tests.dart
```

**Sales (Реализация):**
```bash
flutter test test/features/sales/sales_tests.dart
```

**Products Inflow (Поступление товаров):**
```bash
flutter test test/features/products_inflow/products_inflow_tests.dart
```

**Acceptance (Приемка товаров):**
```bash
flutter test test/features/acceptance/acceptance_tests.dart
```

**API Models:**
```bash
flutter test test/core/models/api_response_model_test.dart
```

## Структура тестов

```
test/
├── README.md                                  # Этот файл
├── TEST_GUIDE.md                             # Полное руководство по тестированию
├── integration_test_setup.dart               # Setup для интеграционных тестов
├── widget_test.dart                          # Smoke тесты приложения
├── core/
│   └── models/
│       └── api_response_model_test.dart      # Тесты API моделей (10 тестов)
├── features/
│   ├── inventory/
│   │   └── inventory_tests.dart              # Тесты раздела "Остатки на складе" (7 тестов)
│   ├── sales/
│   │   └── sales_tests.dart                  # Тесты раздела "Реализация" (10 тестов)
│   ├── products_inflow/
│   │   └── products_inflow_tests.dart        # Тесты раздела "Поступление товаров" (11 тестов)
│   └── acceptance/
│       └── acceptance_tests.dart             # Тесты раздела "Приемка товаров" (11 тестов)
└── models/
    └── product_model_test.dart               # Тесты модели товара (5+ тестов)
```

## Количество тестов по разделам

| Раздел | Файл | Количество | Статус |
|--------|------|-----------|--------|
| Inventory | `inventory_tests.dart` | 7 | ✅ |
| Sales | `sales_tests.dart` | 10 | ✅ |
| Products Inflow | `products_inflow_tests.dart` | 11 | ✅ |
| Acceptance | `acceptance_tests.dart` | 11 | ✅ |
| API Models | `api_response_model_test.dart` | 10 | ✅ |
| Другие | `product_model_test.dart`, `widget_test.dart` | 5+ | ⚠️ |
| **ВСЕГО** | | **54+** | |

## Что тестируется

### ✅ Inventory (Остатки на складе)
- Инициализация моделей производителя/склада/компании
- Статистика и агрегация данных
- Валидация количества товара
- Хранение деталей остатков

### ✅ Sales (Реализация)
- Инициализация модели продажи
- Валидация количества и цены
- Расчет итоговой суммы
- Поддержка различных способов оплаты
- Применение курса валют
- Данные покупателя
- Уникальность номеров продаж

### ✅ Products Inflow (Поступление товаров)
- Инициализация товара
- Хранение количества как строки
- Поддержка атрибутов
- Расчет объема
- Валидация при создании
- Сохранение склада при редактировании
- Поддержка транспортного номера

### ✅ Acceptance (Приемка товаров)
- Инициализация товара приемки
- Хранение количества
- Поддержка атрибутов
- Расчет объема
- Информация об отгрузке
- Валидация полей
- Сохранение данных при редактировании

### ✅ API Models
- Успешные ответы API
- Ошибки с валидацией
- Пагинация
- Обработка пустых данных
- Generic типы
- Множественные ошибки

## Запуск с дополнительными опциями

### Вербозный вывод
```bash
flutter test -v
```

### С покрытием кода
```bash
flutter test --coverage
```

### Запуск только определенного теста
```bash
flutter test test/features/sales/sales_tests.dart -n "Sale total price"
```

### Вывод в JSON формате
```bash
flutter test --machine > test_results.json
```

## Полезные команды

### Очистка перед тестированием
```bash
flutter clean
flutter pub get
flutter test
```

### Проверка покрытия кода (macOS)
```bash
flutter test --coverage
brew install lcov
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Запуск одного test group'а
```bash
flutter test -n "Inventory Section Tests"
```

## Для разработчиков

### Добавление нового теста

1. Создайте файл `feature_name_tests.dart` в папке `test/features/feature_name/`
2. Используйте стандартный шаблон:

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Your Feature Tests', () {
    test('Should test something', () {
      // Arrange
      final data = setupTestData();
      
      // Act
      final result = performAction(data);
      
      // Assert
      expect(result, expectedValue);
    });
  });
}
```

3. Запустите тест: `flutter test`
4. Обновите документацию

### Лучшие практики

1. ✅ Один тест = одна проверка
2. ✅ Описательные названия (`should_do_something`)
3. ✅ AAA паттерн (Arrange → Act → Assert)
4. ✅ Изолированные тесты
5. ✅ Группировка с `group()`
6. ✅ Использование моков для зависимостей

## Решение проблем

### Ошибка: "No ProviderScope found"
Это нормально для unit-тестов без Riverpod контекста. Используйте `TestSetup.createTestContainer()` для интеграционных тестов.

### Ошибка: "unable to find directory entry"
Это просто предупреждение о missing assets. Не влияет на тесты.

### Ошибка при импорте моделей
Убедитесь, что файл существует и путь правильный. Запустите `flutter pub get`.

## Дополнительная информация

Для полного руководства смотрите файл [`TEST_GUIDE.md`](./TEST_GUIDE.md).

## Контакты

Вопросы по тестам? Обновите документацию или обратитесь к команде разработки.

---

**Последнее обновление:** 20 октября 2025 г.
