import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sum_warehouse/core/theme/app_colors.dart';
import 'package:sum_warehouse/features/auth/presentation/providers/auth_provider.dart';
import 'package:sum_warehouse/features/auth/domain/entities/user_entity.dart';

/// Упрощенный экран загрузки без циклов
class SimpleSplashPage extends ConsumerStatefulWidget {
  const SimpleSplashPage({super.key});

  @override
  ConsumerState<SimpleSplashPage> createState() => _SimpleSplashPageState();
}

class _SimpleSplashPageState extends ConsumerState<SimpleSplashPage> {
  bool _initialized = false;
  
  @override
  void initState() {
    super.initState();
    _initialize();
  }
  
  void _initialize() async {
    if (_initialized) return;
    _initialized = true;
    
    print('🚀 SimpleSplashPage: Инициализация начата (Mounted: $mounted)');
    
    // Проверяем текущее состояние авторизации
    final currentState = ref.read(authProvider);
    print('🚀 SimpleSplashPage: Текущее состояние: ${currentState.runtimeType}');
    
    // Если уже авторизован или выполняется загрузка - не запускаем проверку повторно  
    if (currentState.maybeWhen(
      authenticated: (user, token) => true, 
      loading: () => true,
      orElse: () => false
    )) {
      print('🚀 SimpleSplashPage: Уже авторизован или загружается, пропускаем проверку');
      return;
    }
    
    // Небольшая задержка для показа splash screen
    await Future.delayed(const Duration(milliseconds: 800));
    
    if (!mounted) {
      print('🚀 SimpleSplashPage: Виджет размонтирован, прерываем инициализацию');
      return;
    }
    
    print('🚀 SimpleSplashPage: Запускаем проверку авторизации');
    try {
      ref.read(authProvider.notifier).checkAuthStatus();
    } catch (e) {
      print('🔴 SimpleSplashPage: Ошибка при проверке статуса: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Consumer(
        builder: (context, ref, child) {
          final authState = ref.watch(authProvider);
          print('🎨 SplashPage: Отображаем состояние ${authState.runtimeType}');
          
          // Реагируем на изменения состояния для навигации
          authState.maybeWhen(
            authenticated: (user, token) {
              print('🎨 SplashPage: Пользователь авторизован, перенаправляем на секцию по роли');
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!context.mounted) return;
                final target = user.role == UserRole.admin ? '/dashboard' : '/inventory';
                print('🚀 SplashPage: Переход на $target');
                context.go(target);
              });
            },
            unauthenticated: () {
              print('🎨 SplashPage: Пользователь не авторизован, перенаправляем на логин');
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  print('🚀 SplashPage: Переход на /login');
                  context.go('/login');
                }
              });
            },
            orElse: () {},
          );
          
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Логотип
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.warehouse,
                    size: 64,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Название приложения
                const Text(
                  'Sum Warehouse',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Подзаголовок
                const Text(
                  'Система складского учета',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 60),
                
                // Индикатор загрузки и статус
                authState.maybeWhen(
                  initial: () => Column(
                    children: const [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Инициализация...',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                  loading: () => Column(
                    children: const [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Проверка авторизации...',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                  authenticated: (user, token) => Column(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white, size: 32),
                      const SizedBox(height: 16),
                      Text(
                        'Добро пожаловать, ${user.name}!',
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  unauthenticated: () => Column(
                    children: const [
                      Icon(Icons.login, color: Colors.white, size: 32),
                      SizedBox(height: 16),
                      Text(
                        'Переход на страницу входа...',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  error: (message) => Column(
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 32),
                      const SizedBox(height: 16),
                      Text(
                        'Ошибка: $message',
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  orElse: () => Column(
                    children: const [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Загрузка...',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
