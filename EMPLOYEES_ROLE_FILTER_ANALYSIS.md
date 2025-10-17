# 📋 Фильтрация сотрудников по ролям

## 📁 ФАЙЛ
`lib/features/users/presentation/pages/employees_list_page.dart`

---

## 🎯 КАК ЭТО РАБОТАЕТ

### 1️⃣ СОСТОЯНИЕ ФИЛЬТРА

На странице сохраняется выбранная роль в переменной:

```dart
UserRole? _roleFilter;  // Может быть null (Все) или одна из ролей
```

### 2️⃣ ВЫПАДАЮЩЕЕ МЕНЮ РОЛЕЙ

```dart
Widget _buildRoleFilter() {
  return DropdownButtonFormField<UserRole>(
    value: _roleFilter,  // Текущее значение фильтра
    onChanged: (value) {
      setState(() => _roleFilter = value);  // Сохраняем выбор
      _loadUsers();  // Перезагружаем список с новым фильтром
    },
    items: [
      const DropdownMenuItem(value: null, child: Text('Все')),  // Показать всех
      ...UserRole.values.map(  // Все доступные роли
        (role) => DropdownMenuItem(
          value: role,
          child: Text(_getRoleDisplayName(role)),  // Русское название
        ),
      ),
    ],
  );
}
```

**Доступные роли:**
- `null` - Все (без фильтра)
- `UserRole.admin` - Администратор
- `UserRole.operator` - Оператор
- `UserRole.warehouseWorker` - Работник склада
- `UserRole.salesManager` - Менеджер по продажам

### 3️⃣ ЗАГРУЗКА ДАННЫХ С ФИЛЬТРОМ

Когда нажимаешь на роль, вызывается `_loadUsers()`:

```dart
void _loadUsers() {
  final dataSource = ref.read(usersRemoteDataSourceProvider);
  
  // Очищаем список пока загружаются данные
  setState(() {
    _usersFuture = Future.value(PaginatedResponse<UserManagementModel>(data: <UserManagementModel>[]));
  });

  // Загружаем сотрудников с фильтрами
  dataSource.getUsers(
    search: _searchQuery,           // Поиск по имени/логину
    role: _roleFilter?.name,        // ← ФИЛЬТР ПО РОЛИ (преобразуем в строку)
    isBlocked: _isBlockedFilter,    // Фильтр по статусу
  ).then((resp) {
    if (mounted) {
      setState(() {
        _usersFuture = Future.value(resp);  // Показываем результаты
      });
    }
  });
}
```

### 4️⃣ СЕТАП СПИСКА

Список загружается один раз:

```dart
Widget _buildUsersList() {
  final dataSource = ref.watch(usersRemoteDataSourceProvider);

  _usersFuture ??= dataSource.getUsers(
    search: _searchQuery,
    role: _roleFilter?.name,     // ← Передаем роль
    isBlocked: _isBlockedFilter,
  );

  return FutureBuilder(
    future: _usersFuture,
    builder: (context, snapshot) {
      // Показываем результаты
      final users = snapshot.data?.data ?? [];
      // ...
    },
  );
}
```

---

## 🔄 ПОТОК ФИЛЬТРАЦИИ

```
┌─────────────────────────────┐
│  Пользователь выбирает     │
│  роль из выпадающего меню   │
│  (например, "Оператор")     │
└──────────────┬──────────────┘
               │
               ▼
      onChanged вызывается
               │
               ├─ setState(() => _roleFilter = UserRole.operator)
               │
               └─ _loadUsers()
                  │
                  ▼
    dataSource.getUsers(
      role: "operator"  ← Строка "operator"
    )
                  │
                  ▼
    API получает запрос с ролью
                  │
                  ▼
    Возвращает только операторов
                  │
                  ▼
    setState() обновляет UI
                  │
                  ▼
    Список показывает только операторов ✅
```

---

## 🔍 ДЕТАЛИ ФИЛЬТРА

### UserRole enum

```dart
// Из auth domain entities
enum UserRole {
  admin,              // Администратор - полный доступ
  operator,           // Оператор - управление заказами
  warehouseWorker,    // Работник склада - управление товарами
  salesManager,       // Менеджер по продажам - отчеты и продажи
}
```

