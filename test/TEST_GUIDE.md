# Автотесты приложения Sum Warehouse

## Обзор

Этот документ содержит информацию о структуре и запуске автотестов для приложения Sum Warehouse.

## Структура тестов

```
test/
├── widget_test.dart                           # Smoke тесты приложения
├── integration_test_setup.dart                # Setup для интеграционных тестов
├── TEST_GUIDE.md                              # Этот файл
├── core/
│   └── models/
│       └── api_response_model_test.dart       # Тесты моделей API ответов
├── features/
│   ├── inventory/
│   │   └── inventory_tests.dart               # Тесты раздела "Остатки на складе"
│   ├── sales/
│   │   └── sales_tests.dart                   # Тесты раздела "Реализация"
│   └── products_inflow/
│       └── products_inflow_tests.dart         # Тесты раздела "Поступление товаров"
└── models/
    └── product_model_test.dart                # Тесты модели товара
```

## Что тестируется

### 1. Inventory (Остатки на складе)
- ✅ Инициализация модели производителя
- ✅ Расчет статистики склада
- ✅ Агрегация данных компании
- ✅ Валидация количества товара (неотрицательные значения)
- ✅ Уникальность ID производителя
- ✅ Корректность хранения деталей остатков

**Запуск:**
```bash
flutter test test/features/inventory/inventory_tests.dart
```

### 2. Sales (Реализация)
- ✅ Инициализация модели продажи
- ✅ Валидация количества (положительные значения)
- ✅ Проверка расчета итоговой суммы
- ✅ Поддержка различных способов оплаты
- ✅ Применение курса валют
- ✅ Валюта по умолчанию (RUB)
- ✅ Данные покупателя (имя, телефон, email, адрес)
- ✅ Уникальность номеров продаж

**Запуск:**
```bash
flutter test test/features/sales/sales_tests.dart
```

### 3. Products Inflow (Поступление товаров)
- ✅ Инициализация модели товара при поступлении
- ✅ Хранение количества как строки
- ✅ Поддержка атрибутов товара
- ✅ Отслеживание расчета объема
- ✅ Опциональные описания
- ✅ Валидация template ID
- ✅ Сохранение warehouse на редактировании
- ✅ Парсирование даты прибытия
- ✅ Поддержка номера транспорта
- ✅ Конверсия количества в double

**Запуск:**
```bash
flutter test test/features/products_inflow/products_inflow_tests.dart
```

### 4. API Models
- ✅ ApiResponse успешного ответа
- ✅ ApiResponse с ошибками
- ✅ PaginatedResponse с информацией о пагинации
- ✅ Проверка наличия больше страниц
- ✅ Работа с пустыми данными
- ✅ Поддержка generic типов
- ✅ Множественные ошибки валидации

**Запуск:**
```bash
flutter test test/core/models/api_response_model_test.dart
```

## Команды запуска

### Запуск всех тестов
```bash
flutter test
```

### Запуск тестов конкретной папки
```bash
flutter test test/features/
flutter test test/core/
```

### Запуск с вербозным выводом
```bash
flutter test -v
```

### Запуск с результатами в JSON
```bash
flutter test --machine > test_results.json
```

### Запуск с покрытием кода
```bash
flutter test --coverage
```

### Генерирование отчета о покрытии
```bash
# Установить lcov (macOS)
brew install lcov

# Генерировать отчет
genhtml coverage/lcov.info -o coverage/html

# Открыть отчет
open coverage/html/index.html
```

## Примеры написания тестов

### Простой юнит-тест
```dart
test('Description of what is being tested', () {
  // Arrange - подготовка данных
  final testData = 'some value';
  
  // Act - выполнение действия
  final result = testFunction(testData);
  
  // Assert - проверка результата
  expect(result, equals('expected value'));
});
```

### Тест с множественными проверками
```dart
test('Model should have all required fields', () {
  final model = MyModel(
    id: 1,
    name: 'Test',
    active: true,
  );

  expect(model.id, equals(1));
  expect(model.name, isNotEmpty);
  expect(model.active, isTrue);
});
```

### Тест на выброс исключения
```dart
test('Should throw exception on invalid input', () {
  expect(
    () => invalidFunction(-5),
    throwsException,
  );
});
```

## Основные matcher'ы

| Matcher | Описание |
|---------|----------|
| `equals(expected)` | Проверка равенства |
| `isA<Type>()` | Проверка типа |
| `isNotEmpty` | Не пустая строка/список |
| `isEmpty` | Пустая строка/список |
| `isTrue` / `isFalse` | Проверка булева значения |
| `isNull` / `isNotNull` | Проверка на null |
| `greaterThan(value)` | Больше чем |
| `lessThan(value)` | Меньше чем |
| `contains(item)` | Список содержит элемент |
| `throwsException` | Выбрасывает исключение |

## Лучшие практики

1. **Один тест - одна проверка**: Каждый тест должен проверять одно конкретное поведение
2. **Ясные названия**: Используйте описательные имена тестов
3. **AAA паттерн**: Arrange (подготовка) → Act (действие) → Assert (проверка)
4. **Группировка**: Используйте `group()` для организации связанных тестов
5. **Изоляция**: Тесты не должны зависеть друг от друга
6. **Мокирование**: Используйте моки для зависимостей

## Интеграционные тесты

Для интеграционных тестов используйте файл `integration_test_setup.dart`:

```dart
import 'test/integration_test_setup.dart';

void main() {
  group('Integration Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = TestSetup.createTestContainer();
      TestSetup.setupMocks();
    });

    test('Feature should work end-to-end', () async {
      // Ваш интеграционный тест
    });
  });
}
```

## CI/CD Интеграция

Для запуска тестов в CI/CD конвейере:

```yaml
# GitHub Actions пример
- name: Run tests
  run: flutter test --coverage

- name: Upload coverage
  uses: codecov/codecov-action@v3
  with:
    files: ./coverage/lcov.info
```

## Добавление новых тестов

При добавлении новой функции:

1. Создайте файл `feature_name_tests.dart` в соответствующей папке
2. Напишите unit-тесты для бизнес-логики
3. Добавьте интеграционные тесты если необходимо
4. Проверьте, что все тесты проходят локально
5. Убедитесь, что покрытие кода не упало

## Полезные ресурсы

- [Flutter Testing Docs](https://flutter.dev/docs/testing)
- [Dart Test Package](https://pub.dev/packages/test)
- [Flutter Test Package](https://pub.dev/packages/flutter_test)

## Поддержка

Если у вас возникают вопросы по тестам, обратитесь к разработчикам или обновите этот документ.

---

**Последнее обновление:** 20 октября 2025 г.
