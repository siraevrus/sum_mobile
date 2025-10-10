import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sum_warehouse/core/theme/app_colors.dart';
import 'package:sum_warehouse/features/auth/domain/entities/user_entity.dart';
import 'package:sum_warehouse/features/auth/presentation/providers/auth_provider.dart';
import 'package:sum_warehouse/features/auth/presentation/widgets/login_form.dart';

/// Экран авторизации
class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Слушаем изменения состояния аутентификации
    ref.listen<AuthState>(authProvider, (previous, next) {
      print('🟡 LoginPage: Состояние изменилось: ${previous?.runtimeType} → ${next.runtimeType}');
      
      next.maybeWhen(
        authenticated: (user, token) {
          // Успешная авторизация - переходим на секцию по роли
          print('🟢 LoginPage: Успешная авторизация для ${user.email}, переходим по роли');
          final target = user.role == UserRole.admin ? '/dashboard' : '/inventory';
          if (context.mounted) {
            print('🟢 LoginPage: Выполняем go на $target');
            context.go(target);
          }
        },
        error: (message) {
          print('🔴 LoginPage: Ошибка авторизации: $message');
          // Показываем сообщение об ошибке пользователю
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        loading: () {
          print('🟡 LoginPage: Состояние loading');
        },
        orElse: () {
          print('🟡 LoginPage: Другое состояние: ${next.runtimeType}');
        },
      );
    });

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                
                // Логотип и заголовок
                const Icon(
                  Icons.warehouse,
                  size: 80,
                  color: Colors.white,
                ),
                const SizedBox(height: 24),
                
                const Text(
                  'СкладOnline',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                
                const Text(
                  'Система складского учета',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 60),
                
                // Форма входа
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: LoginForm(),
                  ),
                ),
                
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
