import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sum_warehouse/features/auth/presentation/providers/auth_provider.dart';
import 'package:sum_warehouse/features/auth/presentation/widgets/modern_login_form.dart';
import 'package:sum_warehouse/features/auth/domain/entities/user_entity.dart';

/// Современный экран авторизации в стиле веб-фронта
class ModernLoginPage extends ConsumerWidget {
  const ModernLoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Слушаем изменения состояния аутентификации
    ref.listen<AuthState>(authProvider, (previous, next) {
      next.maybeWhen(
        authenticated: (user, token) {
          if (context.mounted) {
            final target = user.role == UserRole.admin ? '/dashboard' : '/inventory';
            context.go(target);
          }
        },
        error: (message) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        orElse: () {},
      );
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Заголовок как на веб-сайте
                const Text(
                  'Система складского учета',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                
                // Подзаголовок
                const Text(
                  'Войдите в свой аккаунт',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF666666),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Форма входа
                const ModernLoginForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
