import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sum_warehouse/core/theme/app_colors.dart';
import 'package:sum_warehouse/features/auth/domain/entities/user_entity.dart';
import 'package:sum_warehouse/features/auth/presentation/providers/auth_provider.dart';
import 'package:sum_warehouse/features/auth/presentation/widgets/login_form.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Экран авторизации
class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Слушаем изменения состояния аутентификации
    ref.listen<AuthState>(authProvider, (previous, next) {
      
      next.maybeWhen(
        authenticated: (user, token) {
          // Успешная авторизация - переходим на секцию по роли
          final target = user.role == UserRole.admin ? '/dashboard' : '/inventory';
          if (context.mounted) {
            context.go(target);
          }
        },
        error: (message) {
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
        },
        orElse: () {
        },
      );
    });

    return Scaffold(
      backgroundColor: const Color(0xFFFAF2E0),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                
                // Логотип и заголовок
                SvgPicture.asset(
                  'assets/logos/logo-expertwood-green.svg',
                  width: 80,
                  height: 80,
                ),
                const SizedBox(height: 24),
                
                const Text(
                  'Wood Warehouse',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF256437),
                  ),
                ),
                const SizedBox(height: 8),
                
                const Text(
                  'Система складского учета',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF256437),
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
