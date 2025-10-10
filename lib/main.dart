import 'package:flutter/material.dart';
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

class SumWarehouseApp extends ConsumerWidget {
  const SumWarehouseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    
    // Запускаем предзагрузку данных при старте приложения
    
    return MaterialApp.router(
      title: 'СкладOnline',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      
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