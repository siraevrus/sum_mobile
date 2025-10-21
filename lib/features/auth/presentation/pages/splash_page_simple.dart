import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sum_warehouse/core/theme/app_colors.dart';
import 'package:sum_warehouse/features/auth/presentation/providers/auth_provider.dart';
import 'package:sum_warehouse/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
    
    
    // Проверяем текущее состояние авторизации
    final currentState = ref.read(authProvider);
    
    // Если уже авторизован или выполняется загрузка - не запускаем проверку повторно  
    if (currentState.maybeWhen(
      authenticated: (user, token) => true, 
      loading: () => true,
      orElse: () => false
    )) {
      return;
    }
    
    // Небольшая задержка для показа splash screen
    await Future.delayed(const Duration(milliseconds: 800));
    
    if (!mounted) {
      return;
    }
    
    try {
      ref.read(authProvider.notifier).checkAuthStatus();
    } catch (e) {
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F1DF),
      body: Consumer(
        builder: (context, ref, child) {
          final authState = ref.watch(authProvider);
          
          // Реагируем на изменения состояния для навигации
          authState.maybeWhen(
            authenticated: (user, token) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!context.mounted) return;
                final target = user.role == UserRole.admin ? '/dashboard' : '/inventory';
                context.go(target);
              });
            },
            unauthenticated: () {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
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
                SvgPicture.asset(
                  "assets/logos/logo-expertwood-green.svg",
                  width: 120,
                  height: 120,
                ),
                const SizedBox(height: 32),
                
                // Название приложения
                const Text(
                  'Expert Wood',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF256437),
                  ),
                ),
                const SizedBox(height: 8),
                
                // Описание
                const Text(
                  'Система складского учета',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF256437),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 48),
                
                // Сообщение о проверке авторизации
                const Text(
                  'Проверка авторизации...',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF256437),
                    fontWeight: FontWeight.w500,
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
