import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sum_warehouse/core/router/app_router.dart';
import 'package:sum_warehouse/core/theme/app_theme.dart';

void main() {
  // Устанавливаем черный статус-бар для iOS один раз при старте
  _setSystemUIStyle();
  
  runApp(
    const ProviderScope(
      child: SumWarehouseApp(),
    ),
  );
}

void _setSystemUIStyle() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.light,
    ),
  );
}

class SumWarehouseApp extends ConsumerWidget {
  const SumWarehouseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    
    return MaterialApp.router(
      title: 'Wood Warehouse',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      
      builder: (context, child) {
        return _SystemUIWrapper(child: child ?? const SizedBox.shrink());
      },
      
      // Локализация
      locale: const Locale('ru'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ru'),
        Locale('en'),
      ],
    );
  }
}

/// Обертка для поддержания статус-бара при переходах между экранами
class _SystemUIWrapper extends StatefulWidget {
  final Widget child;

  const _SystemUIWrapper({required this.child});

  @override
  State<_SystemUIWrapper> createState() => _SystemUIWrapperState();
}

class _SystemUIWrapperState extends State<_SystemUIWrapper> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Восстанавливаем стиль статус-бара когда приложение возобновляется
      _setSystemUIStyle();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}