### Преобразование в строку

**Важно:** Enum в Dart использует camelCase (`warehouseWorker`), но API ожидает snake_case (`warehouse_worker`).

```dart
// ❌ НЕПРАВИЛЬНО:
role: _roleFilter?.name  // Даст "warehouseWorker" вместо "warehouse_worker"

// ✅ ПРАВИЛЬНО:
role: _roleFilter != null ? _getRoleApiValue(_roleFilter!) : null
```

**Функция-конвертер:**

```dart
String _getRoleApiValue(UserRole role) {
  switch (role) {
    case UserRole.admin:
      return 'admin';
    case UserRole.operator:
      return 'operator';
    case UserRole.warehouseWorker:
      return 'warehouse_worker';  // ← snake_case для API
    case UserRole.salesManager:
      return 'sales_manager';      // ← snake_case для API
  }
}
```

Теперь корректные значения передаются на сервер:

### Русские названия

```dart
String _getRoleDisplayName(UserRole role) {
  switch (role) {
    case UserRole.admin:
      return 'Администратор';
    case UserRole.operator:
      return 'Оператор';
    case UserRole.warehouseWorker:
      return 'Работник склада';
    case UserRole.salesManager:
      return 'Менеджер по продажам';
  }
}
```

---

## 🎨 ВИЗУАЛИЗАЦИЯ РОЛЬ

Каждой роли присвоен свой цвет:

```dart
Color _getRoleColor(UserRole role) {
  switch (role) {
    case UserRole.admin:
      return const Color(0xFFE74C3C);  // Красный
    case UserRole.operator:
      return const Color(0xFF3498DB);  // Синий
    case UserRole.warehouseWorker:
      return const Color(0xFF2ECC71);  // Зеленый
    case UserRole.salesManager:
      return const Color(0xFFFF9800);  // Оранжевый
  }
}
```

---

## 📊 ТРИ ФИЛЬТРА ВМЕСТЕ

На странице есть **три фильтра**:

```dart
┌─────────────────────────────────────┐
│  Поиск (search)                     │
│  Роль (role) ← ВОТ ЭТО              │
│  Статус (isBlocked)                 │
└─────────────────────────────────────┘
```

**Все три передаются в одном запросе:**

```dart
dataSource.getUsers(
  search: "Иван",                 // Ищем "Иван"
  role: "operator",               // И это операторы
  isBlocked: false,               // И они активны
)
```

---

## 🔐 ДОСТУПНЫЕ РОЛИ ПО ТИПАМ

### ВНУТРЕННИЕ РОЛИ (для сотрудников):

| Роль | Dart Enum | API Value | Описание |
|------|-----------|-----------|---------|
| Администратор | `UserRole.admin` | `admin` | Полный доступ к системе |
| Оператор | `UserRole.operator` | `operator` | Управление заказами |
| Работник склада | `UserRole.warehouseWorker` | `warehouse_worker` | Управление товарами |
| Менеджер по продажам | `UserRole.salesManager` | `sales_manager` | Отчеты и аналитика |

### ЧТО МОЖЕТ ДЕЛАТЬ КАЖДАЯ РОЛЬ:

```
┌──────────────────┬─────┬─────┬─────┬─────┐
│ Функция          │Адм  │Опер │Скл  │Мен  │
├──────────────────┼─────┼─────┼─────┼─────┤
│ Просмотр товаров │ ✅  │ ✅  │ ✅  │ ✅  │
│ Редактирование   │ ✅  │ ✅  │ ✅  │ ❌  │
│ Управление rolle │ ✅  │ ❌  │ ❌  │ ❌  │
│ Экспорт данных   │ ✅  │ ✅  │ ✅  │ ✅  │
│ Архивирование    │ ✅  │ ❌  │ ❌  │ ❌  │
└──────────────────┴─────┴─────┴─────┴─────┘
```

---

## 📝 КОД ДЛЯ ФИЛЬТРА

### ПОЛНЫЙ ПРОЦЕСС:

