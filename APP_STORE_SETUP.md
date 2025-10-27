# Подготовка приложения для публикации в App Store

## Текущие настройки приложения

### Версия и идентификатор
- **Версия**: 1.0.3+3 (из pubspec.yaml)
- **Bundle ID**: com.sumwarehouse.sumWarehouse
- **Development Team**: Q84E84JTU2
- **Название приложения**: Wood Warehouse

## Что нужно сделать

### Шаг 1: Проверка версии ✅
Версия уже установлена правильно в pubspec.yaml.

### Шаг 2: Настройка подписи в Xcode
1. Откройте проект в Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```
2. Выберите проект Runner в навигаторе
3. Выберите Target "Runner"
4. Откройте вкладку "Signing & Capabilities"
5. Включите "Automatically manage signing"
6. Выберите свою Apple Developer Team

### Шаг 3: Создание архивa
После настройки подписи выполните:
```bash
flutter clean
flutter pub get
cd ios
pod install
cd ..
flutter build ios --release
```

### Шаг 4: Создание архива через Xcode
1. Выберите "Any iOS Device" в качестве цели
2. Product → Archive
3. Дождитесь создания архива
4. В окне Organizer → Distribute App
5. Выберите "App Store Connect"
6. Следуйте инструкциям

### Шаг 5: Загрузка в App Store Connect
1. Проверьте что приложение создано в App Store Connect
2. Загрузите архив через Xcode Organizer
3. Дождитесь обработки
4. Заполните информацию о версии
5. Отправьте на ревью

## Возможные проблемы

### Проблема с подписью
Если возникает ошибка с Development Team:
1. Проверьте что у вас есть действующий Apple Developer Account
2. Проверьте что Team ID правильный в Xcode
3. Возможно нужно обновить сертификаты

### Проблема с иконками
Приложение использует placeholder иконку. Замените:
- Путь к иконке: `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

## Текущий статус
- ✅ Версия настроена
- ❌ Подпись требует настройки в Xcode
- ⚠️ Иконка приложения - placeholder
