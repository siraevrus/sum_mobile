# Обновление логотипа при загрузке приложения

## Сделанные изменения

### 1. Добавлены необходимые файлы и зависимости
- ✅ Скопирован логотип `logo-expertwood.svg` в папку `assets/logos/`
- ✅ Добавлена зависимость `flutter_svg: ^2.0.0` в `pubspec.yaml`
- ✅ Активирована папка `assets/logos/` в конфигурации Flutter

### 2. Обновлены файлы экранов
Заменены стандартные иконки на красивый SVG логотип:

#### `/lib/features/auth/presentation/pages/splash_page.dart`
- Заменён `Icons.warehouse` на `SvgPicture.asset('assets/logos/logo-expertwood.svg')`
- Размер логотипа: 64x64 px (внутри контейнера 120x120 px)
- Добавлен import: `import 'package:flutter_svg/flutter_svg.dart';`

#### `/lib/features/auth/presentation/pages/splash_page_simple.dart`
- Заменён `Icons.warehouse` на `SvgPicture.asset('assets/logos/logo-expertwood.svg')`
- Размер логотипа: 64x64 px (внутри контейнера 120x120 px)
- Добавлен import: `import 'package:flutter_svg/flutter_svg.dart';`

#### `/lib/features/auth/presentation/pages/login_page.dart`
- Заменён `Icons.warehouse` на `SvgPicture.asset('assets/logos/logo-expertwood.svg')`
- Размер логотипа: 80x80 px
- Добавлен colorFilter для поддержки белого цвета на синем фоне
- Добавлен import: `import 'package:flutter_svg/flutter_svg.dart';`

### 3. Описание логотипа
Логотип содержит:
- 🌲 Деревья (символизируют Expert Wood - работу с древесиной)
- 🪚 Деревянный материал (стопка досок)
- 🏗️ Строительный кран (символизирует складское хозяйство)
- Чёрно-белый дизайн, который идеально смотрится на синем фоне приложения

### 4. Результат
При запуске приложения на экране загрузки вместо скучной иконки склада теперь отображается профессиональный логотип компании с размерами согласно дизайну.

## Команды для проверки
```bash
# Обновить зависимости
flutter pub get

# Запустить приложение
flutter run
```

