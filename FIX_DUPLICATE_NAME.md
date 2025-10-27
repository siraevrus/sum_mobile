# Решение проблемы: имя приложения уже используется

## Проблема
"Wood Warehouse" уже используется другим приложением в вашем аккаунте.

## Решение: Измените название приложения

### Вариант 1: Измените в App Store Connect (РЕКОМЕНДУЕТСЯ)
1. Откройте https://appstoreconnect.apple.com
2. Найдите приложение "Wood Warehouse" которое уже существует
3. Измените его название
4. Или удалите его если он больше не нужен

### Вариант 2: Используйте другое имя для нового приложения

#### Шаг 1: Обновите название в коде
Файл: `ios/Runner/Info.plist`
```xml
<key>CFBundleDisplayName</key>
<string>Wood Warehouse App</string>

<key>CFBundleName</key>
<string>Wood Warehouse App</string>
```

#### Шаг 2: Обновите в Xcode
1. Откройте проект Runner
2. General → Display Name = "Wood Warehouse App"
3. Bundle Identifier = com.sumwarehouse.woodWarehouseApp

#### Шаг 3: Соберите заново
```bash
flutter clean
flutter build ipa --release
```

### Вариант 3: Используйте существующее приложение
1. В App Store Connect найдите "Wood Warehouse"
2. Добавьте новую версию
3. Загрузите билд туда

## Рекомендуемые альтернативные названия:
- "Wood Warehouse Mobile"
- "Wood Warehouse Manager"
- "Wood Warehouse System"
- "WoodStock Mobile"
- "WoodStock Manager"

Выберите один и обновите все упоминания!
