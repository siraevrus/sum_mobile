# Просмотр логов при архивировании компании

## Для отладки функции архивирования компании, выполните следующие шаги:

### 1. В терминале запустите Flutter приложение с логами:

```bash
# В папке проекта
flutter logs
```

Или в отдельном терминале во время запуска приложения:

```bash
# Запуск приложения на эмуляторе/телефоне
flutter run

# В другом терминале
flutter logs
```

### 2. Ключевые логи для поиска:

При архивировании компании ищите в логах:

**Успешное архивирование:**
```
[INFO] DioClient: PUT /companies/1/archive - Status 200
[INFO] CompanyDetailsNotifier: Архивирование компании завершено
[SNACK_BAR] Компания "Название" архивирована
```

**Ошибка сети:**
```
[ERROR] ErrorHandler: Network error - Проблемы с сетью. Проверьте подключение к интернету
[DioException] Connection error
```

**Компания не найдена:**
```
[ERROR] ErrorHandler: HTTP 404 - Company not found
```

**Ошибка сервера:**
```
[ERROR] ErrorHandler: Server error (500) - Ошибка на сервере
```

### 3. Просмотр логов с фильтрацией:

```bash
# Только логи архивирования
flutter logs | grep -i archive

# Логи ошибок
flutter logs | grep -i error

# Логи Dio (сетевые запросы)
flutter logs | grep -i dio

# Комбинированный поиск
flutter logs | grep -E "(archive|error|DioException)"
```

### 4. Расширенная отладка в коде:

В файле `lib/features/companies/presentation/pages/company_details_page.dart`, метод `_performArchive`:

```dart
Future<void> _performArchive(BuildContext context, WidgetRef ref, CompanyModel company) async {
  try {
    print('🔍 DEBUG: Начало архивирования компании ${company.id}');
    final notifier = ref.read(companyDetailsProvider(company.id).notifier);
    print('🔍 DEBUG: Notifier получен, вызываем archiveCompany()');
    await notifier.archiveCompany();
    print('✅ DEBUG: Архивирование успешно завершено');
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Компания "${company.name}" архивирована'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  } catch (e) {
    print('❌ DEBUG: Ошибка при архивировании: $e');
    print('❌ DEBUG: Stack trace: $e');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при архивировании: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
```

### 5. Логи на серверной части (Laravel/Backend):

Проверьте файлы логов на сервере:

```bash
# Linux/Mac
tail -f storage/logs/laravel.log | grep -i company

# Или для Windows
Get-Content storage/logs/laravel.log -Tail 50 -Wait | Select-String -Pattern "company" -IgnoreCase
```

Ищите строки:
```
[2024-12-XX XX:XX:XX] local.INFO: Archiving company {id}
[2024-12-XX XX:XX:XX] local.DEBUG: Company archived successfully
[2024-12-XX XX:XX:XX] local.ERROR: Failed to archive company
```

### 6. Проверка базы данных:

```sql
-- PostgreSQL
SELECT id, name, is_archived, updated_at FROM companies ORDER BY updated_at DESC LIMIT 10;

-- MySQL
SELECT id, name, is_archived, updated_at FROM companies ORDER BY updated_at DESC LIMIT 10;

-- SQLite
SELECT id, name, is_archived, updated_at FROM companies ORDER BY updated_at DESC LIMIT 10;
```

### 7. Прямое тестирование API через curl:

```bash
# Получить список компаний
curl -X GET "https://your-api.com/api/companies" \
  -H "Authorization: Bearer 10|JjDIZTEyAcIGRqXUbXlAook1oHMtQkPbSPxHV0dTe657fb6d" \
  -H "Accept: application/json"

# Архивировать компанию ID=1
curl -X PUT "https://your-api.com/api/companies/1/archive" \
  -H "Authorization: Bearer 10|JjDIZTEyAcIGRqXUbXlAook1oHMtQkPbSPxHV0dTe657fb6d" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json"

# Получить детали архивированной компании
curl -X GET "https://your-api.com/api/companies/1" \
  -H "Authorization: Bearer 10|JjDIZTEyAcIGRqXUbXlAook1oHMtQkPbSPxHV0dTe657fb6d" \
  -H "Accept: application/json"
```

### 8. Использование Postman:

1. Откройте Postman
2. Создайте новый request:
   - **Method:** PUT
   - **URL:** `https://your-api.com/api/companies/1/archive`
   - **Headers:**
     - `Authorization: Bearer 10|JjDIZTEyAcIGRqXUbXlAook1oHMtQkPbSPxHV0dTe657fb6d`
     - `Accept: application/json`
     - `Content-Type: application/json`
   - **Body:** Empty

3. Нажмите Send
4. Проверьте Response

### 9. Проверка состояния приложения в DevTools:

```bash
# Запустите Flutter DevTools
flutter pub global activate devtools
devtools

# Откройте в браузере: http://localhost:9100
# Выберите запущенное приложение
# Перейдите на вкладку "Performance" и "Logging"
```

### Типичные проблемы и их решение:

| Проблема | Решение |
|---------|---------|
| 401 Unauthorized | Токен истёк или невалидный, переавторизуйтесь |
| 404 Not Found | Компания с таким ID не существует |
| 422 Unprocessable Entity | Проверьте данные отправляемого запроса |
| Connection timeout | Проверьте подключение к интернету |
| CORS error | Проверьте CORS настройки на сервере |
| SSL Certificate error | На dev добавьте игнорирование SSL сертификатов |

### Дополнительные команды для анализа:

```bash
# Анализ производительности
flutter analyze

# Проверка на потенциальные баги
dart fix --dry-run

# Форматирование кода
dart format .

# Проверка зависимостей
flutter pub outdated
```

