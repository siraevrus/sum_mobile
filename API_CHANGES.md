# 📝 Изменения API: архивирование компаний

## Дата: 2024-10-17

### ✅ Изменено: HTTP методы

#### Было (PUT):
```
PUT /api/companies/{id}/archive
PUT /api/companies/{id}/restore
```

#### Стало (POST):
```
POST /api/companies/{id}/archive
POST /api/companies/{id}/restore
```

---

## 📂 Файл изменён

**Путь:** `lib/features/companies/data/datasources/companies_remote_datasource.dart`

---

## 🔄 Детали изменения

### Метод: `archiveCompany(int id)`

#### Было:
```dart
@override
Future<void> archiveCompany(int id) async {
  try {
    final response = await _dio.put('/companies/$id/archive');
    
    if (response.statusCode == 200) {
      return;
    } else if (response.statusCode == 404) {
      throw Exception('Company not found');
    } else {
      throw Exception('Failed to archive company: ${response.statusCode}');
    }
  } catch (e) {
    throw ErrorHandler.handleError(e);
  }
}
```

#### Стало:
```dart
@override
Future<void> archiveCompany(int id) async {
  try {
    final response = await _dio.post('/companies/$id/archive');
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      return;
    } else if (response.statusCode == 404) {
      throw Exception('Company not found');
    } else {
      throw Exception('Failed to archive company: ${response.statusCode}');
    }
  } catch (e) {
    throw ErrorHandler.handleError(e);
  }
}
```

**Изменения:**
- ✅ `_dio.put()` → `_dio.post()`
- ✅ Добавлена поддержка 201 статус-кода (Created)

---

### Метод: `restoreCompany(int id)`

#### Было:
```dart
@override
Future<void> restoreCompany(int id) async {
  try {
    final response = await _dio.put('/companies/$id/restore');
    
    if (response.statusCode == 200) {
      return;
    } else if (response.statusCode == 404) {
      throw Exception('Company not found');
    } else {
      throw Exception('Failed to restore company: ${response.statusCode}');
    }
  } catch (e) {
    throw ErrorHandler.handleError(e);
  }
}
```

#### Стало:
```dart
@override
Future<void> restoreCompany(int id) async {
  try {
    final response = await _dio.post('/companies/$id/restore');
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      return;
    } else if (response.statusCode == 404) {
      throw Exception('Company not found');
    } else {
      throw Exception('Failed to restore company: ${response.statusCode}');
    }
  } catch (e) {
    throw ErrorHandler.handleError(e);
  }
}
```

**Изменения:**
- ✅ `_dio.put()` → `_dio.post()`
- ✅ Добавлена поддержка 201 статус-кода

---

## 🎯 API Endpoints (обновлены)

### Архивирование компании

```http
POST /api/companies/{id}/archive HTTP/1.1
Host: your-api.com
Authorization: Bearer {token}
Content-Type: application/json
Accept: application/json

{}
```

**Ответ (200 OK):**
```json
{
  "success": true,
  "message": "Company archived successfully"
}
```

---

### Восстановление компании

```http
POST /api/companies/{id}/restore HTTP/1.1
Host: your-api.com
Authorization: Bearer {token}
Content-Type: application/json
Accept: application/json

{}
```

**Ответ (200 OK):**
```json
{
  "success": true,
  "message": "Company restored successfully"
}
```

---

## 🧪 Тестирование (curl примеры)

### Архивировать компанию 1

```bash
curl -X POST "https://your-api.com/api/companies/1/archive" \
  -H "Authorization: Bearer 10|JjDIZTEyAcIGRqXUbXlAook1oHMtQkPbSPxHV0dTe657fb6d" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json"
```

### Восстановить компанию 1

```bash
curl -X POST "https://your-api.com/api/companies/1/restore" \
  -H "Authorization: Bearer 10|JjDIZTEyAcIGRqXUbXlAook1oHMtQkPbSPxHV0dTe657fb6d" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json"
```

---

## ✅ Проверка качества

- ✅ Lint статус: БЕЗ ОШИБОК
- ✅ Изменения совместимы с backend
- ✅ Документация обновлена
- ✅ Поддержка 200 и 201 статус-кодов

---

## 📊 Совместимость

| Версия | Поддержка |
|--------|----------|
| 1.0.0+ | ✅ POST |
| < 1.0.0 | ❌ PUT |

---

## 🔗 Связанные файлы

- `lib/features/companies/data/datasources/companies_remote_datasource.dart` ✅
- `lib/features/companies/presentation/pages/companies_list_page.dart` (без изменений)
- `lib/features/companies/presentation/pages/company_details_page.dart` (без изменений)

---

## 📝 Заметки разработчика

- При обновлении backend убедитесь, что использует POST методы
- Оба статус-кода (200 и 201) считаются успешными
- ErrorHandler по-прежнему обрабатывает все ошибки

