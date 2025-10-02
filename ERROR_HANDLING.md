# Обработка Ошибок

## Обзор

В проекте реализована централизованная система обработки ошибок, которая обеспечивает единообразную обработку сетевых и других ошибок по всему приложению. Все сетевые ошибки преобразуются в понятные для пользователя сообщения.

## Основные компоненты

### 1. ErrorHandler (`lib/core/error/error_handler.dart`)

Централизованный обработчик всех ошибок приложения.

**Основная функция:**
```dart
static AppException handleError(dynamic error)
```

**Обрабатывает:**
- `DioException` - все HTTP-ошибки и сетевые проблемы
- `AppException` - пользовательские исключения
- Другие исключения - преобразует в `UnknownException`

**Для сетевых ошибок:**
- Таймауты (connectionTimeout, sendTimeout, receiveTimeout)
- Проблемы с подключением (connectionError)
- Ошибки SSL-сертификатов (badCertificate)
- Неизвестные сетевые ошибки

Все эти ошибки возвращают единое сообщение:
> **"Проблемы с сетью. Проверьте подключение к интернету"**

**Для серверных ошибок:**
- 400 - Плохой запрос
- 401 - Требуется авторизация
- 403 - Доступ запрещен
- 404 - Ресурс не найден
- 422 - Ошибка валидации (с деталями)
- 500+ - Ошибка сервера

### 2. ErrorHandlerInterceptor (`lib/core/network/dio_client.dart`)

Интерцептор Dio, который автоматически обрабатывает все сетевые ошибки на уровне HTTP-клиента.

**Функционал:**
- Перехватывает все DioException
- Преобразует их через ErrorHandler
- Логирует ошибки для отладки
- Создает новую DioException с понятным сообщением

### 3. AppException (`lib/core/error/app_exceptions.dart`)

Иерархия пользовательских исключений:

- `NetworkException` - Сетевые ошибки
- `AuthException` - Ошибки авторизации
- `ServerException` - Ошибки сервера (с кодом статуса)
- `ValidationException` - Ошибки валидации (с деталями)
- `CacheException` - Ошибки кеша
- `UnknownException` - Неизвестные ошибки

## Использование

### В Remote Data Sources

Все remote data sources должны использовать `ErrorHandler.handleError()` для обработки ошибок:

```dart
import 'package:sum_warehouse/core/error/error_handler.dart';

class MyRemoteDataSourceImpl implements MyRemoteDataSource {
  final Dio _dio;
  
  @override
  Future<MyModel> getData() async {
    try {
      final response = await _dio.get('/data');
      return MyModel.fromJson(response.data);
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }
}
```

### В презентационном слое

Обрабатывайте `AppException` и показывайте пользователю:

```dart
try {
  await repository.getData();
} on NetworkException catch (e) {
  // Показать пользователю: "Проблемы с сетью. Проверьте подключение к интернету"
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(e.message)),
  );
} on ValidationException catch (e) {
  // Показать детали валидации
  showValidationErrors(e.errors);
} on AppException catch (e) {
  // Общая обработка
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(e.message)),
  );
}
```

## Обновленные файлы

Следующие data sources были обновлены для использования централизованного ErrorHandler:

- ✅ `auth_remote_datasource.dart`
- ✅ `sales_remote_datasource.dart`
- ✅ `receipts_remote_datasource.dart`
- ✅ `products_api_datasource.dart`
- ✅ `inventory_stocks_remote_datasource.dart`
- ✅ `users_remote_datasource.dart`
- ✅ `warehouses_remote_datasource.dart`
- ✅ `requests_remote_datasource.dart`
- ✅ `dashboard_remote_datasource.dart`
- ✅ `companies_remote_datasource.dart`
- ✅ `producers_remote_datasource.dart`
- ✅ `inventory_remote_datasource.dart` (импорт добавлен)
- ✅ `product_template_remote_datasource.dart` (импорт добавлен)

## Преимущества

1. **Единообразие**: Все ошибки обрабатываются одинаково по всему приложению
2. **Понятность**: Пользователь видит понятные сообщения вместо системных ошибок
3. **Централизация**: Легко изменить логику обработки ошибок в одном месте
4. **Отладка**: Все ошибки логируются для разработчиков
5. **Типобезопасность**: Использование sealed классов для исключений

## Дальнейшие улучшения

- Добавить локализацию сообщений об ошибках
- Добавить аналитику ошибок (Firebase Crashlytics)
- Добавить retry-логику для временных сетевых ошибок
- Создать UI-компонент для единообразного отображения ошибок

