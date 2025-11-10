import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sum_warehouse/core/router/app_router.dart';
import 'package:sum_warehouse/core/theme/app_theme.dart';
import 'package:sum_warehouse/features/app/presentation/providers/app_counters_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Устанавливаем белый статус-бар с темными иконками глобально
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.light, // для iOS - темные иконки
      statusBarIconBrightness: Brightness.dark, // для Android - темные иконки
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  runApp(
    const ProviderScope(
      child: SumWarehouseApp(),
    ),
  );
}

class SumWarehouseApp extends ConsumerStatefulWidget {
  const SumWarehouseApp({super.key});

  @override
  ConsumerState<SumWarehouseApp> createState() => _SumWarehouseAppState();
}

class _SumWarehouseAppState extends ConsumerState<SumWarehouseApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Отмечаем открытие приложения при запуске
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markAppOpened();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // При возврате из фона обновляем счетчики
    if (state == AppLifecycleState.resumed) {
      _refreshCounters();
    }
  }

  Future<void> _markAppOpened() async {
    try {
      // Предзагружаем счетчики при запуске приложения
      // Это гарантирует, что счетчики будут готовы к моменту открытия меню
      final countersFuture = ref.read(appCountersProvider.future);
      await ref.read(appCountersProvider.notifier).markAppOpened();
      // Ждем завершения загрузки счетчиков
      await countersFuture;
    } catch (e) {
      // Игнорируем ошибки при отметке открытия
    }
  }

  Future<void> _refreshCounters() async {
    try {
      await ref.read(appCountersProvider.notifier).refresh();
    } catch (e) {
      // Игнорируем ошибки при обновлении счетчиков
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    
    return MaterialApp.router(
      title: 'Wood Warehouse',
      theme: AppTheme.lightTheme,
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