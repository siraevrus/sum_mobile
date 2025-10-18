import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sum_warehouse/core/theme/app_colors.dart';
import 'package:sum_warehouse/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Экран загрузки при инициализации приложения
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> 
    with TickerProviderStateMixin {
  
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _authInitialized = false; // Флаг чтобы избежать повторной инициализации
  
  @override
  void initState() {
    super.initState();
    
    // Инициализируем анимации
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
    ));
    
    // Запускаем анимацию
    _controller.forward();
    
    // Инициализируем аутентификацию ТОЛЬКО ОДИН РАЗ
    _initializeAuth();
  }
  
  void _initializeAuth() {
    if (_authInitialized) return;
    _authInitialized = true;
    
    
    // Задержка для анимации, затем проверяем авторизацию
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted && !_authInitialized) return; // Дополнительная проверка
      ref.read(authProvider.notifier).checkAuthStatus();
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    
    // Убираем логи из build() чтобы не засорять консоль при каждом rebuild
    
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
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
                      child: SvgPicture.asset(
                        'assets/logos/logo-expertwood.svg',
                        width: 64,
                        height: 64,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Название приложения
                    const Text(
                      'Expert Wood',
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
                    
                    // Индикатор состояния
                    authState.when(
                      initial: () => _buildLoadingIndicator('Инициализация...'),
                      loading: () => _buildLoadingIndicator('Загрузка...'),
                      authenticated: (user, token) => _buildSuccessIndicator('Добро пожаловать!'),
                      unauthenticated: () => _buildActionButton('Начать работу'),
                      error: (message) => _buildErrorIndicator(message),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildLoadingIndicator(String message) {
    return Column(
      children: [
        const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          message,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
  
  Widget _buildSuccessIndicator(String message) {
    return Column(
      children: [
        const Icon(
          Icons.check_circle_rounded,
          color: Colors.white,
          size: 32,
        ),
        const SizedBox(height: 16),
        Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
  
  Widget _buildActionButton(String text) {
    return ElevatedButton(
      onPressed: () {
        // Переход будет обработан роутером автоматически
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        elevation: 8,
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
  
  Widget _buildErrorIndicator(String message) {
    return Column(
      children: [
        const Icon(
          Icons.error_rounded,
          color: Colors.redAccent,
          size: 32,
        ),
        const SizedBox(height: 16),
        Text(
          'Ошибка загрузки',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            ref.read(authProvider.notifier).checkAuthStatus();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Text('Повторить'),
        ),
      ],
    );
  }
}
