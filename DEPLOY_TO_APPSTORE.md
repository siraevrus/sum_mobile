# Инструкция по загрузке приложения в App Store

## Пошаговая инструкция

### 1. Откройте проект в Xcode
```bash
open ios/Runner.xcworkspace
```

### 2. Настройте подпись
1. В навигаторе выберите проект "Runner"
2. Выберите Target "Runner"
3. Откройте вкладку "Signing & Capabilities"
4. Включите "Automatically manage signing"
5. Выберите вашу Apple Developer Team

### 3. Выберите устройство для сборки
- В верхней панели Xcode выберите "Any iOS Device" (или подключенное устройство)

### 4. Создайте архив
1. Меню: Product → Archive
2. Дождитесь завершения сборки
3. Откроется окно Organizer

### 5. Загрузите в App Store Connect
1. В окне Organizer нажмите "Distribute App"
2. Выберите "App Store Connect"
3. Нажмите "Upload"
4. Следуйте инструкциям
5. Дождитесь завершения загрузки

### 6. Проверьте в App Store Connect
1. Откройте https://appstoreconnect.apple.com
2. Перейдите в "Мои приложения"
3. Найдите "Wood Warehouse"
4. Дождитесь обработки билда (10-30 минут)
5. После обработки нажмите "+ Version"
6. Выберите загруженный билд
7. Заполните информацию о версии
8. Отправьте на ревью

## Текущие настройки приложения:
- Bundle ID: com.sumwarehouse.sumWarehouse
- Версия: 1.0.3+3
- Название: Wood Warehouse
