# Bundle Identifier изменен на Wood.onza.me

## ✅ Изменения внесены

Старый Bundle ID: `ru.expwood.Wood.Warehouse.`  
Новый Bundle ID: **`Wood.onza.me`**

## ⚠️ ВАЖНО: Нужно зарегистрировать новый Bundle ID в Apple Developer

### Шаг 1: Создайте Bundle ID в Developer Portal
1. Откройте https://developer.apple.com/account/resources/identifiers/list
2. Нажмите "+" (добавить новый идентификатор)
3. Выберите "App IDs"
4. Введите Bundle ID: **Wood.onza.me**
5. Описание: "Wood Warehouse App"
6. Save и Register

### Шаг 2: Проверьте Team ID
1. Xcode → Preferences → Accounts
2. Выберите ваш Apple ID
3. Нажмите "Download Manual Profiles"
4. Убедитесь что Team ID правильный

### Шаг 3: Пересоберите приложение
```bash
flutter clean
flutter pub get
flutter build ios --release
```

### Шаг 4: Настройте подпись в Xcode
1. Откройте `ios/Runner.xcworkspace`
2. Выберите проект "Wood Warehouse"
3. Target "Runner" → Signing & Capabilities
4. Bundle Identifier должен быть: **Wood.onza.me**
5. Включите "Automatically manage signing"
6. Выберите ваш Team

### Шаг 5: Создайте архив
1. Выберите "Any iOS Device"
2. Product → Archive
3. Дождитесь завершения

### Шаг 6: Загрузите в App Store Connect
1. Organizer → "Distribute App"
2. "App Store Connect" → "Upload"

## Готово! 🎉
