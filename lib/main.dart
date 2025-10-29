import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sum_warehouse/core/router/app_router.dart';
import 'package:sum_warehouse/core/theme/app_theme.dart';

void main() {
  runApp(
    const ProviderScope(
      child: SumWarehouseApp(),
    ),
  );
}

void _setStatusBarStyle() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
}

/// NavigatorObserver для переустановления статус-бара при навигации
class _SystemUiNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    _setStatusBarStyle();
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    _setStatusBarStyle();
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    _setStatusBarStyle();
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    _setStatusBarStyle();
  }
}

class SumWarehouseApp extends ConsumerWidget {
  const SumWarehouseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: MaterialApp.router(
        title: 'Wood Warehouse',
        theme: AppTheme.lightTheme,
        routerConfig: router,
        debugShowCheckedModeBanner: false,
        
        builder: (context, child) {
          // Переустанавливаем стиль при каждом построении
          _setStatusBarStyle();
          return child ?? const SizedBox.shrink();
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
      ),
    );
  }
}