```dart
// 1. Пользователь меняет фильтр
_buildRoleFilter() {
  onChanged: (value) {
    setState(() => _roleFilter = value);  // Сохраняем
    _loadUsers();  // Перезагружаем
  }
}

// 2. Загружаем с новым фильтром
_loadUsers() {
  dataSource.getUsers(
    role: _roleFilter?.name,  // Передаем роль
  )
}

// 3. Список обновляется
_buildUsersList() {
  _usersFuture = dataSource.getUsers(
    role: _roleFilter?.name,
  );
  
  return FutureBuilder(
    future: _usersFuture,
    builder: (context, snapshot) {
      final users = snapshot.data?.data ?? [];  // Отфильтрованные!
      // Показываем только этих пользователей
    },
  );
}
```

---

## ⚙️ КАК ДОБАВИТЬ НОВУЮ РОЛЬ

Если нужна новая роль:

### Шаг 1: Добавить в enum

```dart
// Где-то в auth entities
enum UserRole {
  admin,
  operator,
  warehouseWorker,
  salesManager,
  supervisor,  // ← Новая роль
}
```

### Шаг 2: Добавить русское название

```dart
String _getRoleDisplayName(UserRole role) {
  switch (role) {
    // ...
    case UserRole.supervisor:
      return 'Супервайзер';  // ← Новое
  }
}
```

### Шаг 3: Добавить цвет

```dart
Color _getRoleColor(UserRole role) {
  switch (role) {
    // ...
    case UserRole.supervisor:
      return const Color(0xFF9B59B6);  // Фиолетовый
  }
}
```

Всё! Новая роль автоматически появится в выпадающем меню.

---

## 🧪 ПРИМЕРЫ ИСПОЛЬЗОВАНИЯ

### Пример 1: Показать только администраторов

```
1. Нажать на выпадающее меню "Роль"
2. Выбрать "Администратор"
3. Список обновится, будут только администраторы
```

### Пример 2: Показать всех активных операторов

```
1. Роль: "Оператор"
2. Статус: "Активные"
3. Список покажет всех активных операторов
```

### Пример 3: Найти сотрудника "Иван" среди работников склада

```
1. Поиск: "Иван"
2. Роль: "Работник склада"
3. Список покажет "Ивана" только если он работник склада
```

---

## 💾 КЭШИРОВАНИЕ

**Важно:** Список кэшируется!

```dart
_usersFuture ??= dataSource.getUsers(...);
```

Это означает:
- При первой загрузке → запрос на сервер
- При изменении фильтра → новый запрос (в `_loadUsers`)
- Но при перестроении виджета без изменений → использует кэш

---

## 📊 ПОТОК ДАННЫХ

```
Выбор в UI
    ↓
setState (_roleFilter = новая роль)
    ↓
_loadUsers()
    ↓
dataSource.getUsers(role: "operator")
    ↓
HTTP GET /users?role=operator
    ↓
API возвращает JSON с отфильтрованными пользователями
    ↓
Парсим в List<UserManagementModel>
    ↓
FutureBuilder получает данные
    ↓
ListView.builder отрисовывает карточки
    ↓
Пользователь видит результаты ✅
```

---

## 🚀 ОПТИМИЗАЦИЯ

Для улучшения:

1. **Добавить дебаунс поиска** - не запрашивать на каждый символ
2. **Кэшировать результаты** - сохранять предыдущие фильтры
3. **Пагинацию** - загружать по частям при большом списке
4. **Многовыбор ролей** - фильтр по нескольким ролям одновременно

---

## ✨ РЕЗЮМЕ

| Параметр | Значение |
|----------|----------|
| **Где находится** | `employees_list_page.dart` |
| **Количество ролей** | 4 (admin, operator, warehouse_worker, sales_manager) |
| **Тип фильтра** | Выпадающее меню (DropdownButtonFormField) |
| **Dart Enum** | `UserRole.admin`, `UserRole.operator`, `UserRole.warehouseWorker`, `UserRole.salesManager` |
| **API Values** | `admin`, `operator`, `warehouse_worker`, `sales_manager` |
| **Передача на сервер** | `role: _roleFilter != null ? _getRoleApiValue(_roleFilter!) : null` |
| **Кэширование** | Есть (через `_usersFuture ??=`) |
| **Комбинация с другими фильтрами** | Да (поиск + роль + статус) |
