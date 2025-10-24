# Файлы бокового меню - Справочник

## Основные файлы, влияющие на боковое меню

### 1. 🎨 ГЛАВНЫЙ ФАЙЛ - Дизайн бокового меню
**`lib/features/dashboard/presentation/widgets/modern_sidebar.dart`**

Это **единственный файл**, где определяется внешний вид бокового меню!

#### Что здесь настраивается:
- **Строка 39:** Основной фон меню
  ```dart
  color: Color(0xFF256437), // Темно-зеленый фон
  ```

- **Строки 77, 129:** Цвет разделителей
  ```dart
  color: Color(0xFF2D7A45), // Светло-зеленый
  ```

- **Строка 89:** Цвет аватара пользователя
  ```dart
  backgroundColor: const Color(0xFF38A169), // Зеленый
  ```

- **Строка 302:** Цвет активного пункта меню
  ```dart
  selectedTileColor: const Color(0xFF2D7A45), // Светло-зеленый
  ```

- **Строки 324, 363:** Цвет раскрытого подменю
  ```dart
  color: Color(0xFF1E5030), // Темный зеленый
  ```

- **Строка 396:** Цвет активного подпункта
  ```dart
  selectedTileColor: const Color(0xFF2D7A45), // Светло-зеленый
  ```

---

### 2. 📱 Страницы, которые ИСПОЛЬЗУЮТ боковое меню

#### 2.1 Основная страница (используется приложением)
**`lib/features/dashboard/presentation/pages/responsive_dashboard_page.dart`**
- **Строка 8:** Импортирует `ModernSidebar`
- **Строка 108:** Использует `ModernSidebar` в Row для десктопа
- **НЕ меняет цвета** - только размещает компонент

#### 2.2 Альтернативная страница (не используется)
**`lib/features/dashboard/presentation/pages/modern_dashboard_page.dart`**
- Импортирует `ModernSidebar`
- В данный момент не используется в роутинге

#### 2.3 Временная страница
**`lib/features/dashboard/presentation/pages/responsive_dashboard_page_temp.dart`**
- **Строка 321:** Использует `ModernSidebar` как drawer (выдвижное меню)
- В данный момент не используется в роутинге

---

### 3. 🔀 Роутинг - где подключается боковое меню

**`lib/core/router/app_router.dart`**
- **Строка 8:** Импортирует `ResponsiveDashboardPage`
- **Строка 100:** Маршрут `/dashboard` → `ResponsiveDashboardPage()`
- **Строки 105+:** Все остальные маршруты тоже используют `ResponsiveDashboardPage`

---

## 🎯 Краткий итог

### Где МЕНЯТЬ цвета бокового меню:
**ТОЛЬКО в одном файле:**
```
lib/features/dashboard/presentation/widgets/modern_sidebar.dart
```

### Где боковое меню ОТОБРАЖАЕТСЯ:
```
lib/features/dashboard/presentation/pages/responsive_dashboard_page.dart
```
(но здесь цвета НЕ настраиваются - только размещение)

---

## 📋 Карта цветов бокового меню

```dart
// Файл: modern_sidebar.dart

Container(
  decoration: BoxDecoration(
    color: Color(0xFF256437), // ← Основной фон меню (строка 39)
  ),
  child: Column(
    children: [
      // Логотип и название
      Container(...),
      
      Divider(
        color: Color(0xFF2D7A45), // ← Разделитель (строка 77)
      ),
      
      // Аватар пользователя
      CircleAvatar(
        backgroundColor: Color(0xFF38A169), // ← Аватар (строка 89)
      ),
      
      Divider(
        color: Color(0xFF2D7A45), // ← Разделитель (строка 129)
      ),
      
      // Пункты меню
      ListTile(
        selectedTileColor: Color(0xFF2D7A45), // ← Активный пункт (строка 302)
      ),
      
      // Раскрытое подменю
      Container(
        color: Color(0xFF1E5030), // ← Фон подменю (строки 324, 363)
        child: ListTile(
          selectedTileColor: Color(0xFF2D7A45), // ← Активный подпункт (строка 396)
        ),
      ),
    ],
  ),
)
```

---

## ⚠️ Важные замечания

1. **Один источник правды:** Все цвета меню определены только в `modern_sidebar.dart`
2. **Страницы - это только контейнеры:** `responsive_dashboard_page.dart` и другие страницы просто размещают компонент, но не меняют его стиль
3. **Роутер использует одну страницу:** Все маршруты (`/dashboard`, `/inventory`, `/sales` и т.д.) используют `ResponsiveDashboardPage`
4. **Меню всегда одинаковое:** Независимо от раздела, боковое меню выглядит одинаково

---

## 🔍 Как проверить, где используется файл

```bash
# Найти все файлы, импортирующие ModernSidebar
grep -r "ModernSidebar" lib/

# Найти все файлы, импортирующие modern_sidebar.dart
grep -r "modern_sidebar" lib/

# Проверить роутинг
grep -r "ResponsiveDashboardPage" lib/core/router/
```

---

## ✅ Чек-лист при изменении цветов меню

- [ ] Изменить `modern_sidebar.dart` (единственный файл с цветами)
- [ ] Запустить `flutter clean`
- [ ] Собрать APK: `flutter build apk --release`
- [ ] Удалить старое приложение с устройства
- [ ] Установить новый APK
- [ ] Проверить результат

---

## 📝 История изменений

### 23 октября 2025
- Изменен основной цвет с синего (#2C5CCF) на темно-зеленый (#256437)
- Все цвета меню обновлены на зеленую палитру
- Файл изменен: `modern_sidebar.dart`
- Другие файлы НЕ требовали изменений



