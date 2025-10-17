# Реализация функции архивирования компании

## Обзор

В этом документе описаны все изменения, внесённые для полной реализации функции архивирования и восстановления компаний в приложении Sum Warehouse.

## Проблема

Функция архивирования компании была частично реализована:
- ✅ Методы API в datasource существовали
- ✅ UI для вызова функции был реализован
- ❌ Методы не были добавлены в абстрактные интерфейсы
- ❌ Методы не были реализованы в репозитории
- ❌ Методы не были добавлены в notifiers для управления состоянием

## Решение

### 1. Обновлены интерфейсы

#### `lib/features/companies/data/datasources/companies_remote_datasource.dart`
- Добавлены аннотации `@override` для методов `archiveCompany` и `restoreCompany`

**Статус-код ответа:**
- 200 OK - успешно архивирована/восстановлена
- 404 Not Found - компания не найдена
- Другие коды - ошибка

### 2. Обновлен репозиторий (домен)

#### `lib/features/companies/domain/repositories/companies_repository.dart`
- Добавлены абстрактные методы:
  - `Future<void> archiveCompany(int id);`
  - `Future<void> restoreCompany(int id);`

### 3. Реализация репозитория (данные)

#### `lib/features/companies/data/repositories/companies_repository_impl.dart`
- Добавлены реализации методов:
  - `archiveCompany(int id)` - вызывает datasource и пробрасывает ошибку
  - `restoreCompany(int id)` - вызывает datasource и пробрасывает ошибку

### 4. Добавлены методы в провайдеры состояния

#### `lib/features/companies/presentation/providers/companies_provider.dart`

**В классе `CompaniesNotifier`:**
```dart
Future<void> archiveCompany(int id) async {
  try {
    await _repository.archiveCompany(id);
    await loadCompanies();
  } catch (error, stackTrace) {
    state = AsyncValue.error(error, stackTrace);
  }
}

Future<void> restoreCompany(int id) async {
  try {
    await _repository.restoreCompany(id);
    await loadCompanies();
  } catch (error, stackTrace) {
    state = AsyncValue.error(error, stackTrace);
  }
}
```

**В классе `CompanyDetailsNotifier`:**
```dart
Future<void> archiveCompany() async {
  try {
    await _repository.archiveCompany(_id);
    await loadCompany();
  } catch (error, stackTrace) {
    state = AsyncValue.error(error, stackTrace);
  }
}

Future<void> restoreCompany() async {
  try {
    await _repository.restoreCompany(_id);
    await loadCompany();
  } catch (error, stackTrace) {
    state = AsyncValue.error(error, stackTrace);
  }
}
```

### 5. Обновлена страница деталей компании

#### `lib/features/companies/presentation/pages/company_details_page.dart`

- Заменена кнопка "Удалить" на кнопки "Архивировать" (для активных) / "Восстановить" (для архивированных)
- Добавлены методы:
  - `_archiveCompany()` - показывает диалог подтверждения
  - `_performArchive()` - выполняет архивирование
  - `_restoreCompany()` - показывает диалог подтверждения
  - `_performRestore()` - выполняет восстановление

## Архитектура запроса

```
UI (company_details_page.dart)
    ↓
CompanyDetailsNotifier.archiveCompany()
    ↓
CompaniesRepository.archiveCompany()
    ↓
CompaniesRepositoryImpl.archiveCompany()
    ↓
CompaniesRemoteDataSource.archiveCompany()
    ↓
CompaniesRemoteDataSourceImpl.archiveCompany()
    ↓
PUT /companies/{id}/archive
    ↓
Backend API
```

## Обработка ошибок

Все ошибки обрабатываются через централизованный `ErrorHandler`:

```dart
try {
  final response = await _dio.put('/companies/$id/archive');
  // ...
} catch (e) {
  throw ErrorHandler.handleError(e);
}
```

**Возможные ошибки:**
- Network Exception - проблемы с подключением
- Server Exception - ошибка сервера (500+)
- Validation Exception - ошибка валидации (422)
- Not Found Exception - компания не найдена (404)

## Тестирование

### Используемый токен
```
10|JjDIZTEyAcIGRqXUbXlAook1oHMtQkPbSPxHV0dTe657fb6d
```

### Шаги тестирования

1. **В приложении:**
   - Откройте раздел "Компания"
   - Выберите компанию
   - Нажмите "Архивировать" (кнопка оранжевого цвета)
   - Подтвердите в диалоговом окне
   - Проверьте, что компания исчезла из списка активных компаний
   - Включите фильтр "Показать архивированные"
   - Проверьте, что компания появилась в архивированных с меткой "Архив"

2. **Восстановление:**
   - В списке архивированных компаний найдите нужную
   - Нажмите "Восстановить" (зелёная кнопка)
   - Проверьте, что компания снова в активных компаниях

### Проверка логов

1. **В консоли Flutter (Debug):**
   - Включите `flutter logs` для просмотра логов
   - Смотрите строки с "ErrorHandler" и "DioException"

2. **На сервере:**
   - Проверьте логи приложения для запросов `PUT /companies/{id}/archive`
   - Проверьте логи БД для обновления флага `is_archived`

## Файлы, которые были изменены

1. ✅ `lib/features/companies/data/datasources/companies_remote_datasource.dart`
   - Добавлены @override аннотации

2. ✅ `lib/features/companies/domain/repositories/companies_repository.dart`
   - Добавлены абстрактные методы

3. ✅ `lib/features/companies/data/repositories/companies_repository_impl.dart`
   - Добавлена реализация методов

4. ✅ `lib/features/companies/presentation/providers/companies_provider.dart`
   - Добавлены методы в CompaniesNotifier
   - Добавлены методы в CompanyDetailsNotifier

5. ✅ `lib/features/companies/presentation/pages/company_details_page.dart`
   - Обновлены кнопки действий
   - Добавлены методы диалогов и выполнения

## Статус реализации

- ✅ Архитектура (Clean Architecture)
- ✅ Управление состоянием (Riverpod)
- ✅ Обработка ошибок (ErrorHandler)
- ✅ UI/UX
- ✅ Интеграция с API
- ✅ Фильтрация архивированных компаний

## Дополнительные возможности для будущей разработки

1. Массовое архивирование компаний
2. История архивирования (когда и кто архивировал)
3. Автоматическое удаление старых архивированных компаний (soft delete → hard delete)
4. Отправка уведомления о архивировании админу
5. Восстановление из архива с восстановлением состояния складов и персонала

