# Пересборка после изменения имени

## ✅ Название изменено на "Wood Warehouse Mobile"

## Следующие шаги:

### 1. Пересоберите приложение
```bash
flutter clean
flutter build ipa --release
```

### 2. Экспортируйте через Xcode
1. Откройте `ios/Runner.xcworkspace`
2. Window → Organizer
3. Найдите архив "Runner"
4. Distribute App → Export
5. Сохраните .ipa

### 3. Загрузите через Transporter
1. Установите Transporter из Mac App Store
2. Откройте Transporter
3. Перетащите .ipa файл
4. Нажмите "Deliver"

### 4. Создайте новое приложение в App Store Connect
1. Откройте https://appstoreconnect.apple.com
2. Мои приложения → "+"
3. Новое приложение iOS
4. Имя: **"Wood Warehouse Mobile"**
5. Первичный язык: Русский
6. Bundle ID: com.sumwarehouse.sumWarehouse
7. Создайте приложение

### 5. Загрузите билд
После загрузки через Transporter:
1. Дождитесь обработки
2. Нажмите "+ Version"
3. Выберите загруженный билд
4. Заполните информацию
5. Отправьте на ревью

## Альтернатива: Обновите существующее приложение
Если хотите использовать старое приложение:
1. Найдите "Wood Warehouse" в App Store Connect
2. Добавьте версию 1.0.3
3. Загрузите билд туда
